# page_curl_flip

A realistic cylindrical page-curl animation for Flutter. Pages peel away like
real paper — perspective, diffuse shadow, and a specular sheen included.

Import it, pass your pages, done. **Zero dependencies** — the package is a
skeleton you decorate: every colour, every label, and every icon is
customizable, and sound is a callback you plug anything into. Built-in page
layout and searchable table of contents. RTL-aware. Works on Android, iOS,
web, and desktop.

![page_curl_flip demo — LTR and RTL books, swipes, buttons, and read-aloud](https://raw.githubusercontent.com/vanisupriyam/page_curl_flip/main/doc/demo.gif)

## Three entry points

| Widget | Use it for |
|---|---|
| `FlipBook` | A complete multi-page book: navigation, searchable table of contents, flip sound with mute |
| `PageCurlRoute` | A `Navigator` transition that peels the previous screen away |
| `CurlOverlay` | The raw curl, driven by any `progress` value you control |

## FlipBook

Every page field is optional — leave one out and it simply does not appear.
One `title` does two jobs: it names the page in the table of contents AND
prints big at the top of the page.

```dart
FlipBook(
  onClose: () => Navigator.of(context).pop(),
  pages: const [
    FlipBookPage(
      title: 'A Tiny Book',        // in the INDEX and printed on the page
      tagline: 'a line under it',  // optional smaller line
      body: Text('Hello.'),        // body is ANY widget — text, image, layout
    ),
    FlipBookPage(
      title: 'Images too',
      body: Center(child: FlutterLogo(size: 160)),
    ),
    FlipBookPage(
      title: 'Full control',
      showTitleOnPage: false,       // title only in the INDEX…
      body: MyCompletelyCustomPage(), // …body fills the whole page
    ),
  ],
)
```

Pages with a `title` appear in the built-in table of contents (INDEX button),
which supports live search and direct jumps.

### Reading direction

Text direction in Flutter has exactly two values, and the book handles both:
left-to-right under English, Dutch, German and other LTR locales, and
right-to-left **automatically** under Arabic, Hebrew and other RTL locales —
buttons mirror and pages flip the opposite way. To force a direction
regardless of locale, set `textDirection: TextDirection.rtl` (or `.ltr`).

### Swipe

Swiping is on by default: a horizontal fling turns the page with the same
curl the buttons use, and the gesture mirrors under RTL.

When a page opens, a hint greets the reader right away: the hint text
between two runs of broad chevrons that fade toward the words — no
background, no container. It fades out after a moment, returns every
20 seconds for as long as the reader stays on the page, and retires forever
once the reader has turned 3 pages by swiping — in any mix of directions —
at which point the gesture is clearly learned. Everything is a switch or a
knob:

```dart
FlipBook(
  swipeToFlip: true,     // default — set false for buttons-only
  showNavButtons: true,  // set false for a gesture-only book
  showSwipeHint: true,   // default — set false to remove the hint
  swipeHintDelay: Duration(seconds: 20),   // how often it returns
  swipeHintDuration: Duration(seconds: 3), // how long it stays visible
  swipeHintMaxSwipes: 3,                   // swipes until "learned"
  onSwipeHintRetired: () => prefs.setBool('swipeLearned', true),
  ...
)
```

"Retires forever" means the life of the book: the package persists nothing,
so a reopened book greets again. To keep a learned reader from being
re-greeted, persist the `onSwipeHintRetired` signal (it fires exactly once,
at the moment of retirement) and pass
`showSwipeHint: !(prefs.getBool('swipeLearned') ?? false)` on the next open.

Hint text: `FlipBookStrings.swipeHint` · colour, size, font:
`FlipBookTheme.swipeHintStyle` · chevron size:
`FlipBookTheme.swipeHintArrowSize` — the chevron glyphs themselves come from
`FlipBookIcons.previous` / `next`.

### Speed

```dart
FlipBook(flipSpeed: FlipSpeed.slow, ...)                          // preset
FlipBook(flipSpeed: FlipSpeed.fast, ...)                          // preset
FlipBook(flipSpeed: const FlipSpeed.custom(Duration(seconds: 2))) // your own
```

### Sound

The package ships **no audio** and has no audio dependency — you provide the
flip sound through a callback, with any player or service you like:

```dart
FlipBook(onPageFlip: _mySound.play, ...) // your sound — a mute button appears
FlipBook(enableSound: false, ...)        // master off-switch, button hidden
FlipBook(showMuteButton: false, ...)     // sound on, speaker button hidden
```

No `onPageFlip` → silent book, no speaker button. The example wires
`audioplayers` with its own 1.15-second sample matched to the flip duration —
copy that pattern, or bring your own.

### Icons

Every icon is replaceable — the same skeleton idea as the labels:

```dart
FlipBook(
  icons: const FlipBookIcons(
    next: Icons.arrow_forward_ios,
    previous: Icons.arrow_back_ios_new,
    volumeOn: Icons.music_note,
  ),
  ...
)
```

Close, chevrons, speaker pair, search, bookmark — all overridable, plus a
shared `size` for the footer icons. Direction arrows are mirrored
automatically under RTL, whatever icon you chose. (The voice controls are
text buttons — see Read aloud — customized through `FlipBookVoiceChips`.)

### Read aloud

Give the book a voice with any speech engine or service — the package draws
a centred voice button and manages its states; you provide the reading:

```dart
FlipBook(
  onReadAloud: (page) => tts.speak(
    // What gets read is your choice — any combination of the three parts:
    pages[page].speechText(title: true, tagline: false, body: true),
  ),
  onReadAloudStop: tts.stop,     // stop tapped: kill the voice
  onReadAloudPause: tts.pause,   // optional — enables pause
  onReadAloudResume: tts.resume, // continue where it paused
)
```

Give each `FlipBookPage` a `bodyText` (the plain-text of its widget body) and
`speechText()` composes title, tagline, and body — each part switchable.

Idle shows a single ▶ play button. While reading it becomes ⏸ pause + ⏹ stop
(pause only when you provide the pause/resume pair); paused shows ▶ + ⏹, and
play continues from where it paused. Stop always resets to the beginning, and
flipping or jumping away stops the reading automatically.

The voice controls are **plain text buttons** — PLAY, PLAY ALL, PAUSE,
RESUME, STOP, styled like PREV/NEXT — because a word explains itself on
every platform where a tooltip cannot. Every label localizes through
`FlipBookStrings`, the style through `FlipBookTheme.voiceChipStyle`, and
any control's content can be replaced with any widget (an icon, an image…)
while the tap handling and screen-reader labels stay the package's:

```dart
FlipBook(
  voiceChips: const FlipBookVoiceChips(
    play: Icon(Icons.play_arrow, size: 16), // this chip becomes an icon
  ),
  ...
)
```

**Play the whole book** — opt in and a PLAY ALL chip appears beside PLAY:
it reads page after page like an audiobook, flipping by itself through the
same callbacks you already provide. PLAY still reads only the shown page —
the reader chooses per tap. STOP ends the chain, PAUSE holds it (RESUME
continues), and a manual flip, a jump, or the app going to background stops
everything:

```dart
FlipBook(readAloudAdvances: true, ...) // default false
```

Play-all reads **while the app is in the foreground** — leaving it stops
the voice and the chain (true background audio needs app-level platform
setup: the iOS `audio` background mode, an Android foreground service).
The example keeps the screen awake while the voice reads
(`wakelock_plus`), so a long listen does not die to the screen timeout.

**Player strip** — opt in and a thin progress bar (plus an optional timing
label) appears above the footer while reading. The package makes no sound,
so your app feeds both values; speech engines report no total duration, so
the label is free-form — the example shows elapsed time:

```dart
FlipBook(
  showReadAloudProgress: true,        // default false
  readAloudProgress: _progress,       // 0.0–1.0, from your engine's events
  readAloudProgressLabel: _elapsed,   // any text, e.g. "0:07" — null hides it
  ...
)
```

Style it with `FlipBookTheme.readAloudProgressColor`,
`readAloudProgressTrackColor`, and `readAloudProgressLabelStyle`; the bar
fills in reading direction (RTL-aware). See `example/lib/main.dart` for a
complete `flutter_tts` wiring — including resume-by-word-position (Android's
engine has no native pause), the progress/elapsed feed from word-boundary
events, and detecting a missing language voice.

### Immersive reading (auto-hiding chrome)

Open the book as a pure page — no buttons, just paper. A tap on the page
reveals the footer (INDEX, voice, PREV/NEXT…), which fades away again after
a few quiet seconds. On mouse platforms, hovering over the bottom reveals it
too. The × close button stays visible in every mode, so the reader always
has a way out:

```dart
FlipBook(
  chrome: FlipBookChrome.autoHide,        // default: FlipBookChrome.always
  chromeRevealFor: Duration(seconds: 3),  // how long a reveal lasts
  ...
)
```

Swiping keeps working while the chrome is hidden — gesture-only reading —
and the swipe hint still greets, since it lives on the page, not in the
chrome.

### Your own buttons, anywhere

Hide the built-in controls and drive the book yourself:

```dart
final controller = FlipBookController();

FlipBook(
  controller: controller,
  showControls: false, // no ×, no INDEX, no PREV/NEXT, no speaker
  pages: [...],
  onClose: () {},
);

// Any widget, any position:
FloatingActionButton(onPressed: controller.nextPage);
```

`controller` gives you `nextPage()`, `previousPage()`, `jumpToPage(i)`,
`openIndex()`, `closeIndex()`, `toggleMute()`, and the current `page`.
To keep the built-in layout but hide only the speaker, use
`showMuteButton: false`.

### Styling and localization

Every colour and text style comes from `FlipBookTheme`; every built-in label
from `FlipBookStrings`. Both have complete defaults, so you only override what
you need:

```dart
FlipBook(
  theme: const FlipBookTheme().copyWith(closeIconColor: Colors.teal),
  strings: const FlipBookStrings(
    index: 'INHALT',
    previous: 'ZURÜCK',
    next: 'WEITER',
  ),
  ...
)
```

## PageCurlRoute

```dart
Navigator.of(context).push(
  PageCurlRoute(
    coverChild: const CoverPage(), // shown, captured, then peeled away
    builder: (_) => const DetailScreen(),
  ),
);
```

All four durations (route forward/reverse, curl forward/reverse) are
constructor parameters.

## CurlOverlay

Drive the curl yourself — from an `AnimationController`, a slider, or a drag:

```dart
CurlOverlay(
  progress: controller.value, // 0.0 flat → 0.5 max curl → 1.0 gone
  child: MyPageContent(),     // captured automatically
)
```

Or capture the page bitmap yourself and pass it as `pageImage` for exact
control over what bends.

## Known limitations (v0.1)

Honest list — these are design decisions or open items, not surprises:

- **Swipes fling, they don't drag.** A horizontal fling plays the full curl
  animation; the page does not follow your finger mid-drag. Interactive
  drag-to-curl may come later if there is demand.
- **`PageCurlRoute` always peels left-to-right**, regardless of locale —
  unlike `FlipBook`, which fully mirrors under RTL.
- **Pages do not scroll.** The built-in title/tagline layout is a fixed
  column; if your content can exceed one page height, give the `body` its own
  `SingleChildScrollView` — the body owns scrolling.
- **Flips show a snapshot.** Each flip captures the page as a bitmap, so an
  animating body (GIF, video) appears frozen during the curl and resumes
  after it.
- **Mute and reading state are not persisted** across widget rebuilds that
  recreate the book.

## Testing note

**Golden baselines are macOS-rendered.** CI runs on `macos-latest` so the
same rasterizer produces and checks them. If you regenerate goldens
(`flutter test --update-goldens test/goldens_test.dart`), do it on macOS —
baselines rendered on Linux or Windows will fail CI.

The package has **zero dependencies** and makes no sound of its own — flip
sound and speech run through your callbacks. In widget tests either pass
`enableSound: false` or provide a no-op `onPageFlip`; the callbacks are
fire-and-forget by design, so an audio failure in your app can never break
the animation.

## How it works

On each flip the current page is captured as a bitmap at the device's pixel
ratio (capped at 2× — a moving curl cannot show more detail, and the cap
halves the bitmap memory), then drawn as 28 vertical slices projected onto a cylinder whose radius
shrinks and grows with `progress`. Slices are depth-sorted, shaded by their
angle to the light, and given a moving specular glint — which is what makes
the paper read as physically curling rather than just rotating.

## License

MIT
