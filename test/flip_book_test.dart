import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip/page_curl_flip.dart';
// Internal widget: the read marker's renderer — tests reach into src
// deliberately, it is not part of the public API.
import 'package:page_curl_flip/src/marked_text.dart';

Widget _app({
  FlipBookFooter? footer,
  Future<void> Function()? onPageFlip,
  VoidCallback? onClose,
  TextDirection direction = TextDirection.ltr,
}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: FlipBook(
        // A book with no sound object is silent — that is the default now.
        footer: footer ??
            (onPageFlip == null
                ? const FlipBookFooter()
                : FlipBookFooter(sound: FlipBookSound(onFlip: onPageFlip))),
        onClose: onClose ?? () {},
        pages: FlipBookPages(items: const [
          FlipBookPage(title: 'One', body: Text('page one')),
          FlipBookPage(title: 'Two', body: Text('page two')),
          FlipBookPage(title: 'Three', body: Text('page three')),
        ]),
      ),
    ),
  );
}

/// A footer control, by the short name it flashes when tapped.
///
/// Two details this hides:
///
/// * It matches the Semantics WIDGET, not the merged semantics node.
///   `find.bySemanticsLabel` resolves to the merged node, whose box is the
///   whole page, so tapping it lands in the middle of the paper instead of
///   on the button.
/// * A control's screen-reader label is the fuller sentence ("Read this
///   page aloud"), not the word flashed on screen ("PLAY") — so the voice
///   controls are mapped here. PLAY and RESUME share a label and never
///   appear at the same time.
const _semanticOf = <String, String>{
  'PLAY': 'Read this page aloud',
  'RESUME': 'Read this page aloud',
  'PLAY ALL': 'Read the whole book aloud',
  'PAUSE': 'Pause reading',
  'STOP': 'Stop reading',
};

