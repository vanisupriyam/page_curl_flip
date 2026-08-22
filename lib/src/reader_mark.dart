import 'package:flutter/widgets.dart';

/// One passage a reader marked by hand, with a pencil and a drag.
///
/// The package draws marks and hands the list back through
/// `FlipBookMarker.onChanged`; **storing them is the app's job.** That is
/// deliberate: a reading widget has no business choosing your database, and
/// bundling one would drag every user of this package into it. Persist with
/// Hive, SharedPreferences, SQLite, a server — whatever the app already
/// uses — and hand them back through `FlipBookMarker.marks` on the next
/// open.
///
/// A mark is addressed by [pageId], not by page number, so inserting a
/// chapter cannot drag it onto the wrong text. Pages without an `id` cannot
/// be marked at all.
@immutable
class ReaderMark {
  /// Creates a mark over one range of one text block.
  const ReaderMark({
    required this.pageId,
    required this.segment,
    required this.start,
    required this.end,
    this.text = '',
  });

  /// Rebuilds a mark from stored primitives — the shape [toMap] writes.
  factory ReaderMark.fromMap(Map<String, dynamic> map) => ReaderMark(
        pageId: map['pageId'] as String,
        segment: map['segment'] as int? ?? 0,
        start: map['start'] as int,
        end: map['end'] as int,
        text: map['text'] as String? ?? '',
      );

  /// The `FlipBookPage.id` this mark belongs to.
  final String pageId;

  /// Which body segment it sits in — the index in
  /// `FlipBookPage.bodySegments`. A mark on the printed title uses
  /// [titleSegment], the tagline [taglineSegment].
  final int segment;

  /// Segment value for a mark on the page's printed title.
  static const int titleSegment = -1;

  /// Segment value for a mark on the page's tagline.
  static const int taglineSegment = -2;

  /// First character of the marked range within that block.
  final int start;

  /// One past the last marked character.
  final int end;

  /// The marked words as they read when the mark was made.
  ///
  /// Not used for drawing — [start] and [end] place the mark. It is stored
  /// so an app can show a list of what a reader marked, and so a mark whose
  /// text no longer matches (an edited or re-translated page) can be
  /// detected rather than drawn over the wrong words.
  final String text;

  /// A copy with the given fields replaced.
  ReaderMark copyWith({
    String? pageId,
    int? segment,
    int? start,
    int? end,
    String? text,
  }) =>
      ReaderMark(
        pageId: pageId ?? this.pageId,
        segment: segment ?? this.segment,
        start: start ?? this.start,
        end: end ?? this.end,
        text: text ?? this.text,
      );

  /// Plain primitives, ready for any store — JSON, a Hive box, a column.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'pageId': pageId,
        'segment': segment,
        'start': start,
        'end': end,
        'text': text,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderMark &&
          other.pageId == pageId &&
          other.segment == segment &&
          other.start == start &&
          other.end == end;

  @override
  int get hashCode => Object.hash(pageId, segment, start, end);

  @override
  String toString() =>
      'ReaderMark($pageId seg:$segment $start-$end ${text.isEmpty ? '' : '"$text"'})';
}
