import 'package:flutter/widgets.dart';

import 'flip_book_page_style.dart';

/// A single page in a `FlipBook`.
///
/// One [title] does two jobs: it is the page's entry in the table of
/// contents AND the big text printed at the top of the page. Every field is
/// optional — leave one out and that element simply does not appear:
///
/// ```dart
/// FlipBookPage(
///   title: 'Chapter 1',              // in the INDEX and on the page
///   tagline: 'where it all started', // smaller line under the title
///   body: Text('Once upon a time…'), // any widget: text, image, layout
/// )
/// ```
///
/// A page that draws its own layout can turn the printed title off with
/// [showTitleOnPage] — the title then appears only in the table of contents,
/// and [body] fills the page edge-to-edge.
///
/// # ⚠️ Read-aloud pages: format the text yourself
///
/// A page read aloud is read in UNITS — each unit is marked on screen and
/// spoken in one call. Give them explicitly with [bodySegments]:
///
/// ```dart
/// FlipBookPage(
///   id: 'chapter-1',
///   title: 'Chapter 1',
///   bodySegments: [
///     'I spent \$23.54 on SendGrid for 5 emails.',
///     'Dr. Smith called it a bargain.',
///   ],
/// )
/// ```
///
/// Passing one [bodyText] string instead makes the book split on full
/// stops, and that guess is wrong sooner or later in every language —
/// `Dr. Smith` and `1. First` break, and no rule set fixes all of them.
/// **The text is yours; splitting it well is your job.** See
/// [bodySegments].
@immutable
class FlipBookPage {
  /// Creates a page; every field is optional.
  const FlipBookPage({
    this.id,
    this.title,
    this.tagline,
    this.body,
    this.bodyText,
    this.bodySegments,
    this.bodyWidgets = const {},
    this.background,
    this.style,
    this.showTitleOnPage = true,
  });

  /// Stable identity for this page, used to store reader marks against it.
  ///
  /// Marks are saved per page, and page NUMBERS move: insert a chapter and
  /// every later page shifts, which would drag every saved mark onto the
  /// wrong text. An id that belongs to the content — `'journal-42'`, a
  /// database key, a slug — survives reordering. Pages without one still
  /// render; they simply cannot carry saved marks.
  final String? id;

  /// The page's name in the table of contents and, while [showTitleOnPage]
  /// is `true`, the big text at the top of the page. `null` hides the page
  /// from the table of contents.
  final String? title;

  /// Smaller line under the title; `null` shows no tagline.
  final String? tagline;

  /// The page body as ANY widget — an image, a video player, a layout of
  /// your own. It fills the paper edge-to-edge when the page prints no
  /// title or tagline, so a full-bleed cover is just `body:`.
  ///
  /// A widget body is your painting, so the book cannot mark sentences
  /// inside it: the read marker, the fading, and auto-scroll need text the
  /// book laid out itself ([bodySegments]). Give a widget body a
  /// [bodyText] if you still want it read aloud as one piece.
  final Widget? body;

  /// The page's text as ONE string. Two jobs:
  ///
  /// * With a [body] widget: the plain-text version the read-aloud voice
  ///   speaks — a widget cannot be spoken.
  /// * Without a [body]: the rendered body too. The book lays the text out
  ///   itself (styled by `FlipBookPageStyle.bodyStyle`) inside a scroll
  ///   view, which is what lets the read marker follow the voice down the
  ///   page.
  ///
  /// The book splits this into reading units on full stops. That guessing
  /// is never perfect — prefer [bodySegments] and decide the units
  /// yourself. Ignored when [bodySegments] is set.
  final String? bodyText;

  /// The page's text already divided into reading units — **the accurate
  /// way to give a page text.**
  ///
  /// # ⚠️ FORMAT YOUR TEXT BEFORE PASSING IT
  ///
  /// One entry = one unit. The book marks it, reads it aloud in one call,
  /// and moves to the next. Nothing is parsed, guessed, or reformatted:
  /// **what you pass is exactly what is shown and spoken.** Splitting the
  /// text is your job, not the book's, and it is the single decision that
  /// determines how the reading feels.
  ///
  /// ```dart
  /// FlipBookPage(
  ///   id: 'journal-42',
  ///   bodySegments: [
  ///     'I spent \$23.54 on SendGrid for 5 emails.',
  ///     'Dr. Smith called it a bargain.',
  ///   ],
  /// )
  /// ```
  ///
  /// Why this exists: automatic splitting cannot tell a sentence from an
  /// abbreviation. `pub.dev`, `\$23.54`, and `a@b.com` survive the built-in
  /// rules, but `Dr. Smith` and `1. First` do not — and no rule set ever
  /// gets every language right. Segments remove the guesswork entirely, and
  /// work identically in every script on earth, RTL included, because the
  /// book never inspects the characters.
  ///
  /// Practical guidance:
  ///
  /// * A unit should be a natural breath — a sentence, or a short group.
  ///   The voice pauses between units, so a split mid-sentence sounds wrong.
  /// * Never split inside an abbreviation, a number, a URL, or an email.
  /// * Any character is safe: brackets, braces, quotes, `~`, `⁅` — there is
  ///   no markup and nothing to escape. Only ordinary Dart string quoting
  ///   applies, and the compiler checks that for you.
  /// * Already have a paragraph string? `text.split('\n\n')` is usually the
  ///   right unit. Loading from ARB or a database? Split there.
  ///
  /// Units render stacked with paragraph spacing, in order.
  final List<String>? bodySegments;

