// The export flow: a blocking progress dialog around the PDF build, then the
// share sheet.

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:page_curl_flip/page_curl_flip.dart';
import 'package:printing/printing.dart';

import 'export_pdf.dart';

/// Builds the PDF and hands it to the share sheet.
///
/// The point of the seam: by the time this runs, the pages are already plain
/// numbers and strings — nothing Flutter-shaped is left, so they can go
/// straight into a document writer or across to an isolate.
/// `<book>-<what>.pdf`, or just `<book>.pdf` for the whole thing.
///
/// Naming each export for its book and kind is what stops a second export
/// overwriting the first.
String exportFilename(FlipBookExportKind kind, bool rtl) {
  final book = rtl ? 'rtl' : 'ltr';
  return switch (kind) {
    FlipBookExportKind.savedPages => '$book-saved.pdf',
    FlipBookExportKind.markedText => '$book-marked.pdf',
    FlipBookExportKind.wholeBook => '$book.pdf',
  };
}

Future<void> showExport(
  BuildContext context,
  FlipBookExportKind kind,
  List<FlipBookExportEntry> entries, {
  bool rtl = false,
}) async {
  if (entries.isEmpty) {
    return;
  }
  // A hundred pages is seconds of real work. The reader is locked out for
  // the duration ON PURPOSE — no back button, no barrier dismiss — because
  // tapping away mid-build leaves a half-written file and no explanation.
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Exporting the PDF — please wait, and do not '
                  'tap anything.',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  final navigator = Navigator.of(context);
  try {
    final bytes = await exportPdf(
      // The heading printed on the PDF. Every app passes its own; the
      // package supplies none.
      title: 'PAGE CURL FLIP',
      entries: entries,
      rtl: rtl,
      markedOnly: kind == FlipBookExportKind.markedText,
      markedHeading: rtl ? 'المقاطع المعلَّمة' : 'Marked passages',
    );
    navigator.pop();
    await Printing.sharePdf(bytes: bytes, filename: exportFilename(kind, rtl));
  } catch (error) {
    // The dialog has no dismiss of its own, so a failure MUST close it —
    // otherwise the reader is stuck behind a spinner for ever.
    navigator.pop();
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('The export failed'),
          content: Text('$error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
