/// How the footer chrome (INDEX, speaker, voice controls, PREV/NEXT, page
/// number) presents itself.
///
/// The header — the × close button — is not part of this: it stays visible
/// in every mode, so the reader always has a way out.
enum FlipBookChrome {
  /// The footer is always visible — the default.
  always,

  /// Immersive reading: the book opens as a pure page (only the swipe hint
  /// greets), and the footer stays hidden until the reader taps the page —
  /// then it fades in, and fades away again after
  /// `FlipBook.chromeRevealFor` of no interaction. On mouse platforms,
  /// hovering over the bottom of the book reveals it too. While hidden the
  /// footer is untappable.
  autoHide,
}
