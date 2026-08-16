import 'package:flutter/widgets.dart';
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

    test('absent and whitespace parts are skipped silently', () {
      const sparse = FlipBookPage(title: '  ', bodyText: 'only body');
      expect(sparse.speechText(), 'only body');
      expect(const FlipBookPage().speechText(), '');
    });
  });
}
