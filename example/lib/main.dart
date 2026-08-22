import 'package:flutter/material.dart';
import 'package:page_curl_flip/page_curl_flip.dart';

import 'ltr_book.dart';
import 'rtl_book.dart';
import 'shared_pages.dart';
import 'stores.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Marks and places are read back BEFORE the first frame, so the book opens
  // at the bookmark instead of jumping to it a moment later.
  await Persist.init();
  runApp(const ExampleApp());
}

/// Two books, named by reading direction: LTR ([LtrBook]) and RTL
/// ([RtlBook]) — one dressed head to toe, one close to the package's
/// defaults, so the two can be compared.
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'page_curl_flip example',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

/// The cover of the magazine: one block per edition, and the one place the
/// package's THIRD entry point is shown — tapping an edition peels the cover
/// away with [PageCurlRoute].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget book, {required bool mirror}) {
    Navigator.of(context).push(
      PageCurlRoute<void>(
        builder: (_) => book,
        // The cover itself is what curls away, so opening a book looks like
        // opening a book.
        coverChild: const _Cover(),
        pageColor: kStock,
        shine: 0.55,
        // Passed explicitly, NOT left to the ambient Directionality.
        //
        // This screen is LTR — the Arabic direction only exists inside the
        // Arabic book, which has not been built yet when the route starts.
        // So `Directionality.of(context)` here says left-to-right for BOTH
        // editions, and the Arabic cover peeled the same way as the English
        // one. The caller knows which book it is
        // opening; the route cannot.
        //
        // Closing follows automatically: the pop reverses this same curl.
        mirror: mirror,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kStock,
        body: Stack(
          children: [
            const Positioned.fill(child: _Cover()),
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 0, 26, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      _Edition(
                        kicker: 'LTR',
                        title: 'ENGLISH\nEDITION',
                        line: 'Three pages. Every feature the package has.',
                        color: kTeal,
                        onTap: () => _open(context, const LtrBook(), mirror: false),
                      ),
                      const SizedBox(height: 14),
                      _Edition(
                        kicker: 'RTL',
                        title: 'الطبعة\nالعربية',
                        line: 'The same book, mirrored, plus a settings page.',
                        color: kPink,
                        textDirection: TextDirection.rtl,
                        onTap: () => _open(context, const RtlBook(), mirror: true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

/// The masthead and the paper it sits on. Reused as the curling cover, so the
/// page that peels away is the page you were just looking at.
class _Cover extends StatelessWidget {
  const _Cover();

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned.fill(child: ColoredBox(color: kStock)),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 54, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAGE\nCURL\nFLIP',
                      style: const TextStyle(
                        fontSize: 58,
                        height: 0.92,
                        letterSpacing: -2.6,
                        fontWeight: FontWeight.w900,
                        color: kPink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(width: 64, height: 5, color: kTeal),
                    const SizedBox(height: 14),
                    const Text(
                      'A REALISTIC PAGE CURL FOR FLUTTER · ZERO DEPENDENCIES',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.4,
                        height: 1.6,
                        fontWeight: FontWeight.w800,
                        color: kInkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

/// One edition block. A colour block that runs the full measure, the way the
/// magazine's quotes do — not a card floating on a background.
class _Edition extends StatelessWidget {
  const _Edition({
    required this.kicker,
    required this.title,
    required this.line,
    required this.color,
    required this.onTap,
    this.textDirection,
  });

  final String kicker;
  final String title;
  final String line;
  final Color color;
  final VoidCallback onTap;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final block = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 3,
              fontWeight: FontWeight.w800,
              color: kOnColourDim,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 30,
              height: 1.0,
              letterSpacing: -1.0,
              fontWeight: FontWeight.w900,
              color: kOnColour,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            line,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: kOnColourDim,
            ),
          ),
        ],
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: kOnColour.withValues(alpha: 0.14),
        child: textDirection == null
            ? block
            : Directionality(textDirection: textDirection!, child: block),
      ),
    );
  }
}
