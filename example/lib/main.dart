import 'dart:async' show unawaited;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:page_curl_flip/page_curl_flip.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() => runApp(const ExampleApp());

/// Two books, named by reading direction: LTR and RTL.
///
/// Both show the same four screens — plain, notebook, kids, magazine — and
/// the RTL book adds one extra screen (voice setup). The content of every
/// page is the package describing its own customization.
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

/// The menu: one tile per book.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('page_curl_flip')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DemoTile(
            title: 'LTR',
            subtitle: 'four screens — swipe or use the arrows',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const LtrBook())),
          ),
          _DemoTile(
            title: 'RTL',
            subtitle:
                'the same book in Arabic and Hebrew, mirrored, '
                'plus a voice-setup screen',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const RtlBook())),
          ),
        ],
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// ── The story the pages tell ──────────────────────────────────────────────────
// Every page carries the same short text about customization, in the page's
// own language.

const _aboutEn =
    'page_curl_flip brings a real paper page-turn to Flutter.\n'
    'Each page curls, bends and falls with natural lighting and depth.\n'
    'Built with zero dependencies — a clean skeleton for any app.\n\n'
    '•  Swipe or tap to turn the page\n'
    '•  Read-aloud voice on every page\n'
    '•  Flip sound through your own audio\n'
    '•  Full LTR and RTL support\n\n'
    'Every widget is fully customizable.';

const _aboutAr =
    'يجلب page_curl_flip قلب الصفحات الورقي الحقيقي إلى Flutter.\n'
    'كل صفحة تنحني وتنقلب وتهبط بإضاءة وعمق طبيعيين.\n'
    'مبني بلا أي تبعيات — هيكل نظيف لأي تطبيق.\n\n'
    '•  اسحب أو اضغط لقلب الصفحة\n'
    '•  قراءة صوتية في كل صفحة\n'
    '•  صوت القلب عبر مشغّلك الصوتي\n'
    '•  دعم كامل للاتجاهين LTR و RTL\n\n'
    'كل عنصر قابل للتخصيص بالكامل.';

const _aboutHe =
    'page_curl_flip מביאה דפדוף נייר אמיתי אל Flutter.\n'
    'כל עמוד מתעקל, מתקפל ונופל עם תאורה ועומק טבעיים.\n'
    'בנויה ללא תלויות — שלד נקי לכל אפליקציה.\n\n'
    '•  החליקו או הקישו כדי לדפדף\n'
    '•  הקראה קולית בכל עמוד\n'
    '•  צליל דפדוף דרך נגן השמע שלכם\n'
    '•  תמיכה מלאה ב-LTR וב-RTL\n\n'
    'כל רכיב ניתן להתאמה מלאה.';

// ── LTR book ──────────────────────────────────────────────────────────────────

class LtrBook extends StatefulWidget {
  const LtrBook({super.key});

  @override
  State<LtrBook> createState() => _LtrBookState();
}

class _LtrBookState extends State<LtrBook> {
  final _reader = _Reader();
  final _sound = _FlipSound();

  /// Feeds the book's opt-in player strip from the reader's events.
  double _readProgress = 0;
  String _readElapsed = '0:00';

  @override
  void initState() {
    super.initState();
    _reader.onProgress = (p) {
      if (mounted) {
        setState(() => _readProgress = p);
      }
    };
    _reader.onElapsed = (t) {
      if (mounted) {
        setState(() => _readElapsed = t);
      }
    };
  }

  // Each page is one self-contained block: title (for the INDEX), an
  // optional tagline, the speech text, and any widget as the body.
  static const _pages = <FlipBookPage>[
    FlipBookPage(
      title: 'page_curl_flip',
      tagline: 'swipe or use the arrows',
      bodyText: _aboutEn,
      body: Text(_aboutEn, style: TextStyle(fontSize: 15, height: 1.6)),
    ),
    // showTitleOnPage: false → the body owns the whole screen and the
    // voice reads only what is visible.
    FlipBookPage(
      title: 'Handwritten',
      showTitleOnPage: false,
      bodyText: _aboutEn,
      body: _NotebookPage(heading: 'page_curl_flip', lines: _aboutEn),
    ),
    FlipBookPage(
      title: 'Magazine cover',
      showTitleOnPage: false,
      bodyText: _aboutEn,
      body: _MagazineCover(
        masthead: 'FLIP',
        issueLine: 'FLUTTER WEEKLY · v0.1 · pub.dev',
        headline: 'PAPER',
        credit: '"pages that feel real" — page_curl_flip',
        poem: _aboutEn,
      ),
    ),
    FlipBookPage(
      title: 'For kids',
      showTitleOnPage: false,
      bodyText: _aboutEn,
      body: _KidsPage(
        badge: 'a package for you!',
        heading: 'flip!',
        poem: _aboutEn,
      ),
    ),
  ];

