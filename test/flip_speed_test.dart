import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip/page_curl_flip.dart';

void main() {
  group('FlipSpeed', () {
    test('presets map to their documented durations', () {
      expect(FlipSpeed.slow.duration, const Duration(milliseconds: 1600));
      expect(FlipSpeed.medium.duration, const Duration(milliseconds: 1200));
      expect(FlipSpeed.fast.duration, const Duration(milliseconds: 750));
    });

    test('custom carries any duration', () {
      const speed = FlipSpeed.custom(Duration(seconds: 3));
      expect(speed.duration, const Duration(seconds: 3));
    });

    test('value equality', () {
      expect(
        const FlipSpeed.custom(Duration(milliseconds: 1200)),
        FlipSpeed.medium,
      );
      expect(FlipSpeed.fast, isNot(FlipSpeed.slow));
    });
  });
}
