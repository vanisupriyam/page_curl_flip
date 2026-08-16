import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip/page_curl_flip.dart';

void main() {
  group('CurlOverlay', () {
    testWidgets('builds at every progress phase without an image',
        (tester) async {
      for (final progress in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        await tester.pumpWidget(
          MaterialApp(home: CurlOverlay(progress: progress)),
        );
        expect(find.byType(CurlOverlay), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('builds with custom shine and shadow, including zero',
        (tester) async {
      for (final (shine, shadow) in [(0.0, 0.0), (1.0, 1.0), (0.3, 0.6)]) {
        await tester.pumpWidget(
          MaterialApp(
            home: CurlOverlay(progress: 0.5, shine: shine, shadow: shadow),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('EDG-07: out-of-range progress is clamped, not crashed',
        (tester) async {
      for (final progress in [-0.5, 1.5]) {
        await tester.pumpWidget(
          MaterialApp(home: CurlOverlay(progress: progress)),
        );
        expect(tester.takeException(), isNull);
      }
    });

    test('out-of-range shine and shadow are rejected', () {
      expect(() => CurlOverlay(progress: 0, shine: 1.5), throwsAssertionError);
      expect(
          () => CurlOverlay(progress: 0, shadow: -0.1), throwsAssertionError);
    });

    testWidgets('auto-capture mode shows the child until capture completes',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CurlOverlay(
            progress: 0,
            child: Text('page content'),
          ),
        ),
      );
      expect(find.text('page content'), findsOneWidget);
    });

    testWidgets('parent rebuilds do not restart the capture cycle',
        (tester) async {
      Widget build(String label) => MaterialApp(
            home: CurlOverlay(
              progress: 0,
              // New Text instance on every build — the pre-fix code treated
              // this as a content change and re-entered the capture phase.
              child: Text(label),
            ),
          );

      await tester.pumpWidget(build('first build'));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      final capturedAfterFirst = find.byType(RepaintBoundary).evaluate().length;

      await tester.pumpWidget(build('second build'));
      await tester.pump();

      // The capture RepaintBoundary must not re-enter the tree.
      expect(
        find.byType(RepaintBoundary).evaluate().length,
        lessThanOrEqualTo(capturedAfterFirst),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
