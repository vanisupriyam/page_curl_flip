import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip_example/main.dart';

void main() {
  testWidgets('home screen lists both books and the theme gallery', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('English book — LTR'), findsOneWidget);
    expect(find.text('Arabic book — RTL'), findsOneWidget);

    for (final tile in [
      'Classic',
      'Old book',
      'Night',
      'Kids',
      'Newspaper',
      'Magazine',
    ]) {
      await tester.scrollUntilVisible(find.text(tile), 100);
      expect(find.text(tile), findsOneWidget);
    }
  });
}