  /// Widgets to drop **between** the text units — an image, a chart, a
  /// video player, a divider.
  ///
  /// The key is the [bodySegments] index the widget is inserted BEFORE, so
  /// `{0: banner}` puts it above the first paragraph and
  /// `{2: Image.asset(...)}` puts it between the second and third. A key
  /// equal to the number of segments appends at the end.
  ///
  /// ```dart
  /// FlipBookPage(
  ///   bodySegments: ['Before the picture.', 'After it.'],
  ///   bodyWidgets: {1: Image.asset('shot.png')},
  /// )
  /// ```
  ///
  /// The text around them stays fully markable and readable — the voice
  /// simply skips the widgets, since there is nothing to speak. Give
  /// each one a finite height: they sit in a scrolling column, so an
  /// unbounded box (an `Expanded`, a bare `Image` in a `Row`) will throw.
  /// A video keeps playing when the reader flips away unless you pause it
  /// in `FlipBookPages.onChanged`, and platform-view content usually does
  /// not appear in the curl's captured bitmap — that page will curl with a
  /// black rectangle where the video is.
  final Map<int, Widget> bodyWidgets;

  /// Optional decoration behind a text page the book lays out itself —
  /// ruled paper, parchment, a watermark. It stretches to the full content
  /// height inside the page's scroll view, so the decoration scrolls with
  /// the text. Ignored when [body] is set: a widget body owns its own
  /// decoration.
  final Widget? background;

  /// Overrides `FlipBookPages.style` for THIS page only.
  ///
  /// A book usually wants one voice throughout, which is why the style lives
  /// on the book. But a demo — or a chapter that is meant to look like ruled
  /// paper while the rest is print — needs its own type without giving up
  /// everything the book lays out for it: marking, read-aloud, auto-scroll.
  /// Setting a `body` widget would buy the look and lose all three.
  ///
  /// Null falls back to the book's style.
  final FlipBookPageStyle? style;

  /// Whether [title] is printed on the page itself. Set `false` when the
  /// [body] brings its own heading, so the title only names the page in the
  /// table of contents.
  final bool showTitleOnPage;

  /// The page's body text however it was supplied — [bodySegments] joined,
  /// or [bodyText]. Empty when the page carries neither.
  String get bodyString =>
      bodySegments?.where((s) => s.trim().isNotEmpty).join('\n\n') ??
      bodyText ??
      '';

  /// Whether this page carries any text the book can lay out itself — a
  /// printed title, a tagline, or a body. A page with none is either a bare
  /// [body] widget or blank paper.
  bool get hasText =>
      (showTitleOnPage && (title?.trim().isNotEmpty ?? false)) ||
      (tagline?.trim().isNotEmpty ?? false) ||
      bodyString.trim().isNotEmpty;

  /// Composes this page's speech text from exactly the parts the caller
  /// wants — any combination: title only, tagline and body, everything.
  /// Absent or disabled parts are skipped; parts are joined with periods.
  ///
  /// The book reads pages unit by unit on its own, so this is for callers
  /// driving a speech engine themselves.
  ///
  /// ```dart
  /// final text = pages[i].speechText(title: true, tagline: false);
  /// ```
  /// By default the voice reads **what the page shows**: a title hidden
  /// from the page ([showTitleOnPage] false) is skipped unless the caller
  /// explicitly passes `title: true`.
  String speechText({bool? title, bool tagline = true, bool body = true}) {
    final readTitle = title ?? showTitleOnPage;
    final bodyPart = bodyString.trim();
    final parts = <String>[
      if (readTitle && (this.title?.trim().isNotEmpty ?? false))
        this.title!.trim(),
      if (tagline && (this.tagline?.trim().isNotEmpty ?? false))
        this.tagline!.trim(),
      if (body && bodyPart.isNotEmpty) bodyPart,
    ];
    return parts.join('. ');
  }
  /// This object with some fields replaced.
  ///
  /// A null argument means "leave it alone", so a field that is already
  /// nullable cannot be cleared this way — construct a new one for that.
  FlipBookPage copyWith({
    String? id,
    String? title,
    String? tagline,
    Widget? body,
    String? bodyText,
    List<String>? bodySegments,
    Map<int, Widget>? bodyWidgets,
    Widget? background,
    FlipBookPageStyle? style,
    bool? showTitleOnPage,
  }) {
    return FlipBookPage(
      id: id ?? this.id,
      title: title ?? this.title,
      tagline: tagline ?? this.tagline,
      body: body ?? this.body,
      bodyText: bodyText ?? this.bodyText,
      bodySegments: bodySegments ?? this.bodySegments,
      bodyWidgets: bodyWidgets ?? this.bodyWidgets,
      background: background ?? this.background,
      style: style ?? this.style,
      showTitleOnPage: showTitleOnPage ?? this.showTitleOnPage,
    );
  }
}
