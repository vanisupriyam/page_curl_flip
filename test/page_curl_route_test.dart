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

    testWidgets(
        'RTL-06: mirror: true flips the curl horizontally, mirror: false does not',
        (tester) async {
      // The mirror is a horizontal flip: x → −x, y and z untouched. Checked
      // on the raw matrix so the assertion does not depend on how the
      // matrix was built.
      const flip = <double>[
        -1, 0, 0, 0, //
        0, 1, 0, 0, //
        0, 0, 1, 0, //
        0, 0, 0, 1, //
      ];

      Future<int> flippedTransformsMidCurl({required bool? mirror}) async {
        // A distinct key per run: an identical MaterialApp would be reused,
        // and the previous run's pushed route would still be on top.
        await tester.pumpWidget(MaterialApp(
          key: ValueKey<String>('mirror=$mirror'),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                PageCurlRoute<void>(
                  mirror: mirror,
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
        await tester.pump();
        await tester.pump();
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300)); // mid-curl
        final count = tester
            .widgetList<Transform>(find.byType(Transform))
            .where((t) => t.transform.storage.join(',') == flip.join(','))
            .length;
        await tester.pumpAndSettle();
        return count;
      }

      expect(await flippedTransformsMidCurl(mirror: true), 1);
      expect(await flippedTransformsMidCurl(mirror: false), 0);
      expect(tester.takeException(), isNull);
    });
  });
}
