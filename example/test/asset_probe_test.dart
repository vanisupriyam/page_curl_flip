import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('bundled flip sound is reachable at the package asset key', () async {
    final data = await rootBundle.load(
        'packages/page_curl_flip/assets/sounds/page_flip.mp3');
    expect(data.lengthInBytes, greaterThan(10000));
  });
}
