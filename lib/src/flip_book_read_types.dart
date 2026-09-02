part of 'flip_book.dart';

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
