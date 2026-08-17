import 'package:flutter/widgets.dart';

/// Optional custom content for the five voice chips (play, play-all,
/// pause, resume, stop).
///
/// By default every chip shows its text label from `FlipBookStrings`
/// (PLAY, PLAY ALL, …) — words explain themselves on every platform,
/// tooltips do not. Provide any widget here to replace a chip's content
/// while keeping the chip's rounded container, tap handling, and screen
/// reader label:
///
/// ```dart
/// FlipBook(
///   voiceChips: const FlipBookVoiceChips(
///     play: Icon(Icons.play_arrow, size: 16),
///     stop: Icon(Icons.stop, size: 16),
///   ),
///   ...
/// )
/// ```
@immutable
class FlipBookVoiceChips {
  /// Creates the chip content set; null fields fall back to text labels.
  const FlipBookVoiceChips({
    this.play,
    this.playAll,
    this.pause,
    this.resume,
    this.stop,
  });

  /// Content of the play chip (reads the shown page).
  final Widget? play;

  /// Content of the play-all chip (`FlipBook.readAloudAdvances`).
  final Widget? playAll;

  /// Content of the pause chip while reading.
  final Widget? pause;

  /// Content of the resume chip while paused.
  final Widget? resume;

  /// Content of the stop chip while reading or paused.
  final Widget? stop;
}
