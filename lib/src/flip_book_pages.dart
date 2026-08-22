import 'package:flutter/material.dart';

import 'flip_book_page.dart';
import 'flip_book_page_style.dart';

/// The book's contents and everything about how a page is presented — the
/// list itself, the paper, the type, the reading direction, where the book
/// opens, and where it is.
///
/// One object so nothing about a page is scattered across the constructor.
///
/// ```dart
/// FlipBook(
///   pages: FlipBookPages(
///     items: const [FlipBookPage(title: 'One', bodySegments: ['Hello.'])],
///     paperColor: const Color(0xFFFBFAF6),
///     style: const FlipBookPageStyle(titleStyle: TextStyle(fontSize: 28)),
///     initialPage: prefs.getInt('lastPage') ?? 0,
///     onChanged: (i) => prefs.setInt('lastPage', i),
///   ),
///   onClose: () => Navigator.of(context).pop(),
/// )
/// ```
@immutable
class FlipBookPages {
  /// Only [items] is required; everything else defaults.
  const FlipBookPages({
    required this.items,
    this.paperColor = Colors.white,
    this.style = const FlipBookPageStyle(),
    this.textDirection,
    this.initialPage = 0,
    this.onChanged,
    this.showNumber = false,
  });

  /// The pages, in reading order.
  final List<FlipBookPage> items;

  /// Background of every page — the paper itself.
  ///
  /// Named for what it is: text colour lives in [style], so a bare `color`
  /// here would be a guess every time someone read it.
  final Color paperColor;

  /// How the book draws a page it lays out itself.
  final FlipBookPageStyle style;

  /// Forces the reading direction. `null` follows the ambient
  /// [Directionality]: left-to-right under English, Dutch and German,
  /// right-to-left automatically under any RTL locale — buttons mirror
  /// and pages flip the other way.
  final TextDirection? textDirection;

  /// The page the book opens at, clamped into range — restore a reader's
  /// place with `initialPage: prefs.getInt('lastPage') ?? 0`.
  final int initialPage;

  /// Fires whenever the shown page changes — a flip, a jump, a contents
  /// tap — with the new index. Persist it to restore via [initialPage].
  final ValueChanged<int>? onChanged;

  /// Shows a small "3 / 12" position indicator in the footer.
  final bool showNumber;
  /// This object with some fields replaced.
  ///
  /// A null argument means "leave it alone", so a field that is already
  /// nullable cannot be cleared this way — construct a new one for that.
  FlipBookPages copyWith({
    List<FlipBookPage>? items,
    Color? paperColor,
    FlipBookPageStyle? style,
    TextDirection? textDirection,
    int? initialPage,
    ValueChanged<int>? onChanged,
    bool? showNumber,
  }) {
    return FlipBookPages(
      items: items ?? this.items,
      paperColor: paperColor ?? this.paperColor,
      style: style ?? this.style,
      textDirection: textDirection ?? this.textDirection,
      initialPage: initialPage ?? this.initialPage,
      onChanged: onChanged ?? this.onChanged,
      showNumber: showNumber ?? this.showNumber,
    );
  }
}
