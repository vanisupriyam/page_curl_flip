import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'flip_book_marker_style.dart';

/// A text block the read marker can mark.
///
/// Renders [text] exactly like a plain [Text], plus the marked sentence:
/// in [FlipBookMarkerStyle.highlight] a broad rounded band is painted
/// behind [marked]; in [FlipBookMarkerStyle.focus] everything except
/// [marked] dims to [dimOpacity] instead — nothing is painted over the
/// text.
///
/// With [autoFollow], a change of [marked] scrolls the nearest enclosing
/// scrollable so the sentence stays in view — the voice must never read
/// below the fold. Pages without a scrollable ancestor are left alone.
///
/// Internal to the package: exported nowhere, consumed by `FlipBook`.
class MarkedText extends StatefulWidget {
  /// Creates a markable text block.
  const MarkedText({
    super.key,
    required this.text,
    required this.style,
    this.marked,
    this.dimmed = false,
    this.markerStyle = FlipBookMarkerStyle.highlight,
    this.markerColor = const Color(0x338A8A8A),
    this.markerRadius = 6,
    this.dimOpacity = 0.35,
    this.autoFollow = false,
    this.savedMarks = const [],
    this.savedMarkColor = const Color(0x338A8A8A),
    this.draftMark,
    this.onDraftMark,
    this.draftLink,
    this.onDraftRect,
    this.maxLines,
    this.overflow,
  });

  /// The full text of this block.
  final String text;

  /// Style of the whole block — the marker never changes the type, only
  /// what sits behind (highlight) or around (focus) the sentence.
  final TextStyle style;

  /// Character range of the sentence being read, in [text]'s offsets;
  /// `null` renders a plain [Text].
  final TextRange? marked;

  /// Reading is under way somewhere else on this page, so this block holds
  /// none of it.
  ///
  /// In [FlipBookMarkerStyle.focus] the whole block dims. Without this
  /// the focus style only worked inside a block that happened to hold two
  /// units — a one-unit title or paragraph lit entirely and nothing around
  /// it faded, so the marker looked broken on exactly the pages that use
  /// segments. The dim belongs to the PAGE, not to one paragraph.
  final bool dimmed;

  /// Band behind the sentence, or dim everything else.
  final FlipBookMarkerStyle markerStyle;

  /// Colour of the highlight band.
  final Color markerColor;

  /// Corner radius of the highlight band.
  final double markerRadius;

  /// In [FlipBookMarkerStyle.focus]: the opacity the rest of the text
  /// fades to.
  final double dimOpacity;

  /// Keep the marked sentence visible in the enclosing scrollable.
  final bool autoFollow;

  /// Ranges the reader marked by hand and saved, in this block's offsets.
  /// Painted under the text like a highlighter, always — reading or not.
  final List<TextRange> savedMarks;

  /// Colour of the reader's own marks, kept separate from the read
  /// marker's so the two never look like the same thing.
  final Color savedMarkColor;

  /// The mark being dragged out right now, not yet saved.
  final TextRange? draftMark;

  /// Fires while the reader drags across this block, with the range under
  /// their finger snapped to whole words. Null disables marking here.
  final ValueChanged<TextRange>? onDraftMark;

  /// Anchors this block for the keep / discard controls, which the book
  /// draws **above the page** rather than inside this block.
  ///
  /// Non-null only on the block that currently holds [draftMark]. The link
  /// is what lets the controls follow the words while the page scrolls,
  /// without this widget knowing anything about the page around it.
  final LayerLink? draftLink;

  /// Reports the marked words' rectangle AND this block's width, both in the
  /// block's own coordinates, so the book can place the keep / discard
  /// controls clear of the marked words — and, under RTL, against the right
  /// edge of the mark rather than the left.
  ///
  /// The block reports, the page decides. Placing the controls here would
  /// confine them to this block's height, and a short paragraph is barely
  /// taller than the control row — leaving nowhere to put it but on top of
  /// the marked words.
  final void Function(Rect rect, double blockWidth)? onDraftRect;

  /// Passed through to the underlying [Text].
  final int? maxLines;

  /// Passed through to the underlying [Text].
  final TextOverflow? overflow;

  @override
  State<MarkedText> createState() => _MarkedTextState();
}

class _MarkedTextState extends State<MarkedText> {
  /// Where the current marking drag began, in character offsets. Held so
  /// the range can be rebuilt from anchor→finger on every move, which is
  /// what lets a reader drag backwards.
  int? _dragAnchor;