  @override
  void dispose() {
    _reader.dispose();
    _sound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlipBook(
      // Direction is forced, so the book looks the same on every device.
      textDirection: TextDirection.ltr,
      // Immersive: the book opens as a pure page — tap it and the whole
      // reader chrome reveals itself, then fades away again. Optional;
      // the default keeps the footer always visible.
      chrome: FlipBookChrome.autoHide,
      // Everything below is decoration — swap any value for your own.
      theme: _bookTheme,
      icons: _bookIcons,
      pageColor: const Color(0xFFFBFAF6),
      showPageNumber: true,
      // Swiping and its hint are on by default: a fading '‹‹‹‹ Swipe ››››'
      // line greets each page and returns every 20 s while the reader
      // stays. Turn either off with swipeToFlip / showSwipeHint, or tune
      // swipeHintDelay.
      // The package persists nothing between opens — the app remembers
      // that the gesture was learned and stops the greeting on the next
      // open. A real app would write this flag to storage.
      showSwipeHint: !_SwipeMemory.learned,
      onSwipeHintRetired: () => _SwipeMemory.learned = true,
      // The flip sound comes from THIS app; the package ships no audio.
      onPageFlip: _sound.play,
      // Play-all: one ▶ reads the whole book — the package flips and
      // chains through the same callbacks. Optional, like everything.
      readAloudAdvances: true,
      // Player strip: the package draws the bar and the timing label, the
      // app feeds both — the package makes no sound, so it cannot know
      // position or time itself.
      showReadAloudProgress: true,
      readAloudProgress: _readProgress,
      readAloudProgressLabel: _readElapsed,
      // The voice reads what each page shows, via the device's TTS engine.
      onReadAloud: (page) => _reader.read(_pages[page].speechText(), 'en-US'),
      onReadAloudStop: _reader.stop,
      onReadAloudPause: _reader.pause,
      onReadAloudResume: _reader.resume,
      onClose: () => Navigator.of(context).pop(),
      pages: _pages,
    );
  }
}

// ── RTL book ──────────────────────────────────────────────────────────────────

class RtlBook extends StatefulWidget {
  const RtlBook({super.key});

  @override
  State<RtlBook> createState() => _RtlBookState();
}

class _RtlBookState extends State<RtlBook> {
  final _reader = _Reader();
  final _sound = _FlipSound();

  /// Same player-strip feed as the LTR book — bar and label mirror with
  /// the book's direction.
  double _readProgress = 0;
  String _readElapsed = '0:00';

  @override
  void initState() {
    super.initState();
    _reader.onProgress = (p) {
      if (mounted) {
        setState(() => _readProgress = p);
      }
    };
    _reader.onElapsed = (t) {
      if (mounted) {
        setState(() => _readElapsed = t);
      }
    };
  }

  /// The voice-setup steps, in Arabic first with a short English footnote.
  static const _settingsBody =
      'إذا لم تستطع سماع صوت هذه الصفحة، فعّل خدمة تحويل النص إلى كلام '
      'من إعدادات الجهاز:\n\n'
      'أندرويد:\n'
      '١. افتح الإعدادات ← الإدارة العامة (أو النظام).\n'
      '٢. اختر «تحويل النص إلى كلام».\n'
      '٣. اختر «خدمات Google للنطق» محرّكًا — ثبّته من متجر بلاي إن لم '
      'يكن موجودًا.\n'
      '٤. افتح ⚙ ← «تثبيت بيانات الصوت» واختر لغتك.\n'
      '٥. عد إلى الكتاب واضغط زر التشغيل.\n\n'
      'آيفون:\n'
      '١. الإعدادات ← تسهيلات الاستخدام ← المحتوى المنطوق.\n'
      '٢. «الأصوات» ← اختر اللغة ونزّل صوتًا.\n'
      '٣. عد إلى الكتاب واضغط زر التشغيل.\n\n'
      '(English: if you cannot hear this page, enable text-to-speech in '
      'your device settings and download a voice for your language.)';

