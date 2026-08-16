import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:page_curl_flip/page_curl_flip.dart';

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
      title: 'For kids',
      showTitleOnPage: false,
      bodyText: _aboutEn,
      body: _KidsPage(
        badge: 'a package for you!',
        heading: 'flip!',
        poem: _aboutEn,
      ),
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
      // Everything below is decoration — swap any value for your own.
      theme: _bookTheme,
      icons: _bookIcons,
      pageColor: const Color(0xFFFBFAF6),
      showPageNumber: true,
      // Swiping and its hint are on by default: a fading '‹‹‹‹ Swipe ››››'
      // line greets each page and returns every 20 s while the reader
      // stays. Turn either off with swipeToFlip / showSwipeHint, or tune
      // swipeHintDelay.
      // The flip sound comes from THIS app; the package ships no audio.
      onPageFlip: _sound.play,
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
  static const _pageLanguages = ['ar', 'ar', 'he', 'ar', 'ar'];

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
        pauseReading: 'إيقاف مؤقت',
        stopReading: 'إيقاف القراءة',
        swipeHint: 'اسحب لقلب الصفحة',
      ),
      theme: _bookTheme,
      icons: _bookIcons,
      pageColor: const Color(0xFFFBFAF6),
      showPageNumber: true,
      onPageFlip: _sound.play,
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
  play: Icons.play_circle_outline,
  pause: Icons.pause_circle_outline,
  stop: Icons.stop_circle_outlined,
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: direction,
      child: ColoredBox(
        color: const Color(0xFF101014),
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
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4FC3F7),
                    fontFamilyFallback: ['Arial Rounded MT Bold', 'casual'],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    poem,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: Color(0xFFECECEC),
                      fontFamilyFallback: ['Arial Rounded MT Bold', 'casual'],
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
        color: Colors.white,
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
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      issueLine,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFF666666),
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
                    color: Colors.black,
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
                            color: Color(0xFF444444),
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
                            color: Color(0xFF444444),
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
                        color: Color(0xFF888888),
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
    return Row(
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

  @override
  Widget build(BuildContext context) {
    const handwriting = TextStyle(
      fontSize: 16,
      height: _lineHeight / 16,
      leadingDistribution: TextLeadingDistribution.even,
      color: Color(0xFF2B3A67),
      fontStyle: FontStyle.italic,
      fontFamilyFallback: ['Marker Felt', 'Bradley Hand', 'casual', 'cursive'],
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
                fontWeight: FontWeight.w600,
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

// ── Flip sound ────────────────────────────────────────────────────────────────

/// The flip sound is this app's, not the package's. The 1.15-second sample
/// matches the flip duration, and pre-loading keeps it in sync with the
/// curl.
class _FlipSound {
  final _player = AudioPlayer();
  Future<void>? _ready;

  Future<void> _prime() => _ready ??= () async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setSource(AssetSource('sounds/page_flip.m4a'));
  }();

  /// Plays from the start; safe to call on every flip.
  Future<void> play() async {
    await _prime();
    await _player.stop();
    try {
      await _player.seek(Duration.zero);
    } catch (_) {
      // stop() already reset the position on this platform.
    }
    await _player.resume();
  }

  void dispose() {
    _player.dispose();
  }
}

// ── Reader ────────────────────────────────────────────────────────────────────

/// A small wrapper around the device's text-to-speech engine, shaped for
/// FlipBook's callbacks: read() completes when speech ends, pause()/resume()
/// continue from the interrupted word, stop() halts immediately.
class _Reader {
  final _tts = FlutterTts();
  bool _configured = false;
  String _text = '';
  String _language = 'en-US';
  int _position = 0;
  int _base = 0;

  Future<void> _configure() async {
    if (_configured) {
      return;
    }
    await _tts.awaitSpeakCompletion(true);
    // Remember how far the voice has come, for pause/resume.
    _tts.setProgressHandler((text, start, end, word) {
      _position = _base + start;
    });
    _configured = true;
  }

  Future<bool> isAvailable(String language) async =>
      await _tts.isLanguageAvailable(language) == true;

  Future<void> read(String text, String language) async {
    await _configure();
    await _tts.stop();
    _text = text;
    _language = language;
    _base = 0;
    _position = 0;
    await _tts.setLanguage(language);
    await _tts.speak(text);
  }

  /// Android's engine has no native pause — stopping while remembering the
  /// word works on every platform.
  Future<void> pause() => _tts.stop();

  Future<void> resume() async {
    _base = _position;
    await _tts.setLanguage(_language);
    await _tts.speak(_text.substring(_position.clamp(0, _text.length)));
  }

  Future<void> stop() => _tts.stop();

  void dispose() {
    _tts.stop();
  }
}
