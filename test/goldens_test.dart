import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip/page_curl_flip.dart';

/// Golden gate (QA spec Q3): pixel-exact baselines for every theme preset,
/// one RTL frame, and one mid-curl frame. Text renders in the deterministic
/// FlutterTest font, so the images are stable across machines.
///
/// Regenerate deliberately after an intended visual change:
///   flutter test --update-goldens test/goldens_test.dart
void main() {
  Widget book({
    FlipBookTheme theme = const FlipBookTheme(),
    Color paper = Colors.white,
    TextDirection? direction,
  }) {
    return MaterialApp(
      home: FlipBook(
        theme: theme,
        pageColor: paper,
        textDirection: direction,
        enableSound: false,
        onReadAloud: (_) async {},
        onClose: () {},
        pages: const [
          FlipBookPage(
            title: 'The look',
            tagline: 'every colour from one preset',
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

  group('Golden gate — presets', () {
    final presets = <String, (FlipBookTheme, Color)>{
      'classic': (FlipBookTheme.classic, FlipBookTheme.classicPaper),
      'old_book': (FlipBookTheme.oldBook, FlipBookTheme.oldBookPaper),
      'night': (FlipBookTheme.night, FlipBookTheme.nightPaper),
      'magazine': (FlipBookTheme.magazine, FlipBookTheme.magazinePaper),
      'kids': (FlipBookTheme.kids, FlipBookTheme.kidsPaper),
      'newspaper': (FlipBookTheme.newspaper, FlipBookTheme.newspaperPaper),
    };

    for (final entry in presets.entries) {
      testWidgets('GOLD: ${entry.key} first page', (tester) async {
        await pumpAt(
          tester,
          book(theme: entry.value.$1, paper: entry.value.$2),
        );
        await expectLater(
          find.byType(FlipBook),
          matchesGoldenFile('goldens/${entry.key}.png'),
        );
      });
    }
  });

  group('Golden gate — frames', () {
    testWidgets('GOLD: RTL chrome mirrors', (tester) async {
      await pumpAt(tester, book(direction: TextDirection.rtl));
      await expectLater(
        find.byType(FlipBook),
        matchesGoldenFile('goldens/rtl.png'),
      );
    });

    testWidgets('GOLD: mid-curl lighting (light paper)', (tester) async {
      await pumpAt(tester, book());
      await tester.tap(find.text('NEXT'));
      await tester.pump();
      // Freeze the flip at its half-way point — maximum curl, where the
      // shadow and sheen are strongest and regressions are most visible.
      await tester.pump(FlipSpeed.medium.duration * 0.5);
      await expectLater(
        find.byType(FlipBook),
        matchesGoldenFile('goldens/mid_curl_light.png'),
      );
    });

    testWidgets('GOLD: mid-curl lighting (night paper)', (tester) async {
      await pumpAt(
        tester,
        book(theme: FlipBookTheme.night, paper: FlipBookTheme.nightPaper),
      );
      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await tester.pump(FlipSpeed.medium.duration * 0.5);
      // Guards the luminance-adaptive sheen: if the white glare ever returns
      // to dark paper, this image diff catches it.
      await expectLater(
        find.byType(FlipBook),
        matchesGoldenFile('goldens/mid_curl_night.png'),
      );
    });
  });
}