  /// The last rectangle handed to [MarkedText.onDraftRect]. Guards the
  /// report so an unchanged drag does not rebuild the page every frame.
  Rect? _reportedRect;

  @override
  void didUpdateWidget(MarkedText old) {
    super.didUpdateWidget(old);
    if (widget.autoFollow &&
        widget.marked != null &&
        widget.marked != old.marked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    }
  }

  /// The clamped range — a stale range from a rebuilt page must never
  /// crash a substring.
  TextRange get _range {
    final marked = widget.marked!;
    final start = marked.start.clamp(0, widget.text.length);
    return TextRange(
        start: start, end: marked.end.clamp(start, widget.text.length));
  }

  /// [MarkedText.style] as the screen actually renders it.
  ///
  /// `Text(style: s)` MERGES the ambient `DefaultTextStyle` — which is where
  /// the app's font comes from — but a `TextPainter` built from the same `s`
  /// merges nothing. Give the painter the unmerged style and it lays the text
  /// out in a different font from the one on screen, so every character
  /// lookup is off by the difference: a drag stops inside a word, the band
  /// paints in the wrong place, and auto-scroll follows the wrong line.
  ///
  /// Widget tests cannot catch this — the test font is one fixed-width face
  /// for every family, which hides the mismatch entirely.
  ///
  /// Everything that measures OR draws this text must go through here.
  TextStyle get _style =>
      DefaultTextStyle.of(context).style.merge(widget.style);

