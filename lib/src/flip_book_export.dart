import 'package:flutter/widgets.dart';

import 'flip_book_export_entry.dart';
import 'flip_book_export_kind.dart';

/// Signature of [FlipBookExport.onExport].
typedef FlipBookExportCallback = void Function(
  FlipBookExportKind kind,
  List<FlipBookExportEntry> entries,
);

/// Lets the reader take part of the book away with them.
///
/// Pass it to `FlipBookContents(export: ...)` and an Export button appears in
/// the table of contents; leave it out and there is none. Tapping it offers
/// three choices — the pages they saved, the passages they marked, or the
/// whole book — and [onExport] fires with that choice and the matching
/// pages, already flattened to plain strings.
///
/// # The package stops at the data
///
/// It builds no file. A PDF needs a document library and embedded fonts, and
/// this package has **zero dependencies** — adding one would make every app
/// that uses a page curl pay for a document writer it never asked for.
///
/// ```dart
/// contents: FlipBookContents(
///   export: FlipBookExport(
///     onExport: (kind, entries) async {
///       final bytes = await buildPdf(entries);   // your app, your format
///       await Printing.sharePdf(bytes: bytes);
///     },
///   ),
/// )
/// ```
///
/// Entries arrive in reading order, numbered the way the footer numbers
/// them, so "page 37" in the export is the page a reader flips to.
@immutable
class FlipBookExport {
  /// Creates the export control; only [onExport] is required.
  const FlipBookExport({
    required this.onExport,
    this.child,
    this.icon,
    this.label = 'Export',
    this.heading = 'What would you like to export?',
    this.savedLabel = 'Pages I saved',
    this.markedLabel = 'Passages I marked',
    this.wholeLabel = 'The whole book',
    this.cancelLabel = 'Cancel',
    this.headingStyle,
    this.optionStyle,
    this.emptyLabel = 'Nothing saved yet',
    this.showEmptyOptions = false,
  });

  /// Fires with the reader's choice and the pages it covers.
  ///
  /// Never fires with an empty list unless [showEmptyOptions] is on: a
  /// choice that would export nothing is disabled instead, which is kinder
  /// than a file with no pages in it.
  final FlipBookExportCallback onExport;

  /// Any widget for the button — a word, an icon, your own badge. Null uses
  /// [icon].
  final Widget? child;

  /// Icon for the button when [child] is null. Null uses a share glyph.
  final IconData? icon;

  /// What the button announces to a screen reader, and its tap label.
  final String label;

  /// Title of the chooser.
  final String heading;

  /// The three choices, in the order they are offered.
  final String savedLabel;

  /// Wording for [FlipBookExportKind.markedText].
  final String markedLabel;

  /// Wording for [FlipBookExportKind.wholeBook].
  final String wholeLabel;

  /// Wording for the dismiss action.
  final String cancelLabel;

  /// Type of the chooser's title.
  final TextStyle? headingStyle;

  /// Type of the three choices.
  final TextStyle? optionStyle;

  /// Shown beside a choice that has nothing behind it yet.
  final String emptyLabel;

  /// Whether a choice with no pages is offered anyway. Off by default —
  /// an empty export is a confusing file, not a feature.
  final bool showEmptyOptions;
}