Finder ctl(String label) => find.byWidgetPredicate(
      (w) =>
          w is Semantics && w.properties.label == (_semanticOf[label] ?? label),
      description: 'control "$label"',
    );

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
      expect(ctl('NEXT'), findsOneWidget);
      expect(ctl('PREV'), findsNothing);
    });

    testWidgets('NEXT flips forward, PREV flips back', (tester) async {
      await tester.pumpWidget(_app());

      await tester.tap(ctl('NEXT'));
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);
      expect(ctl('PREV'), findsOneWidget);

      await tester.tap(ctl('PREV'));
      await tester.pump(); // phase 1: lay out the hidden capture target
      await _finishFlip(tester);
      expect(find.text('page one'), findsOneWidget);
    });

    testWidgets('navigation works under RTL directionality', (tester) async {
      await tester.pumpWidget(_app(direction: TextDirection.rtl));

      await tester.tap(ctl('NEXT'));
      await tester.pump();
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);
    });

    testWidgets(
        'RTL-05: under RTL the nav arrows swap sides and mirror, so they '
        'still point the way the page travels', (tester) async {
      final c = FlipBookController();
      Widget book(TextDirection direction) => MaterialApp(
            home: FlipBook(
              controller: c,
              // Off so the hint's own chevrons stay out of the icon finders.
              swipe: const FlipBookSwipe(hint: null),
              onClose: () {},
              footer: const FlipBookFooter(
                nav: FlipBookNavButtons(
                  previousLabel: 'السابق',
                  nextLabel: 'التالي',
                ),
              ),
              pages: FlipBookPages(textDirection: direction, items: const [
                FlipBookPage(title: 'a', body: Text('p1')),
                FlipBookPage(title: 'b', body: Text('p2')),
                FlipBookPage(title: 'c', body: Text('p3')),
              ]),
            ),
          );

      // LTR first, as the baseline: prev on the left of next.
      await tester.pumpWidget(book(TextDirection.ltr));
      c.jumpToPage(1);
      await tester.pump();
      expect(
        tester.getCenter(find.byIcon(Icons.chevron_left)).dx,
        lessThan(tester.getCenter(find.byIcon(Icons.chevron_right)).dx),
        reason: 'LTR: ‹ prev sits left of next ›',
      );

      // RTL: the Row swaps the buttons' SIDES, and the glyphs are swapped
      // with them, so the pair still reads "< >" on screen.
      //
      // Asserted by POSITION, not by looking for a `Transform` ancestor:
      // `Transform` is everywhere in a widget tree, so its presence proves
      // nothing about which way an arrow points.
      await tester.pumpWidget(book(TextDirection.rtl));
      c.jumpToPage(1);
      await tester.pump();
      expect(
        tester.getCenter(find.byIcon(Icons.chevron_left)).dx,
        lessThan(tester.getCenter(find.byIcon(Icons.chevron_right)).dx),
        reason: 'RTL must still read "< >" left-to-right on screen',
      );

      // And the LEFT-pointing chevron must be the one that advances, because
      // an RTL page travels leftward. Identity, not just position.
      expect(
        tester.getCenter(ctl('التالي')).dx,
        lessThan(tester.getCenter(ctl('السابق')).dx),
        reason: 'RTL: NEXT sits on the left, the way the page turns',
      );
      expect(
        (tester.getCenter(ctl('التالي')).dx -
                tester.getCenter(find.byIcon(Icons.chevron_left)).dx)
            .abs(),
        lessThan(1.0),
        reason: 'the left chevron IS the next control',
      );
      // The Arabic labels are what a screen reader announces now that the
      // controls are icons.
      expect(ctl('التالي'), findsOneWidget);
      expect(ctl('السابق'), findsOneWidget);
    });

    testWidgets(
        'NAV-05: hammering NEXT during a flip advances exactly one page',
        (tester) async {
      await tester.pumpWidget(_app());
      for (var i = 0; i < 5; i++) {
        await tester.tap(ctl('NEXT'), warnIfMissed: false);
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

    testWidgets(
        'SWP-05: a mostly-VERTICAL fling never turns the page, even with a '
        'sideways lean', (tester) async {
      // A vertical fling must scroll the page, never turn it.
      //
      // THIS TEST DOES NOT REPRODUCE THE FAILURE IT GUARDS. Verified by deleting the
      // guard in _onSwipe and re-running: it still passes. In this harness
      // something else contests the gesture arena, so the horizontal
      // recogniser is never swept in uncontested and the vertical fling never
      // reaches _onSwipe at all — the exact condition the device hits cannot
      // be staged here. Kept as a statement of intent and a guard against
      // someone making vertical flings flip pages deliberately; the real
      // verification is a device run. Do not read a pass here as proof.
      await tester.pumpWidget(_app());

      // Straight up, and up-with-a-lean: neither is a page turn.
      await tester.fling(find.text('page one'), const Offset(0, -300), 900);
      await _finishFlip(tester);
      expect(find.text('page one'), findsOneWidget,
          reason: 'a vertical fling must not turn the page');

      await tester.fling(find.text('page one'), const Offset(60, -300), 900);
      await _finishFlip(tester);
      expect(find.text('page one'), findsOneWidget,
          reason: 'still vertical: dy dominates dx, so it is a scroll');

      // The control: a real horizontal fling still works, so the guard did
      // not simply switch swiping off.
      await tester.fling(find.text('page one'), const Offset(-220, 0), 900);
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget,
          reason: 'horizontal swiping must still turn the page');
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
          swipe: const FlipBookSwipe(enabled: false),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
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
          footer: const FlipBookFooter(nav: FlipBookNavButtons(show: false)),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      ));
      expect(ctl('NEXT'), findsNothing);
      expect(ctl('PREV'), findsNothing);
      await tester.fling(find.text('page one'), const Offset(-220, 0), 900);
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);
    });

    testWidgets(
        'SWP-05: the hint greets a page, fades once, and never comes back '
        'on that page', (tester) async {
      final hint = find.text('Swipe to turn the page');
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: FlipBookSwipe(
              hint: FlipBookSwipeHint(showFor: Duration(seconds: 2))),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      ));
      expect(hint, findsOneWidget, reason: 'shows the moment the page opens');

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500)); // fade-out
      expect(hint, findsNothing, reason: 'fades after swipeHintDuration');

      // Waiting on the same page must never bring the hint back — it
      // greets a page once, not on a repeating clock.
      await tester.pump(const Duration(seconds: 30));
      expect(hint, findsNothing, reason: 'the hint never returns to a page');

      // A page change is a new page, so it greets once more (show 2 of 3).
      await tester.tap(ctl('NEXT'));
      await _finishFlip(tester);
      expect(hint, findsOneWidget, reason: 'greets the new page too');
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets(
        'SWP-08: the hint retires after swipeHintMaxShows appearances, '
        'however the pages were turned', (tester) async {
      final hint = find.text('Swipe to turn the page');
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: FlipBookSwipe(
              hint: FlipBookSwipeHint(
                  maxShows: 2, showFor: Duration(seconds: 1))),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
            FlipBookPage(title: 'Three', body: Text('page three')),
          ]),
        ),
      ));
      // Show 1 of 2 — the opening greeting.
      expect(hint, findsOneWidget);

      // A swipe dismisses the showing hint immediately.
      await tester.fling(find.text('page one'), const Offset(-220, 0), 900);
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);
      // Show 2 of 2 — the new page still gets its greeting.
      expect(hint, findsOneWidget, reason: 'the second appearance is allowed');

      // The allowance is now spent: a third page shows nothing, ever.
      await tester.tap(ctl('NEXT'));
      await _finishFlip(tester);
      expect(hint, findsNothing, reason: 'appearances used up');
      await tester.pump(const Duration(seconds: 30));
      expect(hint, findsNothing, reason: 'and it never returns');
    });

    testWidgets(
        'SWP-10: onSwipeHintRetired fires exactly once, on the last '
        'appearance', (tester) async {
      var retired = 0;
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: FlipBookSwipe(
            hint: FlipBookSwipeHint(
              maxShows: 2,
              showFor: const Duration(milliseconds: 200),
              onRetired: () => retired++,
            ),
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
            FlipBookPage(title: 'Three', body: Text('page three')),
          ]),
        ),
      ));
      // Appearance 1 of 2 — below the limit.
      expect(retired, 0, reason: 'one appearance is below the limit');

      // Appearance 2 of 2 — the limit is reached, the signal fires.
      await tester.tap(ctl('NEXT'));
      await _finishFlip(tester);
      expect(retired, 1, reason: 'the signal fires at the limit');

      // Further pages must not fire it again.
      await tester.tap(ctl('NEXT'));
      await _finishFlip(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(retired, 1, reason: 'the signal fires exactly once');
    });

    testWidgets(
        'SWP-11: the swipeHint slot replaces the built-in text and chevrons',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: FlipBookSwipe(
              hint: FlipBookSwipeHint(
                  child: const SizedBox(height: 48, child: Text('MY GIF')))),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      ));
      expect(find.text('MY GIF'), findsOneWidget);
      expect(find.text('Swipe to turn the page'), findsNothing,
          reason: 'the caller widget replaces the default hint entirely');
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('disposing mid-flip does not throw', (tester) async {
      await tester.pumpWidget(_app());
      await tester.tap(ctl('NEXT'));
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

      await tester.tap(ctl('INDEX'));
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
        footer: const FlipBookFooter(
          index: FlipBookIndexButton(label: 'INHALT'),
          nav: FlipBookNavButtons(nextLabel: 'WEITER'),
        ),
      ));

      // The footer draws icons, so an overridden label reaches the screen
      // reader and the transient tap label — not the button face.
      expect(ctl('WEITER'), findsOneWidget);

      // The word flashed on tap is the overridden one. Checked on NEXT
      // rather than INDEX, because opening the contents replaces the whole
      // page — footer, label and all.
      await tester.tap(ctl('WEITER'));
      await tester.pump();
      expect(find.text('WEITER'), findsOneWidget);
      await _finishFlip(tester);

      await tester.tap(ctl('INHALT'));
      await tester.pump();
      expect(find.text('TABLE OF CONTENTS'), findsOneWidget);
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

      await tester.tap(ctl('NEXT'));
      await _finishFlip(tester);
      expect(flips, 1);

      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();
      expect(find.byIcon(Icons.volume_off), findsOneWidget);
      await tester.tap(ctl('PREV'));
      await tester.pump();
      await _finishFlip(tester);
      expect(flips, 1, reason: 'muted flips must not fire onPageFlip');
    });

    testWidgets('no sound object silences the book and hides the speaker',
        (tester) async {
      var flips = 0;
      // No FlipBookSound at all — silence is the absence of the object,
      // not a flag that contradicts one.
      await tester.pumpWidget(_app(footer: const FlipBookFooter()));
      expect(find.byIcon(Icons.volume_up), findsNothing);
      await tester.tap(ctl('NEXT'));
      await _finishFlip(tester);
      expect(flips, 0);

      // With the object: audible, and the speaker appears.
      await tester.pumpWidget(_app(
        footer: FlipBookFooter(
          sound: FlipBookSound(onFlip: () async => flips++),
        ),
      ));
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      await tester.tap(ctl('NEXT'));
      await _finishFlip(tester);
      expect(flips, 1);
    });

    testWidgets('custom icons replace the defaults everywhere', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          // Off so the hint's own chevrons stay out of the icon finders.
          swipe: const FlipBookSwipe(hint: null),
          header: const FlipBookHeader(closeIcon: Icons.cancel),
          footer: const FlipBookFooter(
            nav: FlipBookNavButtons(nextIcon: Icons.arrow_forward),
          ),
          readAloud: FlipBookReadAloud(
            onRead: (_) async {},
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      ));
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets(
        'CTL-01: controls are icons by default and accept any widget — a '
        'word for one, an icon for another', (tester) async {
      final done = Completer<void>();
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: const FlipBookSwipe(hint: null),
          footer: const FlipBookFooter(
            index: FlipBookIndexButton(child: Text('INDEX')),
          ),
          readAloud: FlipBookReadAloud(
            onRead: (_) => done.future,
            play: const Icon(Icons.play_circle, size: 16),
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      ));
      // Defaults are icons: NEXT is a chevron, not the word.
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.text('NEXT'), findsNothing);
      // Per-control override: play took a custom icon, index took a word.
      expect(find.byIcon(Icons.play_circle), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.text('INDEX'), findsOneWidget);
      // Semantics survive whatever the content is — a screen reader still
      // hears the control's name.
      expect(ctl('PLAY'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_circle));
      await tester.pump();
      expect(ctl('STOP'), findsOneWidget);
      done.complete();
      await tester.pump();
    });

    testWidgets(
        'CTL-02: a tapped control names itself for controlLabelFor, then '
        'the label clears', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: const FlipBookSwipe(hint: null),
          footer: FlipBookFooter(tapLabelFor: Duration(seconds: 2)),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      ));
      // Idle: no label — an icon row and nothing else.
      expect(find.text('NEXT'), findsNothing);

      await tester.tap(ctl('NEXT'));
      await tester.pump();
      // The word appears above the footer, naming what was tapped.
      expect(find.text('NEXT'), findsOneWidget);

      await _finishFlip(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('NEXT'), findsNothing, reason: 'the label retires');
    });

    testWidgets('CTL-03: Duration.zero switches the label off entirely',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: const FlipBookSwipe(hint: null),
          footer: FlipBookFooter(tapLabelFor: Duration.zero),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      ));
      await tester.tap(ctl('NEXT'));
      await tester.pump();
      expect(find.text('NEXT'), findsNothing);
      await _finishFlip(tester);
    });

    testWidgets('title prints on the page with its tagline', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          pages: FlipBookPages(items: const [
            FlipBookPage(
              title: 'The Title',
              tagline: 'the tagline',
              body: Text('the body'),
            ),
          ]),
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
          pages: FlipBookPages(items: const [
            FlipBookPage(
              title: 'Index Only',
              showTitleOnPage: false,
              body: Text('custom body'),
            ),
          ]),
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
          pages: FlipBookPages(textDirection: TextDirection.rtl, items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      ));

      await tester.tap(ctl('NEXT'));
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
          pages: FlipBookPages(
              initialPage: 99,
              onChanged: changes.add,
              items: const [
                FlipBookPage(title: 'One', body: Text('page one')),
                FlipBookPage(title: 'Two', body: Text('page two')),
                FlipBookPage(title: 'Three', body: Text('page three')),
              ]),
        ),
      ));
      expect(find.text('page three'), findsOneWidget);
      expect(changes, isEmpty, reason: 'opening is not a change');

      await tester.tap(ctl('PREV'));
      await tester.pump();
      await _finishFlip(tester);
      expect(changes, [1]);

      await tester.tap(ctl('INDEX'));
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
          pages: FlipBookPages(showNumber: true, items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      ));
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(ctl('NEXT'));
      await _finishFlip(tester);
      expect(find.text('2 / 2'), findsOneWidget);
    });

    testWidgets('shrinking the list notifies onPageChanged of the clamp',
        (tester) async {
      final changes = <int>[];
      Widget app(List<FlipBookPage> pages) => MaterialApp(
            home: FlipBook(
              onClose: () {},
              pages: FlipBookPages(
                  initialPage: 2, onChanged: changes.add, items: pages),
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

    test('a feature object defaults every field it does not receive', () {
      // The whole point of the grouped API: name one thing, keep the rest.
      const nav = FlipBookNavButtons(nextIcon: Icons.arrow_forward);
      expect(nav.nextIcon, Icons.arrow_forward);
      expect(nav.previousIcon, Icons.chevron_left, reason: 'untouched');
      expect(nav.show, isTrue);
      expect(nav.nextLabel, 'NEXT');

      const footer = FlipBookFooter(iconSize: 24);
      expect(footer.iconSize, 24);
      expect(footer.autoHide, isFalse);
      expect(footer.sound, isNull, reason: 'no sound object = silent book');
    });

    testWidgets('icons.size drives the footer chevrons and speaker',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          footer: FlipBookFooter(
            iconSize: 24,
            sound: FlipBookSound(onFlip: () async {}),
          ),
          // Off so the hint's chevron train stays out of the icon finders.
          swipe: const FlipBookSwipe(hint: null),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      ));
      expect(
        tester.widget<Icon>(find.byIcon(Icons.chevron_right)).size,
        24,
      );
      expect(tester.widget<Icon>(find.byIcon(Icons.volume_up)).size, 24);
    });

    testWidgets('close button fires onClose', (tester) async {
      var closed = false;
      await tester.pumpWidget(_app(onClose: () => closed = true));
      await tester.tap(find.byIcon(Icons.close));
      expect(closed, isTrue);
    });

    testWidgets(
        'TTS-15: the play-all button chains to the end of the book; plain '
        'play stays page-only', (tester) async {
      // Sentence-driven: each page's readable text is its one-word title,
      // so one call per page — carrying the sentence, not an index.
      final calls = <String>[];
      final completers = <Completer<void>>[];
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          readAloud: FlipBookReadAloud(
            onRead: (sentence) {
              calls.add(sentence);
              final c = Completer<void>();
              completers.add(c);
              return c.future;
            },
            playAll: true,
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
            FlipBookPage(title: 'Three', body: Text('page three')),
          ]),
        ),
      ));

      // Plain ▶ reads only the shown page — completing it advances nothing.
      await tester.tap(ctl('PLAY'));
      await tester.pump();
      expect(calls, ['One']);
      completers[0].complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('page one'), findsOneWidget);
      expect(calls, ['One'], reason: 'plain play never chains');

      // The play-all button chains: each page that finishes naturally
      // flips the book and reads on.
      await tester.tap(ctl('PLAY ALL'));
      await tester.pump();
      expect(calls, ['One', 'One']);

      completers[1].complete();
      await tester.pump();
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);
      expect(calls, ['One', 'One', 'Two']);

      completers[2].complete();
      await tester.pump();
      await _finishFlip(tester);
      expect(find.text('page three'), findsOneWidget);
      expect(calls, ['One', 'One', 'Two', 'Three']);

      // The last page finishes → the chain ends at idle, no extra call.
      completers[3].complete();
      await tester.pump();
      await tester.pump();
      expect(calls, ['One', 'One', 'Two', 'Three']);
      expect(ctl('PLAY'), findsOneWidget);
    });

    testWidgets(
        'TTS-16: stop and a manual flip both break the readAloudAdvances '
        'chain', (tester) async {
      final calls = <String>[];
      final completers = <Completer<void>>[];
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          readAloud: FlipBookReadAloud(
            onRead: (sentence) {
              calls.add(sentence);
              final c = Completer<void>();
              completers.add(c);
              return c.future;
            },
            playAll: true,
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
            FlipBookPage(title: 'Three', body: Text('page three')),
          ]),
        ),
      ));

      // Stop while page one is being play-all-read: the session dies, so
      // the app future completing later must not advance anything.
      await tester.tap(ctl('PLAY ALL'));
      await tester.pump();
      await tester.tap(ctl('STOP'));
      await tester.pump();
      completers[0].complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('page one'), findsOneWidget);
      expect(calls, ['One']);

      // A manual flip during play-all stops the voice and ends the chain —
      // the new page does not start reading by itself.
      await tester.tap(ctl('PLAY ALL'));
      await tester.pump();
      expect(calls, ['One', 'One']);
      await tester.tap(ctl('NEXT'));
      await tester.pump();
      completers[1].complete();
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);
      expect(calls, ['One', 'One']);
      expect(ctl('PLAY'), findsOneWidget);
    });

    testWidgets(
        'TTS-17: leaving the foreground stops the voice and the play-all '
        'chain', (tester) async {
      var stops = 0;
      final calls = <String>[];
      final completers = <Completer<void>>[];
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          readAloud: FlipBookReadAloud(
            onRead: (sentence) {
              calls.add(sentence);
              final c = Completer<void>();
              completers.add(c);
              return c.future;
            },
            playAll: true,
            onStop: () => stops++,
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      ));

      await tester.tap(ctl('PLAY ALL'));
      await tester.pump();
      expect(calls, ['One']);

      // The app goes to background: the package stops the reading state
      // and tells the engine to stop.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(stops, 1, reason: 'backgrounding must stop the engine');

      // The engine's future completing afterwards must not flip anything.
      completers[0].complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('page one'), findsOneWidget);
      expect(calls, ['One'], reason: 'no chain advance in the background');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(ctl('PLAY'), findsOneWidget);
    });

    testWidgets('play reads the shown page and returns to play when done',
        (tester) async {
      await tester.pumpWidget(_app());
      expect(ctl('PLAY'), findsNothing);

      String? readText;
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          readAloud: FlipBookReadAloud(
            onRead: (sentence) async => readText = sentence,
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      ));

      await tester.tap(ctl('PLAY'));
      await tester.pump();
      expect(readText, 'One');

      // The instantly-completed future returns the control to idle.
      await tester.pump();
      expect(ctl('PLAY'), findsOneWidget);
      expect(ctl('STOP'), findsNothing);

      await tester.tap(ctl('NEXT'));
      await _finishFlip(tester);
      await tester.tap(ctl('PLAY'));
      await tester.pump();
      expect(readText, 'Two');
      await tester.pump();
    });

    testWidgets('stop while playing returns to a fresh play button',
        (tester) async {
      final started = Completer<void>();
      var stopped = 0;
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          readAloud: FlipBookReadAloud(
            onRead: (_) => started.future,
            onStop: () => stopped++,
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one'))
          ]),
        ),
      ));

      await tester.tap(ctl('PLAY'));
      await tester.pump();
      // Playing without pause support: stop only.
      expect(ctl('STOP'), findsOneWidget);
      expect(ctl('PAUSE'), findsNothing);
      expect(ctl('PLAY'), findsNothing);

      await tester.tap(ctl('STOP'));
      await tester.pump();
      expect(stopped, 1);
      expect(ctl('PLAY'), findsOneWidget);
      // A stopped session's future completing later changes nothing.
      started.complete();
      await tester.pump();
      expect(ctl('STOP'), findsNothing);
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
          readAloud: FlipBookReadAloud(
            onRead: (_) => first.future,
            onPause: () => paused++,
            onResume: () {
              resumes++;
              return resumed.future;
            },
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one'))
          ]),
        ),
      ));

      await tester.tap(ctl('PLAY'));
      await tester.pump();
      // Playing with pause support: pause + stop.
      expect(ctl('PAUSE'), findsOneWidget);
      expect(ctl('STOP'), findsOneWidget);

      await tester.tap(ctl('PAUSE'));
      await tester.pump();
      expect(paused, 1);
      // Paused: RESUME + STOP.
      expect(ctl('RESUME'), findsOneWidget);
      expect(ctl('STOP'), findsOneWidget);
      expect(ctl('PAUSE'), findsNothing);

      await tester.tap(ctl('RESUME'));
      await tester.pump();
      expect(resumes, 1);
      expect(ctl('PAUSE'), findsOneWidget);

      resumed.complete();
      await tester.pump();
      await tester.pump();
      // Finished: back to the single play button.
      expect(ctl('PLAY'), findsOneWidget);
      expect(ctl('STOP'), findsNothing);
      first.complete();
    });

    testWidgets('TTS-13: speech engine failure quietly returns control to play',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          readAloud: FlipBookReadAloud(
            onRead: (_) async => throw Exception('engine down'),
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one'))
          ]),
        ),
      ));

      await tester.tap(ctl('PLAY'));
      await tester.pump();
      await tester.pump();
      expect(ctl('PLAY'), findsOneWidget);
      expect(ctl('STOP'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TTS-18: an engine failure during play-all ends the WHOLE chain — '
        'zero pages advance', (tester) async {
      // The device bug this pins down (2026-09-02): offline, every clip
      // failed instantly; 0.2.1 treated each errored page as "finished" and
      // chained forward, flipping the whole book at animation speed with no
      // quiet frame to press stop in. On 0.2.1 this test fails with calls
      // for every page and the last page on screen.
      final calls = <String>[];
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          readAloud: FlipBookReadAloud(
            onRead: (sentence) async {
              calls.add(sentence);
              throw Exception('offline');
            },
            playAll: true,
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
            FlipBookPage(title: 'Three', body: Text('page three')),
          ]),
        ),
      ));

      await tester.tap(ctl('PLAY ALL'));
      await tester.pump();
      await tester.pump();
      // Generous settling: if the chain were alive, flips would be running.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));

      expect(calls, ['One'],
          reason: 'the first failure must end the chain, not skip the page');
      expect(find.text('page one'), findsOneWidget,
          reason: 'the book must not have advanced');
      expect(find.text('page three'), findsNothing);
      expect(ctl('PLAY'), findsOneWidget,
          reason: 'back at idle — the reader is in control again');
      expect(tester.takeException(), isNull);
    });

    testWidgets('TTS-19: a failed RESUME ends the chain the same way',
        (tester) async {
      final calls = <String>[];
      final first = Completer<void>();
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          readAloud: FlipBookReadAloud(
            onRead: (sentence) {
              calls.add(sentence);
              return first.future;
            },
            onPause: () {},
            onResume: () async => throw Exception('offline'),
            playAll: true,
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      ));

      await tester.tap(ctl('PLAY ALL'));
      await tester.pump();
      await tester.tap(ctl('PAUSE'));
      await tester.pump();
      await tester.tap(ctl('PLAY'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(calls, ['One']);
      expect(find.text('page one'), findsOneWidget,
          reason: 'a resume the engine refused must not flip the book');
      expect(tester.takeException(), isNull);
    });

    testWidgets('flipping away stops an active read', (tester) async {
      final started = Completer<void>();
      var stopped = 0;
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          readAloud: FlipBookReadAloud(
            onRead: (_) => started.future,
            onStop: () => stopped++,
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      ));

      await tester.tap(ctl('PLAY'));
      await tester.pump();
      await tester.tap(ctl('NEXT'));
      await _finishFlip(tester);
      expect(stopped, 1);
      started.complete();
    });

    testWidgets('showMuteButton false keeps sound on but hides the speaker',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          footer: FlipBookFooter(
            sound: FlipBookSound(onFlip: () async {}, showMute: false),
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one'))
          ]),
        ),
      ));
      expect(find.byIcon(Icons.volume_up), findsNothing);
      expect(find.byIcon(Icons.volume_off), findsNothing);
    });
  });

  group('Scroll identity (SCR)', () {
    testWidgets(
        'SCR-01: a rebuild with recreated-but-equal pages keeps the scroll '
        'place; a flip still opens the next page at its top', (tester) async {
      // The device bug (2026-09-02): the app rebuilds its page list on every
      // state emit — saving a MARK, for one — and ObjectKey(page) read the
      // recreated object as a different page, so the scroll view was thrown
      // away and the reader landed back at the first paragraph. Pages with an
      // id are keyed by it now. On the ObjectKey code this test fails at the
      // offset assert.
      final longBody =
          List.generate(60, (i) => 'Paragraph $i line.').join('\n');
      List<FlipBookPage> pages() => [
            FlipBookPage(id: 'j1', bodySegments: [longBody]),
            const FlipBookPage(id: 'j2', bodySegments: ['Second page.']),
          ];
      Widget book() => MaterialApp(
            home: FlipBook(
              onClose: () {},
              swipe: const FlipBookSwipe(hint: null),
              pages: FlipBookPages(items: pages()),
            ),
          );

      await tester.pumpWidget(book());
      await tester.pump(const Duration(milliseconds: 400));

      final scrollable = find.byType(Scrollable).first;
      await tester.drag(scrollable, const Offset(0, -600));
      await tester.pump();
      final before = tester.state<ScrollableState>(scrollable).position.pixels;
      expect(before, greaterThan(0), reason: 'the reader has scrolled down');

      // The app's case: same content, brand-new objects.
      await tester.pumpWidget(book());
      await tester.pump();

      final after = tester.state<ScrollableState>(scrollable).position.pixels;
      expect(after, before,
          reason: 'recreated-but-equal config must not cost the reader '
              'their place');

      // The key must stay per-page: flipping forward opens page two at ITS
      // top, never inheriting page one's offset.
      await tester.fling(
          find.textContaining('Paragraph 59'), const Offset(-220, 0), 900);
      await _finishFlip(tester);
      expect(find.text('Second page.'), findsOneWidget);
      final pageTwo = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;
      expect(pageTwo, 0, reason: 'a fresh page opens at its top');
    });
  });

  group('Past the end (END)', () {
    testWidgets(
        'END-01: a forward swipe on the last page fires onFlipPastEnd; '
        'backward on page one stays meaningless; null changes nothing',
        (tester) async {
      var pastEnd = 0;
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          onFlipPastEnd: () => pastEnd++,
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 400));

      // Backward on the first page: no previous page, and no callback — the
      // hook is strictly about the END of the book.
      await tester.fling(find.text('page one'), const Offset(220, 0), 900);
      await tester.pump(const Duration(milliseconds: 400));
      expect(pastEnd, 0);

      // Forward to the last page, then forward again — THAT is the moment.
      await tester.fling(find.text('page one'), const Offset(-220, 0), 900);
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);

      await tester.fling(find.text('page two'), const Offset(-220, 0), 900);
      await tester.pump(const Duration(milliseconds: 400));
      expect(pastEnd, 1, reason: 'the impossible forward flip is the signal');
      expect(find.text('page two'), findsOneWidget,
          reason: 'the book itself still does not move');
    });

    testWidgets('END-02: without the hook, the last page still eats the swipe',
        (tester) async {
      // The default is the long-standing behaviour, byte for byte.
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
          ]),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.fling(find.text('page one'), const Offset(-220, 0), 900);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('page one'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Header close position (HDR)', () {
    testWidgets(
        'HDR-01: closeAtEnd swaps the x with the action; the default keeps '
        'the x leading', (tester) async {
      Future<(double, double)> positions(FlipBookHeader header) async {
        await tester.pumpWidget(MaterialApp(
          home: FlipBook(
            onClose: () {},
            header: header,
            pages: FlipBookPages(items: const [
              FlipBookPage(title: 'One', body: Text('page one')),
            ]),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 400));
        final close = tester.getCenter(find.byTooltip('Close')).dx;
        final action = tester.getCenter(find.byKey(const Key('act'))).dx;
        return (close, action);
      }

      const action = SizedBox(key: Key('act'), width: 24, height: 24);

      final (closeLeading, actionTrailing) =
          await positions(const FlipBookHeader(action: action));
      expect(closeLeading, lessThan(actionTrailing),
          reason: 'default: the x leads, as it always has');

      final (closeTrailing, actionLeading) = await positions(
          const FlipBookHeader(action: action, closeAtEnd: true));
      expect(closeTrailing, greaterThan(actionLeading),
          reason: 'closeAtEnd: the two swap places');
    });
  });

  group('Footer width (FTR)', () {
    testWidgets(
        'FTR-01: horizontalInset stretches the bar to the page width minus '
        'the inset; the default stays content-sized', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Future<double> barWidth(FlipBookFooter footerConfig) async {
        await tester.pumpWidget(MaterialApp(
          home: FlipBook(
            onClose: () {},
            footer: footerConfig,
            pages: FlipBookPages(items: const [
              FlipBookPage(title: 'One', body: Text('page one')),
              FlipBookPage(title: 'Two', body: Text('page two')),
            ]),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 400));
        // The bar's surface is the DecoratedBox carrying the footer colour.
        final box = find.byWidgetPredicate((w) =>
            w is DecoratedBox &&
            (w.decoration as BoxDecoration?)?.color == footerConfig.color);
        return tester.getSize(box.first).width;
      }

      final stretched =
          await barWidth(const FlipBookFooter(horizontalInset: 32));
      expect(stretched, 400 - 64,
          reason: 'the bar edges must sit exactly at the inset');

      final packed = await barWidth(const FlipBookFooter());
      expect(packed, lessThan(400 - 24),
          reason: 'without an inset the bar stays content-sized, as before');
    });
  });

  group('Chrome (auto-hide)', () {
    Widget book({
      bool footerAutoHide = true,
      bool headerAutoHide = false,
      bool showHeader = true,
      bool showFooter = true,
      Duration revealFor = const Duration(seconds: 3),
    }) {
      return MaterialApp(
        home: FlipBook(
          onClose: () {},
          header: showHeader ? FlipBookHeader(autoHide: headerAutoHide) : null,
          footer: showFooter
              ? FlipBookFooter(autoHide: footerAutoHide, revealFor: revealFor)
              : null,
          swipe: const FlipBookSwipe(hint: null),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
          ]),
        ),
      );
    }

    // Header and footer each carry an AnimatedOpacity now — resolve each
    // element's own wrap by walking up from a widget inside it.
    // Anchored on the NEXT chevron: these books set showSwipeHint: false,
    // so no other chevron is on screen to confuse the finder.
    double footerOpacity(WidgetTester tester) => tester
        .widget<AnimatedOpacity>(find
            .ancestor(
              of: find.byIcon(Icons.chevron_right),
              matching: find.byType(AnimatedOpacity),
            )
            .first)
        .opacity;

    double headerOpacity(WidgetTester tester) => tester
        .widget<AnimatedOpacity>(find
            .ancestor(
              of: find.byIcon(Icons.close),
              matching: find.byType(AnimatedOpacity),
            )
            .first)
        .opacity;

    testWidgets(
        'CHR-01: autoHide opens as a pure page; a tap reveals the footer '
        'and its buttons work', (tester) async {
      await tester.pumpWidget(book());
      expect(footerOpacity(tester), 0, reason: 'the book opens as a page');

      // A tap anywhere on the page reveals the footer.
      await tester.tap(find.text('page one'));
      await tester.pump();
      expect(footerOpacity(tester), 1);

      // The revealed footer is fully functional.
      await tester.tap(ctl('NEXT'));
      await _finishFlip(tester);
      expect(find.text('page two'), findsOneWidget);
    });

    testWidgets(
        'CHR-02: the revealed footer retires after chromeRevealFor; a '
        'second tap hides it immediately', (tester) async {
      await tester.pumpWidget(book(revealFor: const Duration(seconds: 1)));
      await tester.tap(find.text('page one'));
      await tester.pump();
      expect(footerOpacity(tester), 1);

      // Untouched, it fades away by itself.
      await tester.pump(const Duration(milliseconds: 1200));
      expect(footerOpacity(tester), 0);

      // Tap toggles: reveal, then hide on the next tap.
      await tester.tap(find.text('page one'));
      await tester.pump();
      expect(footerOpacity(tester), 1);
      await tester.tap(find.text('page one'));
      await tester.pump();
      expect(footerOpacity(tester), 0);
    });

    testWidgets('CHR-03: the default mode keeps the footer always visible',
        (tester) async {
      await tester.pumpWidget(book(footerAutoHide: false));
      expect(footerOpacity(tester), 1);

      // Taps and time change nothing.
      await tester.tap(find.text('page one'));
      await tester.pump(const Duration(seconds: 5));
      expect(footerOpacity(tester), 1);
    });

    testWidgets(
        'CHR-04: headerChrome autoHide hides the header independently; a '
        'tap reveals both, the clock retires both', (tester) async {
      await tester.pumpWidget(book(
        headerAutoHide: true,
        revealFor: const Duration(seconds: 1),
      ));
      // The header opens hidden while the footer (chrome: autoHide too in
      // this helper) is hidden as well — the page is fully bare.
      expect(headerOpacity(tester), 0);
      expect(footerOpacity(tester), 0);

      // One tap reveals every auto-hiding element at once.
      await tester.tap(find.text('page one'));
      await tester.pump();
      expect(headerOpacity(tester), 1);
      expect(footerOpacity(tester), 1);

      // The shared clock retires both.
      await tester.pump(const Duration(milliseconds: 1200));
      expect(headerOpacity(tester), 0);
      expect(footerOpacity(tester), 0);

      // Independence: footer always + header autoHide moves only the
      // header.
      await tester.pumpWidget(book(
        footerAutoHide: false,
        headerAutoHide: true,
      ));
      await tester.pump(const Duration(seconds: 4));
      expect(footerOpacity(tester), 1, reason: 'always-footer never hides');
      expect(headerOpacity(tester), 0, reason: 'auto-header stays hidden');
    });

    testWidgets(
        'CHR-05: showHeader and showFooter remove one element without the '
        'other', (tester) async {
      await tester.pumpWidget(book(showHeader: false));
      expect(find.byIcon(Icons.close), findsNothing);
      expect(ctl('NEXT'), findsOneWidget);
      expect(ctl('INDEX'), findsOneWidget);

      await tester.pumpWidget(book(showFooter: false));
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(ctl('NEXT'), findsNothing);
      expect(ctl('INDEX'), findsNothing);
      expect(ctl('PLAY'), findsNothing);
    });
  });

  group('Read marker (MRK)', () {
    // A bodyText page the book lays out itself — the markable shape. The
    // text deliberately contains pub.dev: its dot must not split it.
    const bodyText = 'pub.dev had nothing good. The curl came together. Done.';

    TextRange? markedOf(WidgetTester tester, String text) => tester
        .widgetList<MarkedText>(find.byType(MarkedText))
        .firstWhere((w) => w.text == text)
        .marked;

    Widget book(
      List<Completer<void>> completers,
      List<String> calls, {
      VoidCallback? onStop,
    }) {
      return MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: const FlipBookSwipe(hint: null),
          readAloud: FlipBookReadAloud(
            onRead: (sentence) {
              calls.add(sentence);
              final c = Completer<void>();
              completers.add(c);
              return c.future;
            },
            onStop: onStop,
            onPause: () {},
            onResume: () => Future<void>.value(),
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', bodyText: bodyText),
            FlipBookPage(title: 'Two', bodyText: 'Second page.'),
          ]),
        ),
      );
    }

    testWidgets(
        'MRK-01: the marker follows the voice sentence by sentence and '
        'never splits pub.dev', (tester) async {
      final completers = <Completer<void>>[];
      final calls = <String>[];
      await tester.pumpWidget(book(completers, calls));

      await tester.tap(ctl('PLAY'));
      await tester.pump();
      // Sentence 1 is the printed title; only the title text is marked.
      expect(calls, ['One']);
      expect(markedOf(tester, 'One'), const TextRange(start: 0, end: 3));
      expect(markedOf(tester, bodyText), isNull);

      // Two pumps: the first lets the engine future's continuation run (it
      // calls onReadAloud), the second paints the moved marker.
      completers[0].complete();
      await tester.pump();
      await tester.pump();
      // Sentence 2: the first body sentence — pub.dev's dot is followed by
      // a letter, so it is not a boundary.
      expect(calls.last, 'pub.dev had nothing good.');
      expect(markedOf(tester, 'One'), isNull);
      expect(markedOf(tester, bodyText), const TextRange(start: 0, end: 25));

      completers[1].complete();
      await tester.pump();
      await tester.pump();
      expect(calls.last, 'The curl came together.');

      completers[2].complete();
      await tester.pump();
      await tester.pump();
      expect(calls.last, 'Done.');

      // The last sentence completes → idle, marker gone.
      completers[3].complete();
      await tester.pump();
      await tester.pump();
      expect(markedOf(tester, bodyText), isNull);
      expect(ctl('PLAY'), findsOneWidget);
    });

    testWidgets('MRK-02: pause freezes the marker in place; stop clears it',
        (tester) async {
      final completers = <Completer<void>>[];
      final calls = <String>[];
      var stops = 0;
      await tester.pumpWidget(book(completers, calls, onStop: () => stops++));

      await tester.tap(ctl('PLAY'));
      await tester.pump();
      completers[0].complete();
      await tester.pump();
      await tester.pump();
      final held = markedOf(tester, bodyText);
      expect(held, isNotNull);

      // Pause: the voice stops, the marker holds its place.
      await tester.tap(ctl('PAUSE'));
      await tester.pump();
      expect(markedOf(tester, bodyText), held);

      // Resume: the interrupted sentence finishes through the resume
      // future, then the loop carries on with the next sentence.
      await tester.tap(ctl('RESUME'));
      await tester.pump();
      await tester.pump();
      expect(calls.last, 'The curl came together.');

      // Stop clears the marker entirely.
      await tester.tap(ctl('STOP'));
      await tester.pump();
      expect(stops, 1);
      expect(markedOf(tester, bodyText), isNull);
      expect(markedOf(tester, 'One'), isNull);
    });

    testWidgets('MRK-03: a page flip clears the marker and stops reading',
        (tester) async {
      final completers = <Completer<void>>[];
      final calls = <String>[];
      var stops = 0;
      await tester.pumpWidget(book(completers, calls, onStop: () => stops++));

      await tester.tap(ctl('PLAY'));
      await tester.pump();
      expect(markedOf(tester, 'One'), isNotNull);

      await tester.tap(ctl('NEXT'));
      await tester.pump();
      expect(stops, 1, reason: 'navigation must stop the engine');
      await _finishFlip(tester);
      expect(ctl('PLAY'), findsOneWidget);
      // The new page carries no marker anywhere.
      for (final w in tester.widgetList<MarkedText>(find.byType(MarkedText))) {
        expect(w.marked, isNull);
      }
      // The dead session's future completing must not restart anything.
      completers[0].complete();
      await tester.pump();
      expect(calls, ['One']);
    });

    testWidgets(
        'MRK-04: the focus style dims everything except the unit being '
        'read', (tester) async {
      const text = 'One two three.';
      await tester.pumpWidget(const MaterialApp(
        home: MarkedText(
          text: text,
          style: TextStyle(color: Colors.black, fontSize: 14),
          marked: TextRange(start: 4, end: 14),
          markerStyle: FlipBookMarkerStyle.focus,
        ),
      ));
      final span = tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
      final spans = span.children!.cast<TextSpan>();
      // [before][lit][after] — the middle span holds the full ink, the
      // outer two are faded.
      expect(spans[0].text, 'One ');
      expect(spans[1].text, 'two three.');
      expect(spans[1].style!.color!.a, 1.0, reason: 'the unit keeps full ink');
      expect(spans[0].style!.color!.a, lessThan(1.0), reason: 'rest is dimmed');
    });

    testWidgets(
        'MRK-05: bodySegments are the units — one segment, one mark, one '
        'call, and no sentence guessing inside them', (tester) async {
      final calls = <String>[];
      final completers = <Completer<void>>[];
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: const FlipBookSwipe(hint: null),
          readAloud: FlipBookReadAloud(
            onRead: (sentence) {
              calls.add(sentence);
              final c = Completer<void>();
              completers.add(c);
              return c.future;
            },
            playAll: true,
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(
              // Two sentences inside ONE segment stay together: the author
              // said this is a unit, so the book does not split it.
              bodySegments: [
                'I spent \$23.54 on SendGrid. Dr. Smith called it a bargain.',
                'The second segment.',
              ],
            ),
          ]),
        ),
      ));

      await tester.tap(ctl('PLAY'));
      await tester.pump();
      expect(
          calls,
          [
            'I spent \$23.54 on SendGrid. Dr. Smith called it a bargain.',
          ],
          reason: 'a segment is never split, however many full stops it has');

      completers[0].complete();
      await tester.pump();
      expect(calls.last, 'The second segment.');
    });

    testWidgets(
        'MRK-06: sentencesPerMark groups auto-split sentences; segments '
        'ignore it', (tester) async {
      final calls = <String>[];
      final completers = <Completer<void>>[];
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: const FlipBookSwipe(hint: null),
          readAloud: FlipBookReadAloud(
            onRead: (sentence) {
              calls.add(sentence);
              final c = Completer<void>();
              completers.add(c);
              return c.future;
            },
            unitsPerMark: 2,
          ),
          pages: FlipBookPages(items: const [
            FlipBookPage(bodyText: 'One. Two. Three. Four. Five.'),
          ]),
        ),
      ));

      await tester.tap(ctl('PLAY'));
      await tester.pump();
      expect(calls, ['One. Two.'], reason: 'two sentences per mark');

      completers[0].complete();
      await tester.pump();
      expect(calls.last, 'Three. Four.');

      completers[1].complete();
      await tester.pump();
      expect(calls.last, 'Five.', reason: 'the remainder stands alone');
    });
  });

  group('Reader marking (MRK-07..09) and speed (SPD)', () {
    Widget book({
      bool marking = true,
      List<ReaderMark> marks = const [],
      ValueChanged<List<ReaderMark>>? onMarksChanged,
      String? pageId = 'p1',
      List<String> segments = const ['One two three four five six seven.'],
      bool rtl = false,
    }) {
      return MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: const FlipBookSwipe(hint: null),
          marker: marking
              ? FlipBookMarker(marks: marks, onChanged: onMarksChanged)
              : null,
          pages: FlipBookPages(
              textDirection: rtl ? TextDirection.rtl : null,
              items: [
                FlipBookPage(
                  id: pageId,
                  bodySegments: segments,
                ),
                const FlipBookPage(id: 'p2', bodySegments: ['Second page.']),
              ]),
        ),
      );
    }

    Finder pencil() => find.byIcon(Icons.edit_outlined);
    Finder trash() => find.byIcon(Icons.delete_outline);

    testWidgets(
        'MRK-16: the lit pencil wears activeColor, not the wash made opaque',
        (tester) async {
      // The device bug (2026-09-02): the app's mark wash and its footer bar
      // are the same rose family, so the wash-made-opaque pencil VANISHED
      // into the bar the moment marking switched on. activeColor is the
      // pencil's own voice — the same parameter bookmarks earned on
      // 2026-08-23 for the same disappearance.
      const active = Color(0xFF2C1654);
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: const FlipBookSwipe(hint: null),
          marker: const FlipBookMarker(activeColor: active),
          pages: FlipBookPages(items: const [
            FlipBookPage(id: 'p1', bodySegments: ['One two three.']),
            FlipBookPage(id: 'p2', bodySegments: ['Second page.']),
          ]),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 400));

      Color pencilColor() =>
          tester.widget<Icon>(find.byIcon(Icons.edit_outlined)).color!;

      final idle = pencilColor();
      expect(idle, isNot(active), reason: 'off = the ordinary icon colour');

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      expect(pencilColor(), active,
          reason: 'on = activeColor, never the wash — a wash that matches '
              'the bar would make the pencil invisible');
    });

    testWidgets(
        'MRK-07: the pencil shows only when marking is on and the page has '
        'an id; the trash only when marks exist', (tester) async {
      await tester.pumpWidget(book(marking: false));
      expect(pencil(), findsNothing, reason: 'marking is off');

      await tester.pumpWidget(book());
      expect(pencil(), findsOneWidget);
      expect(trash(), findsNothing, reason: 'nothing saved yet');

      // A page with no id cannot carry marks, so it offers no pencil.
      await tester.pumpWidget(book(pageId: null));
      expect(pencil(), findsNothing);

      await tester.pumpWidget(book(marks: const [
        ReaderMark(pageId: 'p1', segment: 0, start: 0, end: 3),
      ]));
      expect(trash(), findsOneWidget, reason: 'a saved mark reveals the trash');
    });

    testWidgets('BMK-01: the bookmark reports the page and interrupts nothing',
        (tester) async {
      int? bookmarked;
      final c = FlipBookController();
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          controller: c,
          onClose: () {},
          swipe: const FlipBookSwipe(hint: null),
          readAloud: FlipBookReadAloud(
            onRead: (_) => Completer<void>().future,
          ),
          bookmarks: FlipBookBookmarks(onBookmark: (p) => bookmarked = p),
          pages: const FlipBookPages(showNumber: true, items: [
            FlipBookPage(id: 'a', title: 'A', bodySegments: ['One.']),
            FlipBookPage(id: 'b', title: 'B', bodySegments: ['Two.']),
          ]),
        ),
      ));

      c.jumpToPage(1);
      await tester.pump();
      await tester.tap(ctl('PLAY'));
      await tester.pump();

      await tester.tap(ctl('Carry on from here'));
      await tester.pump();

      expect(bookmarked, 1, reason: '0-based index of the page on screen');
      // Bookmarking saves a number and does nothing else: the voice must
      // still be speaking and the page must not have moved.
      expect(ctl('STOP'), findsOneWidget, reason: 'the voice kept reading');
      expect(find.text('2 / 2'), findsOneWidget, reason: 'still on page 2');
    });

    testWidgets(
        'BMK-02: saving a page reports the whole set, and a page '
        'without an id offers no save button', (tester) async {
      Set<String>? saved;
      Widget book({Set<String> initial = const {}, String? id = 'a'}) {
        return MaterialApp(
          home: FlipBook(
            onClose: () {},
            swipe: const FlipBookSwipe(hint: null),
            bookmarks: FlipBookBookmarks(
              saved: initial,
              onSavedChanged: (s) => saved = s,
            ),
            pages: FlipBookPages(items: [
              FlipBookPage(id: id, title: 'A', bodySegments: const ['One.']),
            ]),
          ),
        );
      }

      await tester.pumpWidget(book());
      await tester.tap(ctl('Save this page'));
      await tester.pump();
      expect(saved, {'a'});

      // Already saved → the button offers the opposite, and removing it
      // reports the set without it rather than a "removed" event.
      await tester.pumpWidget(book(initial: const {'a'}));
      await tester.tap(ctl('Remove this page'));
      await tester.pump();
      expect(saved, isEmpty);

      // No id, no save: there would be nothing to remember the page by.
      await tester.pumpWidget(book(id: null));
      expect(ctl('Save this page'), findsNothing);
    });

    testWidgets(
        'EXP-01: the export button appears only with an export '
        'object, and each choice carries the right pages', (tester) async {
      FlipBookExportKind? kind;
      List<FlipBookExportEntry>? got;
      Widget book({bool withExport = true}) {
        return MaterialApp(
          home: FlipBook(
            onClose: () {},
            swipe: const FlipBookSwipe(hint: null),
            bookmarks: const FlipBookBookmarks(saved: {'b'}),
            marker: const FlipBookMarker(marks: [
              ReaderMark(
                pageId: 'c',
                segment: 0,
                start: 0,
                end: 5,
                text: 'Three',
              ),
            ]),
            contents: withExport
                ? FlipBookContents(
                    export: FlipBookExport(onExport: (k, e) {
                      kind = k;
                      got = e;
                    }),
                  )
                : const FlipBookContents(),
            pages: const FlipBookPages(items: [
              FlipBookPage(id: 'a', title: 'A', bodySegments: ['One.']),
              FlipBookPage(id: 'b', title: 'B', bodySegments: ['Two.']),
              FlipBookPage(id: 'c', title: 'C', bodySegments: ['Three four.']),
            ]),
          ),
        );
      }

      // No export object → no button, even inside the contents.
      await tester.pumpWidget(book(withExport: false));
      await tester.tap(ctl('INDEX'));
      await tester.pumpAndSettle();
      expect(ctl('Export'), findsNothing);

      await tester.pumpWidget(book());
      await tester.tap(ctl('Export'));
      await tester.pumpAndSettle();

      // Saved pages: only page 2, and it carries its full text.
      await tester.tap(find.text('Pages I saved'));
      await tester.pumpAndSettle();
      expect(kind, FlipBookExportKind.savedPages);
      expect(got!.length, 1);
      expect(got!.single.number, 2, reason: '1-based, like the footer');
      expect(got!.single.title, 'B');
      expect(got!.single.body, ['Two.']);

      // Marked text: only page 3, and ONLY what was marked — shipping the
      // whole page too would defeat the point of choosing.
      await tester.tap(ctl('Export'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Passages I marked'));
      await tester.pumpAndSettle();
      expect(kind, FlipBookExportKind.markedText);
      expect(got!.single.number, 3);
      expect(got!.single.marks, ['Three']);
      expect(got!.single.body, isEmpty);

      // The whole book: every page, in reading order.
      await tester.tap(ctl('Export'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('The whole book'));
      await tester.pumpAndSettle();
      expect(kind, FlipBookExportKind.wholeBook);
      expect(got!.map((e) => e.number), [1, 2, 3]);
    });

    testWidgets(
        'MRK-14: the finger lands on the character it is over, even when the '
        'ambient text style supplies part of the type', (tester) async {
      // The device bug this guards. `Text(style: s)` MERGES the ambient
      // DefaultTextStyle — under Material that is `bodyMedium`, and it is
      // where the family, the size and the letter spacing come from. A
      // TextPainter built from the same `s` merges nothing. Feed the painter
      // the unmerged style and it lays the text out in different type from
      // what is on screen, so every character lookup is off: a drag stops
      // inside a word, the band paints in the wrong place, and auto-scroll
      // follows the wrong line.
      //
      // Probed on the real tree, the two were:
      //   on screen : Roboto 14, letterSpacing 0.3, height 1.4
      //   painter   : no family, no size, no letter spacing
      // Here the theme makes the gap large enough to measure.
      const body = 'alpha domain bravo charlie delta echo foxtrot';
      List<ReaderMark>? saved;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          // Far enough from the painter's own fallback that a mismatch
          // cannot hide inside one word.
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 40, color: Colors.black),
          ),
        ),
        home: FlipBook(
          onClose: () {},
          swipe: const FlipBookSwipe(hint: null),
          marker: FlipBookMarker(marks: const [], onChanged: (m) => saved = m),
          pages: const FlipBookPages(
            // Carries NO size on purpose — the ambient style supplies it,
            // exactly as a real app's theme does.
            style: FlipBookPageStyle(bodyStyle: TextStyle(color: Colors.black)),
            items: [
              FlipBookPage(id: 'p1', bodySegments: [body])
            ],
          ),
        ),
      ));

      await tester.tap(pencil());
      await tester.pump();

      final rect = tester.getRect(find.text(body));
      // Stay on the FIRST line: at 40 the text wraps, at 14 it does not, and
      // that difference is the whole point.
      const lineY = 5.0;
      final y = rect.top + lineY;
      final draggedTo = rect.width * 0.84;
      final gesture = await tester.startGesture(Offset(rect.left + 4, y));
      await tester.pump();
      await gesture.moveTo(Offset(rect.left + 60, y));
      await tester.pump();
      await gesture.moveTo(Offset(rect.left + draggedTo, y));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      await tester.tap(ctl('SAVE'));
      await tester.pump();

      // Which CHARACTER the finger was really over, measured with the type
      // the screen TRULY paints in. It must be resolved the same way
      // Flutter resolves it — ambient DefaultTextStyle merged with the
      // widget's own style. Reading `Text.style` alone is not enough: that
      // is the *unresolved* style, so when the bug is present it matches the
      // painter's wrong style and the assertion passes on broken code.
      // Character space, not pixels: line wrapping cannot distort it.
      final element = find.text(body).evaluate().first;
      final rendered = DefaultTextStyle.of(element)
          .style
          .merge(tester.widget<Text>(find.text(body)).style);
      final onScreen = TextPainter(
        text: TextSpan(text: body, style: rendered),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width);
      final underFinger =
          onScreen.getPositionForOffset(Offset(draggedTo, 3)).offset;
      onScreen.dispose();

      // Word snapping moves the edge by at most one word, so the saved
      // range must land within a word's width of the finger — a mismatched
      // painter font puts it tens of characters away.
      expect((saved!.single.end - underFinger).abs(), lessThan(12),
          reason: 'the painter and the rendered Text must use the SAME '
              'resolved style, or every character lookup is wrong');
    });

    testWidgets(
        'MRK-13: the SAVE/CANCEL row sits ABOVE the marked words, never '
        'over them', (tester) async {
      // A block tall enough to have room on both sides of the mark, so the
      // preferred side is the one actually chosen.
      const long = 'Alpha bravo charlie delta echo foxtrot golf hotel india '
          'juliett kilo lima mike november oscar papa quebec romeo sierra '
          'tango uniform victor whiskey xray yankee zulu one two three four '
          'five six seven eight nine ten eleven twelve thirteen fourteen.';
      await tester.pumpWidget(book(segments: const [long]));

      await tester.tap(pencil());
      await tester.pump();

      // Drag in the MIDDLE of the paragraph, so there is room on BOTH
      // sides. A mark on the last line would pick "above" under either
      // rule, and would prove nothing.
      final text = find.text(long);
      final box = tester.getRect(text);
      final markY = box.center.dy;
      final gesture = await tester.startGesture(Offset(box.left + 20, markY));
      await gesture.moveTo(Offset(box.left + 90, markY));
      await gesture.up();
      // Two frames: the block measures the mark during layout and reports it
      // afterwards, so the row is placed on the frame after the drag ends.
      await tester.pump();
      await tester.pump();

      expect(ctl('SAVE'), findsOneWidget);
      expect(
        tester.getRect(ctl('SAVE')).bottom,
        lessThanOrEqualTo(markY),
        reason: 'the row must rest above the marked words, not cover them',
      );
      // There is deliberately no assertion that the row stays inside the
      // block: it is drawn at page level, and confining it to the block is
      // what would push it onto the marked words.
      await tester.tap(ctl('SAVE'));
      await tester.pump();
      expect(ctl('SAVE'), findsNothing, reason: 'the row was really tappable');
    });

    testWidgets(
        'MRK-15: a drag DOWN across lines inside one segment marks every '
        'line it crosses', (tester) async {
      // Answers a direct question: is marking limited to one line? Inside a
      // single segment it is not — the drag is followed down the wrapped
      // lines. What a mark cannot cross is a SEGMENT boundary, because a
      // ReaderMark carries exactly one segment index.
      const long = 'Alpha bravo charlie delta echo foxtrot golf hotel india '
          'juliett kilo lima mike november oscar papa quebec romeo sierra '
          'tango uniform victor whiskey xray yankee zulu one two three four '
          'five six seven eight nine ten eleven twelve thirteen fourteen.';
      List<ReaderMark>? saved;
      await tester.pumpWidget(
        book(segments: const [long], onMarksChanged: (m) => saved = m),
      );

      await tester.tap(pencil());
      await tester.pump();

      final box = tester.getRect(find.text(long));
      // Start on the first line, finish two lines lower.
      final gesture =
          await tester.startGesture(Offset(box.left + 10, box.top + 8));
      await gesture.moveTo(Offset(box.left + 120, box.top + 8));
      await gesture.moveTo(Offset(box.right - 20, box.top + 60));
      await gesture.up();
      await tester.pump();
      await tester.pump();

      await tester.tap(ctl('SAVE'));
      await tester.pump();

      expect(saved, isNotNull);
      final mark = saved!.single;
      // A single wrapped line of this block is far shorter than this; a mark
      // spanning ~two lines has to be well over 60 characters.
      expect(
        mark.end - mark.start,
        greaterThan(60),
        reason: 'the mark must follow the drag onto the lines below',
      );
    });

    testWidgets(
        'MRK-16: under RTL the keep/discard row stays ON SCREEN, anchored to '
        'the right', (tester) async {
      // Under RTL the row must stay fully on screen. Anchors pinned to
      // topLeft while the child aligns to the start corner — the right, in
      // RTL — disagree and push the row out of view, leaving only the cross
      // reachable.
      const arabic = 'مرحبا بالعالم من هذه الصفحة العربية الطويلة نسبيا';
      await tester.pumpWidget(book(segments: const [arabic], rtl: true));

      await tester.tap(pencil());
      await tester.pump();

      final box = tester.getRect(find.text(arabic));
      final markY = box.center.dy;
      final gesture = await tester.startGesture(Offset(box.right - 20, markY));
      await gesture.moveTo(Offset(box.right - 120, markY));
      await gesture.up();
      await tester.pump();
      await tester.pump();

      expect(ctl('SAVE'), findsOneWidget);
      final row = tester.getRect(ctl('SAVE'));
      final screen = tester.getRect(find.byType(FlipBook));
      expect(row.left, greaterThanOrEqualTo(screen.left),
          reason: 'the row must not hang off the left edge');
      expect(row.right, lessThanOrEqualTo(screen.right),
          reason: 'the row must not hang off the RIGHT edge — the bug');
      // Both controls reachable, not just the one that happened to fit.
      expect(ctl('CANCEL'), findsOneWidget);
      final cancel = tester.getRect(ctl('CANCEL'));
      expect(cancel.right, lessThanOrEqualTo(screen.right));
    });

    testWidgets(
        'MRK-14: a mark in a SHORT paragraph is still not covered — the row '
        'is not confined to the block', (tester) async {
      // One short line is barely taller than the 44-point control row, so a
      // placement clamped inside the block has nowhere to put the row except
      // on the marked words — which is why the row lives at page level.
      const short = 'Alpha bravo charlie delta.';
      await tester.pumpWidget(book(segments: const [short]));

      await tester.tap(pencil());
      await tester.pump();

      final text = find.text(short);
      final box = tester.getRect(text);
      final markY = box.center.dy;
      final gesture = await tester.startGesture(Offset(box.left + 4, markY));
      await gesture.moveTo(Offset(box.left + 60, markY));
      await gesture.up();
      await tester.pump();
      await tester.pump();

      expect(ctl('SAVE'), findsOneWidget);
      expect(
        tester.getRect(ctl('SAVE')).overlaps(box),
        isFalse,
        reason: 'the row must clear the marked words even in a short block',
      );
      // Still reachable: a row nobody can tap is not a fix.
      await tester.tap(ctl('SAVE'));
      await tester.pump();
      expect(ctl('SAVE'), findsNothing);
    });

    testWidgets(
        'MRK-08: a drag while marking produces a word-snapped draft, SAVE '
        'reports it, CANCEL drops it', (tester) async {
      List<ReaderMark>? saved;
      await tester.pumpWidget(book(onMarksChanged: (m) => saved = m));

      // Idle: no Save/Cancel row.
      expect(ctl('SAVE'), findsNothing);

      await tester.tap(pencil());
      await tester.pump();

      // Drag across the first words of the body.
      final text = find.text('One two three four five six seven.');
      await tester.drag(text, const Offset(60, 0));
      // Second frame: the block reports the mark's rectangle after layout,
      // and the page draws the row from it.
      await tester.pump();
      await tester.pump();
      expect(ctl('SAVE'), findsOneWidget);
      expect(ctl('CANCEL'), findsOneWidget);

      await tester.tap(ctl('CANCEL'));
      await tester.pump();
      expect(ctl('SAVE'), findsNothing, reason: 'the draft is dropped');
      expect(saved, isNull, reason: 'cancel never reports a mark');

      // Cancel turns marking OFF as well. Marking owns the horizontal drag,
      // so a cancel that left the mode on would keep every swipe marking and
      // the page could never be turned.
      expect(saved, isNull);
      await tester.drag(text, const Offset(60, 0));
      await tester.pump();
      await tester.pump();
      expect(ctl('SAVE'), findsNothing,
          reason: 'marking is off, so a drag no longer marks');

      // Marking again costs one tap on the pencil — and the SAME range still
      // brings the row back, which is what caught the stale-rectangle guard.
      await tester.tap(pencil());
      await tester.pump();
      await tester.drag(text, const Offset(60, 0));
      await tester.pump();
      await tester.pump();
      expect(ctl('SAVE'), findsOneWidget);
      await tester.tap(ctl('SAVE'));
      await tester.pump();

      expect(saved, isNotNull);
      expect(saved!.length, 1);
      final mark = saved!.single;
      expect(mark.pageId, 'p1');
      expect(mark.end, greaterThan(mark.start));

      // Word snapping is the guarantee: a drag that lands mid-word grows
      // outward, so a mark never begins or ends inside one.
      const body = 'One two three four five six seven.';
      final startsClean = mark.start == 0 || body[mark.start - 1] == ' ';
      final endsClean = mark.end == body.length || body[mark.end] == ' ';
      expect(startsClean, isTrue, reason: 'start snapped to a word edge');
      expect(endsClean, isTrue, reason: 'end snapped to a word edge');
      expect(mark.text, body.substring(mark.start, mark.end).trim());
      expect(ctl('SAVE'), findsNothing, reason: 'saving leaves the mode');
    });

    testWidgets(
        'MRK-10: readTitle/readTagline/readBody choose what is spoken — and '
        'therefore what dims', (tester) async {
      final calls = <String>[];
      final completers = <Completer<void>>[];
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: const FlipBookSwipe(hint: null),
          readAloud: FlipBookReadAloud(
            onRead: (unit) {
              calls.add(unit);
              final c = Completer<void>();
              completers.add(c);
              return c.future;
            },
            // The title is on the page but out of the performance.
            readTitle: false,
          ),
          pages: const FlipBookPages(items: [
            FlipBookPage(
              title: 'One',
              tagline: 'A tagline.',
              bodySegments: ['The body.'],
            ),
          ]),
        ),
      ));

      await tester.tap(ctl('PLAY'));
      await tester.pump();
      expect(calls, ['A tagline.'], reason: 'the title is skipped entirely');

      completers[0].complete();
      await tester.pump();
      await tester.pump();
      expect(calls.last, 'The body.');

      // And the excluded title must not FADE either. It is outside the
      // performance, so it keeps full ink while the body speaks — dimming
      // it would tell the reader it is waiting its turn, and it never gets
      // one.
      final title = tester
          .widgetList<MarkedText>(find.byType(MarkedText))
          .firstWhere((w) => w.text == 'One');
      expect(title.dimmed, isFalse, reason: 'a part never read never dims');

      final tagline = tester
          .widgetList<MarkedText>(find.byType(MarkedText))
          .firstWhere((w) => w.text == 'A tagline.');
      expect(tagline.dimmed, isTrue,
          reason: 'a part that IS read recedes while another speaks');
    });

    testWidgets(
        'MRK-11: a title can be READ yet never fade — it stays the page\'s '
        'anchor instead of flickering', (tester) async {
      final calls = <String>[];
      final completers = <Completer<void>>[];
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: const FlipBookSwipe(hint: null),
          readAloud: FlipBookReadAloud(
            onRead: (unit) {
              calls.add(unit);
              final c = Completer<void>();
              completers.add(c);
              return c.future;
            },
            readTitle: true, // spoken in its turn…
            fadeTitle: false, // …but never recedes afterwards
          ),
          pages: const FlipBookPages(items: [
            FlipBookPage(
              title: 'One.',
              bodySegments: ['The body.'],
            ),
          ]),
        ),
      ));

      MarkedText block(String text) => tester
          .widgetList<MarkedText>(find.byType(MarkedText))
          .firstWhere((w) => w.text == text);

      await tester.tap(ctl('PLAY'));
      await tester.pump();
      expect(calls, ['One.'], reason: 'the title is still read');

      completers[0].complete();
      await tester.pump();
      await tester.pump();
      expect(calls.last, 'The body.');
      expect(block('One.').dimmed, isFalse,
          reason: 'read, but fadeTitle: false keeps it at full ink');
    });

    testWidgets(
        'SPD-02: only the speeds in options appear, and the chosen one is '
        'more than a bolder weight', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FlipBook(
          onClose: () {},
          swipe: const FlipBookSwipe(hint: null),
          readAloud: FlipBookReadAloud(
            onRead: (_) => Completer<void>().future,
            speed: const FlipBookSpeedControl(
              options: [FlipBookReadSpeed.slow, FlipBookReadSpeed.normal],
              initial: FlipBookReadSpeed.slow,
            ),
          ),
          pages: const FlipBookPages(items: [FlipBookPage(bodyText: 'Body.')]),
        ),
      ));
      // The pace lives on the voice row, and that row only carries it while
      // the voice is speaking.
      await tester.tap(ctl('PLAY'));
      await tester.pump();
      expect(find.text('0.5x'), findsOneWidget);
      expect(find.text('1x'), findsOneWidget);
      expect(find.text('1.5x'), findsNothing, reason: 'not in options');

      // The chosen speed sits on a filled pill, not just heavier type.
      expect(
        find.ancestor(
          of: find.text('0.5x'),
          matching: find.byType(DecoratedBox),
        ),
        findsWidgets,
      );

      // Tapping it names itself, like every other control.
      await tester.tap(find.text('1x'));
      await tester.pump();
      expect(find.text('1x speed'), findsOneWidget);
    });

    testWidgets(
        'MRK-18: turning the page ends marking mode and drops the draft',
        (tester) async {
      // Marking belongs to the page it was started on. A pencil still lit
      // after the page turns — most visible during PLAY ALL, where the book
      // turns its own pages — keeps a mode the reader never asked for, and
      // an unsaved draft would outlive the text it points at.
      List<ReaderMark>? saved;
      await tester.pumpWidget(book(onMarksChanged: (m) => saved = m));

      await tester.tap(pencil());
      await tester.pump();
      await tester.drag(
          find.text('One two three four five six seven.'), const Offset(60, 0));
      await tester.pump();
      await tester.pump();
      expect(ctl('SAVE'), findsOneWidget, reason: 'a draft is in progress');

      // Marking blocks swiping, so drive the flip with the buttons.
      await tester.tap(ctl('NEXT'), warnIfMissed: false);
      await _finishFlip(tester);

      expect(ctl('SAVE'), findsNothing,
          reason: 'the draft belonged to the page that is gone');
      expect(saved, isNull, reason: 'an abandoned draft is never saved');
      // Marking is off, so the swipe hint and swiping are available again.
      expect(trash(), findsNothing);
    });

    testWidgets('MRK-17: the trash appears only on a page that HAS marks',
        (tester) async {
      // The trash clears the shown page only, so its visibility must match:
      // a mark on page 3 must not light the trash on page 2 and offer to
      // "clear marked text" where there is none.
      await tester.pumpWidget(book(
        marks: const [ReaderMark(pageId: 'p2', segment: 0, start: 0, end: 6)],
      ));
      expect(trash(), findsNothing,
          reason: 'page p1 holds no marks, so it gets no trash');

      // The book's second page is p2, which does hold one.
      await tester.fling(find.byType(FlipBook), const Offset(-220, 0), 900);
      await _finishFlip(tester);
      expect(trash(), findsOneWidget,
          reason: 'p2 holds a mark, so the trash belongs here');
    });

    testWidgets(
        'MRK-09: the trash clears THIS page only, and reports the survivors',
        (tester) async {
      // A trash button drawn on a page means that page: clearing must never
      // reach the marks on a page the reader is not looking at.
      List<ReaderMark>? saved;
      await tester.pumpWidget(book(
        marks: const [
          ReaderMark(pageId: 'p1', segment: 0, start: 0, end: 3),
          ReaderMark(pageId: 'p2', segment: 0, start: 0, end: 6),
        ],
        onMarksChanged: (m) => saved = m,
      ));
      await tester.tap(trash());
      await tester.pump();

      expect(saved, isNotNull);
      expect(saved!.map((m) => m.pageId), isNot(contains('p1')),
          reason: 'the shown page loses its marks');
      expect(saved!.map((m) => m.pageId), contains('p2'),
          reason: 'every OTHER page keeps its own — this is the bug');
      expect(saved!.length, 1);
    });

    testWidgets(
        'SPD-01: the speed control shows only with read-aloud wired and '
        'reports the reader\'s choice', (tester) async {
      FlipBookReadSpeed? picked;
      Widget speedBook({
        required bool show,
        bool withVoice = true,
        FlipBookReadSpeed speed = FlipBookReadSpeed.normal,
      }) {
        return MaterialApp(
          home: FlipBook(
            onClose: () {},
            swipe: const FlipBookSwipe(hint: null),
            readAloud: withVoice
                ? FlipBookReadAloud(
                    // Never completes, so the book stays in the playing
                    // phase — which is the only phase that shows the pace.
                    onRead: (_) => Completer<void>().future,
                    onPause: () {},
                    onResume: () => Completer<void>().future,
                    speed: show
                        ? FlipBookSpeedControl(
                            initial: speed,
                            onChanged: (s) => picked = s,
                          )
                        : null,
                  )
                : null,
            pages:
                FlipBookPages(items: const [FlipBookPage(bodyText: 'Body.')]),
          ),
        );
      }

      // No tap here: pumpWidget keeps the same State, so a reading started
      // in one case would still be running in the next.
      await tester.pumpWidget(speedBook(show: false));
      expect(find.text('0.5x'), findsNothing, reason: 'opt-in');

      // No voice wired → no speed control, however the flag is set.
      await tester.pumpWidget(speedBook(show: true, withVoice: false));
      expect(find.text('0.5x'), findsNothing);

      // Wired but SILENT: the pace stays hidden. There is nothing to be
      // fast or slow about until a voice is actually speaking.
      await tester.pumpWidget(speedBook(show: true));
      expect(find.text('0.5x'), findsNothing, reason: 'idle hides the pace');

      await tester.tap(ctl('PLAY'));
      await tester.pump();
      // Multipliers, not words: they say what they do in every language
      // and take a third of the width.
      expect(find.text('0.5x'), findsOneWidget);
      expect(find.text('1x'), findsOneWidget);
      expect(find.text('1.5x'), findsOneWidget);

      await tester.tap(find.text('1.5x'));
      await tester.pump();
      expect(picked, FlipBookReadSpeed.fast);

      // Paused is not playing, so the pace goes away again.
      await tester.tap(ctl('PAUSE'));
      await tester.pump();
      expect(find.text('0.5x'), findsNothing, reason: 'paused hides the pace');

      // The chosen one is styled differently from the rest.
      await tester
          .pumpWidget(speedBook(show: true, speed: FlipBookReadSpeed.fast));
      await tester.tap(ctl('PLAY'));
      await tester.pump();
      final fast = tester.widget<Text>(find.text('1.5x')).style!;
      final slow = tester.widget<Text>(find.text('0.5x')).style!;
      expect(fast.fontWeight, isNot(slow.fontWeight));
    });
  });

  group('FlipBookController', () {
    Widget app(FlipBookController controller, {bool showControls = false}) {
      return MaterialApp(
        home: FlipBook(
          controller: controller,
          // No footer object = a chrome-free book driven by the controller.
          footer: showControls ? const FlipBookFooter() : null,
          header: showControls ? const FlipBookHeader() : null,
          onClose: () {},
          pages: FlipBookPages(items: const [
            FlipBookPage(title: 'One', body: Text('page one')),
            FlipBookPage(title: 'Two', body: Text('page two')),
            FlipBookPage(title: 'Three', body: Text('page three')),
          ]),
        ),
      );
    }

    testWidgets('showControls false renders no buttons at all', (tester) async {
      await tester.pumpWidget(app(FlipBookController()));
      expect(find.text('page one'), findsOneWidget);
      expect(ctl('NEXT'), findsNothing);
      expect(ctl('INDEX'), findsNothing);
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
      FlipBookPages pages = const FlipBookPages(items: [
        FlipBookPage(title: 'One', body: Text('page one')),
        FlipBookPage(title: 'Two', body: Text('page two')),
        FlipBookPage(title: 'Three', body: Text('page three')),
      ]),
      FlipBookController? controller,
      FlipSpeed speed = FlipSpeed.medium,
      Future<void> Function(String)? onReadAloud,
    }) {
      return MaterialApp(
        home: FlipBook(
          controller: controller,
          flipSpeed: speed,
          readAloud: onReadAloud == null
              ? null
              : FlipBookReadAloud(onRead: onReadAloud),
          onClose: () {},
          pages: pages,
        ),
      );
    }

    testWidgets('EDG-01: an empty pages list renders without crashing',
        (tester) async {
      await tester.pumpWidget(book(pages: FlipBookPages(items: const [])));
      expect(tester.takeException(), isNull);
      expect(ctl('NEXT'), findsNothing);
      expect(ctl('INDEX'), findsNothing);
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
        pages: FlipBookPages(
            items: const [FlipBookPage(title: 'One', body: Text('page one'))]),
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

      await tester.tap(ctl('NEXT'));
      // Pump only as long as the FAST flip needs; a stale slow duration
      // would leave the animation unfinished and this expectation failing.
      await _finishFlip(tester, speed: FlipSpeed.fast);
      expect(find.text('page two'), findsOneWidget);
    });

    testWidgets('EDG-04: jumpToPage during a flip wins over the animation',
        (tester) async {
      final controller = FlipBookController();
      await tester.pumpWidget(book(controller: controller));

      await tester.tap(ctl('NEXT'));
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

      await tester.tap(ctl('NEXT'));
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

      await tester.tap(ctl('PLAY'));
      await tester.tap(ctl('PLAY'), warnIfMissed: false);
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
              onClose: () {},
              pages: FlipBookPages(items: const [
                FlipBookPage(title: 'A1', body: Text('book A'))
              ]),
            ),
          );
      Widget bookB() => SizedBox(
            width: 300,
            height: 500,
            child: FlipBook(
              controller: controller,
              onClose: () {},
              pages: FlipBookPages(items: const [
                FlipBookPage(title: 'B1', body: Text('book B one')),
                FlipBookPage(title: 'B2', body: Text('book B two')),
              ]),
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

      expect(ctl('INDEX'), findsOneWidget);
      expect(ctl('NEXT'), findsOneWidget);
      expect(ctl('Read this page aloud'), findsOneWidget);
      expect(ctl('Close'), findsOneWidget);

      await tester.tap(ctl('NEXT'));
      await _finishFlip(tester);
      expect(ctl('PREV'), findsOneWidget);
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
          onClose: () {},
          pages: FlipBookPages(items: const [
            FlipBookPage(
              title: 'A fairly long chapter title that wraps',
              tagline: 'and a descriptive tagline underneath that also wraps',
              body: Text('short body'),
            ),
          ]),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TOC-07: duplicate titles keep their own pages; whitespace-only '
        'titles stay out of the TOC', (tester) async {
      await tester.pumpWidget(book(
          pages: FlipBookPages(items: const [
        FlipBookPage(title: 'Same', body: Text('first same')),
        FlipBookPage(title: '   ', body: Text('whitespace page')),
        FlipBookPage(title: 'Same', body: Text('second same')),
      ])));

      await tester.tap(ctl('INDEX'));
      await tester.pump();
      expect(find.text('Same'), findsNWidgets(2));

      await tester.tap(find.text('Same').last);
      await tester.pump();
      expect(find.text('second same'), findsOneWidget);
    });
  });
}
