import 'package:flutter/material.dart';

import 'flip_book_export.dart';

/// The table of contents: the page the INDEX button opens, its search
/// field, and its rows.
///
/// It builds itself from the pages that carry a `title`; a page without one
/// simply is not listed.
@immutable
class FlipBookContents {
  /// Every field defaults; `const FlipBookContents()` is the standard list.
  const FlipBookContents({
    this.export,
    this.heading = 'TABLE OF CONTENTS',
    this.searchHint = 'Search by title',
    this.headingStyle = _heading,
    this.searchStyle = _body,
    this.searchHintStyle = _bodyFaint,
    this.searchIcon = Icons.search,
    this.searchIconColor = Colors.black38,
    this.searchFill = const Color(0x0A000000),
    this.searchFocusBorder = Colors.black26,
    this.dividerColor = const Color(0x14000000),
    this.numberStyle = _number,
    this.titleStyle = _body,
    this.currentStyle = _current,
    this.currentIcon = Icons.bookmark,
    this.currentIconColor = Colors.black87,
    this.splashColor = const Color(0x14000000),
  });

  static const TextStyle _heading = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: Colors.black87,
  );
  static const TextStyle _body = TextStyle(fontSize: 14, color: Colors.black87);
  static const TextStyle _bodyFaint =
      TextStyle(fontSize: 14, color: Colors.black38);
  static const TextStyle _number =
      TextStyle(fontSize: 12, color: Colors.black38);
  static const TextStyle _current = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  /// Lets the reader take part of the book away — an Export button in the
  /// table of contents, and a chooser behind it. Null means no button.
  ///
  /// The contents page is the right home for it: it is the one screen that
  /// already shows the whole book at once, so "which pages" is a question
  /// the reader is already answering there.
  final FlipBookExport? export;

  /// Heading above the list.
  final String heading;

  /// Placeholder in the search field.
  final String searchHint;

  /// Style of the heading.
  final TextStyle headingStyle;

  /// Style of text typed into the search field.
  final TextStyle searchStyle;

  /// Style of the placeholder.
  final TextStyle searchHintStyle;

  /// Prefix glyph of the search field.
  final IconData searchIcon;

  /// Colour of that glyph.
  final Color searchIconColor;

  /// Background fill of the search field.
  final Color searchFill;

  /// Border colour while the field is focused.
  final Color searchFocusBorder;

  /// Colour of the rules between rows.
  final Color dividerColor;

  /// Style of the page-number column.
  final TextStyle numberStyle;

  /// Style of a row's title.
  final TextStyle titleStyle;

  /// Style of the row matching the page being read.
  final TextStyle currentStyle;

  /// Glyph marking that row.
  final IconData currentIcon;

  /// Colour of that glyph.
  final Color currentIconColor;

  /// Ripple colour when a row is tapped.
  final Color splashColor;
}
