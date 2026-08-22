/// What the reader chose to export.
///
/// The book hands this back with the matching entries; turning them into a
/// file is the app's job, because a document format is an app decision and
/// this package carries no dependencies.
enum FlipBookExportKind {
  /// Only the pages the reader saved with the save button — full text.
  savedPages,

  /// Only the passages the reader marked, grouped by the page they are on.
  markedText,

  /// Every page in the book, full text.
  wholeBook,
}