  /// Mirrors the [Text] layout exactly — same style, direction, scale, and
  /// line limits — so the boxes it reports are the boxes on screen.
  TextPainter _layout(double maxWidth) => TextPainter(
        text: TextSpan(text: widget.text, style: _style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: widget.maxLines,
        ellipsis: widget.overflow == TextOverflow.ellipsis ? '…' : null,
      )..layout(maxWidth: maxWidth);

  /// Scrolls the enclosing scrollable so the marked sentence sits about a
  /// third from the top — the read-along behaviour of every audiobook
  /// reader. No scrollable, no size, or no boxes → quietly does nothing.
  void _follow() {
    if (!mounted || widget.marked == null) {
      return;
    }
    final render = context.findRenderObject();
    if (render is! RenderBox || !render.attached || !render.hasSize) {
      return;
    }
    final viewport = RenderAbstractViewport.maybeOf(render);
    final position = Scrollable.maybeOf(context)?.position;
    if (viewport == null || position == null) {
      return;
    }
    final painter = _layout(render.size.width);
    final range = _range;
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: range.start, extentOffset: range.end),
    );
    painter.dispose();
    if (boxes.isEmpty) {
      return;
    }
    final target = viewport
        .getOffsetToReveal(render, 0.3, rect: boxes.first.toRect())
        .offset
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 8) {
      return;
    }
    position.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  /// The character offset under a local drag position.
  int _offsetAt(Offset local) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return 0;
    }
    final painter = _layout(box.size.width);
    final position = painter.getPositionForOffset(local);
    painter.dispose();
    return position.offset.clamp(0, widget.text.length);
  }

  /// Grows [a]..[b] outward to whole words.
  ///
  /// A mark that starts mid-word ("hel|lo world") reads as a mistake, so
  /// the range is widened to the word edges on both sides. Scripts written
  /// without spaces have no edges to find, and the range is left as dragged.
  TextRange _snapToWords(int a, int b) {
    var start = a < b ? a : b;
    var end = a < b ? b : a;
    bool isWord(int i) =>
        i >= 0 && i < widget.text.length && widget.text[i].trim().isNotEmpty;
    while (start > 0 && isWord(start - 1)) {
      start--;
    }
    while (end < widget.text.length && isWord(end)) {
      end++;
    }
    return TextRange(start: start, end: end);
  }

  void _onDragStart(DragStartDetails details) {
    _dragAnchor = _offsetAt(details.localPosition);
    _emitDraft(_dragAnchor!);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dragAnchor == null) {
      return;
    }
    _emitDraft(_offsetAt(details.localPosition));
  }

  void _emitDraft(int offset) {
    final range = _snapToWords(_dragAnchor!, offset);
    if (!range.isCollapsed) {
      widget.onDraftMark!(range);
    }
  }

  /// [style] faded to [MarkedText.dimOpacity] — the receding ink of the
  /// focus style.
  TextStyle _dimmed(TextStyle style) {
    final ink = style.color!;
    return style.copyWith(
      color: ink.withValues(alpha: ink.a * widget.dimOpacity),
    );
  }

  /// The rectangle the marked words occupy inside this block.
  ///
  /// Reported upwards through [MarkedText.onDraftRect]; the page places the
  /// keep / discard controls from it. This widget deliberately makes no
  /// decision about where the controls go — it cannot see the page, and a
  /// block that is barely taller than the control row has no honest answer.
  /// Null when the range lays out to nothing.
  Rect? _draftRect(TextRange range, double maxWidth) {
    final painter = _layout(maxWidth);
    final boxes = painter.getBoxesForSelection(
      TextSelection(
        baseOffset: range.start.clamp(0, widget.text.length),
        extentOffset: range.end.clamp(0, widget.text.length),
      ),
      boxHeightStyle: ui.BoxHeightStyle.max,
    );
    painter.dispose();
    if (boxes.isEmpty) {
      return null;
    }
    var top = boxes.first.top;
    var bottom = boxes.first.bottom;
    var left = boxes.first.left;
    var right = boxes.first.right;
    for (final box in boxes) {
      if (box.top < top) top = box.top;
      if (box.bottom > bottom) bottom = box.bottom;
      if (box.left < left) left = box.left;
      if (box.right > right) right = box.right;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// The focus rendering: [litStart]..[litEnd] in full ink, everything
  /// else dimmed.
  Widget _focusSpans(int litStart, int litEnd, TextStyle dim) => Text.rich(
        TextSpan(children: [
          TextSpan(text: widget.text.substring(0, litStart), style: dim),
          TextSpan(
            text: widget.text.substring(litStart, litEnd),
            style: _style,
          ),
          TextSpan(text: widget.text.substring(litEnd), style: dim),
        ]),
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );

  /// The text itself, with the read marker applied when this block holds
  /// it — a focus dim needs different spans, so it replaces the plain text
  /// rather than painting behind it.
  Widget _buildText() {
    final style = _style;
    final plain = Text(
      widget.text,
      style: style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
    if (widget.marked == null) {
      // Someone else on the page holds the marker: in focus style this
      // whole block recedes, which is what makes the marked unit stand out.
      if (widget.dimmed &&
          widget.markerStyle == FlipBookMarkerStyle.focus &&
          style.color != null) {
        return Text(
          widget.text,
          style: _dimmed(style),
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      }
      return plain;
    }
    final range = _range;
    if (range.isCollapsed) {
      return plain;
    }
    if (widget.markerStyle == FlipBookMarkerStyle.focus) {
      if (style.color == null) {
        return plain; // No ink to dim — render untouched.
      }
      return _focusSpans(range.start, range.end, _dimmed(style));
    }
    return plain;
  }

  /// Every band to paint behind the text, back to front: the reader's saved
  /// marks, the one being dragged now, and — in highlight style — the read
  /// marker on top.
  List<_Band> _bands() {
    final bands = <_Band>[
      for (final mark in widget.savedMarks) _Band(mark, widget.savedMarkColor),
    ];
    final draft = widget.draftMark;
    if (draft != null && !draft.isCollapsed) {
      bands.add(_Band(draft, widget.savedMarkColor));
    }
    if (widget.marked != null &&
        widget.markerStyle == FlipBookMarkerStyle.highlight) {
      final range = _range;
      if (!range.isCollapsed) {
        bands.add(_Band(range, widget.markerColor));
      }
    }
    return bands;
  }

  @override
  Widget build(BuildContext context) {
    final text = _buildText();
    final bands = _bands();
    final marking = widget.onDraftMark != null;
    if (bands.isEmpty && !marking) {
      return text;
    }
    Widget block = LayoutBuilder(
      builder: (context, constraints) {
        final painted = CustomPaint(
          painter: _MarkerBandPainter(
            text: widget.text,
            style: _style,
            bands: bands,
            radius: widget.markerRadius,
            direction: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: widget.maxLines,
            ellipsis: widget.overflow == TextOverflow.ellipsis,
            maxWidth: constraints.maxWidth,
          ),
          child: text,
        );
        final link = widget.draftLink;
        final draft = widget.draftMark;
        if (link == null || draft == null || draft.isCollapsed) {
          // Forget the last rectangle when the draft goes. Without this,
          // cancelling and then marking the SAME words again reports nothing
          // — the guard below sees an unchanged rectangle — and the row
          // never comes back.
          _reportedRect = null;
          return painted;
        }
        // Measured during layout, reported after the frame: the page rebuilds
        // with the new rectangle, and setState during build is not allowed.
        final rect = _draftRect(draft, constraints.maxWidth);
        if (rect != null && rect != _reportedRect) {
          _reportedRect = rect;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onDraftRect?.call(rect, constraints.maxWidth);
            }
          });
        }
        // The target carries no controls of its own — it only tells the page
        // where these words are, so the row can follow them as they scroll.
        return CompositedTransformTarget(link: link, child: painted);
      },
    );
    if (marking) {
      // Marking mode owns the horizontal drag, so the page cannot flip
      // underneath the finger while a passage is being marked.
      block = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: (_) => _dragAnchor = null,
        child: block,
      );
    }
    return block;
  }
}

