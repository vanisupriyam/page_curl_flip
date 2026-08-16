# page_curl_flip

A realistic cylindrical page-curl animation for Flutter. Pages peel away like
real paper — perspective, diffuse shadow, and a specular sheen included.

Import it, pass your pages, done. Built-in page-flip sound, built-in page
layout, built-in table of contents. RTL-aware. Works on Android, iOS, web,
and desktop.

<!-- TODO before publishing: demo GIF here -->

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

### Speed

```dart
FlipBook(flipSpeed: FlipSpeed.slow, ...)                          // preset
FlipBook(flipSpeed: FlipSpeed.fast, ...)                          // preset
FlipBook(flipSpeed: const FlipSpeed.custom(Duration(seconds: 2))) // your own
```

### Sound

A page-flip sound ships with the package and plays on every flip, with a mute
button in the footer. One switch controls everything:

```dart
FlipBook(enableSound: false, ...)       // silent book, no mute button at all
FlipBook(showMuteButton: false, ...)    // sound on, speaker button hidden
FlipBook(onPageFlip: _playMySound, ...) // your own flip sound instead
```

### Read aloud

Give the book a voice with any speech engine or service — the package draws
a centred voice button and manages its states; you provide the reading:

```dart
FlipBook(
  onReadAloud: (page) => tts.speak(texts[page]), // future ends = done reading
  onReadAloudStop: tts.stop,                     // stop tapped: kill the voice
  onReadAloudPause: tts.pause,                   // optional — enables pause
  onReadAloudResume: tts.resume,                 // continue where it paused
)
```

Idle shows a single ▶ play button. While reading it becomes ⏸ pause + ⏹ stop
(pause only when you provide the pause/resume pair); paused shows ▶ + ⏹, and
play continues from where it paused. Stop always resets to the beginning, and
flipping or jumping away stops the reading automatically. See
`example/lib/main.dart` for a complete `flutter_tts` wiring — including
resume-by-word-position (Android's engine has no native pause) and detecting
a missing language voice.

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

### Preset themes

Six ready-made looks, each with a matching paper colour — pick one and adjust
anything with `copyWith`:

```dart
FlipBook(
  theme: FlipBookTheme.oldBook,          // classic · oldBook · night ·
  pageColor: FlipBookTheme.oldBookPaper, // magazine · kids · newspaper
  pages: [...],
)
```

| Preset | Look |
|---|---|
| `classic` | white paper, neutral ink — the default |
| `oldBook` | sepia serif, italic taglines |
| `night` | light ink on near-black, gold bookmark |
| `magazine` | heavy black titles, one red accent |
| `kids` | crayon-bright, big rounded titles |
| `newspaper` | black serif on newsprint, no colour |

### The light on the paper

The curl carries a sheen and a depth shadow. By default the sheen adapts to
the paper: full on white, only a whisper on dark colours — so dark themes
never get a glaring light sweep. Both are also directly yours:

```dart
FlipBook(shine: 0, ...)            // no light at all
FlipBook(shine: 0.2, shadow: 0.4)  // your own mix, 0–1
```

(The same knobs exist on `CurlOverlay` and `PageCurlRoute`.)

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

## Testing note

The built-in sound uses the `audioplayers` plugin — the package's only
dependency. Plugins have no implementation inside `flutter test`, so widget
tests that flip pages should pass `enableSound: false` (or provide their own
`onPageFlip`). Sound failures at runtime are swallowed by design: audio can
never break the animation.

## How it works

On each flip the current page is captured as a bitmap at the device's pixel
ratio, then drawn as 28 vertical slices projected onto a cylinder whose radius
shrinks and grows with `progress`. Slices are depth-sorted, shaded by their
angle to the light, and given a moving specular glint — which is what makes
the paper read as physically curling rather than just rotating.

## License

MIT
