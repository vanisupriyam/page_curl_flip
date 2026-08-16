import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('the example\'s own flip sound asset is bundled', () async {
    final data = await rootBundle.load('assets/sounds/page_flip.m4a');
    expect(data.lengthInBytes, greaterThan(5000));
  });
}