  /// The speech language of each page — the kids page is Hebrew, so both
  /// RTL scripts appear in one book.
  // Order matches _pages: plain, handwritten, magazine, kids (Hebrew),
  // voice setup.
  static const _pageLanguages = ['ar', 'ar', 'ar', 'he', 'ar'];

  static const _pages = <FlipBookPage>[
    FlipBookPage(
      title: 'page_curl_flip',
      tagline: 'اسحب أو استخدم الأسهم',
      bodyText: _aboutAr,
      body: Text(_aboutAr, style: TextStyle(fontSize: 15, height: 1.9)),
    ),
    FlipBookPage(
      title: 'بخط اليد',
      showTitleOnPage: false,
      bodyText: _aboutAr,
      body: _NotebookPage(
        heading: 'page_curl_flip',
        lines: _aboutAr,
        textDirection: TextDirection.rtl,
      ),
    ),
    FlipBookPage(
      title: 'غلاف مجلة',
      showTitleOnPage: false,
      bodyText: _aboutAr,
      body: _MagazineCover(
        masthead: 'فليب',
        issueLine: 'أسبوعية Flutter · الإصدار 0.1 · pub.dev',
        headline: 'الورق',
        credit: '«صفحات كأنها حقيقية» — page_curl_flip',
        poem: _aboutAr,
        direction: TextDirection.rtl,
      ),
    ),
    // Hebrew — a second RTL script, completely different from Arabic.
    FlipBookPage(
      title: 'לילדים',
      showTitleOnPage: false,
      bodyText: _aboutHe,
      body: _KidsPage(
        badge: 'חבילה בשבילך!',
        heading: 'flip!',
        poem: _aboutHe,
        direction: TextDirection.rtl,
      ),
    ),
    // The RTL book's extra screen: how to install a voice. The body is
    // scrollable because the steps are longer than one page.
    FlipBookPage(
      title: 'إعدادات الصوت',
      tagline: 'إن لم تسمع صوت هذه الصفحة',
      bodyText:
          'إذا لم تستطع سماع صوت هذه الصفحة، فعّل خدمة تحويل النص '
          'إلى كلام من إعدادات الجهاز، ثم نزّل صوت اللغة التي تريدها.',
      body: SingleChildScrollView(
        child: Text(_settingsBody, style: TextStyle(fontSize: 14, height: 1.8)),
      ),
    ),
  ];

