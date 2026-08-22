import 'package:flutter/material.dart';

/// How the book draws a page it lays out itself — the printed title, the
/// tagline, and body text.
///
/// It has no effect on a page whose `body` is your own widget: that is your
/// painting, and the book does not style it.
@immutable
class FlipBookPageStyle {
  /// Every field defaults; `const FlipBookPageStyle()` is the standard page.
  const FlipBookPageStyle({
    this.titleStyle = _title,
    this.taglineStyle = _tagline,
    this.bodyStyle = _body,
    this.padding = const EdgeInsets.fromLTRB(32, 72, 32, 96),
  });

  static const TextStyle _title = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
    height: 1.25,
  );
  static const TextStyle _tagline = TextStyle(
    fontSize: 14,
    color: Colors.black54,
    height: 1.4,
  );
  static const TextStyle _body = TextStyle(
    fontSize: 15,
    color: Colors.black87,
    height: 1.6,
  );

  /// Style of the title printed at the top of a page.
  final TextStyle titleStyle;

  /// Style of the tagline under it.
  final TextStyle taglineStyle;

  /// Style of body text the book renders itself — `bodySegments` or
  /// `bodyText` without a `body` widget.
  final TextStyle bodyStyle;

  /// Padding around a page the book lays out. Every page paints behind the
  /// floating chrome, so the default clears the header at the top and the
  /// footer at the bottom; shrink it if your book hides its chrome.
  final EdgeInsetsGeometry padding;

  /// This object with some fields replaced.
  ///
  /// A null argument means "leave it alone", so a field that is already
  /// nullable cannot be cleared this way — construct a new one for that.
  FlipBookPageStyle copyWith({
    TextStyle? titleStyle,
    TextStyle? taglineStyle,
    TextStyle? bodyStyle,
    EdgeInsetsGeometry? padding,
  }) {
    return FlipBookPageStyle(
      titleStyle: titleStyle ?? this.titleStyle,
      taglineStyle: taglineStyle ?? this.taglineStyle,
      bodyStyle: bodyStyle ?? this.bodyStyle,
      padding: padding ?? this.padding,
    );
  }
}