/// One painted band: a range and the colour it is drawn in.
@immutable
class _Band {
  const _Band(this.range, this.color);

  final TextRange range;
  final Color color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Band && other.range == range && other.color == color;

  @override
  int get hashCode => Object.hash(range, color);
}

/// Paints the highlight band behind the marked sentence — every line box it
/// covers. The painter caches its [TextPainter] and rebuilds it only when
/// the text, style, or width actually change.
class _MarkerBandPainter extends CustomPainter {
  _MarkerBandPainter({
    required this.text,
    required this.style,
    required this.bands,
    required this.radius,
    required this.direction,
    required this.textScaler,
    required this.maxWidth,
    required this.ellipsis,
    this.maxLines,
  });

  final String text;
  final TextStyle style;
  final List<_Band> bands;
  final double radius;
  final TextDirection direction;
  final TextScaler textScaler;
  final double maxWidth;
  final bool ellipsis;
  final int? maxLines;

  /// Builds a painter for one paint pass. Deliberately not cached.
  ///
  /// A `CustomPainter` has no `dispose`, and a fresh one is constructed on
  /// every rebuild — so a cached `TextPainter` would leave its native
  /// `ui.Paragraph` unreleased each time, which during read-aloud means once
  /// per sentence. [paint] builds one, shares it across the bands, and
  /// disposes it before returning.
  TextPainter _layOut() => TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: textScaler,
        maxLines: maxLines,
        ellipsis: ellipsis ? '…' : null,
      )..layout(maxWidth: maxWidth);

  /// One rectangle per LINE the range covers.
  ///
  /// `getBoxesForSelection` returns a box per text RUN, not per line, and
  /// Arabic breaks into many runs — drawing each as its own rounded rect
  /// produced a wall of bricks across a marked sentence. Boxes that share a
  /// line are merged here, so a mark is one clean band per line in every
  /// script.
  List<Rect> _lineRects(TextPainter painter, TextRange range) {
    final boxes = painter.getBoxesForSelection(
      TextSelection(
        baseOffset: range.start.clamp(0, text.length),
        extentOffset: range.end.clamp(0, text.length),
      ),
      boxHeightStyle: ui.BoxHeightStyle.max,
    );
    final lines = <Rect>[];
    for (final box in boxes) {
      final rect = box.toRect();
      // Same line: the vertical spans overlap. Comparing tops alone fails
      // when one run carries a taller glyph than its neighbour.
      final i = lines.indexWhere(
        (l) => rect.top < l.bottom - 0.5 && rect.bottom > l.top + 0.5,
      );
      if (i < 0) {
        lines.add(rect);
      } else {
        lines[i] = lines[i].expandToInclude(rect);
      }
    }
    return lines;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // One painter for every band, released before this method returns.
    final painter = _layOut();
    for (final band in bands) {
      final paint = Paint()..color = band.color;
      for (final line in _lineRects(painter, band.range)) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(line.inflate(1), Radius.circular(radius)),
          paint,
        );
      }
    }
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _MarkerBandPainter old) =>
      old.text != text ||
      old.style != style ||
      !listEquals(old.bands, bands) ||
      old.radius != radius ||
      old.direction != direction ||
      old.textScaler != textScaler ||
      old.maxWidth != maxWidth ||
      old.ellipsis != ellipsis ||
      old.maxLines != maxLines;
}
