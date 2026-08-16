import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip_example/main.dart';

void main() {
  testWidgets('home screen lists the LTR and RTL books', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('LTR'), findsOneWidget);
    expect(find.text('RTL'), findsOneWidget);
  });
}
