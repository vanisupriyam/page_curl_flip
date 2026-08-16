# Changelog

## 0.1.0

Initial release.

- `FlipBook` — multi-page book widget with cylindrical page-curl transitions,
  searchable table of contents, built-in flip sound with mute toggle
  (`enableSound: false` for a silent book), and full RTL support.
- `FlipBookPage` — every field optional: `title` (named in the table of
  contents and printed on the page — `showTitleOnPage: false` keeps it off
  the page), `tagline`, and `body` (any widget).
- Automatic right-to-left support under RTL locales, plus a `textDirection`
  override on `FlipBook`.
- `FlipSpeed` — `slow` / `medium` / `fast` presets or
  `FlipSpeed.custom(Duration)`.
- `CurlOverlay` — the raw curl animation driven by a single `progress` value;
  works with a pre-captured bitmap or auto-captures a child widget.
- `PageCurlRoute` — a `PageRoute` that peels the previous screen away like a
  page, with an optional cover widget and configurable durations.
- `FlipBookTheme` — fully optional styling with sensible defaults and
  `copyWith`, plus six preset looks with matching paper colours: `classic`,
  `oldBook`, `night`, `magazine`, `kids`, `newspaper`.
- Read-aloud: a centred ▶ play control that reads the shown page through any
  speech engine (`onReadAloud`), with ⏸ pause / resume (`onReadAloudPause` /
  `onReadAloudResume`) and ⏹ stop (`onReadAloudStop`); reading stops
  automatically on navigation.
- `FlipBookStrings` — every built-in label and semantic label overridable for
  localization.
- `FlipBookController` + `showControls: false` — hide every built-in button
  and drive the book with your own UI (`nextPage`, `previousPage`,
  `jumpToPage`, `openIndex`, `closeIndex`, `toggleMute`); `showMuteButton:
  false` hides just the speaker while the sound stays on.
- Paper-aware lighting: the curl's sheen scales with the page colour, so
  dark themes flip without glare; `shine` and `shadow` (0–1) expose both
  layers on `FlipBook`, `CurlOverlay`, and `PageCurlRoute`.
- Single dependency: `audioplayers`, for the built-in flip sound.
