/// Turns the book's export data into a PDF.
///
/// # Why this lives in the example, not the package
///
/// `page_curl_flip` has **zero dependencies** — that is the whole promise.
/// A PDF needs a document library and embedded fonts, so every app using a
/// page curl would pay for a document writer it never asked for. The package
/// stops at [FlipBookExportEntry]: plain numbers and strings. What you are
/// reading is the other half, and it belongs to the app.
///
/// # Why the work happens off the UI thread
///
/// Laying out a hundred pages and subsetting a font is real CPU work, and on
/// the UI thread it freezes the screen for seconds with no way to say why.
/// [FlipBookExportEntry.toMap] exists precisely so the job can cross an
/// isolate boundary — a widget never could.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:page_curl_flip/page_curl_flip.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Everything the isolate needs, in types that can cross to it.
@immutable
class _Job {
  const _Job({
    required this.title,
    required this.pages,
    required this.rtl,
    required this.latin,
    required this.latinBold,
    required this.arabic,
    required this.markedOnly,
    required this.markedHeading,
  });

  final String title;
  final List<Map<String, dynamic>> pages;
  final bool rtl;
  final Uint8List latin;
  final Uint8List latinBold;
  final Uint8List arabic;
  final bool markedOnly;
  final String markedHeading;
}

/// Builds the document. Call it through [exportPdf], not directly.
Future<Uint8List> _build(_Job job) async {
  final body = pw.Font.ttf(job.latin.buffer.asByteData());
  final bold = pw.Font.ttf(job.latinBold.buffer.asByteData());
  final arabic = pw.Font.ttf(job.arabic.buffer.asByteData());

  final doc = pw.Document(
    // Deflates the page content streams. The other half of a small file is
    // font subsetting, which the pdf package does on its own: only the
    // glyphs actually used are embedded, which is what keeps a book with
    // Arabic in it down to hundreds of kilobytes instead of megabytes.
    compress: true,
    theme: pw.ThemeData.withFont(
      base: body,
      bold: bold,
      // Arabic is not a fallback for style — it is the only one of these
      // fonts that HAS Arabic glyphs. Without it the RTL book exports as
      // empty boxes.
      fontFallback: [arabic],
    ),
  );

  final direction = job.rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: direction,
      margin: const pw.EdgeInsets.fromLTRB(48, 56, 48, 56),
      // A page number on every sheet: this is a document someone prints and
      // then talks from.
      footer: (context) => pw.Container(
        alignment: job.rtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
        child: pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        pw.Text(job.title, style: pw.TextStyle(font: bold, fontSize: 22)),
        pw.SizedBox(height: 24),
        for (final page in job.pages) ..._entry(page, job),
      ],
    ),
  );
  return doc.save();
}

/// One book page as PDF widgets.
List<pw.Widget> _entry(Map<String, dynamic> page, _Job job) {
  final number = page['number'] as int;
  final title = page['title'] as String?;
  final tagline = page['tagline'] as String?;
  final body = (page['body'] as List?)?.cast<String>() ?? const <String>[];
  final marks = (page['marks'] as List?)?.cast<String>() ?? const <String>[];

  return [
    // The page number leads, because it is the whole point of the document:
    // a recruiter reads a passage here and can then say "page 37".
    pw.Text(
      title == null ? 'Page $number' : 'Page $number — $title',
      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
    ),
    if (tagline != null && tagline.trim().isNotEmpty) ...[
      pw.SizedBox(height: 2),
      pw.Text(
        tagline,
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey700,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    ],
    pw.SizedBox(height: 8),
    if (marks.isNotEmpty) ...[
      if (!job.markedOnly)
        pw.Text(
          job.markedHeading,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      for (final mark in marks)
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6),
          padding: const pw.EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          child: pw.Text(mark, style: const pw.TextStyle(fontSize: 11)),
        ),
    ],
    for (final unit in body)
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          unit,
          style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
        ),
      ),
    pw.SizedBox(height: 18),
  ];
}

/// Builds a PDF from [entries] on a background isolate.
///
/// Fonts are read on the main isolate — `rootBundle` is not available on a
/// spawned one — and handed over as bytes.
Future<Uint8List> exportPdf({
  required String title,
  required List<FlipBookExportEntry> entries,
  required bool rtl,
  required bool markedOnly,
  String markedHeading = 'Marked passages',
}) async {
  Future<Uint8List> load(String name) async =>
      (await rootBundle.load('assets/fonts/$name')).buffer.asUint8List();

  final job = _Job(
    title: title,
    pages: [for (final e in entries) e.toMap()],
    rtl: rtl,
    latin: await load('DMSans-Regular.ttf'),
    latinBold: await load('DMSans-SemiBold.ttf'),
    arabic: await load('NotoSansArabic-Regular.ttf'),
    markedOnly: markedOnly,
    markedHeading: markedHeading,
  );
  return compute(_build, job);
}
