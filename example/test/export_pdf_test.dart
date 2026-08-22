import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip/page_curl_flip.dart';
import 'package:page_curl_flip_example/export_pdf.dart';

/// The export is the one feature whose output nobody looks at while
/// developing — you tap a button and a share sheet appears. So the bytes
/// themselves are asserted here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const entries = [
    FlipBookExportEntry(
      number: 7,
      id: 'a',
      title: 'A page with a title',
      tagline: 'and a tagline',
      body: ['One sentence.', 'Another one.'],
    ),
    FlipBookExportEntry(
      number: 12,
      id: 'b',
      title: 'A marked page',
      marks: ['the passage the reader kept'],
    ),
  ];

  test('EXP-05: the export really produces a PDF', () async {
    final bytes = await exportPdf(
      title: 'From my journal',
      entries: entries,
      rtl: false,
      markedOnly: false,
    );

    // %PDF- is the file signature. Without it nothing will open the file.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(2000), reason: 'not an empty shell');

    // Compression plus font subsetting is what keeps this small. Two pages
    // carrying three embedded faces would be megabytes unsubset.
    expect(
      bytes.length,
      lessThan(400 * 1024),
      reason: 'compress + subsetting must actually be happening',
    );
  });

  test(
    'EXP-06: an Arabic export embeds a font that HAS Arabic glyphs',
    () async {
      final arabic = await exportPdf(
        title: 'من دفتري',
        entries: const [
          FlipBookExportEntry(
            number: 1,
            id: 'ar',
            title: 'صفحة',
            body: ['هذه فقرة عربية كاملة.'],
          ),
        ],
        rtl: true,
        markedOnly: false,
      );
      expect(String.fromCharCodes(arabic.take(5)), '%PDF-');

      // The built-in PDF fonts carry no Arabic at all, so an unfontted export
      // would still be a valid file — just full of empty boxes. Size is the
      // observable difference: real glyphs have to be embedded.
      final latin = await exportPdf(
        title: 'x',
        entries: const [
          FlipBookExportEntry(number: 1, id: 'l', title: 'x', body: ['x']),
        ],
        rtl: false,
        markedOnly: false,
      );
      expect(
        arabic.length,
        greaterThan(latin.length),
        reason: 'Arabic glyphs must actually be embedded',
      );
    },
  );

  test(
    'EXP-07: subsetting scales with the text, not with the font file',
    () async {
      Future<int> sizeOf(int paragraphs) async {
        final bytes = await exportPdf(
          title: 'size probe',
          entries: [
            FlipBookExportEntry(
              number: 1,
              id: 'p',
              title: 'p',
              body: List.filled(paragraphs, 'The quick brown fox jumps.'),
            ),
          ],
          rtl: false,
          markedOnly: false,
        );
        return bytes.length;
      }

      // Ten times the text repeated from the same small alphabet must not be
      // ten times the file: the font is embedded once, subset to the glyphs
      // used, and the repeated text deflates.
      final small = await sizeOf(2);
      final large = await sizeOf(20);
      expect(large, lessThan(small * 3));
    },
  );
}
