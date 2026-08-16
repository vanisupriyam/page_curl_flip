import 'package:flutter/material.dart';

/// All visual styling for `FlipBook`.
///
/// Every field has a neutral default designed for white paper, so
/// `const FlipBookTheme()` works out of the box. Pass your own design tokens
/// to match your app, or start from the default and adjust with [copyWith]:
///
/// ```dart
/// const FlipBookTheme().copyWith(
///   navButtonStyle: myLabelStyle,
///   tocSplashColor: myAccent.withValues(alpha: 0.1),
/// )
/// ```
@immutable
class FlipBookTheme {
  /// Creates a theme; every field falls back to a neutral default.
  const FlipBookTheme({
    this.closeIconColor = Colors.black54,
    this.indexButtonStyle = _footerLabel,
    this.navButtonStyle = _footerLabel,
    this.navButtonIconColor = Colors.black54,
    this.muteIconColor = Colors.black54,
    this.tocHeadingStyle = _tocHeading,
    this.tocSearchStyle = _body,
    this.tocSearchHintStyle = _bodyFaint,
    this.tocSearchIconColor = Colors.black38,
    this.tocSearchFillColor = const Color(0x0A000000),
    this.tocSearchFocusBorderColor = Colors.black26,
    this.tocDividerColor = const Color(0x14000000),
    this.tocItemNumberStyle = _tocNumber,
    this.tocItemTitleStyle = _body,
    this.tocItemCurrentStyle = _bodyCurrent,
    this.tocItemCurrentIconColor = Colors.black87,
    this.tocSplashColor = const Color(0x14000000),
    this.pageTitleStyle = _pageTitle,
    this.pageTaglineStyle = _pageTagline,
    this.pagePadding = const EdgeInsets.fromLTRB(32, 24, 32, 24),
    this.pageNumberStyle = _footerLabel,
    this.swipeHintStyle = _swipeHint,
    this.swipeHintArrowSize = 20,
  });

