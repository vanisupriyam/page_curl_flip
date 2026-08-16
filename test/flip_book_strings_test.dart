import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip/page_curl_flip.dart';

void main() {
  group('FlipBookStrings', () {
    test('defaults to English', () {
      const strings = FlipBookStrings();
      expect(strings.index, 'INDEX');
      expect(strings.previous, 'PREV');
      expect(strings.next, 'NEXT');
      expect(strings.tableOfContents, 'TABLE OF CONTENTS');
      expect(strings.searchHint, 'Search by title');
      expect(strings.close, 'Close');
      expect(strings.mute, 'Mute flip sound');
      expect(strings.unmute, 'Unmute flip sound');
    });

    test('value equality', () {
      expect(const FlipBookStrings(), const FlipBookStrings());
      expect(const FlipBookStrings().hashCode,
          const FlipBookStrings().hashCode);
      expect(const FlipBookStrings(next: 'WEITER'),
          isNot(const FlipBookStrings()));
    });
  });
}
