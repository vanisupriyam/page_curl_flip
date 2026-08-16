import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip/page_curl_flip.dart';

void main() {
  group('PageCurlRoute', () {
    testWidgets('without cover: destination appears after the transition',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              PageCurlRoute<void>(
                builder: (_) => const Text('destination'),
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ));

      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('destination'), findsOneWidget);
    });

    testWidgets('with cover: cover shows first, then the curl reveals',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              PageCurlRoute<void>(
                coverChild: const ColoredBox(
                  color: Colors.white,
                  child: Center(child: Text('cover')),
                ),
                builder: (_) => const Text('destination'),
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ));

      await tester.tap(find.text('go'));
      await tester.pump(); // process the tap
      await tester.pump(); // first frame of the pushed route
      // Pre-capture phase: cover is on top.
      expect(find.text('cover'), findsOneWidget);

      // Flush the bitmap capture, then run the curl to completion.
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('destination'), findsOneWidget);
      expect(find.text('cover'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pop returns to the origin without errors', (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navKey,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              PageCurlRoute<void>(
                builder: (_) => const Text('destination'),
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ));

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      expect(find.text('go'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
