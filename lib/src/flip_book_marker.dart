import 'package:flutter/widgets.dart';

import 'reader_mark.dart';

/// The reader's own marking: a pencil in the footer, a drag across the
/// words, then keep or discard.
///
/// Independent of read-aloud — a reader marks passages whether or not the
/// book can speak. Pass this object to switch marking on; leave it out and
/// no pencil appears and nothing about marking is configurable, because
/// nothing about it exists.
///
/// **The package stores nothing.** [onChanged] reports the new list and
/// [marks] takes it back on the next open, so a mark persists in whatever
/// store the app already uses — Hive, SharedPreferences, SQLite, a server.
/// A reading widget has no business choosing your database.
///
/// ```dart
/// FlipBook(
///   marker: FlipBookMarker(
///     marks: savedMarks,
///     onChanged: (marks) => store.save(marks),
///     color: Colors.amber.withValues(alpha: 0.35),
///   ),
///   ...
/// )
/// ```
///
/// Marking works on text the book lays out itself, and only on pages that
/// carry a `FlipBookPage.id` — a mark has to know what it belongs to.
@immutable
class FlipBookMarker {
  /// Switches reader marking on; every field has a default.
  const FlipBookMarker({
    this.marks = const [],
    this.onChanged,
    this.color = const Color(0x338A8A8A),
    this.pencil,
    this.clear,
    this.save,
    this.cancel,
    this.pencilLabel = 'Mark a passage',
    this.stopLabel = 'Stop marking',
    this.clearLabel = 'Clear all marks',
    this.saveLabel = 'SAVE',
    this.cancelLabel = 'CANCEL',
    this.actionStyle,
    this.iconColor,
    this.actionBarColor,
    this.actionBarOpacity = 0.35,
  });

  /// The reader's saved marks, drawn under the text. Load them from your
  /// own store and hand them in.
  final List<ReaderMark> marks;

  /// Fires with the complete new list when the reader saves a mark or
  /// clears them all. Persist it, pass it back through [marks].
  final ValueChanged<List<ReaderMark>>? onChanged;

  /// Background of the floating SAVE / CANCEL row.
  ///
  /// The row rests directly above the passage the reader just dragged out,
  /// so it always covers a line of the page. Null takes the footer's bar
  /// colour faded to [actionBarOpacity], which is what lets the text behind
  /// it stay readable. The words themselves keep full strength — fading
  /// those too gives text over text, and neither can be read.
  final Color? actionBarColor;

  /// How opaque the default action bar is, `0`..`1`. Ignored once
  /// [actionBarColor] is set: that colour is used exactly as given.
  final double actionBarOpacity;

  /// Colour of a marked passage. Deliberately its own field so a reader's
  /// marks never look like the read-aloud highlight.
  final Color color;

  /// Content of the pencil control. Null keeps the built-in icon; pass a
  /// `Text` for a word instead.
  final Widget? pencil;

  /// Content of the trash control.
  final Widget? clear;

  /// Content of the save control.
  final Widget? save;

  /// Content of the cancel control.
  final Widget? cancel;

  /// Word for the pencil while marking is off.
  final String pencilLabel;

  /// Word for the pencil while marking is on.
  final String stopLabel;

  /// Word for the trash control.
  final String clearLabel;

  /// Word for the save control.
  final String saveLabel;

  /// Word for the cancel control.
  final String cancelLabel;

  /// Text style of the save / cancel row; null uses the footer's.
  final TextStyle? actionStyle;

  /// Colour of the pencil and trash icons; null uses the footer's.
  final Color? iconColor;

  /// This object with some fields replaced.
  ///
  /// A null argument means "leave it alone", so a field that is already
  /// nullable cannot be cleared this way — construct a new one for that.
  FlipBookMarker copyWith({
    List<ReaderMark>? marks,
    ValueChanged<List<ReaderMark>>? onChanged,
    Color? actionBarColor,
    double? actionBarOpacity,
    Color? color,
    Widget? pencil,
    Widget? clear,
    Widget? save,
    Widget? cancel,
    String? pencilLabel,
    String? stopLabel,
    String? clearLabel,
    String? saveLabel,
    String? cancelLabel,
    TextStyle? actionStyle,
    Color? iconColor,
  }) {
    return FlipBookMarker(
      marks: marks ?? this.marks,
      onChanged: onChanged ?? this.onChanged,
      actionBarColor: actionBarColor ?? this.actionBarColor,
      actionBarOpacity: actionBarOpacity ?? this.actionBarOpacity,
      color: color ?? this.color,
      pencil: pencil ?? this.pencil,
      clear: clear ?? this.clear,
      save: save ?? this.save,
      cancel: cancel ?? this.cancel,
      pencilLabel: pencilLabel ?? this.pencilLabel,
      stopLabel: stopLabel ?? this.stopLabel,
      clearLabel: clearLabel ?? this.clearLabel,
      saveLabel: saveLabel ?? this.saveLabel,
      cancelLabel: cancelLabel ?? this.cancelLabel,
      actionStyle: actionStyle ?? this.actionStyle,
      iconColor: iconColor ?? this.iconColor,
    );
  }
}
