import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip/page_curl_flip.dart';

/// Golden gate: pixel-exact baselines for the default look, a customized
/// look (theme + icons), the mirrored RTL chrome, and two mid-curl frames —
/// mid-curl is where lighting regressions hide.
///
/// Regenerate deliberately after an intended visual change:
///   flutter test --update-goldens test/goldens_test.dart
void main() {
  Widget book({
    FlipBookTheme theme = const FlipBookTheme(),
    FlipBookIcons icons = const FlipBookIcons(),
    Color paper = Colors.white,
    TextDirection? direction,
    bool hint = false,
  }) {
    return MaterialApp(
      home: FlipBook(
        theme: theme,
        icons: icons,
        pageColor: paper,
        textDirection: direction,
        // Off in the chrome baselines; the hint has its own golden.
        showSwipeHint: hint,
        onReadAloud: (_) async {},
        onClose: () {},
        pages: const [
          FlipBookPage(
            title: 'The look',
            tagline: 'every colour is customizable',
            body: Text('This page is the golden baseline.'),
          ),
          FlipBookPage(title: 'Second', body: Text('page two')),
        ],
      ),
    );
  }

  Future<void> pumpAt(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
  }

  group('Golden gate', () {
    testWidgets('GOLD: default skeleton', (tester) async {
      await pumpAt(tester, book());
      await expectLater(
        find.byType(FlipBook),
        matchesGoldenFile('goldens/default.png'),
      );
    });

    testWidgets('GOLD: customized theme and icons', (tester) async {
      await pumpAt(
        tester,
        book(
          paper: const Color(0xFFFBFAF6),
          theme: const FlipBookTheme().copyWith(
            closeIconColor: const Color(0xFF3E5641),
            navButtonIconColor: const Color(0xFF3E5641),
            pageTitleStyle: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B3A2E),
            ),
          ),
          icons: const FlipBookIcons(
            next: Icons.arrow_forward_ios,
            previous: Icons.arrow_back_ios_new,
            play: Icons.play_circle_outline,
          ),
        ),
      );
      await expectLater(
        find.byType(FlipBook),
        matchesGoldenFile('goldens/customized.png'),
      );
    });

    testWidgets('GOLD: RTL chrome mirrors', (tester) async {
      await pumpAt(tester, book(direction: TextDirection.rtl));
      await expectLater(
        find.byType(FlipBook),
        matchesGoldenFile('goldens/rtl.png'),
      );
    });

    testWidgets('GOLD: swipe hint — fading chevron train', (tester) async {
      // The hint greets the page, so it is visible at open — capture it
      // before its duration elapses.
      await pumpAt(tester, book(hint: true));
      await expectLater(
        find.byType(FlipBook),
        matchesGoldenFile('goldens/swipe_hint.png'),
      );
    });

    testWidgets('GOLD: mid-curl lighting (light paper)', (tester) async {
      await pumpAt(tester, book());
      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await tester.pump(FlipSpeed.medium.duration * 0.5);
      await expectLater(
        find.byType(FlipBook),
        matchesGoldenFile('goldens/mid_curl_light.png'),
      );
    });

    testWidgets('GOLD: mid-curl lighting (dark paper)', (tester) async {
      // Guards the luminance-adaptive sheen: if the white glare ever
      // returns to dark paper, this image diff catches it.
      await pumpAt(tester, book(paper: const Color(0xFF121212)));
      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await tester.pump(FlipSpeed.medium.duration * 0.5);
      await expectLater(
        find.byType(FlipBook),
        matchesGoldenFile('goldens/mid_curl_dark.png'),
      );
    });
  });
}
