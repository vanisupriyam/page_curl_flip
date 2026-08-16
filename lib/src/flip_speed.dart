import 'package:flutter/foundation.dart';

/// The speed of a `FlipBook` page-flip animation.
///
/// Use a preset, or any duration you like:
///
/// ```dart
/// FlipBook(flipSpeed: FlipSpeed.fast, ...)
/// FlipBook(flipSpeed: const FlipSpeed.custom(Duration(seconds: 2)), ...)
/// ```
@immutable
class FlipSpeed {
  /// A flip that takes exactly [duration].
  const FlipSpeed.custom(this.duration);

  /// A slow, deliberate flip (1600 ms).
  static const FlipSpeed slow = FlipSpeed.custom(Duration(milliseconds: 1600));

  /// The default flip (1200 ms).
  static const FlipSpeed medium =
      FlipSpeed.custom(Duration(milliseconds: 1200));

  /// A quick flip (750 ms).
  static const FlipSpeed fast = FlipSpeed.custom(Duration(milliseconds: 750));

  /// How long one page flip takes.
  final Duration duration;

  @override
  bool operator ==(Object other) =>
      other is FlipSpeed && other.duration == duration;

  @override
  int get hashCode => duration.hashCode;
}