  static const TextStyle _footerLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: Colors.black54,
  );
  static const TextStyle _tocHeading = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: Colors.black87,
  );
  static const TextStyle _body = TextStyle(
    fontSize: 14,
    color: Colors.black87,
  );
  static const TextStyle _bodyFaint = TextStyle(
    fontSize: 14,
    color: Colors.black38,
  );
  static const TextStyle _tocNumber = TextStyle(
    fontSize: 12,
    color: Colors.black38,
  );
  static const TextStyle _bodyCurrent = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );
  static const TextStyle _pageTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
    height: 1.25,
  );
  static const TextStyle _pageTagline = TextStyle(
    fontSize: 14,
    color: Colors.black54,
    height: 1.4,
  );
  static const TextStyle _swipeHint = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: Color(0xFF555555),
  );

  /// Colour of the × close icon in the header.
  final Color closeIconColor;

  /// Text style for the INDEX footer button.
  final TextStyle indexButtonStyle;

  /// Text style for the PREV and NEXT footer buttons.
  final TextStyle navButtonStyle;

  /// Colour of the ‹ and › chevron icons next to PREV / NEXT.
  final Color navButtonIconColor;

  /// Colour of the volume icon in the footer.
  final Color muteIconColor;

  /// Text style for the table-of-contents heading.
  final TextStyle tocHeadingStyle;

  /// Text style for text typed into the search field.
  final TextStyle tocSearchStyle;

  /// Text style for the search field placeholder.
  final TextStyle tocSearchHintStyle;

  /// Colour of the search prefix icon.
  final Color tocSearchIconColor;

  /// Background fill colour of the search field.
  final Color tocSearchFillColor;

  /// Border colour of the search field when focused.
  final Color tocSearchFocusBorderColor;

  /// Colour of dividers between TOC rows.
  final Color tocDividerColor;

  /// Text style for the page-number column in each TOC row.
  final TextStyle tocItemNumberStyle;

  /// Text style for a TOC row title (default / not current page).
  final TextStyle tocItemTitleStyle;

  /// Text style for the TOC row that matches the current page.
  final TextStyle tocItemCurrentStyle;

  /// Colour of the bookmark icon shown on the current page's TOC row.
  final Color tocItemCurrentIconColor;

  /// InkWell splash colour for TOC rows.
  final Color tocSplashColor;

  /// Text style for the title printed at the top of a page.
  final TextStyle pageTitleStyle;

  /// Text style for a page's `tagline`.
  final TextStyle pageTaglineStyle;

  /// Padding around a page the book lays out itself (printed title /
  /// tagline / body). Ignored when a page shows only a `body` — that fills
  /// the paper edge-to-edge.
  final EdgeInsetsGeometry pagePadding;

  /// Text style for the optional "3 / 12" page indicator.
  final TextStyle pageNumberStyle;

  /// Text style of the transient swipe hint. The hint has no background —
  /// just this text with fading chevrons on both sides, which take their
  /// colour from this style's `color`.
  final TextStyle swipeHintStyle;

  /// Size of the fading chevrons beside the swipe hint text.
  final double swipeHintArrowSize;

  /// Returns a copy of this theme with the given fields replaced.
  FlipBookTheme copyWith({
    Color? closeIconColor,
    TextStyle? indexButtonStyle,
    TextStyle? navButtonStyle,
    Color? navButtonIconColor,
    Color? muteIconColor,
    TextStyle? tocHeadingStyle,
    TextStyle? tocSearchStyle,
    TextStyle? tocSearchHintStyle,
    Color? tocSearchIconColor,
    Color? tocSearchFillColor,
    Color? tocSearchFocusBorderColor,
    Color? tocDividerColor,
    TextStyle? tocItemNumberStyle,
    TextStyle? tocItemTitleStyle,
    TextStyle? tocItemCurrentStyle,
    Color? tocItemCurrentIconColor,
    Color? tocSplashColor,
    TextStyle? pageTitleStyle,
    TextStyle? pageTaglineStyle,
    EdgeInsetsGeometry? pagePadding,
    TextStyle? pageNumberStyle,
    TextStyle? swipeHintStyle,
    double? swipeHintArrowSize,
  }) {
    return FlipBookTheme(
      closeIconColor: closeIconColor ?? this.closeIconColor,
      indexButtonStyle: indexButtonStyle ?? this.indexButtonStyle,
      navButtonStyle: navButtonStyle ?? this.navButtonStyle,
      navButtonIconColor: navButtonIconColor ?? this.navButtonIconColor,
      muteIconColor: muteIconColor ?? this.muteIconColor,
      tocHeadingStyle: tocHeadingStyle ?? this.tocHeadingStyle,
      tocSearchStyle: tocSearchStyle ?? this.tocSearchStyle,
      tocSearchHintStyle: tocSearchHintStyle ?? this.tocSearchHintStyle,
      tocSearchIconColor: tocSearchIconColor ?? this.tocSearchIconColor,
      tocSearchFillColor: tocSearchFillColor ?? this.tocSearchFillColor,
      tocSearchFocusBorderColor:
          tocSearchFocusBorderColor ?? this.tocSearchFocusBorderColor,
      tocDividerColor: tocDividerColor ?? this.tocDividerColor,
      tocItemNumberStyle: tocItemNumberStyle ?? this.tocItemNumberStyle,
      tocItemTitleStyle: tocItemTitleStyle ?? this.tocItemTitleStyle,
      tocItemCurrentStyle: tocItemCurrentStyle ?? this.tocItemCurrentStyle,
      tocItemCurrentIconColor:
          tocItemCurrentIconColor ?? this.tocItemCurrentIconColor,
      tocSplashColor: tocSplashColor ?? this.tocSplashColor,
      pageTitleStyle: pageTitleStyle ?? this.pageTitleStyle,
      pageTaglineStyle: pageTaglineStyle ?? this.pageTaglineStyle,
      pagePadding: pagePadding ?? this.pagePadding,
      pageNumberStyle: pageNumberStyle ?? this.pageNumberStyle,
      swipeHintStyle: swipeHintStyle ?? this.swipeHintStyle,
      swipeHintArrowSize: swipeHintArrowSize ?? this.swipeHintArrowSize,
    );
  }
}
