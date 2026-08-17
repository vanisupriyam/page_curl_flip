import 'package:flutter/foundation.dart';

/// Every built-in label used by `FlipBook`, overridable for localization.
///
/// All fields default to English. Visible labels ([index], [previous], [next],
/// [tableOfContents], [searchHint]) are rendered on screen; the semantic
/// labels ([close], [mute], [unmute]) are announced by screen readers only.
///
/// ```dart
/// FlipBook(
///   strings: const FlipBookStrings(
///     index: 'INHALT',
///     previous: 'ZURÜCK',
///     next: 'WEITER',
///   ),
///   ...
/// )
/// ```
@immutable
class FlipBookStrings {
  /// Creates a set of labels; every field defaults to English.
  const FlipBookStrings({
    this.index = 'INDEX',
    this.previous = 'PREV',
    this.next = 'NEXT',
    this.tableOfContents = 'TABLE OF CONTENTS',
    this.searchHint = 'Search by title',
    this.close = 'Close',
    this.mute = 'Mute flip sound',
    this.unmute = 'Unmute flip sound',
    this.readAloud = 'Read this page aloud',
    this.readAllAloud = 'Read the whole book aloud',
    this.pauseReading = 'Pause reading',
    this.stopReading = 'Stop reading',
    this.play = 'PLAY',
    this.playAll = 'PLAY ALL',
    this.pause = 'PAUSE',
    this.resume = 'RESUME',
    this.stop = 'STOP',
    this.swipeHint = 'Swipe to turn the page',
  });

  /// Footer button that opens the table of contents.
  final String index;

  /// Footer button that flips to the previous page.
  final String previous;

  /// Footer button that flips to the next page.
  final String next;

  /// Heading of the table-of-contents page.
  final String tableOfContents;

  /// Placeholder of the table-of-contents search field.
  final String searchHint;

  /// Semantic label of the × close button.
  final String close;

  /// Semantic label of the volume button while sound is on.
  final String mute;

  /// Semantic label of the volume button while sound is off.
  final String unmute;

  /// Semantic label of the read-aloud button (see `FlipBook.onReadAloud`).
  final String readAloud;

  /// Semantic label of the play-all button (`FlipBook.readAloudAdvances`).
  final String readAllAloud;

  /// Semantic label of the pause button while reading is in progress.
  final String pauseReading;

  /// Semantic label of the stop button while reading or paused.
  final String stopReading;

  /// Visible label of the play chip (reads the shown page).
  final String play;

  /// Visible label of the play-all chip (`FlipBook.readAloudAdvances`).
  final String playAll;

  /// Visible label of the pause chip while reading.
  final String pause;

  /// Visible label of the resume chip while paused.
  final String resume;

  /// Visible label of the stop chip while reading or paused.
  final String stop;

  /// Text of the transient swipe hint shown when the book opens.
  final String swipeHint;

  @override
  bool operator ==(Object other) =>
      other is FlipBookStrings &&
      other.index == index &&
      other.previous == previous &&
      other.next == next &&
      other.tableOfContents == tableOfContents &&
      other.searchHint == searchHint &&
      other.close == close &&
      other.mute == mute &&
      other.unmute == unmute &&
      other.readAloud == readAloud &&
      other.readAllAloud == readAllAloud &&
      other.pauseReading == pauseReading &&
      other.stopReading == stopReading &&
      other.play == play &&
      other.playAll == playAll &&
      other.pause == pause &&
      other.resume == resume &&
      other.stop == stop &&
      other.swipeHint == swipeHint;

  @override
  int get hashCode => Object.hash(
      index,
      previous,
      next,
      tableOfContents,
      searchHint,
      close,
      mute,
      unmute,
      readAloud,
      readAllAloud,
      pauseReading,
      stopReading,
      play,
      playAll,
      pause,
      resume,
      stop,
      swipeHint);
}