  /// Reads the page in its own language; if the device has no voice for
  /// it, a dialog points to the settings screen at the end of the book.
  Future<void> _readAloud(int page) async {
    final language = _pageLanguages[page];
    if (!await _reader.isAvailable(language)) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('لا يوجد صوت — no voice'),
            content: const Text(
              'لا يوجد صوت لهذه اللغة على هذا الجهاز — الخطوات كاملة في '
              'صفحة «إعدادات الصوت» آخر الكتاب.\n\n'
              'No voice for this language is installed — full steps are on '
              "the book's last page.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }
    await _reader.read(_pages[page].speechText(), language);
  }

  @override
  void dispose() {
    _reader.dispose();
    _sound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlipBook(
      // RTL: layout, arrows, flips, and swipes all mirror.
      textDirection: TextDirection.rtl,
      // Every built-in label, translated.
      strings: const FlipBookStrings(
        index: 'الفهرس',
        previous: 'السابق',
        next: 'التالي',
        tableOfContents: 'جدول المحتويات',
        searchHint: 'ابحث بالعنوان',
        close: 'إغلاق',
        mute: 'كتم صوت الصفحات',
        unmute: 'تشغيل صوت الصفحات',
        readAloud: 'اقرأ هذه الصفحة بصوت عالٍ',
        readAllAloud: 'اقرأ الكتاب كاملاً بصوت عالٍ',
        pauseReading: 'إيقاف مؤقت',
        stopReading: 'إيقاف القراءة',
        // The playback terms Arabic media apps actually use — not literal
        // translations: تشغيل (play), استئناف (resume-playback).
        play: 'تشغيل',
        playAll: 'تشغيل الكل',
        pause: 'إيقاف مؤقت',
        resume: 'استئناف',
        stop: 'إيقاف',
        swipeHint: 'اسحب لقلب الصفحة',
      ),
      chrome: FlipBookChrome.autoHide,
      theme: _bookTheme,
      icons: _bookIcons,
      pageColor: const Color(0xFFFBFAF6),
      showPageNumber: true,
      // The learned-gesture memory is app-wide: three swipes in either
      // book retire the hint in both.
      showSwipeHint: !_SwipeMemory.learned,
      onSwipeHintRetired: () => _SwipeMemory.learned = true,
      onPageFlip: _sound.play,
      readAloudAdvances: true,
      showReadAloudProgress: true,
      readAloudProgress: _readProgress,
      readAloudProgressLabel: _readElapsed,
      onReadAloud: _readAloud,
      onReadAloudStop: _reader.stop,
      onReadAloudPause: _reader.pause,
      onReadAloudResume: _reader.resume,
      onClose: () => Navigator.of(context).pop(),
      pages: _pages,
    );
  }
}

// ── Shared decoration ─────────────────────────────────────────────────────────
// Both books use the same custom theme and icons, so LTR and RTL look
// identical — only mirrored.

const _ink = Color(0xFF3E5641);

final _bookTheme = const FlipBookTheme().copyWith(
  closeIconColor: _ink,
  navButtonIconColor: _ink,
  muteIconColor: _ink,
  tocItemCurrentIconColor: _ink,
  // Voice buttons dress like the other footer text buttons.
  voiceChipStyle: const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: _ink,
  ),
  // The strip floats over every page — including the black magazine
  // cover — so the bar picks colours that read on light AND dark paper.
  readAloudProgressColor: const Color(0xFFD32F2F),
  readAloudProgressTrackColor: const Color(0x338A8A8A),
  readAloudProgressLabelStyle: const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: Color(0xFF8A8A8A),
  ),
  navButtonStyle: const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: _ink,
  ),
  indexButtonStyle: const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: _ink,
  ),
  pageNumberStyle: const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: _ink,
  ),
  pageTitleStyle: const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Color(0xFF2B3A2E),
    height: 1.25,
  ),
  pageTaglineStyle: const TextStyle(
    fontSize: 13,
    fontStyle: FontStyle.italic,
    color: Color(0xFF6B7F6E),
  ),
);

const _bookIcons = FlipBookIcons(
  next: Icons.arrow_forward_ios,
  previous: Icons.arrow_back_ios_new,
  volumeOn: Icons.music_note,
  volumeOff: Icons.music_off,
);

// ── The screens ───────────────────────────────────────────────────────────────
// Drawn entirely by page bodies; body-only pages render full-bleed.

/// Neon-on-black children's screen.
class _KidsPage extends StatelessWidget {
  const _KidsPage({
    required this.badge,
    required this.heading,
    required this.poem,
    this.direction = TextDirection.ltr,
  });

  final String badge;
  final String heading;
  final String poem;
  final TextDirection direction;

  /// Explicit per-platform pick, no bundled font: Chalkboard SE is Apple's
  /// built-in kid-print font; Android has no named equivalent, so its
  /// 'casual' alias picks the vendor's kid-print font (Coming Soon on
  /// stock Android). Each platform shows its own native kids writing.
  static String get _kidsFont =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'Chalkboard SE' : 'casual';

  /// iOS's Chalkboard SE is much bolder than Android's kid print — ask for
  /// the Light face (w300) there to bring the stroke weight closer.
  static FontWeight get _kidsHeadingWeight =>
      defaultTargetPlatform == TargetPlatform.iOS
      ? FontWeight.w200
      : FontWeight.w800;

