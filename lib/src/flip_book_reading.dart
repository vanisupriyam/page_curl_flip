part of 'flip_book.dart';

/// Everything that speaks: the reading loop, its sessions, pause/resume,
/// and the play-all chain. Split out of the state 2026-09-02 — the runaway
/// bug (TTS-18) lived three lines from unrelated marking code, which is the
/// argument for this file existing.
mixin _ReadAloudMixin on _FlipBookStateBase {
  // ── Read-aloud ─────────────────────────────────────────────────────────────
  // Idle shows a single play button. Playing shows pause (when the caller
  // supports it) and stop. Paused shows play (resume) and stop. _readSession
  // guards against a stale future's completion overwriting a newer state:
  // pause and stop both invalidate the session, so the previous await's
  // continuation is ignored.
  //
  // Reading is sentence-by-sentence: the page's visible text is split into
  // sentences, each handed to onReadAloud in turn. The loop therefore always
  // knows which sentence the voice is on — that index IS the read marker,
  // with no engine timing events involved.

  @override
  bool get _canPauseReading =>
      _read?.onPause != null && _read?.onResume != null;

  /// The sentence the marker draws, or null when idle / marker disabled.
  @override
  _SentenceRef? get _currentSentence {
    final i = _markedSentence;
    if (!(_read?.highlight.show ?? false) ||
        i == null ||
        i >= _readSentences.length) {
      return null;
    }
    return _readSentences[i];
  }

  /// Sentence boundaries. `。` `！` `？` end a sentence unconditionally (CJK
  /// writes no space after them) and so does a newline; `.` `!` `?` `…` `؟`
  /// end one only when the character after the terminator-and-quote run is
  /// whitespace or the end of the text — which keeps `pub.dev` and `8.5`
  /// whole.
  static List<TextRange> _splitSentences(String text) {
    const cjk = '。！？';
    const western = '.!?…؟';
    const closers = '"\'’”)»›';
    final ranges = <TextRange>[];
    var start = 0;
    var i = 0;
    void close(int end) {
      if (text.substring(start, end).trim().isNotEmpty) {
        ranges.add(TextRange(start: start, end: end));
      }
      start = end;
      i = end;
    }

    while (i < text.length) {
      final c = text[i];
      if (c == '\n' || cjk.contains(c)) {
        var end = i + 1;
        while (end < text.length && closers.contains(text[end])) {
          end++;
        }
        close(end);
      } else if (western.contains(c)) {
        var j = i + 1;
        while (j < text.length &&
            (western.contains(text[j]) || closers.contains(text[j]))) {
          j++;
        }
        if (j >= text.length || text[j] == ' ' || text[j] == '\n') {
          close(j);
        } else {
          i++;
        }
      } else {
        i++;
      }
    }
    if (start < text.length && text.substring(start).trim().isNotEmpty) {
      ranges.add(TextRange(start: start, end: text.length));
    }
    return ranges;
  }

  /// What the voice reads and the marker marks: exactly the parts the page
  /// HAS — printed title, tagline, and the body, in that order.
  ///
  /// The body arrives one of two ways. `bodySegments` are the author's own
  /// units, taken exactly as written — one segment, one mark, one call to
  /// the engine. A single `bodyText` is split here instead, on full stops,
  /// grouped [FlipBookReadAloud.unitsPerMark] at a time; that guessing is what
  /// segments exist to avoid.
  List<_SentenceRef> _sentencesOf(FlipBookPage page) {
    final refs = <_SentenceRef>[];
    final perMark =
        (_read?.unitsPerMark ?? 1) < 1 ? 1 : (_read?.unitsPerMark ?? 1);

    void split(_ReadPart part, int segment, String? source) {
      if (source == null || source.trim().isEmpty) {
        return;
      }
      final ranges = _splitSentences(source);
      // Merge consecutive sentences into one mark. They share a string, so
      // the group is simply first.start → last.end.
      for (var i = 0; i < ranges.length; i += perMark) {
        final last = (i + perMark - 1).clamp(i, ranges.length - 1);
        final range = TextRange(start: ranges[i].start, end: ranges[last].end);
        refs.add(_SentenceRef(
          part,
          segment,
          range,
          source.substring(range.start, range.end).trim(),
        ));
      }
    }

    final read = _read;
    split(
      _ReadPart.title,
      0,
      page.showTitleOnPage && (read?.readTitle ?? true) ? page.title : null,
    );
    split(_ReadPart.tagline, 0,
        (read?.readTagline ?? true) ? page.tagline : null);

    if (!(read?.readBody ?? true)) {
      return refs;
    }
    final segments = page.bodySegments;
    if (segments != null) {
      for (var i = 0; i < segments.length; i++) {
        final text = segments[i].trim();
        if (text.isEmpty) {
          continue;
        }
        refs.add(_SentenceRef(
          _ReadPart.body,
          i,
          TextRange(start: 0, end: segments[i].length),
          text,
        ));
      }
    } else {
      split(_ReadPart.body, 0, page.bodyText);
    }
    return refs;
  }

  /// The reading loop: mark unit [start], speak it, await completion,
  /// advance. Every lap re-checks the session so pause, stop, navigation,
  /// or a newer session all end this loop silently.
  ///
  /// The mark moves only when the engine reports the unit finished — never
  /// on a timer. That is why it cannot drift, and why a reader who slows
  /// the voice down sees the mark slow down with it, for free.
  Future<void> _runSentences(int session, int start) async {
    for (var i = start; i < _readSentences.length; i++) {
      if (!mounted || session != _readSession) {
        return;
      }
      setState(() => _markedSentence = i);
      try {
        await _read!.onRead(_readSentences[i].text);
      } catch (_) {
        // The engine failed — a lost network, a missing clip (TTS-13). End
        // the WHOLE reading, never just this page: the play-all chain cannot
        // tell "failed instantly" from "finished", so chaining an errored
        // page forward flips the book end to end at animation speed with no
        // quiet frame in which to press stop (found on a device, offline,
        // 2026-09-02, TTS-18).
        if (!mounted || session != _readSession) {
          return;
        }
        _failReadingSession();
        return;
      }
      if (!mounted || session != _readSession) {
        return;
      }
    }
    if (!mounted || session != _readSession) {
      return;
    }
    _endReadingSession();
  }

  /// Reading ended because the engine failed: the same idle reset as a
  /// natural end, but the play-all chain dies with the page. Only a page
  /// that truly finished may carry the book forward.
  void _failReadingSession() {
    _readChains = false;
    _endReadingSession();
  }

  /// Reading finished on its own: back to idle, marker cleared, and the
  /// play-all chain carries on if it owns this session.
  void _endReadingSession() {
    setState(() {
      _readPhase = _ReadPhase.idle;
      _markedSentence = null;
    });
    if ((_read?.playAll ?? false) && _readChains) {
      unawaited(_advanceReading());
    }
  }

  /// After a resume, the interrupted unit finishes through the app's
  /// resume future — then the loop carries on with the next one.
  Future<void> _resumeThenContinue(int session) async {
    var failed = false;
    try {
      await _read?.onResume!();
    } catch (_) {
      failed = true;
    }
    if (!mounted || session != _readSession) {
      return;
    }
    if (failed) {
      // Same rule as the loop: a resume the engine cannot honour ends the
      // whole reading — chaining here would be the same runaway, one page in.
      _failReadingSession();
      return;
    }
    await _runSentences(session, (_markedSentence ?? -1) + 1);
  }

  /// The play-all chain ([FlipBookReadAloud.playAll]): a page that finishes
  /// reading naturally flips forward and reads on, to the end of the book.
  /// Stop, a manual flip, or a jump all invalidate the session or move the
  /// page out from under the chain — each check below ends it cleanly.
  Future<void> _advanceReading() async {
    final target = _pageIndex + 1;
    if (target >= _pageCount || _flipPhase != _FlipPhase.idle) {
      return; // Last page, or a flip already in progress.
    }
    await _goNext();
    if (!mounted ||
        _readPhase != _ReadPhase.idle ||
        _flipPhase != _FlipPhase.idle ||
        _pageIndex != target) {
      return; // A user action won the race — the chain ends here.
    }
    _playReading(_pageIndex, chain: true);
  }

  @override
  void _playReading(int page, {bool chain = false}) {
    // EDG-06: two taps inside one frame must not start two speech sessions.
    if (_readPhase != _ReadPhase.idle || _pageCount == 0) {
      return;
    }
    final refs =
        _sentencesOf(widget.pages.items[page.clamp(0, _pageCount - 1)]);
    if (refs.isEmpty) {
      return; // Nothing readable on this page.
    }
    _readChains = chain;
    _readSentences = refs;
    final session = ++_readSession;
    setState(() => _readPhase = _ReadPhase.playing);
    unawaited(_runSentences(session, 0));
  }

  @override
  void _pauseReading() {
    if (_readPhase != _ReadPhase.playing) {
      return;
    }
    _readSession++; // Orphans the running loop. The marker holds its place.
    _read?.onPause?.call();
    setState(() => _readPhase = _ReadPhase.paused);
  }

  @override
  void _resumeReading() {
    final session = ++_readSession;
    setState(() => _readPhase = _ReadPhase.playing);
    unawaited(_resumeThenContinue(session));
  }

  @override
  void _stopReading() {
    if (_readPhase == _ReadPhase.idle) {
      return;
    }
    _readSession++;
    _readChains = false;
    _read?.onStop?.call();
    setState(() {
      _readPhase = _ReadPhase.idle;
      _markedSentence = null; // Stop, navigation, background: marker clears.
    });
  }

  /// Keep / discard the passage just dragged out. Floated under the marked
  /// words by [MarkedText], not parked in the footer.
}
