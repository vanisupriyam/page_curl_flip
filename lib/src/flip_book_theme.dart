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

  // ── Presets ─────────────────────────────────────────────────────────────────
  // Ready-made looks. Each has a matching *Paper colour to pass as
  // FlipBook.pageColor. Start from any preset and adjust with [copyWith].

  /// Matching paper for [classic].
  static const Color classicPaper = Colors.white;

  /// Matching paper for [oldBook] — warm cream.
  static const Color oldBookPaper = Color(0xFFF6ECD9);

  /// Matching paper for [night] — near-black.
  static const Color nightPaper = Color(0xFF121212);

  /// Matching paper for [magazine].
  static const Color magazinePaper = Colors.white;

  /// Matching paper for [kids] — warm white.
  static const Color kidsPaper = Color(0xFFFFFDF5);

  /// Matching paper for [newspaper] — aged newsprint.
  static const Color newspaperPaper = Color(0xFFF4F1E8);

  /// The default look: white paper, neutral ink, clean sans.
  static const FlipBookTheme classic = FlipBookTheme();

  static const List<String> _serif = ['Georgia', 'Times New Roman', 'serif'];
  static const List<String> _rounded = [
    'Arial Rounded MT Bold',
    'casual',
    'sans-serif',
  ];

  /// An old story book: sepia ink, serif faces, italic taglines.
  /// Pair with [oldBookPaper]; beautiful with a slow flip.
  static const FlipBookTheme oldBook = FlipBookTheme(
    closeIconColor: Color(0xFF7A5C48),
    indexButtonStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: Color(0xFF7A5C48),
        fontFamilyFallback: _serif),
    navButtonStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: Color(0xFF7A5C48),
        fontFamilyFallback: _serif),
    navButtonIconColor: Color(0xFF7A5C48),
    muteIconColor: Color(0xFF7A5C48),
    tocHeadingStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: Color(0xFF4A3728),
        fontFamilyFallback: _serif),
    tocSearchStyle: TextStyle(
        fontSize: 14, color: Color(0xFF4A3728), fontFamilyFallback: _serif),
    tocSearchHintStyle: TextStyle(
        fontSize: 14, color: Color(0xFFA08975), fontFamilyFallback: _serif),
    tocSearchIconColor: Color(0xFFA08975),
    tocSearchFillColor: Color(0x1A7A5C48),
    tocSearchFocusBorderColor: Color(0x667A5C48),
    tocDividerColor: Color(0x337A5C48),
    tocItemNumberStyle: TextStyle(
        fontSize: 12, color: Color(0xFFA08975), fontFamilyFallback: _serif),
    tocItemTitleStyle: TextStyle(
        fontSize: 14, color: Color(0xFF4A3728), fontFamilyFallback: _serif),
    tocItemCurrentStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4A3728),
        fontFamilyFallback: _serif),
    tocItemCurrentIconColor: Color(0xFF7A5C48),
    tocSplashColor: Color(0x267A5C48),
    pageTitleStyle: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4A3728),
        height: 1.25,
        fontFamilyFallback: _serif),
    pageTaglineStyle: TextStyle(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        color: Color(0xFF7A5C48),
        height: 1.4,
        fontFamilyFallback: _serif),
  );

  /// Dark-mode reading: light ink on near-black paper, muted gold accents.
  /// Pair with [nightPaper].
  static const FlipBookTheme night = FlipBookTheme(
    closeIconColor: Color(0xFF9E9A8E),
    indexButtonStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: Color(0xFF9E9A8E)),
    navButtonStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: Color(0xFF9E9A8E)),
    navButtonIconColor: Color(0xFF9E9A8E),
    muteIconColor: Color(0xFF9E9A8E),
    tocHeadingStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: Color(0xFFE4E1D8)),
    tocSearchStyle: TextStyle(fontSize: 14, color: Color(0xFFE4E1D8)),
    tocSearchHintStyle: TextStyle(fontSize: 14, color: Color(0xFF6B6759)),
    tocSearchIconColor: Color(0xFF6B6759),
    tocSearchFillColor: Color(0x14FFFFFF),
    tocSearchFocusBorderColor: Color(0x4DFFFFFF),
    tocDividerColor: Color(0x26FFFFFF),
    tocItemNumberStyle: TextStyle(fontSize: 12, color: Color(0xFF6B6759)),
    tocItemTitleStyle: TextStyle(fontSize: 14, color: Color(0xFFE4E1D8)),
    tocItemCurrentStyle: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFC9A96A)),
    tocItemCurrentIconColor: Color(0xFFC9A96A),
    tocSplashColor: Color(0x1AFFFFFF),
    pageTitleStyle: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE4E1D8),
        height: 1.25),
    pageTaglineStyle:
        TextStyle(fontSize: 14, color: Color(0xFF9E9A8E), height: 1.4),
  );

  /// Editorial and punchy: heavy black titles, tight spacing, one red accent.
  /// Pair with [magazinePaper].
  static const FlipBookTheme magazine = FlipBookTheme(
    closeIconColor: Colors.black,
    indexButtonStyle: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: Colors.black),
    navButtonStyle: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: Colors.black),
    navButtonIconColor: Color(0xFFD32F2F),
    muteIconColor: Colors.black,
    tocHeadingStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
        color: Colors.black),
    tocSearchStyle: TextStyle(fontSize: 14, color: Colors.black),
    tocSearchHintStyle: TextStyle(fontSize: 14, color: Colors.black38),
    tocSearchIconColor: Colors.black38,
    tocSearchFillColor: Color(0x0D000000),
    tocSearchFocusBorderColor: Colors.black,
    tocDividerColor: Color(0x33000000),
    tocItemNumberStyle: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD32F2F)),
    tocItemTitleStyle: TextStyle(fontSize: 14, color: Colors.black87),
    tocItemCurrentStyle: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFD32F2F)),
    tocItemCurrentIconColor: Color(0xFFD32F2F),
    tocSplashColor: Color(0x14000000),
    pageTitleStyle: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: Colors.black,
        height: 1.15),
    pageTaglineStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: Color(0xFF757575),
        height: 1.4),
  );

  /// A children's storybook: big rounded titles, crayon-bright accents.
  /// Pair with [kidsPaper].
  static const FlipBookTheme kids = FlipBookTheme(
    closeIconColor: Color(0xFFFF7043),
    indexButtonStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: Color(0xFF29A0DA),
        fontFamilyFallback: _rounded),
    navButtonStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: Color(0xFF29A0DA),
        fontFamilyFallback: _rounded),
    navButtonIconColor: Color(0xFFFF7043),
    muteIconColor: Color(0xFF29A0DA),
    tocHeadingStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: Color(0xFF3A3A3A),
        fontFamilyFallback: _rounded),
    tocSearchStyle: TextStyle(fontSize: 15, color: Color(0xFF3A3A3A)),
    tocSearchHintStyle: TextStyle(fontSize: 15, color: Color(0xFF9E9E9E)),
    tocSearchIconColor: Color(0xFF29A0DA),
    tocSearchFillColor: Color(0x1A4FC3F7),
    tocSearchFocusBorderColor: Color(0xFF4FC3F7),
    tocDividerColor: Color(0x334FC3F7),
    tocItemNumberStyle: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFFB300)),
    tocItemTitleStyle: TextStyle(fontSize: 15, color: Color(0xFF3A3A3A)),
    tocItemCurrentStyle: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF29A0DA)),
    tocItemCurrentIconColor: Color(0xFFFFB300),
    tocSplashColor: Color(0x33FFC107),
    pageTitleStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Color(0xFF29A0DA),
        height: 1.2,
        fontFamilyFallback: _rounded),
    pageTaglineStyle: TextStyle(
        fontSize: 16,
        color: Color(0xFF5C5C5C),
        height: 1.4,
        fontFamilyFallback: _rounded),
  );

  /// The morning paper: black condensed serif headlines, gray rules,
  /// no colour anywhere. Pair with [newspaperPaper].
  static const FlipBookTheme newspaper = FlipBookTheme(
    closeIconColor: Color(0xFF1A1A1A),
    indexButtonStyle: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: Color(0xFF1A1A1A),
        fontFamilyFallback: _serif),
    navButtonStyle: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: Color(0xFF1A1A1A),
        fontFamilyFallback: _serif),
    navButtonIconColor: Color(0xFF555555),
    muteIconColor: Color(0xFF555555),
    tocHeadingStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: Color(0xFF1A1A1A),
        fontFamilyFallback: _serif),
    tocSearchStyle: TextStyle(
        fontSize: 14, color: Color(0xFF1A1A1A), fontFamilyFallback: _serif),
    tocSearchHintStyle: TextStyle(
        fontSize: 14, color: Color(0xFF999999), fontFamilyFallback: _serif),
    tocSearchIconColor: Color(0xFF777777),
    tocSearchFillColor: Color(0x0D000000),
    tocSearchFocusBorderColor: Color(0xFF1A1A1A),
    tocDividerColor: Color(0x66000000),
    tocItemNumberStyle: TextStyle(
        fontSize: 12, color: Color(0xFF777777), fontFamilyFallback: _serif),
    tocItemTitleStyle: TextStyle(
        fontSize: 14, color: Color(0xFF1A1A1A), fontFamilyFallback: _serif),
    tocItemCurrentStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
        fontFamilyFallback: _serif),
    tocItemCurrentIconColor: Color(0xFF1A1A1A),
    tocSplashColor: Color(0x14000000),
    pageTitleStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: Color(0xFF1A1A1A),
        height: 1.15,
        fontFamilyFallback: _serif),
    pageTaglineStyle: TextStyle(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: Color(0xFF555555),
        height: 1.4,
        fontFamilyFallback: _serif),
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
    );
  }
}