  static FontWeight get _kidsBodyWeight =>
      defaultTargetPlatform == TargetPlatform.iOS
      ? FontWeight.w200
      : FontWeight.w400;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: direction,
      child: ColoredBox(
        // Very pale lemon yellow — a light, friendly page (was near-black).
        color: const Color(0xFFFFFDE7),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 56, 28, 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3A2C00),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  heading,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: _kidsHeadingWeight,
                    // Deeper blue for contrast on the pale page.
                    color: const Color(0xFF0288D1),
                    fontFamily: _kidsFont,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    poem,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: const Color(0xFF424242),
                      fontFamily: _kidsFont,
                      fontWeight: _kidsBodyWeight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A magazine cover: masthead, red rule, the Flutter bird as the hero
/// image, a giant headline, tiny body copy, and a barcode footer.
class _MagazineCover extends StatelessWidget {
  const _MagazineCover({
    required this.masthead,
    required this.issueLine,
    required this.headline,
    required this.credit,
    required this.poem,
    this.direction = TextDirection.ltr,
  });

  final String masthead;
  final String issueLine;
  final String headline;
  final String credit;
  final String poem;
  final TextDirection direction;

  static const _red = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final paragraphs = poem.split('\n\n');
    return Directionality(
      textDirection: direction,
      child: ColoredBox(
        // Black cover — the light type and the bright hero plate pop on it.
        color: Colors.black,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 48, 22, 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      masthead,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 0.9,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      issueLine,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 3,
                  width: double.infinity,
                  color: _red,
                ),
                Expanded(
                  flex: 5,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(26),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0xFFE3F2FD), Colors.white],
                        ),
                      ),
                      child: const FlutterLogo(size: 130),
                    ),
                  ),
                ),
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  credit,
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: _red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                // Tiny two-column body copy, like a real cover.
                Expanded(
                  flex: 3,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          paragraphs.first,
                          style: const TextStyle(
                            fontSize: 8,
                            height: 1.5,
                            color: Color(0xFFBBBBBB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          paragraphs.length > 1
                              ? paragraphs.sublist(1).join('\n\n')
                              : '',
                          style: const TextStyle(
                            fontSize: 8,
                            height: 1.5,
                            color: Color(0xFFBBBBBB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const _Barcode(),
                    const SizedBox(width: 10),
                    Text(
                      direction == TextDirection.rtl
                          ? 'ملكية عامة · ٠٫٠٠'
                          : 'PUBLIC DOMAIN · 0.00',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A fake barcode drawn from stripes — pure decoration.
class _Barcode extends StatelessWidget {
  const _Barcode();

  @override
  Widget build(BuildContext context) {
    const widths = [
      2.0,
      1.0,
      3.0,
      1.0,
      2.0,
      1.0,
      1.0,
      3.0,
      2.0,
      1.0,
      2.0,
      3.0,
      1.0,
      1.0,
      2.0,
      1.0,
      3.0,
      1.0,
      2.0,
      2.0,
    ];
    // The stripes sit on a white plate, like a real barcode on a dark cover.
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final w in widths)
              Container(
                width: w,
                height: 22,
                margin: const EdgeInsets.only(right: 1),
                color: Colors.black,
              ),
          ],
        ),
      ),
    );
  }
}

/// A ruled notebook sheet: the text rows sit exactly on the painted lines,
/// and the red margin follows the reading direction.
class _NotebookPage extends StatelessWidget {
  const _NotebookPage({
    required this.heading,
    required this.lines,
    this.textDirection = TextDirection.ltr,
  });

  final String heading;
  final String lines;
  final TextDirection textDirection;

  static const _lineHeight = 32.0;

  /// Explicit per-platform pick, no bundled font: Marker Felt is Apple's
  /// built-in marker handwriting; Android has no named equivalent, so its
  /// 'casual' alias picks the vendor's handwriting-print font (Coming Soon
  /// on stock Android). Arabic text falls through to the system Arabic
  /// font on both platforms — neither pick carries Arabic glyphs.
  static String get _notesFont =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'Marker Felt' : 'casual';

  /// iOS's Marker Felt is heavier than Android's — ask for its Thin face
  /// (w300) there to bring the stroke weight closer.
  static FontWeight get _notesWeight =>
      defaultTargetPlatform == TargetPlatform.iOS
      ? FontWeight.w200
      : FontWeight.w400;

  @override
  Widget build(BuildContext context) {
    final handwriting = TextStyle(
      fontSize: 16,
      height: _lineHeight / 16,
      leadingDistribution: TextLeadingDistribution.even,
      color: const Color(0xFF2B3A67),
      fontStyle: FontStyle.italic,
      fontFamily: _notesFont,
      fontWeight: _notesWeight,
    );
    final isRtl = textDirection == TextDirection.rtl;
    return CustomPaint(
      painter: _RuledPaperPainter(lineHeight: _lineHeight, marginRight: isRtl),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isRtl ? 24 : 56,
          _lineHeight,
          isRtl ? 56 : 24,
          0,
        ),
        child: Column(
          crossAxisAlignment: isRtl
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              heading,
              textDirection: textDirection,
              style: handwriting.copyWith(
                fontSize: 20,
                height: _lineHeight / 20,
                // Heading stays a step heavier than the body on each
                // platform — thin overall on iOS (Marker Felt runs heavy).
                fontWeight: defaultTargetPlatform == TargetPlatform.iOS
                    ? FontWeight.w200
                    : FontWeight.w600,
              ),
            ),
            Expanded(
              child: Text(
                lines,
                textDirection: textDirection,
                style: handwriting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuledPaperPainter extends CustomPainter {
  const _RuledPaperPainter({
    required this.lineHeight,
    required this.marginRight,
  });

  final double lineHeight;
  final bool marginRight;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFDFBF3),
    );

    // Text rows are exactly lineHeight tall, so their bottoms land on
    // multiples of lineHeight — draw the rules there.
    final rule = Paint()
      ..color = const Color(0x338BA7D4)
      ..strokeWidth = 1;
    for (var y = lineHeight * 2; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rule);
    }

    final margin = Paint()
      ..color = const Color(0x55D46A6A)
      ..strokeWidth = 1.5;
    final x = marginRight ? size.width - 44 : 44.0;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), margin);
  }

  @override
  bool shouldRepaint(_RuledPaperPainter old) =>
      old.lineHeight != lineHeight || old.marginRight != marginRight;
}

