import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'capture.dart';
import 'curl_overlay.dart';
import 'flip_book_bookmarks.dart';
import 'flip_book_contents.dart';
import 'flip_book_export.dart';
import 'flip_book_export_entry.dart';
import 'flip_book_export_kind.dart';
import 'flip_book_footer.dart';
import 'flip_book_header.dart';
import 'flip_book_marker.dart';
import 'flip_book_page.dart';
import 'flip_book_page_style.dart';
import 'flip_book_pages.dart';
import 'flip_book_read_aloud.dart';
import 'flip_book_read_speed.dart';
import 'flip_book_swipe.dart';
import 'flip_speed.dart';
import 'marked_text.dart';
import 'read_marker_text.dart';
import 'reader_mark.dart';

/// Drives a [FlipBook] from outside the widget — flip, jump, open the table
/// of contents, mute — so an app can remove the built-in chrome
/// (`header: null, footer: null`) and draw its own controls anywhere:
///
/// ```dart
/// final controller = FlipBookController();
///
/// FlipBook(
///   controller: controller,
///   header: null,
///   footer: null,
///   pages: FlipBookPages(items: const [...]),
///   onClose: () {},
/// );
///
/// // Your own button, any position, any style:
/// FloatingActionButton(onPressed: controller.nextPage);
/// ```
///
/// The controller shares this file with [FlipBook] — the same pattern Flutter
/// uses for `ExpansionTileController` — because it operates directly on the
/// widget's private state.
class FlipBookController {
  // Attach order, oldest first. The last entry is the book being driven;
  // when it is disposed the previous one automatically takes over (EDG-08).
  final List<_FlipBookState> _attached = [];

  _FlipBookState? get _state => _attached.isEmpty ? null : _attached.last;

  void _attach(_FlipBookState state) {
    _attached
      ..remove(state)
      ..add(state);
  }

  void _detach(_FlipBookState state) {
    _attached.remove(state);
  }

  /// Whether a [FlipBook] is currently attached to this controller.
  bool get isAttached => _state != null;

  /// Index of the page the book is showing; 0 while detached.
  int get page => _state?._pageIndex ?? 0;

  /// Whether the flip sound is currently muted.
  bool get isMuted => _state?._muted ?? false;

  /// Flips forward one page with the curl animation, honouring the book's
  /// reading direction. Does nothing on the last page or while detached.
  Future<void> nextPage() async => _state?._goNext();

  /// Flips back one page with the curl animation, honouring the book's
  /// reading direction. Does nothing on the first page or while detached.
  Future<void> previousPage() async => _state?._goPrev();

  /// Jumps straight to the page at [index] with no animation — the same move
  /// as tapping an entry in the table of contents. Out-of-range indices are
  /// ignored.
  void jumpToPage(int index) {
    final state = _state;
    if (state == null || index < 0 || index >= state._pageCount) {
      return;
    }
    state._jumpToPage(index);
  }

  /// Opens the table of contents. Needs at least one page with a title.
  /// Ignored while a flip is in progress (EDG-05) — the TOC opening over a
  /// half-finished animation would show inconsistent page state.
  void openIndex() {
    final state = _state;
    if (state == null ||
        !state._hasIndex ||
        state._showIndex ||
        state._flipPhase != _FlipPhase.idle) {
      return;
    }
    state._toggleIndex();
  }

  /// Closes the table of contents if it is open.
  void closeIndex() {
    final state = _state;
    if (state == null || !state._showIndex) {
      return;
    }
    state._toggleIndex();
  }

  /// Mutes or unmutes the flip sound.
  void toggleMute() => _state?._toggleMute();
}

/// A multi-page book widget with a cylindrical page-curl transition.
///
/// Supply [pages] and a way out, and you have a working book:
///
/// ```dart
/// FlipBook(
///   onClose: () => Navigator.of(context).pop(),
///   pages: const [
///     FlipBookPage(title: 'My Book', tagline: 'a cover page'),
///     FlipBookPage(title: 'Chapter 1', bodySegments: ['Once upon a time.']),
///   ],
/// )
/// ```
///
/// **A feature exists only if you pass its object.** No [readAloud] means no
/// voice control, no highlight, and nothing about reading to configure — so
/// a plain book carries no settings for things it does not do. Pass the
/// object and every field inside it defaults sensibly until you override
/// it. The same holds for [marker], [footer], [header], [swipe] and
/// [contents].
///
/// The flip direction follows the ambient [Directionality]: in RTL locales
/// "next" curls the opposite way, matching how a real book reads.
class FlipBook extends StatefulWidget {
  /// Creates a flip book. Only [pages] and [onClose] are required.
  const FlipBook({
    super.key,
    required this.pages,
    required this.onClose,
    this.header = const FlipBookHeader(),
    this.footer = const FlipBookFooter(),
    this.readAloud,
    this.marker,
    this.bookmarks,
    this.swipe = const FlipBookSwipe(),
    this.contents = const FlipBookContents(),
    this.flipSpeed = FlipSpeed.medium,
    this.controller,
    this.shine,
    this.shadow,
  });

  /// The book's contents and everything about how a page is presented —
  /// the list, the paper colour, the type, the reading direction, where it
  /// opens, and where it is. See [FlipBookPages].
  final FlipBookPages pages;

  /// Called when the × close button is tapped.
  final VoidCallback onClose;

  /// The top strip: the × close button and anything beside it. `null`
  /// removes it — then give the reader another way out.
  final FlipBookHeader? header;

  /// The bottom bar and every control on it. `null` removes it; drive the
  /// book through a [FlipBookController] instead.
  final FlipBookFooter? footer;

  /// Gives the book a voice. `null` — the default — means a silent book
  /// with no voice controls and no reading highlight.
  final FlipBookReadAloud? readAloud;

  /// Lets the reader mark passages with a pencil. `null` — the default —
  /// means no pencil. Independent of [readAloud]: a reader marks whether or
  /// not the book can speak.
  final FlipBookMarker? marker;

  /// The reader's two ways of keeping a place — a bookmark to carry on
  /// from, and saved pages to come back to. Null means neither button.
  final FlipBookBookmarks? bookmarks;

  /// Turning pages by hand, and the hint that teaches it.
  final FlipBookSwipe swipe;

  /// The table of contents the INDEX button opens.
  final FlipBookContents contents;

  /// Duration preset of the flip animation.
  final FlipSpeed flipSpeed;

  /// Drives the book from outside the widget — see [FlipBookController].
  final FlipBookController? controller;

  /// Strength of the sheen on the curling paper, 0–1. `null` (default)
  /// adapts to [pageColor] — full sheen on white paper, a whisper on dark
  /// paper. `0` removes the light completely.
  final double? shine;

  /// Strength of the curl's depth shadow, 0–1. `null` (default) uses the
  /// standard shadow; `0` removes it.
  final double? shadow;

  @override
  State<FlipBook> createState() => _FlipBookState();
}

/// Fallback look of the swipe hint when the caller gives no style.
const TextStyle _defaultSwipeHintStyle = TextStyle(
  fontSize: 17,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.4,
  color: Color(0xFF555555),
);

