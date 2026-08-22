/// How fast the reader wants to be read to.
///
/// The package makes no sound, so it cannot change a speaking rate — it
/// owns the control, the state, and the label, and hands the choice to the
/// app through `FlipBook.onReadSpeedChanged`. The app applies it to its own
/// engine (`flutter_tts`'s `setSpeechRate`, for instance).
///
/// The read marker needs no adjustment: it moves when a unit finishes
/// speaking, so a slower voice simply holds each mark longer, exactly in
/// step, with nothing to configure.
enum FlipBookReadSpeed {
  /// Half speed — for a language being learned, or a reader who wants time
  /// to follow the words. Labelled `0.5x`.
  slow,

  /// The engine's own natural rate. Labelled `1x`.
  normal,

  /// Half again as fast, for a reader who already knows the text.
  /// Labelled `1.5x`.
  fast;

  /// A rate multiplier against [normal], for engines that take one.
  ///
  /// `flutter_tts` wants an absolute rate rather than a multiplier, and its
  /// scale differs per platform, so the example multiplies its own base
  /// rate by this. Nothing in the package uses the number itself.
  double get rateFactor => switch (this) {
        FlipBookReadSpeed.slow => 0.5,
        FlipBookReadSpeed.normal => 1.0,
        FlipBookReadSpeed.fast => 1.5,
      };
}
