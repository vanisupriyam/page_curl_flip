import 'package:flutter/widgets.dart';

/// Turning pages by hand, and the hint that teaches it.
@immutable
class FlipBookSwipe {
  /// Every field defaults; `const FlipBookSwipe()` is swipe-on with a hint.
  const FlipBookSwipe({
    this.enabled = true,
    this.hint = const FlipBookSwipeHint(),
  });

  /// Whether a horizontal fling turns the page.
  ///
  /// The gesture mirrors under RTL, so a swipe always moves the page the
  /// way that script reads. Switching it off also removes the [hint] —
  /// teaching a gesture that does nothing would be a lie.
  final bool enabled;

  /// The transient hint; `null` removes it.
  final FlipBookSwipeHint? hint;
  /// This object with some fields replaced.
  ///
  /// A null argument means "leave it alone", so a field that is already
  /// nullable cannot be cleared this way — construct a new one for that.
  FlipBookSwipe copyWith({
    bool? enabled,
    FlipBookSwipeHint? hint,
  }) {
    return FlipBookSwipe(
      enabled: enabled ?? this.enabled,
      hint: hint ?? this.hint,
    );
  }
}

/// The line that greets a page: text between two runs of fading chevrons,
/// no background, no container.
///
/// It greets a page, fades, and **does not come back to that page**.
/// After [maxShows] appearances it retires for the life of the book. An
/// earlier version returned every 20 seconds while the reader stayed —
/// that nags someone who is trying to read.
@immutable
class FlipBookSwipeHint {
  /// Every field defaults; `const FlipBookSwipeHint()` is the standard hint.
  const FlipBookSwipeHint({
    this.showFor = const Duration(seconds: 3),
    this.maxShows = 3,
    this.onRetired,
    this.child,
    this.text = 'Swipe to turn the page',
    this.style,
    this.arrowSize = 26,
  });

  /// How long it stays visible each time.
  final Duration showFor;

  /// How many appearances before it retires for good.
  final int maxShows;

  /// Fires once, when the last appearance ends. The package persists
  /// nothing between opens — save this and pass `hint: null` next time so a
  /// reader who already learned the gesture is not greeted again.
  final VoidCallback? onRetired;

  /// Replaces the whole hint with any widget — an animated GIF of the
  /// gesture, an illustration. It is decoration and never receives taps, so
  /// give it a real size; the package wraps it in a [Semantics] label from
  /// [text] so an image still announces itself.
  final Widget? child;

  /// The hint wording, and what a screen reader announces for [child].
  final String text;

  /// Colour, size and font of the wording. The chevrons take their colour
  /// from it too.
  final TextStyle? style;

  /// Size of the fading chevrons beside the wording.
  final double arrowSize;
}