class _FlipBookState extends State<FlipBook>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Shorthands onto the feature objects. A null footer/header/readAloud/
  // marker means that feature does not exist, so every read of it goes
  // through one of these rather than repeating the null check.
  FlipBookFooter? get _footer => widget.footer;
  FlipBookHeader? get _header => widget.header;
  FlipBookReadAloud? get _read => widget.readAloud;
  FlipBookMarker? get _marker => widget.marker;
  FlipBookBookmarks? get _bookmarks => widget.bookmarks;
  FlipBookSwipe get _swipe => widget.swipe;
  FlipBookSwipeHint? get _hint => widget.swipe.hint;
  FlipBookPageStyle get _pageStyle => widget.pages.style;

  int _pageIndex = 0;
  int _nextIndex = 0;
  _FlipPhase _flipPhase = _FlipPhase.idle;
  bool _muted = false;
  bool _showIndex = false;

  _ReadPhase _readPhase = _ReadPhase.idle;
  int _readSession = 0;

  /// Whether the current read session belongs to the play-all chain
  /// ([FlipBookReadAloud.playAll]) — set per tap, so ▶ stays page-only.
  bool _readChains = false;

  /// The sentences of the page being read, and which one the voice is on —
  /// null between sessions. The pair IS the read marker's state: pause
  /// keeps it (the mark holds its place), stop and navigation clear it.
  List<_SentenceRef> _readSentences = const [];
  int? _markedSentence;

  /// Marking mode: the pencil is on, so a drag marks text instead of
  /// turning the page. [_draft] is the range under the finger, awaiting
  /// Save or Cancel.
  bool _marking = false;

  /// How far the current pointer has travelled on each axis, accumulated from
  /// raw events. See _onSwipe: the drag recogniser cannot report this.
  Offset _pointerTravel = Offset.zero;

  ReaderMark? _draft;

  /// Pins the keep / discard row to the marked words. The block holding the
  /// draft is the target; the row at page level is the follower, so it keeps
  /// its place while the page scrolls.
  final LayerLink _draftLink = LayerLink();

  /// Where the marked words sit inside their own block, as the block last
  /// measured them. Null until the block reports, which is one frame after
  /// the drag — the row appears with the mark, not before it.
  Rect? _draftRect;

  /// Width of the block holding the draft, so the row can be placed against
  /// the right edge of a mark under RTL.
  double _draftBlockWidth = 0;

  /// The control name shown above the footer for FlipBook.controlLabelFor
  /// after a tap; null while nothing was tapped recently.
  String? _controlLabel;
  Timer? _controlLabelTimer;

  /// The reading pace the footer shows as chosen. Seeded from the caller's
  /// initial value and updated when the reader picks another, so the
  /// control stays correct even if the app does not rebuild.
  FlipBookReadSpeed _readSpeed = FlipBookReadSpeed.normal;

  bool _swipeHintVisible = false;

  /// Appearances used so far, counted for the life of the book — not
  /// swipes. See [_showSwipeHint].
  int _swipeHintShowCount = 0;
  Timer? _swipeHintTimer;

  /// Footer visibility while `FlipBookFooter.autoHide` is on; permanently
  /// true when it is off. The header has its own flag so the two hide
  /// independently, on one shared retire clock.
  bool _chromeVisible = true;
  bool _headerVisible = true;
  Timer? _chromeTimer;

  ui.Image? _capturedImage;
  final _repaintKey = GlobalKey();
  final _prevCaptureKey = GlobalKey();

  late final AnimationController _ctrl;
  late final CurvedAnimation _curved;

  int get _pageCount => widget.pages.items.length;
  bool get _hasIndex =>
      widget.pages.items.any((p) => p.title?.trim().isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.pages.items.isNotEmpty) {
      _pageIndex =
          widget.pages.initialPage.clamp(0, widget.pages.items.length - 1);
      _nextIndex = _pageIndex;
    }
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.flipSpeed.duration,
    );
    _curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    widget.controller?._attach(this);
    if (_swipeHintEligible) {
      _showSwipeHint();
    }
    // Immersive mode opens as a pure page; the first tap reveals the
    // hidden chrome. In `always` mode the element simply is.
    _chromeVisible = !(_footer?.autoHide ?? false);
    _readSpeed = _read?.speed?.initial ?? FlipBookReadSpeed.normal;
    _headerVisible = !(_header?.autoHide ?? false);
  }

  /// Leaving the foreground stops ALL reading operations — the voice and
  /// the play-all chain alike. Without this the engine's stopped future
  /// would complete in the background and the chain would keep flipping a
  /// book nobody is looking at.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _stopReading();
    }
  }

  /// Whether the hint may still greet a page: it is enabled, swiping is on,
  /// and it has not used up its [FlipBookSwipeHint.maxShows] appearances.
  bool get _swipeHintEligible =>
      (_hint != null) &&
      _swipe.enabled &&
      _swipeHintShowCount < (_hint?.maxShows ?? 0);

  /// Shows the hint once and counts the appearance.
  ///
  /// Once per page, never repeating on it — a hint that keeps coming back
  /// nags a reader who is trying to read. It greets a page, fades, and
  /// after [FlipBookSwipeHint.maxShows] appearances it is gone for the
  /// life of the book.
  void _showSwipeHint() {
    _swipeHintShowCount++;
    _swipeHintVisible = true;
    _armSwipeHintHide();
    // The signal fires exactly once: the count only ever grows, and only
    // here, so == can match a single time.
    if (_swipeHintShowCount == (_hint?.maxShows ?? 0)) {
      _hint?.onRetired?.call();
    }
  }

  /// Fades the hint out after [FlipBookSwipeHint.showFor]. It does not
  /// come back on this page.
  void _armSwipeHintHide() {
    _swipeHintTimer?.cancel();
    _swipeHintTimer = Timer((_hint?.showFor ?? Duration.zero), () {
      if (mounted && _swipeHintVisible) {
        setState(() => _swipeHintVisible = false);
      }
    });
  }

  /// A swipe dismisses the hint it was showing — the reader clearly does
  /// not need it any more on this page. The appearance still counts; it was
  /// shown.
  void _dismissSwipeHint() {
    _swipeHintTimer?.cancel();
    if (_swipeHintVisible) {
      setState(() => _swipeHintVisible = false);
    }
  }

  /// The hint line: `‹‹‹‹ Swipe ››››` — chevrons darkest at the outer ends,
  /// fading step by step toward the text for a fade-away look. The chevrons
  /// overlap into a tight, broad train. Text, colour, size, and font all
  /// come from [FlipBookSwipeHint.text] / [FlipBookSwipeHint.style] /
  /// [FlipBookSwipeHint.arrowSize].
  /// The whole hint, wrapped in a semantic label so a caller's image or
  /// animation still announces itself to a screen reader.
  Widget _buildSwipeHint() {
    return Semantics(
      label: _hint?.text ?? '',
      excludeSemantics: true,
      child: _hint?.child ?? _buildDefaultSwipeHint(),
    );
  }

  Widget _buildDefaultSwipeHint() {
    final hint = _hint!;
    final nav = _footer?.nav ?? const FlipBookNavButtons();
    final style = hint.style ?? _defaultSwipeHintStyle;
    final color = style.color ?? const Color(0xFF555555);
    // Outermost chevron (dark) → the one touching the text (lightest).
    const fades = [1.0, 0.7, 0.45, 0.2];
    Widget arrow(IconData glyph, double fade) => Align(
          widthFactor: 0.6, // overlap neighbours into a tight ‹‹‹‹ train
          child: Icon(
            glyph,
            size: hint.arrowSize,
            color: color.withValues(alpha: color.a * fade),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      // Scale down rather than overflow when a long hint text meets a
      // narrow phone — the line always fits on one row.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Directionality(
          // Visual order is fixed: left-pointing chevrons sit left, in
          // every locale. RTL scripts inside the Text still render
          // correctly.
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final fade in fades) arrow(nav.previousIcon, fade),
              const SizedBox(width: 10),
              Text(hint.text, style: style),
              const SizedBox(width: 10),
              for (final fade in fades.reversed) arrow(nav.nextIcon, fade),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(FlipBook old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      old.controller?._detach(this);
      widget.controller?._attach(this);
    }
    // EDG-03: a rebuilt flipSpeed must take effect, not stay frozen at
    // whatever initState saw.
    if (widget.flipSpeed != old.flipSpeed) {
      _ctrl.duration = widget.flipSpeed.duration;
    }
    // A chrome mode rebuilt to `always` must show the element — visibility
    // is otherwise only decided in initState, and an app switching modes at
    // runtime would keep a permanently hidden "always" footer.
    if (widget.footer?.autoHide != old.footer?.autoHide &&
        !(_footer?.autoHide ?? false)) {
      _chromeVisible = true;
    }
    if (widget.header?.autoHide != old.header?.autoHide &&
        !(_header?.autoHide ?? false)) {
      _headerVisible = true;
    }
    // EDG-02: a shrunken pages list must never leave the shown index past
    // the new end.
    final maxIndex = _pageCount == 0 ? 0 : _pageCount - 1;
    if (_pageIndex > maxIndex) {
      _pageIndex = maxIndex;
      // The shown page really changed — the persistence seam must hear it,
      // or an app restoring via pages.onChanged keeps a stale index forever.
      widget.pages.onChanged?.call(_pageIndex);
    }
    if (_nextIndex > maxIndex) {
      _nextIndex = maxIndex;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?._detach(this);
    _swipeHintTimer?.cancel();
    _controlLabelTimer?.cancel();
    _chromeTimer?.cancel();
    // Reverse order of creation: the curve listens to the controller, so it
    // must detach before the controller goes away.
    _curved.dispose();
    _ctrl.dispose();
    _capturedImage?.dispose();
    super.dispose();
  }

  /// Fires the caller's [FlipBookSound.onFlip] — the package ships no sound
  /// of its own. Best-effort: a failing sound must never interrupt the flip.
  Future<void> _playFlipSound() async {
    try {
      await _footer?.sound?.onFlip.call();
    } catch (_) {
      // Sound is decoration; the flip goes on.
    }
  }

  void _toggleMute() => setState(() => _muted = !_muted);
  void _toggleIndex() => setState(() => _showIndex = !_showIndex);

  /// EDG-04: an explicit jump is the user's latest intent, so it wins over
  /// any flip in flight — the animation is aborted, its bitmap released, and
  /// the pending flip continuation sees a changed phase and gives up.
  void _jumpToPage(int index) {
    _stopReading();
    if (_flipPhase == _FlipPhase.animatingForward ||
        _flipPhase == _FlipPhase.animatingBackward) {
      _ctrl.stop();
    }
    final abandoned = _capturedImage;
    final changed = _pageIndex != index;
    setState(() {
      _flipPhase = _FlipPhase.idle;
      _capturedImage = null;
      _pageIndex = index;
      _showIndex = false;
      _swipeHintVisible = false;
    });
    abandoned?.dispose();
    // The hint greets a new page — until its appearances run out.
    if (_swipeHintEligible) {
      setState(_showSwipeHint);
    }
    if (changed) {
      widget.pages.onChanged?.call(_pageIndex);
    }
  }

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

  bool get _canPauseReading =>
      _read?.onPause != null && _read?.onResume != null;

  /// The sentence the marker draws, or null when idle / marker disabled.
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
        break; // The engine failed — quietly return control (TTS-13).
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
      _endReadingSession();
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

  void _pauseReading() {
    if (_readPhase != _ReadPhase.playing) {
      return;
    }
    _readSession++; // Orphans the running loop. The marker holds its place.
    _read?.onPause?.call();
    setState(() => _readPhase = _ReadPhase.paused);
  }

  void _resumeReading() {
    final session = ++_readSession;
    setState(() => _readPhase = _ReadPhase.playing);
    unawaited(_resumeThenContinue(session));
  }

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
  // ── Bookmarks, saved pages, export ────────────────────────────────────

  /// Whether the page on screen is the one the reader will carry on from.
  bool get _isBookmarked => _bookmarks?.bookmarkedPage == _pageIndex;

  /// The id of the page on screen, when it has one. A page without an id
  /// cannot be saved: there would be nothing to remember it by.
  String? get _currentPageId => _pageIndex >= 0 && _pageIndex < _pageCount
      ? widget.pages.items[_pageIndex].id
      : null;

  bool get _isSaved {
    final id = _currentPageId;
    return id != null && (_bookmarks?.saved.contains(id) ?? false);
  }

  /// Reports the current page as the place to carry on from.
  ///
  /// Deliberately does nothing else: it must not stop the voice, drop a mark
  /// or turn a page. A reader keeping their place is not asking the book to
  /// change.
  void _onBookmark() {
    _bookmarks?.onBookmark?.call(_pageIndex);
    setState(() {});
  }

  /// Adds or removes the current page from the saved set, then reports the
  /// whole set — the same in-and-out seam the marks use.
  void _onToggleSaved() {
    final marks = _bookmarks;
    final id = _currentPageId;
    if (marks?.onSavedChanged == null || id == null) {
      return;
    }
    final next = Set<String>.from(marks!.saved);
    if (!next.remove(id)) {
      next.add(id);
    }
    marks.onSavedChanged!(next);
    setState(() {});
  }

  /// Flattens the book into plain entries for [kind].
  ///
  /// Numbers are 1-based, matching the footer, so "page 37" in an export is
  /// the page a reader flips to. Order is reading order in every case.
  List<FlipBookExportEntry> _exportEntries(FlipBookExportKind kind) {
    final saved = _bookmarks?.saved ?? const <String>{};
    final marks = _marker?.marks ?? const <ReaderMark>[];
    final entries = <FlipBookExportEntry>[];

    for (int i = 0; i < _pageCount; i++) {
      final page = widget.pages.items[i];
      final id = page.id;
      final units = page.bodySegments ??
          (page.bodyText == null ? const <String>[] : [page.bodyText!]);

      // The passages this reader marked on this page, in the order they
      // appear in the text rather than the order they were made.
      final pageMarks = id == null
          ? const <ReaderMark>[]
          : (marks.where((m) => m.pageId == id).toList()
            ..sort((a, b) => a.segment != b.segment
                ? a.segment.compareTo(b.segment)
                : a.start.compareTo(b.start)));

      final markText = [
        for (final m in pageMarks)
          if (m.text.trim().isNotEmpty)
            m.text.trim()
          else if (m.segment < units.length)
            units[m.segment]
                .substring(
                  m.start.clamp(0, units[m.segment].length),
                  m.end.clamp(0, units[m.segment].length),
                )
                .trim(),
      ]..removeWhere((t) => t.isEmpty);

      final include = switch (kind) {
        FlipBookExportKind.wholeBook => true,
        FlipBookExportKind.savedPages => id != null && saved.contains(id),
        FlipBookExportKind.markedText => markText.isNotEmpty,
      };
      if (!include) {
        continue;
      }
      entries.add(FlipBookExportEntry(
        number: i + 1,
        id: id,
        title: page.title,
        tagline: page.tagline,
        // A marked-text export carries only what was marked. Shipping the
        // whole page too would defeat the point of choosing.
        body: kind == FlipBookExportKind.markedText ? const [] : units,
        marks: markText,
      ));
    }
    return entries;
  }

  /// Offers the three choices and reports the one taken.
  Future<void> _openExport(FlipBookExport export) async {
    final counts = {
      for (final k in FlipBookExportKind.values) k: _exportEntries(k).length,
    };
    final chosen = await showModalBottomSheet<FlipBookExportKind>(
      context: context,
      builder: (sheetContext) {
        Widget option(FlipBookExportKind kind, String label) {
          final count = counts[kind] ?? 0;
          final enabled = count > 0 || export.showEmptyOptions;
          return ListTile(
            enabled: enabled,
            title: Text(label, style: export.optionStyle),
            subtitle: Text(count > 0 ? '$count' : export.emptyLabel),
            onTap: enabled ? () => Navigator.of(sheetContext).pop(kind) : null,
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(export.heading, style: export.headingStyle),
              ),
              option(FlipBookExportKind.savedPages, export.savedLabel),
              option(FlipBookExportKind.markedText, export.markedLabel),
              option(FlipBookExportKind.wholeBook, export.wholeLabel),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(export.cancelLabel),
              ),
            ],
          ),
        );
      },
    );
    if (chosen == null) {
      return;
    }
    export.onExport(chosen, _exportEntries(chosen));
  }

  Widget _buildMarkActions() {
    final marker = _marker!;
    final footer = _footer ?? const FlipBookFooter();
    Widget action(Widget? child, IconData icon, String label, VoidCallback f) {
      return _FooterControl(
        semanticLabel: label,
        onTap: f,
        child:
            child ?? Icon(icon, size: footer.iconSize, color: footer.iconColor),
      );
    }

    // Translucent by default: the row clears the marked words, but a line of
    // ordinary text can still end up behind it, so the reader must be able
    // to read straight through it.
    final barColor = marker.actionBarColor ??
        footer.color.withValues(
          alpha: footer.color.a * marker.actionBarOpacity,
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(footer.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            action(marker.save, Icons.check_rounded, marker.saveLabel,
                _saveDraftMark),
            action(marker.cancel, Icons.close_rounded, marker.cancelLabel,
                _cancelDraftMark),
          ],
        ),
      ),
    );
  }

  /// Height reserved for the keep / discard row. `_FooterControl` floors its
  /// touch target at 44, so 44 is the row — this constant must equal the
  /// row's real height, or the row is placed as if it were taller than it is
  /// and rests back down on the words it exists to clear.
  static const double _markRowHeight = 44;

  /// Breathing room between the row and the marked words.
  static const double _markRowGap = 4;

  /// The keep / discard row, drawn **at page level** and pinned to the
  /// marked words through [_draftLink].
  ///
  /// It belongs at page level rather than inside the text block: a short
  /// paragraph is barely taller than the row, so confined to the block the
  /// only place left for it is on top of the marked words — the one thing it
  /// must never hide, since that is what the reader is deciding about. The
  /// link keeps it on those words as the page scrolls.
  Widget _buildMarkActionsOverlay() {
    final rect = _draftRect!;

    // Vertically: above the mark by preference, since a reader's eye is
    // already at the start of what they dragged. Below only when the mark
    // sits on the block's first line and there is nothing above to use —
    // that covers the NEXT line of prose, never the marked one.
    final above = rect.top >= _markRowHeight + _markRowGap;
    final dy = above
        ? rect.top - _markRowHeight - _markRowGap
        : rect.bottom + _markRowGap;

    // Horizontally: centred on the mark, but never past either edge.
    //
    // An earlier version offset the row by the mark's own left (or right
    // under RTL). Mark the last word on a line and the row hung off the
    // screen — half the capsule on iOS, almost none of it in Arabic
    //. An Align inside a box the width of the block
    // cannot put its child outside that box, so the clamping is structural
    // rather than arithmetic, and it works the same in both directions.
    final width = _draftBlockWidth;
    final fx = width <= 0
        ? 0.0
        : ((rect.center.dx / width) * 2 - 1).clamp(-1.0, 1.0);

    return CompositedTransformFollower(
      link: _draftLink,
      showWhenUnlinked: false,
      targetAnchor: Alignment.topLeft,
      followerAnchor: Alignment.topLeft,
      offset: Offset(0, dy),
      child: SizedBox(
        width: width,
        child: Align(
          alignment: Alignment(fx, -1),
          child: _buildMarkActions(),
        ),
      ),
    );
  }

  /// The marked words moved or resized — redraw the row against them.
  void _onDraftRect(Rect rect, double blockWidth) {
    if ((_draftRect != rect || _draftBlockWidth != blockWidth) && mounted) {
      setState(() {
        _draftRect = rect;
        _draftBlockWidth = blockWidth;
      });
    }
  }

  /// Names the control just tapped, briefly. Every footer control routes
  /// through here, so an icon-only footer is still self-explaining.
  void _showControlLabel(String label) {
    if ((_footer?.tapLabelFor ?? Duration.zero) == Duration.zero) {
      return;
    }
    _controlLabelTimer?.cancel();
    setState(() => _controlLabel = label);
    _controlLabelTimer = Timer((_footer?.tapLabelFor ?? Duration.zero), () {
      if (mounted) {
        setState(() => _controlLabel = null);
      }
    });
  }

  // ── Reader marks ───────────────────────────────────────────────────────────
  // The pencil turns marking mode on; a drag over the text builds a draft
  // range; Save adds it to the list the app owns, Cancel drops it. The
  // package holds no storage of its own — marker.onChanged is the whole seam.

  /// Whether marking can run at all on the page being shown: enabled by the
  /// caller, and the page has an id to hang a mark on.
  bool get _canMark =>
      (_marker != null) &&
      _pageCount > 0 &&
      (widget.pages.items[_pageIndex].id?.isNotEmpty ?? false);

  /// This page's saved marks for one block, as plain ranges.
  List<TextRange> _marksFor(FlipBookPage page, int segment) {
    final id = page.id;
    if (id == null) {
      return const [];
    }
    return [
      for (final mark in (_marker?.marks ?? const <ReaderMark>[]))
        if (mark.pageId == id && mark.segment == segment)
          TextRange(start: mark.start, end: mark.end),
    ];
  }

  void _toggleMarking() {
    setState(() {
      _marking = !_marking;
      _draft = null; // Leaving the mode always drops an unsaved draft.
      _draftRect = null;
    });
    // Marking replaces the swipe gesture, so the hint would be a lie.
    if (_marking) {
      _dismissSwipeHint();
    }
  }

  void _onDraftMark(int segment, TextRange range, String blockText) {
    final id = widget.pages.items[_pageIndex].id;
    if (id == null) {
      return;
    }
    setState(() {
      _draft = ReaderMark(
        pageId: id,
        segment: segment,
        start: range.start,
        end: range.end,
        text: blockText
            .substring(
              range.start.clamp(0, blockText.length),
              range.end.clamp(0, blockText.length),
            )
            .trim(),
      );
    });
  }

  void _saveDraftMark() {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    // A repeated mark over the same words must not stack up.
    final next = [
      ...(_marker?.marks ?? const <ReaderMark>[]).where((m) => m != draft),
      draft
    ];
    setState(() {
      _draft = null;
      _draftRect = null;
      _marking = false;
    });
    _marker?.onChanged?.call(next);
  }

  /// Discards the mark being dragged AND turns marking off.
  ///
  /// Leaving the mode matters as much as dropping the mark: marking owns the
  /// horizontal drag, so a reader still in it cannot swipe to another page.
  /// Marking again costs one tap on the pencil.
  void _cancelDraftMark() => setState(() {
        _draft = null;
        _draftRect = null;
        _marking = false;
      });

  /// Whether the page being shown carries any of the reader's marks.
  ///
  /// Drives the trash button: no marks on this page, no button.
  bool get _pageHasMarks {
    if (_marker == null || _pageCount == 0) {
      return false;
    }
    // Mid-flip the trash must already speak for the page ARRIVING, since
    // _pageIndex only moves once the flip finishes.
    final index =
        _flipPhase == _FlipPhase.idle ? _pageIndex : _nextIndex;
    final id = widget.pages.items[index].id;
    if (id == null || id.isEmpty) {
      return false;
    }
    return (_marker?.marks ?? const <ReaderMark>[])
        .any((m) => m.pageId == id);
  }

  /// Clears the marks on the page being shown — and only those.
  ///
  /// A trash button drawn on a page means that page: every other page keeps
  /// its own marks, and those survivors are what gets reported.
  void _clearMarks() {
    setState(() {
      _draft = null;
      _draftRect = null;
      _marking = false;
    });
    final id = _pageCount > 0 ? widget.pages.items[_pageIndex].id : null;
    final kept = (_marker?.marks ?? const <ReaderMark>[])
        .where((m) => m.pageId != id)
        .toList();
    _marker?.onChanged?.call(kept);
  }

  // ── Chrome visibility ──────────────────────────────────────────────────────
  // `autoHide: false` keeps an element permanently on. `autoHide: true` is the
  // immersive mode: a tap on the page toggles every auto-hiding element at
  // once, and revealed chrome retires by itself after `revealFor` of no
  // interaction. Footer and header carry the flag separately and are
  // independent — only the elements with autoHide on ever move.

  bool get _footerAuto => (_footer?.autoHide ?? false);
  bool get _headerAuto => (_header?.autoHide ?? false);

  void _toggleChrome() {
    if (!_footerAuto && !_headerAuto) {
      return;
    }
    final anyHidden =
        (_footerAuto && !_chromeVisible) || (_headerAuto && !_headerVisible);
    if (anyHidden) {
      _revealChrome();
    } else {
      _chromeTimer?.cancel();
      setState(() {
        if (_footerAuto) {
          _chromeVisible = false;
        }
        if (_headerAuto) {
          _headerVisible = false;
        }
      });
    }
  }

  void _revealChrome() {
    if (!_footerAuto && !_headerAuto) {
      return;
    }
    if ((_footerAuto && !_chromeVisible) || (_headerAuto && !_headerVisible)) {
      setState(() {
        if (_footerAuto) {
          _chromeVisible = true;
        }
        if (_headerAuto) {
          _headerVisible = true;
        }
      });
    }
    _armChromeHide();
  }

  /// (Re)starts the retire clock — called on reveal and on every chrome
  /// interaction, so a control never vanishes mid-use.
  void _armChromeHide() {
    _chromeTimer?.cancel();
    _chromeTimer =
        Timer((_footer?.revealFor ?? const Duration(seconds: 3)), () {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_footerAuto) {
          _chromeVisible = false;
        }
        if (_headerAuto) {
          _headerVisible = false;
        }
      });
    });
  }

  // ── Forward flip (NEXT) ────────────────────────────────────────────────────
  // Captures the current page, shows the target page underneath, then peels
  // the captured snapshot away left→right (progress 0→1).

  Future<void> _flipToNext(int target) async {
    if (_flipPhase != _FlipPhase.idle || target < 0 || target >= _pageCount) {
      return;
    }
    _stopReading();

    if ((_footer?.sound != null) && !_muted) {
      unawaited(_playFlipSound());
    }

    // Capture the current page as bitmap so it can curl away — synchronous,
    // so there is no gap between deciding to flip and starting to animate.
    final captured = capturePage(
      _repaintKey,
      pixelRatio: captureRatioOf(context),
    );

    setState(() {
      _nextIndex = target;
      _capturedImage = captured;
      _flipPhase = _FlipPhase.animatingForward;
    });

    await _animateCurl(forward: true);

    if (!mounted || _flipPhase != _FlipPhase.animatingForward) {
      // Disposed, or a jump aborted this flip and owns the state now.
      return;
    }

    _finishFlip();
  }

  // ── Backward flip (PREV) ───────────────────────────────────────────────────
  // Phase 1: renders the target page below the current page for one frame and
  // captures it as a bitmap (invisible to the user — current page covers it).
  // Phase 2: animates the captured bitmap descending onto the current page
  // (progress 1→0) so strips carry the prev-page texture as they settle flat.

  Future<void> _flipToPrev(int target) async {
    if (_flipPhase != _FlipPhase.idle || target < 0 || target >= _pageCount) {
      return;
    }
    _stopReading();

    if ((_footer?.sound != null) && !_muted) {
      unawaited(_playFlipSound());
    }

    // Phase 1: render target page hidden below current page for capture.
    setState(() {
      _nextIndex = target;
      _flipPhase = _FlipPhase.capturingPrev;
    });

    // Wait one frame so the capture target is laid out and painted.
    final frameDone = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => frameDone.complete());
    await frameDone.future;

    if (!mounted || _flipPhase != _FlipPhase.capturingPrev) {
      // Disposed, or a jump aborted this flip during the frame wait.
      return;
    }

    final captured = capturePage(
      _prevCaptureKey,
      pixelRatio: captureRatioOf(context),
    );

    // Phase 2: animate the captured bitmap descending (progress 1→0).
    setState(() {
      _capturedImage = captured;
      _flipPhase = _FlipPhase.animatingBackward;
    });

    await _animateCurl(forward: false);

    if (!mounted || _flipPhase != _FlipPhase.animatingBackward) {
      return;
    }

    _finishFlip();
  }

  /// Runs the curl animation. If the widget is disposed mid-flight the
  /// returned [TickerFuture] simply never completes and `dispose()` has
  /// already released the captured image — no cleanup is missed.
  Future<void> _animateCurl({required bool forward}) =>
      forward ? _ctrl.forward(from: 0) : _ctrl.reverse(from: 1.0);

  void _finishFlip() {
    final toDispose = _capturedImage;
    final changed = _pageIndex != _nextIndex;
    setState(() {
      _pageIndex = _nextIndex;
      _flipPhase = _FlipPhase.idle;
      _capturedImage = null;
      _swipeHintVisible = false;
      // Marking belongs to the page it was started on. Carrying it across a
      // flip would leave the pencil lit on a page the reader never chose to
      // mark, and would let an unsaved draft outlive the text it points at.
      if (changed) {
        _marking = false;
        _draft = null;
        _draftRect = null;
      }
    });
    toDispose?.dispose();
    // The hint greets a new page — until its appearances run out.
    if (_swipeHintEligible) {
      setState(_showSwipeHint);
    }
    if (changed) {
      widget.pages.onChanged?.call(_pageIndex);
    }
  }

  /// Lays out a page from its optional parts.
  ///
  /// Three shapes:
  /// * `body` widget without printed title or tagline → the widget fills
  ///   the paper edge-to-edge (full layout control stays with the caller).
  /// * `body` widget under a printed title/tagline → the fixed layout: the
  ///   header text stays put, the body gets the remaining space.
  /// * text without a `body` → a text page the book lays out itself,
  ///   everything in one scroll view — long text scrolls, and every part
  ///   is markable text the read marker can follow.
  ///
  /// [live] is true only for the page actually being shown — capture
  /// targets and flip destinations are rendered with the marker off.
  Widget _pageContent(FlipBookPage page, {required bool live}) {
    final style = page.style ?? _pageStyle;
    final highlight = _read?.highlight ?? const FlipBookHighlight();
    final marker = _marker;
    final printedTitle = page.showTitleOnPage ? page.title : null;
    final marked = live ? _currentSentence : null;

    Widget markable(
      String text,
      TextStyle style,
      _ReadPart part, {
      int segment = 0,
      bool follow = false,
      int? maxLines,
      TextOverflow? overflow,
    }) {
      final range =
          marked != null && marked.part == part && marked.segment == segment
              ? marked.range
              : null;
      // The caller's own renderer, when they gave one: whatever it
      // returns IS the block, marker and all.
      final custom = _read?.highlight.builder;
      if (custom is ReadMarkerTextBuilder) {
        return Builder(
          builder: (context) => custom(
            context,
            ReadMarkerText(
              text: text,
              style: style,
              marked: range,
              maxLines: maxLines,
              overflow: overflow,
            ),
          ),
        );
      }
      // A mark belongs to a block, and title/tagline are blocks of their
      // own — hence their reserved segment numbers.
      final markSegment = switch (part) {
        _ReadPart.title => ReaderMark.titleSegment,
        _ReadPart.tagline => ReaderMark.taglineSegment,
        _ReadPart.body => segment,
      };
      final draft = _draft;
      // A part recedes only when it is BOTH read and faded. Excluded from
      // reading, it is not in the performance and must keep full ink; and a
      // heading can be read yet never fade, so it stays the page's anchor
      // instead of flickering every time the body speaks.
      final partDims = switch (part) {
        _ReadPart.title =>
          (_read?.readTitle ?? true) && (_read?.fadeTitle ?? true),
        _ReadPart.tagline =>
          (_read?.readTagline ?? true) && (_read?.fadeTagline ?? true),
        _ReadPart.body =>
          (_read?.readBody ?? true) && (_read?.fadeBody ?? true),
      };
      return MarkedText(
        text: text,
        style: style,
        marked: range,
        // The dim belongs to the page: while any block holds the marker,
        // every other participating block recedes.
        dimmed: marked != null && range == null && partDims,
        markerStyle: highlight.style,
        markerColor: highlight.color,
        markerRadius: highlight.radius,
        dimOpacity: highlight.dimOpacity,
        autoFollow: follow,
        savedMarks: _marksFor(page, markSegment),
        savedMarkColor: (marker?.color ?? const Color(0x338A8A8A)),
        draftMark: draft != null && draft.segment == markSegment
            ? TextRange(start: draft.start, end: draft.end)
            : null,
        // The block anchors and measures; the page draws the row. See
        // _buildMarkActions.
        draftLink:
            draft != null && draft.segment == markSegment ? _draftLink : null,
        onDraftRect:
            draft != null && draft.segment == markSegment ? _onDraftRect : null,
        onDraftMark: live && _marking && _canMark
            ? (range) => _onDraftMark(markSegment, range, text)
            : null,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    if (page.body == null && (page.hasText || page.bodyWidgets.isNotEmpty)) {
      final column = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (printedTitle != null)
            markable(printedTitle, style.titleStyle, _ReadPart.title,
                follow: live),
          if (printedTitle != null && page.tagline != null)
            const SizedBox(height: 6),
          if (page.tagline != null)
            markable(page.tagline!, style.taglineStyle, _ReadPart.tagline,
                follow: live),
          if (printedTitle != null || page.tagline != null)
            const SizedBox(height: 20),
          ..._buildBodyBlocks(page, markable, live: live),
        ],
      );
      // ObjectKey: each page keeps its own scroll position, and a flip
      // opens the next page at its top instead of inheriting this one's.
      // The padding belongs to the TEXT, not to the page: on the scroll view
      // it would wrap the background too, and a decorated page could never
      // reach the screen edge. The background fills the page; only the words
      // are inset.
      return SingleChildScrollView(
        key: ObjectKey(page),
        padding: page.background == null ? style.padding : null,
        child: page.background == null
            ? column
            : Stack(
                children: [
                  Positioned.fill(child: page.background!),
                  Padding(padding: style.padding, child: column),
                ],
              ),
      );
    }

    if (printedTitle == null && page.tagline == null) {
      return page.body ?? const SizedBox.shrink();
    }
    return Padding(
      padding: style.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // maxLines bounds the printed title so a long one at large text
          // scale can never push the body into a RenderFlex overflow
          // (LAY-06).
          if (printedTitle != null)
            markable(printedTitle, style.titleStyle, _ReadPart.title,
                maxLines: 3, overflow: TextOverflow.ellipsis),
          if (printedTitle != null && page.tagline != null)
            const SizedBox(height: 6),
          if (page.tagline != null)
            markable(page.tagline!, style.taglineStyle, _ReadPart.tagline,
                maxLines: 3, overflow: TextOverflow.ellipsis),
          if (page.body != null) ...[
            const SizedBox(height: 20),
            Expanded(child: page.body!),
          ],
        ],
      ),
    );
  }

  /// The body of a text page: one block per `bodySegments` entry, or one
  /// block for a whole `bodyText`. Separate blocks are what let the marker
  /// address a single segment, and they carry the paragraph spacing.
  List<Widget> _buildBodyBlocks(
    FlipBookPage page,
    _MarkableBuilder markable, {
    required bool live,
  }) {
    final style = (page.style ?? _pageStyle).bodyStyle;
    final segments = page.bodySegments;
    if (segments == null) {
      final text = page.bodyText;
      if (text == null || text.isEmpty) {
        return const [];
      }
      return [markable(text, style, _ReadPart.body, follow: live)];
    }
    final blocks = <Widget>[];
    void gap() {
      if (blocks.isNotEmpty) {
        blocks.add(const SizedBox(height: 16));
      }
    }

    for (var i = 0; i < segments.length; i++) {
      // A widget keyed to this index sits BEFORE the segment.
      final widgetHere = page.bodyWidgets[i];
      if (widgetHere != null) {
        gap();
        blocks.add(widgetHere);
      }
      if (segments[i].trim().isEmpty) {
        continue;
      }
      gap();
      blocks.add(
        markable(segments[i], style, _ReadPart.body, segment: i, follow: live),
      );
    }
    // A key past the last segment appends.
    final trailing = page.bodyWidgets[segments.length];
    if (trailing != null) {
      gap();
      blocks.add(trailing);
    }
    return blocks;
  }

  TextDirection get _direction =>
      widget.pages.textDirection ?? Directionality.of(context);

  /// A horizontal fling turns the page — the same smooth animation the
  /// buttons trigger, direction-aware: in LTR a leftward swipe goes
  /// forward; in RTL a rightward swipe does.
  void _onSwipe(DragEndDetails details) {
    // Marking owns the drag: a reader dragging out a passage must not have
    // the page turn under their finger.
    if (!_swipe.enabled ||
        _marking ||
        _showIndex ||
        _flipPhase != _FlipPhase.idle) {
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 80) {
      return; // Too gentle to be a page turn.
    }
    // A vertical flick must never turn the page.
    //
    // details.velocity cannot answer this: a HorizontalDragGestureRecognizer
    // reports velocity constrained to its OWN axis, so dy is always zero.
    //
    // Raw pointer travel is the honest measure — a Listener sees every move
    // event whatever the gesture arena decides, so the vertical component
    // survives to be compared.
    if (_pointerTravel.dx.abs() <= _pointerTravel.dy.abs()) {
      return; // Predominantly vertical — a scroll, not a page turn.
    }
    final backward = _direction == TextDirection.rtl
        ? velocity < 0 // RTL: leftward swipe goes back.
        : velocity > 0; // LTR: rightward swipe goes back.
    // Only a swipe that actually turns a page counts toward "learned" —
    // a fling at the edge of the book flips nothing and proves nothing.
    final canFlip = backward ? _pageIndex > 0 : _pageIndex < _pageCount - 1;
    if (!canFlip) {
      return;
    }
    _dismissSwipeHint(); // The reader is swiping; the hint has done its job.
    unawaited(backward ? _goPrev() : _goNext());
  }

  /// Direction-aware navigation: in RTL the forward flip uses the backward
  /// animation so the page curls the way an RTL book actually turns.
  Future<void> _goNext() {
    final target = _pageIndex + 1;
    if (target >= _pageCount) {
      return Future<void>.value();
    }
    return _direction == TextDirection.rtl
        ? _flipToPrev(target)
        : _flipToNext(target);
  }

  Future<void> _goPrev() {
    final target = _pageIndex - 1;
    if (target < 0) {
      return Future<void>.value();
    }
    return _direction == TextDirection.rtl
        ? _flipToNext(target)
        : _flipToPrev(target);
  }

  Widget _buildPage(int index) {
    // EDG-01: an empty pages list renders blank paper, never a RangeError —
    // apps that build pages from async data show the book before the fetch.
    final page = _pageCount == 0
        ? const FlipBookPage()
        : widget.pages.items[index.clamp(0, _pageCount - 1)];
    // A page that prints nothing above its body owns the WHOLE screen —
    // the chrome floats on top instead of reserving paper-coloured strips
    // above and below, so a dark cover is dark to the screen edge.
    final fullBleed = (page.title == null || !page.showTitleOnPage) &&
        page.tagline == null &&
        page.body != null;
    return _FlipBookScaffold(
      rtl: _direction == TextDirection.rtl,
      fullBleed: fullBleed,
      content: _pageContent(page, live: index == _pageIndex),
      footer: _footer ?? const FlipBookFooter(),
      header: _header,
      read: _read,
      marker: _marker,
      bookmarks: _bookmarks,
      isBookmarked: _isBookmarked,
      isSaved: _isSaved,
      onBookmark: _bookmarks?.onBookmark != null ? _onBookmark : null,
      // A page with no id cannot be saved — there is nothing to remember it
      // by — so the button is absent rather than dead.
      onToggleSaved:
          _bookmarks?.onSavedChanged != null && _currentPageId != null
              ? _onToggleSaved
              : null,
      pageNumber: widget.pages.showNumber ? '${index + 1} / $_pageCount' : null,
      headerAction: _header?.action,
      hasIndex: _hasIndex,
      isMuted: _muted,
      showHeader: (_header != null),
      showFooter: (_footer != null),
      onClose: widget.onClose,
      onNext: (_footer?.nav.show ?? false) && index < _pageCount - 1
          ? _goNext
          : null,
      onPrev: (_footer?.nav.show ?? false) && index > 0 ? _goPrev : null,
      onMuteToggle: (_footer?.sound != null) &&
              (_footer?.sound?.showMute ?? false) &&
              _footer?.sound?.onFlip != null
          ? _toggleMute
          : null,
      readPhase: _readPhase,
      canPauseReading: _canPauseReading,
      onReadPlay: _read?.onRead != null
          ? () => _readPhase == _ReadPhase.paused
              ? _resumeReading()
              : _playReading(index)
          : null,
      onReadPlayAll: (_read?.playAll ?? false) && _read?.onRead != null
          ? () => _playReading(index, chain: true)
          : null,
      onReadPause: _pauseReading,
      onReadStop: _stopReading,
      onToggleIndex: _toggleIndex,
      readSpeed: _readSpeed,
      onReadSpeedChanged: _read?.speed == null
          ? null
          : (speed) {
              setState(() => _readSpeed = speed);
              _read!.speed!.onChanged?.call(speed);
            },
      marking: _marking,
      onToggleMarking: _canMark ? _toggleMarking : null,
      // The trash belongs to THIS page: a mark elsewhere in the book must not
      // put a live clear button on a page that has none.
      onClearMarks: _pageHasMarks ? _clearMarks : null,
      chromeVisible: _chromeVisible || _showIndex,
      headerVisible: _headerVisible || _showIndex,
      onFooterInteraction: _footerAuto ? _armChromeHide : null,
      onHeaderInteraction: _headerAuto ? _armChromeHide : null,
      controlLabel: _controlLabel,
      onControlUsed: _showControlLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = Scaffold(
      backgroundColor: widget.pages.paperColor,
      body: Listener(
        // Raw pointer travel, recorded before any recogniser claims the
        // gesture — this is what tells a swipe from a scroll.
        onPointerDown: (_) => _pointerTravel = Offset.zero,
        onPointerMove: (e) => _pointerTravel += e.delta,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: _onSwipe,
          // Immersive mode: a tap on the page toggles every auto-hiding
          // element. Taps that land on buttons are consumed by them and
          // never reach this.
          onTap: _footerAuto || _headerAuto ? _toggleChrome : null,
          // No SafeArea here: pages paint to the physical screen edges (a
          // black cover is black to the last pixel). The chrome, the TOC,
          // and the built-in page layout carry their own SafeArea, so
          // buttons and text still clear notches and system bars.
          child: Stack(
            fit: StackFit.expand,
            children: [
              // PREV capture target — rendered below the current page so it is
              // painted (toImage works) but invisible to the user.
              // ColoredBox gives it a solid background so it can be captured
              // correctly (page content on pageColor, no transparency).
              if (_flipPhase == _FlipPhase.capturingPrev)
                RepaintBoundary(
                  key: _prevCaptureKey,
                  child: ColoredBox(
                    color: widget.pages.paperColor,
                    child: _buildPage(_nextIndex),
                  ),
                ),

              if (_showIndex && _hasIndex)
                SafeArea(
                  child: _IndexPage(
                    pages: widget.pages.items,
                    currentPage: _pageIndex,
                    headerAction: _header?.action,
                    contents: widget.contents,
                    footer: _footer ?? const FlipBookFooter(),
                    header: _header,
                    onSelect: _jumpToPage,
                    onClose: _toggleIndex,
                    onExport: widget.contents.export != null
                        ? () => _openExport(widget.contents.export!)
                        : null,
                  ),
                )
              else if (_flipPhase == _FlipPhase.animatingForward)
                // NEXT: destination page shows through as the current page peels
                // away. IgnorePointer keeps layout identical (buttons present)
                // so there is no footer shift when animation ends.
                IgnorePointer(
                  child: _buildPage(_nextIndex),
                )
              else
                // PREV (animating or idle): ColoredBox makes this page opaque so
                // it fully hides the capture target stacked below during
                // _capturingPrev. IgnorePointer blocks touches during animation
                // without changing the widget tree, so no layout shift occurs.
                IgnorePointer(
                  ignoring: _flipPhase == _FlipPhase.animatingBackward,
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: ColoredBox(
                      color: widget.pages.paperColor,
                      child: _buildPage(_pageIndex),
                    ),
                  ),
                ),

              if ((_flipPhase == _FlipPhase.animatingForward ||
                      _flipPhase == _FlipPhase.animatingBackward) &&
                  !_showIndex)
                AnimatedBuilder(
                  animation: _curved,
                  builder: (_, __) => CurlOverlay(
                    progress: _curved.value,
                    pageImage: _capturedImage,
                    pageColor: widget.pages.paperColor,
                    shine: widget.shine,
                    shadow: widget.shadow,
                  ),
                ),

              // The reader's keep / discard row, pinned to the words they just
              // dragged out. It lives HERE, at page level, precisely so it is
              // never confined to the height of one paragraph — see
              // _buildMarkActionsOverlay.
              if (_draft != null && _draftRect != null && !_showIndex)
                _buildMarkActionsOverlay(),

              // Transient swipe hint — no pill, no background: by default
              // just the text with fading chevrons. It greets a page once,
              // fades, and retires after FlipBookSwipeHint.maxShows.
              if ((_hint != null) && _swipe.enabled && !_showIndex)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 96,
                  child: IgnorePointer(
                    child: Center(
                      // AnimatedSwitcher rather than AnimatedOpacity so the
                      // hint leaves the tree entirely while hidden — its
                      // chevrons must not pollute icon finders or semantics.
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        child: _swipeHintVisible
                            ? _buildSwipeHint()
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),

              // Immersive mode, mouse platforms: hovering over the book's
              // bottom (footer) or top (header) edge reveals the hidden
              // chrome — the desktop/web equivalent of the tap. Mouse-only;
              // touches pass through.
              if (_footerAuto)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 96,
                  child: MouseRegion(
                    opaque: false,
                    hitTestBehavior: HitTestBehavior.translucent,
                    onEnter: (_) => _revealChrome(),
                  ),
                ),
              if (_headerAuto)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 96,
                  child: MouseRegion(
                    opaque: false,
                    hitTestBehavior: HitTestBehavior.translucent,
                    onEnter: (_) => _revealChrome(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final dir = widget.pages.textDirection;
    return dir == null ? book : Directionality(textDirection: dir, child: book);
  }
}

// ── Read phase ────────────────────────────────────────────────────────────────

/// Lifecycle of the centre read-aloud control.
enum _ReadPhase { idle, playing, paused }

/// Which page element a sentence belongs to — where the marker draws it.
enum _ReadPart { title, tagline, body }

/// Builds one markable text block. Passed to [_FlipBookState._buildBodyBlocks]
/// so the body helper renders blocks exactly as the page layout does.
typedef _MarkableBuilder = Widget Function(
  String text,
  TextStyle style,
  _ReadPart part, {
  int segment,
  bool follow,
  int? maxLines,
  TextOverflow? overflow,
});

/// One reading unit of a page: which element it belongs to, which body
/// segment (0 for title and tagline), its character range inside that
/// block's own string, and the trimmed text handed to the engine.
@immutable
class _SentenceRef {
  const _SentenceRef(this.part, this.segment, this.range, this.text);

  final _ReadPart part;
  final int segment;
  final TextRange range;
  final String text;
}

/// Lifecycle of a page flip. One value instead of four booleans: illegal
/// combinations (capturing while animating, busy while idle) are
/// unrepresentable, and every guard reads a single field.
enum _FlipPhase {
  /// No flip in progress.
  idle,

  /// PREV phase 1: the target page renders hidden for one frame so it can
  /// be captured.
  capturingPrev,

  /// The captured page is peeling away (NEXT).
  animatingForward,

  /// The captured page is descending back (PREV).
  animatingBackward,
}

// ── Scaffold ──────────────────────────────────────────────────────────────────

class _FlipBookScaffold extends StatelessWidget {
  const _FlipBookScaffold({
    required this.content,
    required this.footer,
    required this.rtl,
    this.header,
    this.read,
    this.marker,
    this.bookmarks,
    this.isBookmarked = false,
    this.isSaved = false,
    this.onBookmark,
    this.onToggleSaved,
    required this.isMuted,
    required this.hasIndex,
    required this.readPhase,
    required this.canPauseReading,
    required this.fullBleed,
    this.showHeader = true,
    this.showFooter = true,
    this.headerVisible = true,
    this.onHeaderInteraction,
    this.readSpeed = FlipBookReadSpeed.normal,
    this.onReadSpeedChanged,
    this.marking = false,
    this.onToggleMarking,
    this.onClearMarks,
    this.pageNumber,
    this.headerAction,
    this.onClose,
    this.onNext,
    this.onPrev,
    this.onMuteToggle,
    this.onReadPlay,
    this.onReadPlayAll,
    this.onReadPause,
    this.onReadStop,
    this.onToggleIndex,
    this.chromeVisible = true,
    this.onFooterInteraction,
    this.controlLabel,
    this.onControlUsed,
  });

  /// Reading direction, taken from the book rather than from an ambient
  /// [Directionality], so an explicit `pages.textDirection` still wins.
  final bool rtl;

  final Widget content;

  /// The bar and its controls. Never null here: the scaffold is only built
  /// when a footer exists, or with defaults for a chrome-free book.
  final FlipBookFooter footer;

  /// The top strip, when the book has one.
  final FlipBookHeader? header;

  /// Read-aloud, when the book can speak — its labels and control content.
  final FlipBookReadAloud? read;

  /// Reader marking, when it is switched on.
  final FlipBookMarker? marker;

  /// The bookmark and save-page controls, when the book has them.
  final FlipBookBookmarks? bookmarks;

  /// Whether the page on screen is the one to carry on from.
  final bool isBookmarked;

  /// Whether the page on screen is in the reader's saved set.
  final bool isSaved;

  /// Keeps this page as the place to carry on from. Null hides the button.
  final VoidCallback? onBookmark;

  /// Adds or removes this page from the saved set. Null hides the button.
  final VoidCallback? onToggleSaved;
  final bool isMuted;
  final bool hasIndex;
  final _ReadPhase readPhase;
  final bool canPauseReading;
  final bool fullBleed;
  final String? pageNumber;
  final Widget? headerAction;
  final VoidCallback? onClose;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final VoidCallback? onMuteToggle;
  final VoidCallback? onReadPlay;
  final VoidCallback? onReadPlayAll;
  final VoidCallback? onReadPause;
  final VoidCallback? onReadStop;
  final VoidCallback? onToggleIndex;

  /// Whether the header and the footer render at all — the structural
  /// switches, independent of the chrome visibility animation below.
  final bool showHeader;
  final bool showFooter;

  /// Footer visibility — while false the footer fades out
  /// and stops accepting taps.
  final bool chromeVisible;

  /// Header visibility (FlipBook.headerChrome) — same animation as the
  /// footer, hiding upward instead of sinking.
  final bool headerVisible;

  /// Fired on any pointer-down inside the footer / header so the auto-hide
  /// clock restarts; null outside autoHide mode.
  final VoidCallback? onFooterInteraction;
  final VoidCallback? onHeaderInteraction;

  /// The chosen reading speed, and the seam that reports a change. A null
  /// callback hides the control.
  final FlipBookReadSpeed readSpeed;
  final ValueChanged<FlipBookReadSpeed>? onReadSpeedChanged;

  /// Reader marking: whether the pencil is currently on, whether a dragged
  /// passage is waiting to be kept, and the four actions. A null
  /// [onToggleMarking] hides the pencil; a null [onClearMarks] hides the
  /// trash, which is how it appears only once something is saved.
  final bool marking;
  final VoidCallback? onToggleMarking;
  final VoidCallback? onClearMarks;

  /// The control name to show above the footer right now, or null.
  final String? controlLabel;

  /// Reports the name of a control the reader just tapped.
  final ValueChanged<String>? onControlUsed;

  @override
  Widget build(BuildContext context) {
    if (!showHeader && !showFooter) {
      // Chrome-free book: pure pages, driven by a FlipBookController.
      return content;
    }
    // EVERY page paints edge to edge and the chrome floats above it — so
    // dark pages are fully dark to the physical screen edge, and in
    // autoHide mode a hidden footer leaves no dead band. Body-only pages
    // own the whole surface (and their own safe insets, like the example's
    // magazine cover); the built-in structured layout is kept inside
    // SafeArea, clearing notches before `pagePadding` clears the bars.
    return Stack(
      fit: StackFit.expand,
      children: [
        if (fullBleed) content else SafeArea(child: content),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader)
                _chromeWrap(
                  _header(),
                  visible: headerVisible,
                  onInteraction: onHeaderInteraction,
                  hiddenOffset: const Offset(0, -0.25),
                ),
              const Spacer(),
              if (showFooter)
                _chromeWrap(
                  _footer(),
                  visible: chromeVisible,
                  onInteraction: onFooterInteraction,
                  hiddenOffset: const Offset(0, 0.25),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Chrome auto-hide: fade + slight travel while hidden, untappable, and
  /// out of the semantics tree — a screen reader must not focus invisible
  /// buttons. Interactions inside visible chrome restart the clock.
  Widget _chromeWrap(
    Widget child, {
    required bool visible,
    required VoidCallback? onInteraction,
    required Offset hiddenOffset,
  }) {
    return Listener(
      onPointerDown: onInteraction == null ? null : (_) => onInteraction(),
      child: IgnorePointer(
        ignoring: !visible,
        child: ExcludeSemantics(
          excluding: !visible,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: AnimatedSlide(
              offset: visible ? Offset.zero : hiddenOffset,
              duration: const Duration(milliseconds: 220),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return _FlipBookHeader(
      closeIcon: (header?.closeIcon ?? Icons.close),
      closeIconColor: (header?.closeColor ?? Colors.black54),
      closeLabel: (header?.closeLabel ?? 'Close'),
      onClose: onClose,
      headerAction: headerAction,
    );
  }

  Widget _footer() {
    // Two rows, because one row of nine icons on a phone is a scrum.
    // Line 1 is the BOOK: where you are and how you move. Line 2 is the
    // VOICE: everything that makes a sound. A reader looking for "next
    // page" never has to scan past a play button to find it.
    final voice = _voiceRow();
    final bar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _footerButtons(),
        if (voice != null) ...[const SizedBox(height: 2), voice],
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The tapped control names itself for a moment. Icons cannot
          // explain themselves, and a tooltip needs a long-press nobody
          // performs on a phone — so the book simply says the word.
          _controlLabel(),
          // A surface behind the controls: over a photo or dark paper a
          // bare icon row is unreadable. Transparent restores the floating
          // look the book had before 0.2.0.
          DecoratedBox(
            decoration: BoxDecoration(
              color: footer.color,
              borderRadius: BorderRadius.circular(footer.radius),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: bar,
            ),
          ),
        ],
      ),
    );
  }

  /// The transient label above the footer naming the control just tapped.
  /// Reserves its own height so the footer never jumps as it comes and goes.
  Widget _controlLabel() {
    return SizedBox(
      height: 30,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: controlLabel == null
              ? const SizedBox.shrink()
              : DecoratedBox(
                  key: ValueKey(controlLabel),
                  decoration: BoxDecoration(
                    color: footer.tapLabelColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(controlLabel!, style: footer.tapLabelStyle),
                  ),
                ),
        ),
      ),
    );
  }

  /// 0.5x · 1x · 1.5x — the reader's own pace. The package only reports the
  /// choice; the app applies it to its speech engine.
  /// Takes the settings rather than reaching for `read!.speed!`.
  ///
  /// The double bang was safe only because the single call site checked first
  /// — the invariant lived in the caller, not in the type, so any second call
  /// site would have crashed. A parameter carries the guarantee.
  Widget _speedControl(FlipBookSpeedControl speedSettings) {
    Widget option(FlipBookReadSpeed speed, String label) {
      final selected = speed == readSpeed;
      final fill = speedSettings.selectedColor ?? footer.iconColor;
      final text = Text(
        label,
        style: selected
            ? (speedSettings.selectedStyle ??
                footer.pageNumberStyle.copyWith(
                  fontWeight: FontWeight.w800,
                  color: footer.color,
                ))
            : (speedSettings.style ?? footer.pageNumberStyle),
      );
      return _FooterControl(
        semanticLabel: '$label ${speedSettings.semantics}',
        onTap: () {
          // The tapped speed names itself like every other control:
          // a bolder weight alone is hard to spot.
          onControlUsed?.call('$label ${speedSettings.tapSuffix}');
          onReadSpeedChanged!(speed);
        },
        child: selected
            // A filled pill, not just a heavier weight.
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  child: text,
                ),
              )
            : text,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Semantics(
        label: speedSettings.semantics,
        container: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final speed in speedSettings.options) ...[
                if (speed != speedSettings.options.first)
                  const SizedBox(width: 14),
                option(speed, _speedLabel(speedSettings, speed)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The label of one speed, from the caller's wording.
  String _speedLabel(FlipBookSpeedControl settings, FlipBookReadSpeed speed) =>
      switch (speed) {
        FlipBookReadSpeed.slow => settings.slowLabel,
        FlipBookReadSpeed.normal => settings.normalLabel,
        FlipBookReadSpeed.fast => settings.fastLabel,
      };

  /// One footer control: the caller's widget when they gave one, otherwise
  /// the built-in icon. Tapping announces [label] through [onControlUsed].
  /// [label] is the short word flashed above the footer on a tap;
  /// [semanticLabel] is the fuller sentence a screen reader announces. They
  /// differ on purpose — "PLAY" is right on screen, "Read this page aloud"
  /// is right in the ear.
  Widget _control({
    required Widget? content,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? semanticLabel,
  }) {
    return _FooterControl(
      semanticLabel: semanticLabel ?? label,
      onTap: () {
        onControlUsed?.call(label);
        onTap();
      },
      child: content ?? Icon(icon, size: footer.iconSize, color: color),
    );
  }

  /// The footer is three flexible zones — left, centre, right — and each
  /// zone scales its own contents down (FittedBox) when the screen is
  /// narrow or the font scale is large, so no control is ever clipped.
  Widget _footerButtons() {
    // One evenly spread row, not three weighted groups.
    //
    // The groups were `Expanded` with fixed flexes, and each was a
    // `FittedBox`: a group that could not fit SHRANK its icons — and their
    // tap targets with them — while its neighbours kept empty space. Five
    // controls in a two-sevenths slot came out at about half size and were
    // genuinely hard to hit.
    //
    // `Wrap` with `spaceEvenly` spreads every control across the whole bar
    // and, unlike a `Row`, drops to a second line instead of overflowing on
    // a narrow phone. Nothing is ever scaled down to make it fit.
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 2,
      children: [
        if (hasIndex && onToggleIndex != null)
          _control(
            content: footer.index.child,
            icon: footer.index.icon,
            label: footer.index.label,
            color: footer.iconColor,
            onTap: onToggleIndex!,
          ),
        if (onBookmark != null)
          _control(
            content: isBookmarked
                ? bookmarks?.bookmarkedChild
                : bookmarks?.bookmarkChild,
            icon: isBookmarked
                ? (bookmarks?.bookmarkedIcon ?? Icons.bookmark)
                : (bookmarks?.bookmarkIcon ?? Icons.bookmark_border),
            label: isBookmarked
                ? (bookmarks?.bookmarkedLabel ?? '')
                : (bookmarks?.bookmarkLabel ?? ''),
            color: isBookmarked
                ? (bookmarks?.activeColor ??
                    bookmarks?.color ??
                    footer.iconColor)
                : (bookmarks?.color ?? footer.iconColor),
            onTap: onBookmark!,
          ),
        if (onToggleSaved != null)
          _control(
            content: isSaved ? bookmarks?.savedChild : bookmarks?.saveChild,
            icon: isSaved
                // A star reads as "favourite". These pages are the ones the
                // reader collects and exports, so the glyph says "add to my
                // set" and, once added, says it is in.
                ? (bookmarks?.savedIcon ?? Icons.library_add_check)
                : (bookmarks?.saveIcon ?? Icons.library_add),
            label: isSaved
                ? (bookmarks?.unsaveLabel ?? '')
                : (bookmarks?.saveLabel ?? ''),
            color: isSaved
                ? (bookmarks?.activeColor ??
                    bookmarks?.color ??
                    footer.iconColor)
                : (bookmarks?.color ?? footer.iconColor),
            onTap: onToggleSaved!,
          ),
        if (onToggleMarking != null)
          _control(
            content: marker?.pencil,
            icon: Icons.edit_outlined,
            label: marking
                ? (marker?.stopLabel ?? '')
                : (marker?.pencilLabel ?? ''),
            // The pencil stays lit while marking is on, so the
            // reader can see why swiping stopped turning pages.
            color: marking
                ? (marker?.color ?? const Color(0x338A8A8A))
                    .withValues(alpha: 1)
                : footer.iconColor,
            onTap: onToggleMarking!,
          ),
        if (onClearMarks != null)
          _control(
            content: marker?.clear,
            icon: Icons.delete_outline,
            label: (marker?.clearLabel ?? ''),
            color: footer.iconColor,
            onTap: onClearMarks!,
          ),
        if (pageNumber != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(pageNumber!, style: footer.pageNumberStyle),
          ),
        // A Row reverses its children under RTL, so "previous" lands on
        // the right — but the GLYPH is not mirrored with it, which showed an
        // Arabic reader "> <" where the arrows should read "< >". Swap the
        // default chevrons so each still points the way it travels. A caller
        // who supplied their own icon or child gets it untouched: mirroring
        // someone else's artwork would be a guess.
        if (onPrev != null)
          _navControl(
            content: footer.nav.previousChild,
            icon: _navIcon(footer.nav.previousIcon, back: true, rtl: rtl),
            label: footer.nav.previousLabel,
            onTap: onPrev!,
          ),
        if (onNext != null)
          _navControl(
            content: footer.nav.nextChild,
            icon: _navIcon(footer.nav.nextIcon, back: false, rtl: rtl),
            label: footer.nav.nextLabel,
            onTap: onNext!,
          ),
      ],
    );
  }

  /// Line 2 of the footer: everything that makes a sound — the flip-sound
  /// speaker, the voice transport, and the pace.
  ///
  /// Null when the book has neither a voice nor a mute button, and then the
  /// footer is a single row again — a silent book must not pay for an empty
  /// strip.
  Widget? _voiceRow() {
    final hasVoice = onReadPlay != null;
    final hasMute = onMuteToggle != null;
    if (!hasVoice && !hasMute) {
      return null;
    }
    // The pace shows only while the voice is actually speaking — paused or
    // idle, there is nothing to be fast or slow about.
    // Resolved to a value, not a boolean: the widget below then needs no
    // bang at all, and the "is it configured" question is answered once.
    final speed = read?.speed;
    final speedSettings = (onReadSpeedChanged != null &&
            speed != null &&
            speed.options.isNotEmpty &&
            readPhase == _ReadPhase.playing)
        ? speed
        : null;
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 2,
      children: [
        if (hasMute)
          _control(
            content: isMuted ? footer.sound?.offChild : footer.sound?.onChild,
            icon: isMuted
                ? (footer.sound?.offIcon ?? Icons.volume_off)
                : (footer.sound?.onIcon ?? Icons.volume_up),
            label: isMuted
                ? (footer.sound?.unmuteLabel ?? '')
                : (footer.sound?.muteLabel ?? ''),
            color: (footer.sound?.color ?? footer.iconColor),
            onTap: onMuteToggle!,
          ),
        // Idle → play (+ play-all). Playing → pause (when supported) +
        // stop. Paused → resume + stop.
        if (hasVoice) ...[
          if (readPhase == _ReadPhase.idle) ...[
            _control(
              content: read?.play,
              icon: Icons.play_arrow_rounded,
              label: (read?.playLabel ?? ''),
              semanticLabel: (read?.readAloudSemantics ?? ''),
              color: footer.iconColor,
              onTap: onReadPlay!,
            ),
            if (onReadPlayAll != null)
              _control(
                content: read?.playAllControl,
                icon: Icons.playlist_play_rounded,
                label: (read?.playAllLabel ?? ''),
                semanticLabel: (read?.readAllSemantics ?? ''),
                color: footer.iconColor,
                onTap: onReadPlayAll!,
              ),
          ],
          if (readPhase == _ReadPhase.paused)
            _control(
              content: read?.resume,
              icon: Icons.play_arrow_rounded,
              label: (read?.resumeLabel ?? ''),
              semanticLabel: (read?.readAloudSemantics ?? ''),
              color: footer.iconColor,
              onTap: onReadPlay!,
            ),
          if (readPhase == _ReadPhase.playing && canPauseReading)
            _control(
              content: read?.pause,
              icon: Icons.pause_rounded,
              label: (read?.pauseLabel ?? ''),
              semanticLabel: (read?.pauseSemantics ?? ''),
              color: footer.iconColor,
              onTap: onReadPause!,
            ),
          if (readPhase != _ReadPhase.idle)
            _control(
              content: read?.stop,
              icon: Icons.stop_rounded,
              label: (read?.stopLabel ?? ''),
              semanticLabel: (read?.stopSemantics ?? ''),
              color: footer.iconColor,
              onTap: onReadStop!,
            ),
        ],
        if (speedSettings != null) _speedControl(speedSettings),
      ],
    );
  }

  /// PREV / NEXT: the same control, with the glyph mirrored under RTL so a
  /// custom arrow still points with the page travel.
  Widget _navControl({
    required Widget? content,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        Widget glyph = content ??
            Icon(icon,
                size: footer.iconSize,
                color: (footer.nav.color ?? footer.iconColor));
        if (isRtl) {
          glyph = Transform.flip(flipX: true, child: glyph);
        }
        return _FooterControl(
          semanticLabel: label,
          onTap: () {
            onControlUsed?.call(label);
            onTap();
          },
          child: glyph,
        );
      },
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _FlipBookHeader extends StatelessWidget {
  const _FlipBookHeader({
    required this.closeIcon,
    required this.closeIconColor,
    required this.closeLabel,
    this.onClose,
    this.headerAction,
  });

  final IconData closeIcon;
  final Color closeIconColor;
  final String closeLabel;
  final VoidCallback? onClose;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            // The explicit semanticLabel is what screen readers announce;
            // the tooltip alone only fills the tooltip attribute (ACC-01).
            icon: Icon(closeIcon, size: 20, semanticLabel: closeLabel),
            color: closeIconColor,
            tooltip: closeLabel,
          ),
          const Spacer(),
          if (headerAction != null) headerAction!,
        ],
      ),
    );
  }
}

// ── Footer control ───────────────────────────────────────────────────────────

/// One footer control: the caller's widget (or the built-in icon) inside a
/// generous, opaque tap area.
///
/// The padding is invisible touch target — icons sit close together
/// visually while fingers still land reliably, which is what a row of small
/// glyphs on a phone needs.
class _FooterControl extends StatelessWidget {
  const _FooterControl({
    required this.child,
    required this.semanticLabel,
    required this.onTap,
  });

  final Widget child;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // A floor on the touchable area, not just on the glyph. An icon
        // drawn at 24 with 8 of padding is a 40-point target; anything
        // smaller is a button people miss.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Center(widthFactor: 1, heightFactor: 1, child: child),
          ),
        ),
      ),
    );
  }
}

