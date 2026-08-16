import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip/page_curl_flip.dart';

Widget _app({
  FlipBookStrings strings = const FlipBookStrings(),
  bool enableSound = true,
  Future<void> Function()? onPageFlip,
  VoidCallback? onClose,
  TextDirection direction = TextDirection.ltr,
}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: FlipBook(
        strings: strings,
        enableSound: enableSound,
        onPageFlip: onPageFlip,
        onClose: onClose ?? () {},
        pages: const [
          FlipBookPage(title: 'One', body: Text('page one')),
          FlipBookPage(title: 'Two', body: Text('page two')),
          FlipBookPage(title: 'Three', body: Text('page three')),
        ],
      ),
    ),
  );
}

/// Completes a flip started by a tap: pumps the animation to its end using
/// the book's actual speed — no timing literals to go stale.
Future<void> _finishFlip(
  WidgetTester tester, {
  FlipSpeed speed = FlipSpeed.medium,
}) async {
  await tester.pump();
  await tester.pump(speed.duration + const Duration(milliseconds: 100));
  await tester.pump();
}

void main() {
  group('FlipBook navigation', () {
    testWidgets('shows the first page with NEXT but no PREV', (tester) async {
      await tester.pumpWidget(_app());
      expect(find.text('page one'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
      expect(find.text('PREV'), findsNothing);
    });

    testWidgets('NEXT flips forward, PREV flips back', (tester) async {
      await tester.pumpWidget(_app());

      await tester.tap(find.text('NEXT'));
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);
      expect(find.text('PREV'), findsOneWidget);

      await tester.tap(find.text('PREV'));
      await tester.pump(); // phase 1: lay out the hidden capture target
      await _finishFlip(tester);
      expect(find.text('page one'), findsOneWidget);
    });

    testWidgets('navigation works under RTL directionality', (tester) async {
      await tester.pumpWidget(_app(direction: TextDirection.rtl));

      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);
    });

    testWidgets(
        'RTL-05: Arabic chevrons sit after their word and point with the '
        'page direction', (tester) async {
      final c = FlipBookController();
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          controller: c,
          textDirection: TextDirection.rtl,
          enableSound: false,
          // Off so the hint's own chevrons stay out of the icon finders.
          showSwipeHint: false,
          onClose: () {},
          strings: const FlipBookStrings(previous: 'السابق', next: 'التالي'),
          pages: const [
            FlipBookPage(title: 'a', body: Text('p1')),
            FlipBookPage(title: 'b', body: Text('p2')),
            FlipBookPage(title: 'c', body: Text('p3')),
          ],
        ),
      ));
      c.jumpToPage(1);
      await tester.pump();

      // Icons keep their identity (NEXT = icons.next = chevron_right);
      // under RTL each arrow is mirrored VISUALLY by Transform.flip — which
      // works for any custom icon — and the Row mirrors the positions.
      // Net result on screen: ‹التالي … السابق›
      final nextX = tester.getCenter(find.text('التالي')).dx;
      final nextArrowX = tester.getCenter(find.byIcon(Icons.chevron_right)).dx;
      expect(nextArrowX, lessThan(nextX),
          reason: 'NEXT arrow must sit left of التالي');

      final prevX = tester.getCenter(find.text('السابق')).dx;
      final prevArrowX = tester.getCenter(find.byIcon(Icons.chevron_left)).dx;
      expect(prevArrowX, greaterThan(prevX),
          reason: 'PREV arrow must sit right of السابق');

      // And the visual mirror itself is present on both arrows.
      expect(
        find.ancestor(
          of: find.byIcon(Icons.chevron_right),
          matching: find.byType(Transform),
        ),
        findsWidgets,
        reason: 'RTL arrows must be visually mirrored',
      );
    });

    testWidgets(
        'NAV-05: hammering NEXT during a flip advances exactly one page',
        (tester) async {
      await tester.pumpWidget(_app());
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('NEXT'), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 20));
      }
      await _finishFlip(tester);
      await tester.pump(const Duration(milliseconds: 1400));
      expect(find.text('page two'), findsOneWidget);
      expect(find.text('page three'), findsNothing);
    });

    testWidgets('SWP-01: a left swipe flips forward in LTR, right goes back',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.fling(find.text('page one'), const Offset(-220, 0), 900);
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);

      await tester.fling(find.text('page two'), const Offset(220, 0), 900);
      await tester.pump();
      await _finishFlip(tester);
      expect(find.text('page one'), findsOneWidget);
    });

    testWidgets('SWP-02: swipes mirror under RTL', (tester) async {
      await tester.pumpWidget(_app(direction: TextDirection.rtl));
      // RTL: rightward swipe goes forward.
      await tester.fling(find.text('page one'), const Offset(220, 0), 900);
      await tester.pump();
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);
    });

    testWidgets('SWP-03: swipeToFlip false ignores swipes', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipeToFlip: false,
          pages: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ],
        ),
      ));
      await tester.fling(find.text('page one'), const Offset(-220, 0), 900);
      await _finishFlip(tester);
      expect(find.text('page one'), findsOneWidget);
    });

    testWidgets('SWP-04: showNavButtons false hides PREV/NEXT; swipe works',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          showNavButtons: false,
          pages: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ],
        ),
      ));
      expect(find.text('NEXT'), findsNothing);
      expect(find.text('PREV'), findsNothing);
      await tester.fling(find.text('page one'), const Offset(-220, 0), 900);
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);
    });

    testWidgets(
        'SWP-05: the hint greets the page, fades, and returns every '
        'swipeHintDelay while the reader stays', (tester) async {
      final hint = find.text('Swipe to turn the page');
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipeHintDelay: const Duration(seconds: 4),
          swipeHintDuration: const Duration(seconds: 2),
          pages: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ],
        ),
      ));
      expect(hint, findsOneWidget, reason: 'shows the moment the page opens');

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500)); // fade-out
      expect(hint, findsNothing, reason: 'fades after swipeHintDuration');

      await tester.pump(const Duration(seconds: 4));
      expect(hint, findsOneWidget,
          reason: 'returns after swipeHintDelay on the same page');

      // A page change restarts the cycle with the hint visible.
      await tester.tap(find.text('NEXT'));
      await _finishFlip(tester);
      expect(hint, findsOneWidget, reason: 'greets the new page too');
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets(
        'SWP-08: swipes in BOTH directions count toward the limit; edge '
        'flings do not', (tester) async {
      final hint = find.text('Swipe to turn the page');
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipeHintMaxSwipes: 2,
          swipeHintDelay: const Duration(seconds: 1),
          pages: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
            FlipBookPage(title: 'Three', body: Text('page three')),
          ],
        ),
      ));
      // A backward fling on the FIRST page turns nothing — it must neither
      // count nor eat the hint.
      await tester.fling(find.text('page one'), const Offset(220, 0), 900);
      await tester.pump();
      expect(find.text('page one'), findsOneWidget);
      expect(hint, findsOneWidget, reason: 'an edge fling proves nothing');

      // Swipe 1 of 2: forward (leftward).
      await tester.fling(find.text('page one'), const Offset(-220, 0), 900);
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);
      expect(hint, findsOneWidget,
          reason: 'one swipe does not count as learned yet');

      // Swipe 2 of 2: BACKWARD (rightward) — the other direction counts
      // just the same, and the mixed pair reaches the limit.
      await tester.fling(find.text('page two'), const Offset(220, 0), 900);
      await tester.pump();
      await _finishFlip(tester);
      expect(find.text('page one'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500)); // fade-out
      expect(hint, findsNothing,
          reason: 'two mixed-direction swipes = gesture learned');
      await tester.pump(const Duration(seconds: 3)); // past delay + duration
      expect(hint, findsNothing, reason: 'and the cycle never returns');
    });

    testWidgets('disposing mid-flip does not throw', (tester) async {
      await tester.pumpWidget(_app());
      await tester.tap(find.text('NEXT'));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100)); // mid-animation

      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  });

  group('FlipBook table of contents', () {
    testWidgets('INDEX opens the TOC, search filters, tap jumps',
        (tester) async {
      await tester.pumpWidget(_app());

      await tester.tap(find.text('INDEX'));
      await tester.pump();
      expect(find.text('TABLE OF CONTENTS'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
      // Exactly one row — the current page — carries the bookmark.
      expect(find.byIcon(Icons.bookmark), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Thr');
      await tester.pump();
      expect(find.text('Three'), findsOneWidget);
      expect(find.text('One'), findsNothing);

      await tester.tap(find.text('Three'));
      await tester.pump();
      expect(find.text('page three'), findsOneWidget);
    });
  });

  group('FlipBook customisation', () {
    testWidgets('strings override every built-in label', (tester) async {
      await tester.pumpWidget(_app(
        strings: const FlipBookStrings(
          index: 'INHALT',
          next: 'WEITER',
          tableOfContents: 'INHALTSVERZEICHNIS',
        ),
      ));

      expect(find.text('WEITER'), findsOneWidget);
      await tester.tap(find.text('INHALT'));
      await tester.pump();
      expect(find.text('INHALTSVERZEICHNIS'), findsOneWidget);
    });

    testWidgets('no onPageFlip: silent book, no speaker button',
        (tester) async {
      await tester.pumpWidget(_app());
      expect(find.byIcon(Icons.volume_up), findsNothing);
      expect(find.byIcon(Icons.volume_off), findsNothing);
    });

    testWidgets('with onPageFlip: mute button shows, toggles, and mutes',
        (tester) async {
      var flips = 0;
      await tester.pumpWidget(_app(onPageFlip: () async => flips++));
      expect(find.byIcon(Icons.volume_up), findsOneWidget);

      await tester.tap(find.text('NEXT'));
      await _finishFlip(tester);
      expect(flips, 1);

      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();
      expect(find.byIcon(Icons.volume_off), findsOneWidget);
      await tester.tap(find.text('PREV'));
      await tester.pump();
      await _finishFlip(tester);
      expect(flips, 1, reason: 'muted flips must not fire onPageFlip');
    });

    testWidgets('enableSound false silences and hides even with onPageFlip',
        (tester) async {
      var flips = 0;
      await tester.pumpWidget(
          _app(enableSound: false, onPageFlip: () async => flips++));
      expect(find.byIcon(Icons.volume_up), findsNothing);
      await tester.tap(find.text('NEXT'));
      await _finishFlip(tester);
      expect(flips, 0);
    });

    testWidgets('custom icons replace the defaults everywhere', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          // Off so the hint's own chevrons stay out of the icon finders.
          showSwipeHint: false,
          icons: const FlipBookIcons(
            next: Icons.arrow_forward,
            close: Icons.cancel,
            play: Icons.play_circle,
          ),
          onReadAloud: (_) async {},
          pages: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ],
        ),
      ));
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.play_circle), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('title prints on the page with its tagline', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          enableSound: false,
          pages: const [
            FlipBookPage(
              title: 'The Title',
              tagline: 'the tagline',
              body: Text('the body'),
            ),
          ],
        ),
      ));

      expect(find.text('The Title'), findsOneWidget);
      expect(find.text('the tagline'), findsOneWidget);
      expect(find.text('the body'), findsOneWidget);
    });

    testWidgets('showTitleOnPage false keeps the title off the page',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          enableSound: false,
          pages: const [
            FlipBookPage(
              title: 'Index Only',
              showTitleOnPage: false,
              body: Text('custom body'),
            ),
          ],
        ),
      ));

      expect(find.text('Index Only'), findsNothing);
      expect(find.text('custom body'), findsOneWidget);
    });

    testWidgets('textDirection parameter forces RTL navigation',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          enableSound: false,
          textDirection: TextDirection.rtl,
          pages: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ],
        ),
      ));

      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);
    });

    testWidgets('initialPage opens there; onPageChanged reports every move',
        (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          initialPage: 99, // out of range — clamps to the last page
          onPageChanged: changes.add,
          pages: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
            FlipBookPage(title: 'Three', body: Text('page three')),
          ],
        ),
      ));
      expect(find.text('page three'), findsOneWidget);
      expect(changes, isEmpty, reason: 'opening is not a change');

      await tester.tap(find.text('PREV'));
      await tester.pump();
      await _finishFlip(tester);
      expect(changes, [1]);

      await tester.tap(find.text('INDEX'));
      await tester.pump();
      await tester.tap(find.text('Three'));
      await tester.pump();
      expect(changes, [1, 2]);
    });

    testWidgets('showPageNumber shows "n / total" and tracks flips',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          showPageNumber: true,
          pages: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ],
        ),
      ));
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(find.text('NEXT'));
      await _finishFlip(tester);
      expect(find.text('2 / 2'), findsOneWidget);
    });

    testWidgets('shrinking the list notifies onPageChanged of the clamp',
        (tester) async {
      final changes = <int>[];
      Widget app(List<FlipBookPage> pages) => MaterialApp(
            home: FlipBook(
              onClose: () {},
              initialPage: 2,
              onPageChanged: changes.add,
              pages: pages,
            ),
          );
      const three = [
        FlipBookPage(title: 'One', body: Text('page one')),
        FlipBookPage(title: 'Two', body: Text('page two')),
        FlipBookPage(title: 'Three', body: Text('page three')),
      ];
      await tester.pumpWidget(app(three));
      await tester.pumpWidget(app(three.sublist(0, 1)));
      await tester.pump();
      expect(changes, [0], reason: 'the clamp moved the page — report it');
    });

    test('FlipBookIcons.copyWith replaces only the named fields', () {
      const base = FlipBookIcons();
      final custom = base.copyWith(next: Icons.arrow_forward, size: 20);
      expect(custom.next, Icons.arrow_forward);
      expect(custom.size, 20);
      expect(custom.previous, base.previous);
    });

    testWidgets('close button fires onClose', (tester) async {
      var closed = false;
      await tester.pumpWidget(_app(onClose: () => closed = true));
      await tester.tap(find.byIcon(Icons.close));
      expect(closed, isTrue);
    });

    testWidgets('play reads the shown page and returns to play when done',
        (tester) async {
      await tester.pumpWidget(_app());
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      int? readPage;
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          enableSound: false,
          onReadAloud: (i) async => readPage = i,
          pages: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ],
        ),
      ));

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(readPage, 0);

      // The instantly-completed future returns the control to idle.
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);

      await tester.tap(find.text('NEXT'));
      await _finishFlip(tester);
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(readPage, 1);
      await tester.pump();
    });

    testWidgets('stop while playing returns to a fresh play button',
        (tester) async {
      final started = Completer<void>();
      var stopped = 0;
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          enableSound: false,
          onReadAloud: (_) => started.future,
          onReadAloudStop: () => stopped++,
          pages: const [FlipBookPage(title: 'One', body: Text('page one'))],
        ),
      ));

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      // Playing without pause support: stop only.
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();
      expect(stopped, 1);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      // A stopped session's future completing later changes nothing.
      started.complete();
      await tester.pump();
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('pause shows play+stop, resume continues, stop resets',
        (tester) async {
      final first = Completer<void>();
      final resumed = Completer<void>();
      var paused = 0;
      var resumes = 0;
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          enableSound: false,
          onReadAloud: (_) => first.future,
          onReadAloudPause: () => paused++,
          onReadAloudResume: () {
            resumes++;
            return resumed.future;
          },
          onReadAloudStop: () {},
          pages: const [FlipBookPage(title: 'One', body: Text('page one'))],
        ),
      ));

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      // Playing with pause support: pause + stop.
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      expect(paused, 1);
      // Paused: play (resume) + stop.
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(resumes, 1);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      resumed.complete();
      await tester.pump();
      await tester.pump();
      // Finished: back to the single play button.
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
      first.complete();
    });

    testWidgets('TTS-13: speech engine failure quietly returns control to play',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          enableSound: false,
          onReadAloud: (_) async => throw Exception('engine down'),
          pages: const [FlipBookPage(title: 'One', body: Text('page one'))],
        ),
      ));

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('flipping away stops an active read', (tester) async {
      final started = Completer<void>();
      var stopped = 0;
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          enableSound: false,
          onReadAloud: (_) => started.future,
          onReadAloudStop: () => stopped++,
          pages: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ],
        ),
      ));

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.tap(find.text('NEXT'));
      await _finishFlip(tester);
      expect(stopped, 1);
      started.complete();
    });

    testWidgets('showMuteButton false keeps sound on but hides the speaker',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          showMuteButton: false,
          pages: const [FlipBookPage(title: 'One', body: Text('page one'))],
        ),
      ));
      expect(find.byIcon(Icons.volume_up), findsNothing);
      expect(find.byIcon(Icons.volume_off), findsNothing);
    });
  });

  group('FlipBookController', () {
    Widget app(FlipBookController controller, {bool showControls = false}) {
      return MaterialApp(
        home: FlipBook(
          controller: controller,
          showControls: showControls,
          enableSound: false,
          onClose: () {},
          pages: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
            FlipBookPage(title: 'Three', body: Text('page three')),
          ],
        ),
      );
    }

    testWidgets('showControls false renders no buttons at all', (tester) async {
      await tester.pumpWidget(app(FlipBookController()));
      expect(find.text('page one'), findsOneWidget);
      expect(find.text('NEXT'), findsNothing);
      expect(find.text('INDEX'), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('nextPage and previousPage flip with animation',
        (tester) async {
      final controller = FlipBookController();
      await tester.pumpWidget(app(controller));
      expect(controller.isAttached, isTrue);
      expect(controller.page, 0);

      final flip = controller.nextPage();
      await _finishFlip(tester);
      await flip;
      expect(controller.page, 1);
      expect(find.text('page two'), findsOneWidget);

      final back = controller.previousPage();
      await tester.pump(); // phase 1: lay out the hidden capture target
      await _finishFlip(tester);
      await back;
      expect(controller.page, 0);
      expect(find.text('page one'), findsOneWidget);
    });

    testWidgets('jumpToPage is instant and ignores bad indices',
        (tester) async {
      final controller = FlipBookController();
      await tester.pumpWidget(app(controller));

      controller.jumpToPage(2);
      await tester.pump();
      expect(find.text('page three'), findsOneWidget);

      controller.jumpToPage(99); // out of range — ignored
      await tester.pump();
      expect(controller.page, 2);
    });

    testWidgets('openIndex and closeIndex drive the TOC', (tester) async {
      final controller = FlipBookController();
      await tester.pumpWidget(app(controller));

      controller.openIndex();
      await tester.pump();
      expect(find.text('TABLE OF CONTENTS'), findsOneWidget);

      controller.closeIndex();
      await tester.pump();
      expect(find.text('TABLE OF CONTENTS'), findsNothing);
    });

    testWidgets('detaches when the book is disposed', (tester) async {
      final controller = FlipBookController();
      await tester.pumpWidget(app(controller));
      expect(controller.isAttached, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(controller.isAttached, isFalse);
      expect(controller.page, 0);
    });
  });

  group('Edge cases — spec §4.10', () {
    Widget book({
      List<FlipBookPage> pages = const [
        FlipBookPage(title: 'One', body: Text('page one')),
        FlipBookPage(title: 'Two', body: Text('page two')),
        FlipBookPage(title: 'Three', body: Text('page three')),
      ],
      FlipBookController? controller,
      FlipSpeed speed = FlipSpeed.medium,
      Future<void> Function(int)? onReadAloud,
    }) {
      return MaterialApp(
        home: FlipBook(
          controller: controller,
          flipSpeed: speed,
          enableSound: false,
          onReadAloud: onReadAloud,
          onClose: () {},
          pages: pages,
        ),
      );
    }

    testWidgets('EDG-01: an empty pages list renders without crashing',
        (tester) async {
      await tester.pumpWidget(book(pages: const []));
      expect(tester.takeException(), isNull);
      expect(find.text('NEXT'), findsNothing);
      expect(find.text('INDEX'), findsNothing);
    });

    testWidgets('EDG-02: shrinking the pages list clamps the shown page',
        (tester) async {
      final controller = FlipBookController();
      await tester.pumpWidget(book(controller: controller));
      controller.jumpToPage(2);
      await tester.pump();
      expect(find.text('page three'), findsOneWidget);

      await tester.pumpWidget(book(
        controller: controller,
        pages: const [FlipBookPage(title: 'One', body: Text('page one'))],
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('page one'), findsOneWidget);
      expect(controller.page, 0);
    });

    testWidgets('EDG-03: a rebuilt flipSpeed takes effect on the next flip',
        (tester) async {
      await tester.pumpWidget(book(speed: FlipSpeed.slow));
      await tester.pumpWidget(book(speed: FlipSpeed.fast));

      await tester.tap(find.text('NEXT'));
      // Pump only as long as the FAST flip needs; a stale slow duration
      // would leave the animation unfinished and this expectation failing.
      await _finishFlip(tester, speed: FlipSpeed.fast);
      expect(find.text('page two'), findsOneWidget);
    });

    testWidgets('EDG-04: jumpToPage during a flip wins over the animation',
        (tester) async {
      final controller = FlipBookController();
      await tester.pumpWidget(book(controller: controller));

      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100)); // mid-animation

      controller.jumpToPage(2);
      await tester.pump();
      expect(find.text('page three'), findsOneWidget);

      // The aborted flip's timeline passes; the jump must not be undone.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('page three'), findsOneWidget);
      expect(controller.page, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EDG-05: openIndex during a flip is ignored, works after',
        (tester) async {
      final controller = FlipBookController();
      await tester.pumpWidget(book(controller: controller));

      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      controller.openIndex();
      await tester.pump();
      expect(find.text('TABLE OF CONTENTS'), findsNothing);

      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);

      controller.openIndex();
      await tester.pump();
      expect(find.text('TABLE OF CONTENTS'), findsOneWidget);
    });

    testWidgets('EDG-06: double-tapping play starts exactly one session',
        (tester) async {
      var starts = 0;
      final reading = Completer<void>();
      await tester.pumpWidget(book(onReadAloud: (_) {
        starts++;
        return reading.future;
      }));

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.tap(find.byIcon(Icons.play_arrow), warnIfMissed: false);
      await tester.pump();
      expect(starts, 1);

      reading.complete();
      await tester.pump();
      await tester.pump();
    });

    testWidgets(
        'EDG-08: a controller shared by two books drives the last attached; '
        'the survivor reclaims it', (tester) async {
      final controller = FlipBookController();
      Widget bookA() => SizedBox(
            width: 300,
            height: 500,
            child: FlipBook(
              controller: controller,
              enableSound: false,
              onClose: () {},
              pages: const [FlipBookPage(title: 'A1', body: Text('book A'))],
            ),
          );
      Widget bookB() => SizedBox(
            width: 300,
            height: 500,
            child: FlipBook(
              controller: controller,
              enableSound: false,
              onClose: () {},
              pages: const [
                FlipBookPage(title: 'B1', body: Text('book B one')),
                FlipBookPage(title: 'B2', body: Text('book B two')),
              ],
            ),
          );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Row(children: [bookA(), bookB()])),
      ));

      // Last attached (book B) is the one the controller drives.
      unawaited(controller.nextPage());
      await _finishFlip(tester);
      expect(find.text('book B two'), findsOneWidget);
      expect(find.text('book A'), findsOneWidget);

      // Book B goes away; on its next rebuild book A reclaims the controller.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Row(children: [bookA()])),
      ));
      await tester.pump();
      expect(controller.isAttached, isTrue);
      expect(controller.page, 0);
    });

    testWidgets('ACC-01: every control announces its semantic label',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(book(onReadAloud: (_) async {}));

      expect(find.bySemanticsLabel('INDEX'), findsOneWidget);
      expect(find.bySemanticsLabel('NEXT'), findsOneWidget);
      expect(find.bySemanticsLabel('Read this page aloud'), findsOneWidget);
      expect(find.bySemanticsLabel('Close'), findsOneWidget);

      await tester.tap(find.text('NEXT'));
      await _finishFlip(tester);
      expect(find.bySemanticsLabel('PREV'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('LAY-06: 320×568 at 2× text scale does not overflow',
        (tester) async {
      tester.view.physicalSize = const Size(640, 1136);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2.0)),
          child: child!,
        ),
        home: FlipBook(
          enableSound: false,
          onClose: () {},
          pages: const [
            FlipBookPage(
              title: 'A fairly long chapter title that wraps',
              tagline: 'and a descriptive tagline underneath that also wraps',
              body: Text('short body'),
            ),
          ],
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TOC-07: duplicate titles keep their own pages; whitespace-only '
        'titles stay out of the TOC', (tester) async {
      await tester.pumpWidget(book(pages: const [
        FlipBookPage(title: 'Same', body: Text('first same')),
        FlipBookPage(title: '   ', body: Text('whitespace page')),
        FlipBookPage(title: 'Same', body: Text('second same')),
      ]));

      await tester.tap(find.text('INDEX'));
      await tester.pump();
      expect(find.text('Same'), findsNWidgets(2));

      await tester.tap(find.text('Same').last);
      await tester.pump();
      expect(find.text('second same'), findsOneWidget);
    });
  });
}
