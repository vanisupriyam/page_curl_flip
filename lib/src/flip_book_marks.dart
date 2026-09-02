part of 'flip_book.dart';

/// Everything the reader keeps: bookmarks, saved pages, export, and the
/// pencil's reader marks. Same 2026-09-02 split as the reading mixin.
mixin _MarksMixin on _FlipBookStateBase {
  // ── Bookmarks, saved pages, export ────────────────────────────────────

  /// Whether the page on screen is the one the reader will carry on from.
  @override
  bool get _isBookmarked => _bookmarks?.bookmarkedPage == _pageIndex;

  /// The id of the page on screen, when it has one. A page without an id
  /// cannot be saved: there would be nothing to remember it by.
  @override
  String? get _currentPageId => _pageIndex >= 0 && _pageIndex < _pageCount
      ? widget.pages.items[_pageIndex].id
      : null;

  @override
  bool get _isSaved {
    final id = _currentPageId;
    return id != null && (_bookmarks?.saved.contains(id) ?? false);
  }

  /// Reports the current page as the place to carry on from.
  ///
  /// Deliberately does nothing else: it must not stop the voice, drop a mark
  /// or turn a page. A reader keeping their place is not asking the book to
  /// change.
  @override
  void _onBookmark() {
    _bookmarks?.onBookmark?.call(_pageIndex);
    setState(() {});
  }

  /// Adds or removes the current page from the saved set, then reports the
  /// whole set — the same in-and-out seam the marks use.
  @override
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
  @override
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
  @override
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
    final fx =
        width <= 0 ? 0.0 : ((rect.center.dx / width) * 2 - 1).clamp(-1.0, 1.0);

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
  @override
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
  @override
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
  @override
  bool get _canMark =>
      (_marker != null) &&
      _pageCount > 0 &&
      (widget.pages.items[_pageIndex].id?.isNotEmpty ?? false);

  /// This page's saved marks for one block, as plain ranges.
  @override
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

  @override
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

  @override
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
  @override
  bool get _pageHasMarks {
    if (_marker == null || _pageCount == 0) {
      return false;
    }
    // Mid-flip the trash must already speak for the page ARRIVING, since
    // _pageIndex only moves once the flip finishes.
    final index = _flipPhase == _FlipPhase.idle ? _pageIndex : _nextIndex;
    final id = widget.pages.items[index].id;
    if (id == null || id.isEmpty) {
      return false;
    }
    return (_marker?.marks ?? const <ReaderMark>[]).any((m) => m.pageId == id);
  }

  /// Clears the marks on the page being shown — and only those.
  ///
  /// A trash button drawn on a page means that page: every other page keeps
  /// its own marks, and those survivors are what gets reported.
  @override
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
}
