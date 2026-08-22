import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip/page_curl_flip.dart';

void main() {
  group('FlipBookPage.speechText', () {
    const page = FlipBookPage(
      title: 'The Title',
      tagline: 'the tagline',
      body: Text('ignored widget'),
      bodyText: 'the body text',
    );

    test('all parts by default', () {
      expect(page.speechText(), 'The Title. the tagline. the body text');
    });

    test('every combination is the caller\'s choice', () {
      expect(page.speechText(tagline: false, body: false), 'The Title');
      expect(page.speechText(title: false, body: false), 'the tagline');
      expect(page.speechText(title: false, tagline: false), 'the body text');
      expect(page.speechText(body: false), 'The Title. the tagline');
      expect(page.speechText(tagline: false), 'The Title. the body text');
      expect(page.speechText(title: false), 'the tagline. the body text');
    });

    test('a title hidden from the page is skipped by default', () {
      const hidden = FlipBookPage(
        title: 'Handwritten notes',
        showTitleOnPage: false,
        bodyText: 'the poem itself',
      );
      // Reads what the page shows — no more "handwritten notes,
      // handwritten notes" echo.
      expect(hidden.speechText(), 'the poem itself');
      // The caller can still force it.
      expect(
          hidden.speechText(title: true), 'Handwritten notes. the poem itself');
    });

    test('absent and whitespace parts are skipped silently', () {
      const sparse = FlipBookPage(title: '  ', bodyText: 'only body');
      expect(sparse.speechText(), 'only body');
      expect(const FlipBookPage().speechText(), '');
    });
  });
  _copyWithContract();

  _perPageStyleContract();

}

void _copyWithContract() {
  group('copyWith — added', () {
    test('CPY-01: a changed field lands, every other field survives', () {
      const page = FlipBookPage(
        id: 'a',
        title: 'Title',
        tagline: 'Tag',
        bodySegments: ['one', 'two'],
        showTitleOnPage: false,
      );
      final renamed = page.copyWith(title: 'New');
      expect(renamed.title, 'New');
      expect(renamed.id, 'a', reason: 'untouched fields must survive');
      expect(renamed.tagline, 'Tag');
      expect(renamed.bodySegments, ['one', 'two']);
      expect(renamed.showTitleOnPage, isFalse,
          reason: 'a false bool must not be re-defaulted to true');
    });

    test('CPY-02: copyWith with no arguments is a faithful copy', () {
      const style = FlipBookPageStyle(
        titleStyle: TextStyle(fontSize: 31),
        bodyStyle: TextStyle(fontSize: 17),
      );
      final same = style.copyWith();
      expect(same.titleStyle.fontSize, 31);
      expect(same.bodyStyle.fontSize, 17);
      expect(same.padding, style.padding);
    });

    test('CPY-03: the required callback survives a copy', () {
      Future<void> read(String _) async {}
      final aloud = FlipBookReadAloud(onRead: read, playAll: true);
      final quieter = aloud.copyWith(playAll: false);
      expect(quieter.onRead, same(read),
          reason: 'a required function field must carry over');
      expect(quieter.playAll, isFalse);
    });
  });
}

void _perPageStyleContract() {
  group('FlipBookPage.style — added', () {
    testWidgets('STY-01: a page style overrides the book style, and only for '
        'that page', (tester) async {
      const bookBody = TextStyle(fontSize: 11, color: Color(0xFF111111));
      const pageBody = TextStyle(fontSize: 29, color: Color(0xFF222222));

      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: const FlipBookSwipe(hint: null),
          pages: const FlipBookPages(
            style: FlipBookPageStyle(bodyStyle: bookBody),
            items: [
              // Overrides the book.
              FlipBookPage(
                id: 'p1',
                bodySegments: ['styled page'],
                style: FlipBookPageStyle(bodyStyle: pageBody),
              ),
              // Falls back to the book.
              FlipBookPage(id: 'p2', bodySegments: ['plain page']),
            ],
          ),
        ),
      ));

      expect(tester.widget<Text>(find.text('styled page')).style?.fontSize, 29,
          reason: 'the page style must win on its own page');

      await tester.fling(find.byType(FlipBook), const Offset(-220, 0), 900);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(tester.widget<Text>(find.text('plain page')).style?.fontSize, 11,
          reason: 'a page without a style falls back to the book\'s');
    });
  });
}