// ── Index / TOC ───────────────────────────────────────────────────────────────

class _IndexPage extends StatefulWidget {
  const _IndexPage({
    required this.pages,
    required this.currentPage,
    required this.contents,
    required this.footer,
    required this.onSelect,
    required this.onClose,
    this.header,
    this.headerAction,
    this.onExport,
  });

  final List<FlipBookPage> pages;
  final int currentPage;
  final FlipBookContents contents;
  final FlipBookFooter footer;
  final FlipBookHeader? header;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;
  final Widget? headerAction;

  /// Opens the export chooser. Null when the book has no `contents.export`,
  /// and then no button is drawn.
  final VoidCallback? onExport;

  @override
  State<_IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<_IndexPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final export = widget.contents.export;
    final filtered = [
      for (int i = 0; i < widget.pages.length; i++)
        if (widget.pages[i].title != null &&
            widget.pages[i].title!.toLowerCase().contains(_query.toLowerCase()))
          (index: i, title: widget.pages[i].title!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FlipBookHeader(
          closeIcon: widget.header?.closeIcon ?? Icons.close,
          closeIconColor: widget.header?.closeColor ?? Colors.black54,
          closeLabel: widget.header?.closeLabel ?? 'Close',
          onClose: widget.onClose,
          headerAction: widget.headerAction,
        ),

        // ── Content ───────────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The heading shares its line with Export. The contents
                // page is the one screen showing the whole book at once, so
                // "which pages" is a question the reader is already here to
                // answer.
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.contents.heading,
                        style: widget.contents.headingStyle,
                      ),
                    ),
                    if (widget.onExport != null && export != null)
                      _FooterControl(
                        semanticLabel: export.label,
                        onTap: widget.onExport!,
                        child: export.child ??
                            Icon(
                              export.icon ?? Icons.ios_share,
                              size: widget.footer.iconSize,
                              color: widget.contents.currentIconColor,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: widget.contents.searchStyle,
                  decoration: InputDecoration(
                    hintText: widget.contents.searchHint,
                    hintStyle: widget.contents.searchHintStyle,
                    prefixIcon: Icon(
                      widget.contents.searchIcon,
                      size: 16,
                      color: widget.contents.searchIconColor,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    filled: true,
                    fillColor: widget.contents.searchFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: widget.contents.searchFocusBorder,
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: widget.contents.dividerColor),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: widget.contents.dividerColor, height: 1),
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      final isCurrent = item.index == widget.currentPage;
                      return InkWell(
                        onTap: () => widget.onSelect(item.index),
                        splashColor: widget.contents.splashColor,
                        highlightColor: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '${item.index + 1}',
                                  style: widget.contents.numberStyle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: isCurrent
                                      ? widget.contents.currentStyle
                                      : widget.contents.titleStyle,
                                ),
                              ),
                              if (isCurrent)
                                Icon(
                                  widget.contents.currentIcon,
                                  size: 14,
                                  color: widget.contents.currentIconColor,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The chevron that points the way a page actually travels.
///
/// A `Row` reverses its children under RTL, so the previous button moves to
/// the right — but its glyph does not turn with it, which showed an Arabic
/// reader `> <` where the arrows should read `< >`. Only the two package
/// defaults are mirrored; an icon the caller chose is returned untouched,
/// because flipping someone else's artwork would be a guess.
IconData _navIcon(IconData icon, {required bool back, required bool rtl}) {
  if (!rtl || (icon != Icons.chevron_left && icon != Icons.chevron_right)) {
    return icon;
  }
  return back ? Icons.chevron_right : Icons.chevron_left;
}
