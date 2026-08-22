import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip/page_curl_flip.dart';

/// The NEXT control, by the label it announces. The footer draws icons, so
/// there is no word to find — see the note on `ctl` in flip_book_test.dart.
Finder nextControl() => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == 'NEXT',
      description: 'NEXT control',
    );

/// Golden gate: pixel-exact baselines for the default look, a customized
/// look (theme + icons), the mirrored RTL chrome, and two mid-curl frames —
/// mid-curl is where lighting regressions hide.
///
/// Regenerate deliberately after an intended visual change:
///   flutter test --update-goldens test/goldens_test.dart
void main() {
  Widget book({
    FlipBookFooter footer = const FlipBookFooter(),
    FlipBookHeader header = const FlipBookHeader(),
    FlipBookPageStyle pageStyle = const FlipBookPageStyle(),
    Color paper = Colors.white,
    TextDirection? direction,
    bool hint = false,
  }) {
    return MaterialApp(
      home: FlipBook(
        footer: footer,
        header: header,
        // Off in the chrome baselines; the hint has its own golden.
        swipe: FlipBookSwipe(hint: hint ? const FlipBookSwipeHint() : null),
        readAloud: FlipBookReadAloud(onRead: (_) async {}),
        onClose: () {},
        pages: FlipBookPages(
            style: pageStyle,
            paperColor: paper,
            textDirection: direction,
            items: const [
              FlipBookPage(
                title: 'The look',
                tagline: 'every colour is customizable',
                body: Text('This page is the golden baseline.'),
              ),
              FlipBookPage(title: 'Second', body: Text('page two')),
            ]),
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

    testWidgets('GOLD: customized look, per feature', (tester) async {
      await pumpAt(
        tester,
        book(
          paper: const Color(0xFFFBFAF6),
          header: const FlipBookHeader(closeColor: Color(0xFF3E5641)),
          footer: const FlipBookFooter(
            iconColor: Color(0xFF3E5641),
            nav: FlipBookNavButtons(
              nextIcon: Icons.arrow_forward_ios,
              previousIcon: Icons.arrow_back_ios_new,
            ),
          ),
          pageStyle: const FlipBookPageStyle(
            titleStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B3A2E),
            ),
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
      await tester.tap(nextControl());
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
      await tester.tap(nextControl());
      await tester.pump();
      await tester.pump(FlipSpeed.medium.duration * 0.5);
      await expectLater(
        find.byType(FlipBook),
        matchesGoldenFile('goldens/mid_curl_dark.png'),
      );
    });
  });
}
