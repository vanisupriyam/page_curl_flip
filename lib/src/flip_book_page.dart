import 'package:flutter/widgets.dart';

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
@immutable
class FlipBookPage {
  /// Creates a page; every field is optional.
  const FlipBookPage({
    this.title,
    this.tagline,
    this.body,
    this.bodyText,
    this.showTitleOnPage = true,
  });

  /// The page's name in the table of contents and, while [showTitleOnPage]
  /// is `true`, the big text at the top of the page. `null` hides the page
  /// from the table of contents.
  final String? title;

  /// Smaller line under the title; `null` shows no tagline.
  final String? tagline;

  /// The page body — any widget; `null` renders blank paper under the title.
  final Widget? body;

  /// Plain-text version of [body] for the read-aloud voice. The body is a
  /// widget and cannot be spoken; provide its text here to make it readable.
  final String? bodyText;

  /// Whether [title] is printed on the page itself. Set `false` when the
  /// [body] brings its own heading, so the title only names the page in the
  /// table of contents.
  final bool showTitleOnPage;

  /// Composes this page's speech text from exactly the parts the caller
  /// wants — any combination: title only, tagline and body, everything.
  /// Absent or disabled parts are skipped; parts are joined with periods.
  ///
  /// ```dart
  /// onReadAloud: (i) => tts.speak(
  ///   pages[i].speechText(title: true, tagline: false, body: true),
  /// )
  /// ```
  /// By default the voice reads **what the page shows**: a title hidden
  /// from the page ([showTitleOnPage] false) is skipped unless the caller
  /// explicitly passes `title: true`.
  String speechText({bool? title, bool tagline = true, bool body = true}) {
    final readTitle = title ?? showTitleOnPage;
    final parts = <String>[
      if (readTitle && (this.title?.trim().isNotEmpty ?? false))
        this.title!.trim(),
      if (tagline && (this.tagline?.trim().isNotEmpty ?? false))
        this.tagline!.trim(),
      if (body && (bodyText?.trim().isNotEmpty ?? false)) bodyText!.trim(),
    ];
    return parts.join('. ');
  }
}
