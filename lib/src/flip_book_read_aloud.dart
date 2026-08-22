import 'package:flutter/widgets.dart';

import 'flip_book_marker_style.dart';
import 'flip_book_read_speed.dart';

/// Gives the book a voice.
///
/// Pass this object and the play control appears; leave it out and the book
/// is silent, with no voice buttons, no highlight, and nothing about
/// reading to configure — because none of it exists.
///
/// The book reads **unit by unit**: it calls [onRead] once per unit and
/// waits for that future before moving on. Driving the cycle from
/// completions rather than engine timing events is what makes the highlight
/// behave identically on every platform, and what lets a slower voice slow
/// the highlight down for free.
///
/// ```dart
/// FlipBook(
///   readAloud: FlipBookReadAloud(
///     onRead: (unit) => tts.speak(unit),
///     onStop: tts.stop,
///     playAll: true,
///     highlight: FlipBookHighlight(style: FlipBookMarkerStyle.focus),
///   ),
///   ...
/// )
/// ```
@immutable
class FlipBookReadAloud {
  /// Switches read-aloud on; only [onRead] is required.
  const FlipBookReadAloud({
    required this.onRead,
    this.onStop,
    this.onPause,
    this.onResume,
    this.playAll = false,
    this.unitsPerMark = 1,
    this.readTitle = true,
    this.readTagline = true,
    this.readBody = true,
    this.fadeTitle = true,
    this.fadeTagline = true,
    this.fadeBody = true,
    this.highlight = const FlipBookHighlight(),
    this.speed,
    this.play,
    this.playAllControl,
    this.pause,
    this.resume,
    this.stop,
    this.playLabel = 'PLAY',
    this.playAllLabel = 'PLAY ALL',
    this.pauseLabel = 'PAUSE',
    this.resumeLabel = 'RESUME',
    this.stopLabel = 'STOP',
    this.readAloudSemantics = 'Read this page aloud',
    this.readAllSemantics = 'Read the whole book aloud',
    this.pauseSemantics = 'Pause reading',
    this.stopSemantics = 'Stop reading',
  });

  /// Speaks one unit. The future must complete when the engine finishes it;
  /// the book then highlights and speaks the next.
  final Future<void> Function(String unit) onRead;

  /// Kill the voice — stop tapped, a flip, or the app backgrounded.
  final VoidCallback? onStop;

  /// Pause the voice. The pause control appears only when both this and
  /// [onResume] are given.
  final VoidCallback? onPause;

  /// Continue a paused unit; the future completes when THAT unit ends.
  final Future<void> Function()? onResume;

  /// One play reads the whole book, flipping by itself.
  final bool playAll;

  /// Whether the printed title is read aloud.
  ///
  /// A part switched off here is skipped by the voice **and never dims** —
  /// it is not in the performance, so the highlight leaves it at full ink.
  final bool readTitle;

  /// Whether the tagline is read aloud. See [readTitle].
  final bool readTagline;

  /// Whether the body is read aloud. See [readTitle].
  final bool readBody;

  /// Whether the printed title recedes while another unit is speaking.
  ///
  /// Separate from [readTitle] so a heading can be **read but never fade**:
  /// a title is the page's anchor, and dimming it every time the body
  /// speaks makes the page flicker around the reader. Set `readTitle: true`
  /// with `fadeTitle: false` and the title is spoken in its turn, then
  /// stays at full ink for the rest of the page.
  ///
  /// A part dims only when it is BOTH read and faded, so
  /// `readTitle: false` leaves it at full ink whatever this says.
  final bool fadeTitle;

  /// Whether the tagline recedes while another unit speaks. See [fadeTitle].
  final bool fadeTagline;

  /// Whether the body recedes while another unit speaks. See [fadeTitle].
  final bool fadeBody;

  /// How many sentences the highlight covers at a time when the book splits
  /// the text itself. Ignored for `FlipBookPage.bodySegments`, where the
  /// author already decided the units.
  final int unitsPerMark;

  /// How the unit being spoken is shown on the page.
  final FlipBookHighlight highlight;

  /// The reader's own pace control; null hides it.
  final FlipBookSpeedControl? speed;

  /// Content of the play control. Null keeps the built-in icon; pass a
  /// `Text` for a word.
  final Widget? play;

  /// Content of the play-all control.
  final Widget? playAllControl;

  /// Content of the pause control.
  final Widget? pause;

  /// Content of the resume control.
  final Widget? resume;

  /// Content of the stop control.
  final Widget? stop;

  /// Word flashed above the footer when play is tapped.
  final String playLabel;

  /// Word flashed when play-all is tapped.
  final String playAllLabel;

  /// Word flashed when pause is tapped.
  final String pauseLabel;

  /// Word flashed when resume is tapped.
  final String resumeLabel;

  /// Word flashed when stop is tapped.
  final String stopLabel;

  /// What a screen reader announces for play and resume — an icon says
  /// nothing on its own.
  final String readAloudSemantics;

  /// What a screen reader announces for play-all.
  final String readAllSemantics;

  /// What a screen reader announces for pause.
  final String pauseSemantics;

  /// What a screen reader announces for stop.
  final String stopSemantics;

