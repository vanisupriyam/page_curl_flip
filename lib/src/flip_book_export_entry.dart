import 'package:flutter/foundation.dart';

/// One page in an export, flattened to plain values.
///
/// Deliberately dumb: numbers and strings only, no widgets and no Flutter
/// types beyond `@immutable`. That is what lets an app hand it straight to
/// a PDF writer, a share sheet, a text file, or an isolate — a widget could
/// not cross any of those boundaries.
///
/// The book fills these in the order the reader would meet them.
@immutable
class FlipBookExportEntry {
  /// Creates an entry; the book builds these for you.
  const FlipBookExportEntry({
    required this.number,
    this.id,
    this.title,
    this.tagline,
    this.body = const [],
    this.marks = const [],
  });

  /// The page's **1-based** number, the one printed in the footer — so a
  /// reader can find it again by flipping.
  final int number;

  /// The page's `FlipBookPage.id`, when it has one.
  final String? id;

  /// The page's title, when it has one.
  final String? title;

  /// The line under the title, when it has one.
  final String? tagline;

  /// The page's full text, one entry per reading unit. Empty for a
  /// marked-text export, which carries only [marks].
  final List<String> body;

  /// The passages the reader marked on this page, in reading order. Empty
  /// unless the page carries marks.
  final List<String> marks;

  /// The entry as plain maps and strings — ready for an isolate, a file, or
  /// a database.
  Map<String, dynamic> toMap() => {
        'number': number,
        if (id != null) 'id': id,
        if (title != null) 'title': title,
        if (tagline != null) 'tagline': tagline,
        if (body.isNotEmpty) 'body': body,
        if (marks.isNotEmpty) 'marks': marks,
      };

  @override
  String toString() => 'FlipBookExportEntry($number, ${title ?? '-'}, '
      '${body.length} units, ${marks.length} marks)';
}