// ── Swipe memory ──────────────────────────────────────────────────────────────

/// The package keeps no state between opens; remembering that the reader
/// has learned the swipe gesture is the app's job. This example remembers
/// for the app's lifetime — a real app would persist the flag to storage
/// and restore it at startup.
class _SwipeMemory {
  static bool learned = false;
}

// ── Flip sound ────────────────────────────────────────────────────────────────

/// The flip sound is this app's, not the package's. The 1.15-second sample
/// matches the flip duration, and pre-loading keeps it in sync with the
/// curl.
class _FlipSound with WidgetsBindingObserver {
  _FlipSound() {
    WidgetsBinding.instance.addObserver(this);
  }

  final _player = AudioPlayer();
  Future<void>? _ready;

  Future<void> _prime() => _ready ??= () async {
    // Android: the silent/vibrate gate lives on the PLAYER's audio
    // attributes (respectSilence → ringtone usage), not on the global
    // context — set it once here. iOS is handled by the global session
    // assert in play() below.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _player.setAudioContext(
        AudioContextConfig(respectSilence: true).build(),
      );
    }
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setSource(AssetSource('sounds/page_flip.m4a'));
  }();

  /// iOS interrupts the audio session when the app leaves the foreground
  /// and resumes interrupted players when it returns — which replayed the
  /// flip sound on background AND on relaunch. Stopping the player the
  /// moment the app stops being active leaves nothing to resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _player.stop();
    }
  }

  /// Plays from the start; safe to call on every flip.
  Future<void> play() async {
    await _prime();
    // Respect the iPhone ring/silent switch: audioplayers defaults the iOS
    // audio session to the `playback` category, which by Apple's rules
    // ignores the switch. `respectSilence` swaps it for `ambient` — a UI
    // effect sound should obey silent mode. Re-asserted on every flip
    // because the session is one shared object and read-aloud switches it
    // to `playback` for itself (a deliberate listen must sound regardless).
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(respectSilence: true).build(),
    );
    await _player.stop();
    try {
      await _player.seek(Duration.zero);
    } catch (_) {
      // stop() already reset the position on this platform.
    }
    await _player.resume();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
  }
}

// ── Reader ────────────────────────────────────────────────────────────────────

/// A small wrapper around the device's text-to-speech engine, shaped for
/// FlipBook's callbacks: read() completes when speech ends, pause()/resume()
/// continue from the interrupted word, stop() halts immediately.
class _Reader with WidgetsBindingObserver {
  _Reader() {
    WidgetsBinding.instance.addObserver(this);
  }