  /// This object with some fields replaced.
  ///
  /// A null argument means "leave it alone", so a field that is already
  /// nullable cannot be cleared this way — construct a new one for that.
  FlipBookReadAloud copyWith({
    Future<void> Function(String unit)? onRead,
    Future<void> Function()? onResume,
    VoidCallback? onStop,
    VoidCallback? onPause,
    bool? playAll,
    bool? readTitle,
    bool? readTagline,
    bool? readBody,
    bool? fadeTitle,
    bool? fadeTagline,
    bool? fadeBody,
    int? unitsPerMark,
    FlipBookHighlight? highlight,
    FlipBookSpeedControl? speed,
    Widget? play,
    Widget? playAllControl,
    Widget? pause,
    Widget? resume,
    Widget? stop,
    String? playLabel,
    String? playAllLabel,
    String? pauseLabel,
    String? resumeLabel,
    String? stopLabel,
    String? readAloudSemantics,
    String? readAllSemantics,
    String? pauseSemantics,
    String? stopSemantics,
  }) {
    return FlipBookReadAloud(
      onRead: onRead ?? this.onRead,
      onResume: onResume ?? this.onResume,
      onStop: onStop ?? this.onStop,
      onPause: onPause ?? this.onPause,
      playAll: playAll ?? this.playAll,
      readTitle: readTitle ?? this.readTitle,
      readTagline: readTagline ?? this.readTagline,
      readBody: readBody ?? this.readBody,
      fadeTitle: fadeTitle ?? this.fadeTitle,
      fadeTagline: fadeTagline ?? this.fadeTagline,
      fadeBody: fadeBody ?? this.fadeBody,
      unitsPerMark: unitsPerMark ?? this.unitsPerMark,
      highlight: highlight ?? this.highlight,
      speed: speed ?? this.speed,
      play: play ?? this.play,
      playAllControl: playAllControl ?? this.playAllControl,
      pause: pause ?? this.pause,
      resume: resume ?? this.resume,
      stop: stop ?? this.stop,
      playLabel: playLabel ?? this.playLabel,
      playAllLabel: playAllLabel ?? this.playAllLabel,
      pauseLabel: pauseLabel ?? this.pauseLabel,
      resumeLabel: resumeLabel ?? this.resumeLabel,
      stopLabel: stopLabel ?? this.stopLabel,
      readAloudSemantics: readAloudSemantics ?? this.readAloudSemantics,
      readAllSemantics: readAllSemantics ?? this.readAllSemantics,
      pauseSemantics: pauseSemantics ?? this.pauseSemantics,
      stopSemantics: stopSemantics ?? this.stopSemantics,
    );
  }
}

/// How the unit being read aloud is shown on the page.
@immutable
class FlipBookHighlight {
  /// Every field defaults; `const FlipBookHighlight()` is the standard look.
  const FlipBookHighlight({
    this.show = true,
    this.style = FlipBookMarkerStyle.focus,
    this.color = const Color(0x338A8A8A),
    this.radius = 6,
    this.dimOpacity = 0.35,
    this.builder,
  });

  /// Whether the spoken unit is marked at all.
  final bool show;

  /// A band behind the unit, or the rest of the page dimmed around it.
  final FlipBookMarkerStyle style;

  /// Colour of the band in `FlipBookMarkerStyle.highlight`.
  final Color color;

  /// Corner radius of that band.
  final double radius;

  /// In `FlipBookMarkerStyle.focus`: the opacity everything else fades to.
  final double dimOpacity;

  /// Draw the marked text yourself — see `ReadMarkerTextBuilder`. Whatever
  /// it returns replaces the built-in rendering entirely.
  final Object? builder;
}

/// The reader's pace control: `0.5x · 1x · 1.5x` in the footer.
///
/// The package makes no sound, so it reports the choice and the app applies
/// it to its engine. The highlight needs no adjustment — it moves on
/// completions, so it slows with the voice by itself.
@immutable
class FlipBookSpeedControl {
  /// Shows the control; [onChanged] is where the choice arrives.
  const FlipBookSpeedControl({
    this.options = FlipBookReadSpeed.values,
    this.initial = FlipBookReadSpeed.normal,
    this.onChanged,
    this.slowLabel = '0.5x',
    this.normalLabel = '1x',
    this.fastLabel = '1.5x',
    this.semantics = 'Reading speed',
    this.style,
    this.selectedStyle,
    this.selectedColor,
    this.tapSuffix = 'speed',
  });

  /// Which speeds the reader may choose, in the order they appear.
  ///
  /// A list rather than a switch per speed: the order is yours, an empty
  /// list hides the row, and a speed added to the enum later does not
  /// appear in anyone's book uninvited.
  final List<FlipBookReadSpeed> options;

  /// The speed the book starts at, and the one it shows as chosen.
  final FlipBookReadSpeed initial;

  /// Fires when the reader picks a different speed. Apply it to your engine
  /// — it takes effect on the next unit, because restarting a sentence
  /// mid-word to change pace sounds broken.
  final ValueChanged<FlipBookReadSpeed>? onChanged;

  /// Label of the half-speed option. Multipliers by default: a third of
  /// the width of words, and they need no translation.
  final String slowLabel;

  /// Label of the natural-rate option.
  final String normalLabel;

  /// Label of the faster option.
  final String fastLabel;

  /// What a screen reader calls the group.
  final String semantics;

  /// Style of an unselected speed label; null uses the footer's.
  final TextStyle? style;

  /// Style of the speed currently chosen. It also sits on a filled pill
  /// ([selectedColor]), because a bolder weight alone is hard to spot.
  final TextStyle? selectedStyle;

  /// Fill behind the chosen speed; null uses the footer's icon colour.
  final Color? selectedColor;

  /// Word flashed when a speed is tapped — `1.5x` becomes `1.5x speed`.
  final String tapSuffix;
}
