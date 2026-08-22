/// How the read marker shows the sentence being read aloud.
///
/// The marker replaces a player-style progress bar with a book gesture: a
/// reader following a voice does not watch a timeline, they hold a place in
/// the text. Both styles are driven by the same sentence-by-sentence read
/// cycle, so they work identically on every platform — no speech-engine
/// timing events are involved.
enum FlipBookMarkerStyle {
  /// A broad translucent band behind the sentence being read — the classic
  /// read-along look (Kindle, Play Books). Colour and corner radius come
  /// from `FlipBookHighlight.color` and `FlipBookHighlight.radius`.
  highlight,

  /// The sentence being read keeps its full ink and everything else on the
  /// page fades to `FlipBookHighlight.dimOpacity` — the "line focus"
  /// pattern from accessibility readers. Calmer than [highlight] on decorated
  /// paper, because nothing is painted over the text.
  focus,
}
