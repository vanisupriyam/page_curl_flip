# Changelog

## 0.1.0

Initial release.

- `FlipBook` — multi-page book widget with cylindrical page-curl
  transitions, searchable table of contents, and full RTL support. Zero
  dependencies: the flip sound is a callback (`onPageFlip`) you wire to any
  audio player — the example shows an `audioplayers` setup.
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
  `copyWith`; `FlipBookIcons` — every icon the book draws is replaceable.
  The package is a skeleton: decoration belongs to the app.
- Read-aloud: a centred ▶ play control that reads the shown page through any
  speech engine (`onReadAloud`), with ⏸ pause / resume (`onReadAloudPause` /
  `onReadAloudResume`) and ⏹ stop (`onReadAloudStop`); reading stops
  automatically on navigation. The controls are text chips (PLAY, PLAY
  ALL, PAUSE, RESUME, STOP — localizable via `FlipBookStrings`, styled via
  `FlipBookTheme.voiceChip*`); any chip's content is replaceable with any
  widget through `FlipBookVoiceChips`. Every page paints edge to edge
  behind the floating chrome (structured pages clear it via the default
  `pagePadding`). Opt-in extras, all default off:
  `readAloudAdvances` (a PLAY ALL chip beside PLAY reads the whole book —
  the package flips and chains through the same callbacks; stop, pause,
  manual flips, and the app leaving the foreground all stop it; plain ▶
  stays page-only) and a player strip — `showReadAloudProgress` + app-fed
  `readAloudProgress` 0..1 and free-form `readAloudProgressLabel` (engines
  report no duration; the example feeds elapsed time), themable via
  `FlipBookTheme.readAloudProgress*`.
- Immersive reading: `chrome: FlipBookChrome.autoHide` opens the book as a
  pure page — a tap reveals the footer, which fades away after
  `chromeRevealFor` (bottom-edge hover reveals it on mouse platforms); the
  × close button stays visible in every mode. Default is
  `FlipBookChrome.always`, today's behaviour.
- `FlipBookStrings` — every built-in label and semantic label overridable for
  localization.
- `FlipBookController` + `showControls: false` — hide every built-in button
  and drive the book with your own UI (`nextPage`, `previousPage`,
  `jumpToPage`, `openIndex`, `closeIndex`, `toggleMute`); `showMuteButton:
  false` hides just the speaker while the sound stays on.
- Paper-aware lighting: the curl's sheen scales with the page colour, so
  dark themes flip without glare; `shine` and `shadow` (0–1) expose both
  layers on `FlipBook`, `CurlOverlay`, and `PageCurlRoute`.
- `FlipBookPage.speechText()` reads what the page shows: titles hidden via
  `showTitleOnPage: false` are skipped unless explicitly requested.
- Swipe to flip: a horizontal fling turns the page (mirrored under RTL).
  `swipeToFlip` (on by default) and `showNavButtons` (hide PREV/NEXT for a
  gesture-only book).
- Swipe hint (on by default): a background-free line — the text between
  broad chevrons fading toward the words — greets every page the moment it
  opens, stays for `swipeHintDuration` (3 s), returns every
  `swipeHintDelay` (20 s) while the reader stays on the page, and retires
  after `swipeHintMaxSwipes` (3) page-turning swipes in any mix of
  directions — the gesture counts as learned; flings at the edge of the
  book turn nothing and count nothing.
  Customizable via `showSwipeHint`,
  `FlipBookStrings.swipeHint`, `FlipBookTheme.swipeHintStyle`, and
  `FlipBookTheme.swipeHintArrowSize`. The package persists nothing between
  opens — `onSwipeHintRetired` fires exactly once when the gesture counts
  as learned, so the app can remember and pass `showSwipeHint: false` next
  time.
- `initialPage`, `onPageChanged` (also fired when a shrinking page list
  clamps the current page), and an opt-in `showPageNumber` "3 / 12"
  indicator styled by `FlipBookTheme.pageNumberStyle`.
