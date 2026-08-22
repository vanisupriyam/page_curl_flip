import 'package:flutter/widgets.dart';

/// Everything the book knows about one markable text block — the printed
/// title, the tagline, or a `bodyText` page — handed to
/// [ReadMarkerTextBuilder] so an app can draw its own read marker.
///
/// The builder is called for these blocks in every state: while idle
/// [marked] is null and the block should simply render [text]; while the
/// voice reads, [marked] is the unit being spoken, in [text]'s own offsets.
/// Whatever the builder returns replaces the book's built-in marker
/// rendering entirely — both the highlight band and the focus dim.
@immutable
class ReadMarkerText {
  /// Bundles one markable block's state.
  const ReadMarkerText({
    required this.text,
    required this.style,
    this.marked,
    this.maxLines,
    this.overflow,
  });

  /// The block's full text.
  final String text;

  /// The theme style the book would render this block with.
  final TextStyle style;

  /// Character range of the unit being read aloud, or null while this
  /// block is not being read.
  final TextRange? marked;

  /// Line limit the book would apply (titles are capped at 3).
  final int? maxLines;

  /// Overflow the book would apply.
  final TextOverflow? overflow;
}

/// Signature of `FlipBookHighlight.builder` — return any widget to
/// draw a markable block your own way. See [ReadMarkerText].
typedef ReadMarkerTextBuilder = Widget Function(
  BuildContext context,
  ReadMarkerText details,
);
