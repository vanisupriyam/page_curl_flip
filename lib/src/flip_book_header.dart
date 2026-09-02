import 'package:flutter/material.dart';

/// The strip at the top of the book: the × close button, and anything you
/// put beside it.
///
/// Always present unless you pass `header: null`, because a reader must
/// always have a way out of the book.
@immutable
class FlipBookHeader {
  /// Every field defaults; `const FlipBookHeader()` is the standard header.
  const FlipBookHeader({
    this.closeIcon = Icons.close,
    this.closeColor = Colors.black54,
    this.closeLabel = 'Close',
    this.action,
    this.autoHide = false,
    this.closeAtEnd = false,
  });

  /// Glyph of the close button.
  final IconData closeIcon;

  /// Colour of that glyph.
  final Color closeColor;

  /// What a screen reader announces for it.
  final String closeLabel;

  /// Optional widget at the trailing edge — a language switch, a bookmark,
  /// anything.
  final Widget? action;

  /// Fades the header away until the reader taps the page, like the footer.
  /// Off by default: the way out stays in reach unless you decide otherwise.
  final bool autoHide;

  /// Puts the × at the trailing edge instead of the leading one, swapping
  /// places with [action]. Trailing follows the text direction, so an RTL
  /// book's "end" is its left. Default false — the × leads, as it always has.
  final bool closeAtEnd;

  /// This object with some fields replaced.
  ///
  /// A null argument means "leave it alone", so a field that is already
  /// nullable cannot be cleared this way — construct a new one for that.
  FlipBookHeader copyWith({
    IconData? closeIcon,
    Color? closeColor,
    String? closeLabel,
    Widget? action,
    bool? autoHide,
    bool? closeAtEnd,
  }) {
    return FlipBookHeader(
      closeIcon: closeIcon ?? this.closeIcon,
      closeColor: closeColor ?? this.closeColor,
      closeLabel: closeLabel ?? this.closeLabel,
      action: action ?? this.action,
      autoHide: autoHide ?? this.autoHide,
      closeAtEnd: closeAtEnd ?? this.closeAtEnd,
    );
  }
}