  final _tts = FlutterTts();
  bool _configured = false;
  String _text = '';
  String _language = 'en-US';
  int _position = 0;
  int _base = 0;

  /// Feeds the book's opt-in player strip: progress 0.0–1.0 from the word
  /// boundaries the engine already emits, and elapsed time from a stopwatch
  /// (speech engines report no duration — elapsed is what is knowable).
  ValueChanged<double>? onProgress;
  ValueChanged<String>? onElapsed;
  final _elapsed = Stopwatch();

  /// The engine's speak future also completes when pause/stop kill it —
  /// only the session that finishes NATURALLY may report "done" (1.0),
  /// otherwise the bar would jump to full on every pause.
  int _session = 0;

  String get _elapsedLabel {
    final s = _elapsed.elapsed.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _configure() async {
    if (_configured) {
      return;
    }
    await _tts.awaitSpeakCompletion(true);
    // Remember how far the voice has come, for pause/resume.
    _tts.setProgressHandler((text, start, end, word) {
      _position = _base + start;
      // Re-assert the screen wakelock on every word — self-healing if a
      // platform quietly dropped it (seen on iOS mid-play-all).
      _screenAwake(true);
      if (_text.isNotEmpty) {
        onProgress?.call(_position / _text.length);
        onElapsed?.call(_elapsedLabel);
      }
    });
    _configured = true;
  }

  Future<bool> isAvailable(String language) async =>
      await _tts.isLanguageAvailable(language) == true;

  /// Read-aloud is a deliberate listen — like any audio player it must
  /// sound even with the iPhone silent switch on, so it asserts the
  /// `playback` category before every speak. (The flip sound asserts
  /// `ambient` before every play for the opposite reason: the iOS audio
  /// session is one shared object, and whoever spoke last set its mode.)
  Future<void> _assertAudioCategory() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
      IosTextToSpeechAudioCategoryOptions.mixWithOthers,
    ]);
  }

  /// Best-effort screen wakelock: a long listen (play-all) must not die to
  /// the screen timeout — reading stops on background by design, so the
  /// screen staying on is what keeps the voice alive. Failures are
  /// swallowed; the lock must never break reading.
  void _screenAwake(bool on) {
    unawaited(
      (on ? WakelockPlus.enable() : WakelockPlus.disable()).catchError((_) {}),
    );
  }

  Future<void> read(String text, String language) async {
    await _configure();
    await _assertAudioCategory();
    await _tts.stop();
    final session = ++_session;
    _text = text;
    _language = language;
    _base = 0;
    _position = 0;
    _elapsed
      ..reset()
      ..start();
    _screenAwake(true);
    onProgress?.call(0);
    onElapsed?.call(_elapsedLabel);
    await _tts.setLanguage(language);
    await _tts.speak(text);
    if (session == _session) {
      _elapsed.stop();
      _screenAwake(false);
      onProgress?.call(1);
    }
  }

  /// Android's engine has no native pause — stopping while remembering the
  /// word works on every platform.
  Future<void> pause() {
    _session++; // The dying speak future must not report "done".
    _elapsed.stop();
    _screenAwake(false);
    return _tts.stop();
  }

  Future<void> resume() async {
    await _assertAudioCategory();
    final session = ++_session;
    _elapsed.start();
    _screenAwake(true);
    _base = _position;
    await _tts.setLanguage(_language);
    await _tts.speak(_text.substring(_position.clamp(0, _text.length)));
    if (session == _session) {
      _elapsed.stop();
      _screenAwake(false);
      onProgress?.call(1);
    }
  }

  Future<void> stop() {
    _session++;
    _elapsed.stop();
    _screenAwake(false);
    return _tts.stop();
  }

  /// Android keeps the TTS engine speaking after the app is backgrounded
  /// (iOS suspends it with the app). A book has no business reading to a
  /// closed cover — stop the voice when the app leaves the foreground.
  /// The speak future completes on stop, so the book's ▶ control resets
  /// by its normal completion path.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      stop(); // Bumps the session too — no stale "done" reports.
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session++;
    _screenAwake(false);
    _tts.stop();
  }
}
