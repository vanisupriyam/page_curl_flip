import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:page_curl_flip/page_curl_flip.dart';

void main() => runApp(const ExampleApp());

/// Two [FlipBook]s: an English left-to-right book where every page looks
/// different, and an Arabic right-to-left book. Both wire the read-aloud
/// button to the device's own text-to-speech engine — the simplest reader.
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

/// Menu of the two books.
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
            title: 'English book — LTR',
            subtitle:
                'Every page different: poem, image, colour, font. '
                'INDEX and read-aloud bottom-left.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const EnglishBook()),
            ),
          ),
          _DemoTile(
            title: 'Arabic book — RTL',
            subtitle: 'Same widget, flipped reading direction, Arabic labels',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const ArabicBook())),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 24, 8, 8),
            child: Text(
              'Theme gallery — same book, six looks',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          for (final preset in _presets)
            _DemoTile(
              title: preset.name,
              subtitle: preset.subtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ThemedBook(theme: preset.theme, paper: preset.paper),
                ),
              ),
            ),
          _DemoTile(
            title: 'Magazine',
            subtitle: 'body-only pages designed like a real magazine',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MagazineBook()),
            ),
          ),
        ],
      ),
    );
  }

  static const _presets = [
    (
      name: 'Classic',
      subtitle: 'the default — white paper, neutral ink',
      theme: FlipBookTheme.classic,
      paper: FlipBookTheme.classicPaper,
    ),
    (
      name: 'Old book',
      subtitle: 'sepia serif, italic taglines',
      theme: FlipBookTheme.oldBook,
      paper: FlipBookTheme.oldBookPaper,
    ),
    (
      name: 'Night',
      subtitle: 'light ink on near-black, gold bookmark',
      theme: FlipBookTheme.night,
      paper: FlipBookTheme.nightPaper,
    ),
    (
      name: 'Kids',
      subtitle: 'crayon-bright, big rounded titles',
      theme: FlipBookTheme.kids,
      paper: FlipBookTheme.kidsPaper,
    ),
    (
      name: 'Newspaper',
      subtitle: 'black serif on newsprint, no colour',
      theme: FlipBookTheme.newspaper,
      paper: FlipBookTheme.newspaperPaper,
    ),
  ];
}

/// The same three pages rendered under whichever preset theme is passed in —
/// the whole difference between the six gallery entries is two arguments.
class ThemedBook extends StatefulWidget {
  const ThemedBook({super.key, required this.theme, required this.paper});

  final FlipBookTheme theme;
  final Color paper;

  @override
  State<ThemedBook> createState() => _ThemedBookState();
}

class _ThemedBookState extends State<ThemedBook> {
  final _reader = _Reader();

  static const _spokenTexts = [
    'This book and the other five in the gallery share the exact same '
        'pages. Only the theme argument changes.',
    'Search field, dividers, page numbers, the current page bookmark — all '
        'recoloured by the preset.',
    'Make it yours: copyWith adjusts any field.',
  ];

  @override
  void dispose() {
    _reader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return FlipBook(
      theme: theme,
      pageColor: widget.paper,
      onReadAloud: (page) => _reader.read(_spokenTexts[page], 'en-US'),
      onReadAloudStop: _reader.stop,
      onReadAloudPause: _reader.pause,
      onReadAloudResume: _reader.resume,
      onClose: () => Navigator.of(context).pop(),
      pages: [
        FlipBookPage(
          title: 'The look',
          tagline: 'every colour and style from one preset',
          body: Text(
            'This book and the other five in the gallery share the exact '
            'same pages — only the theme argument changes.',
            style: theme.tocItemTitleStyle,
          ),
        ),
        FlipBookPage(
          title: 'The index too',
          tagline: 'open INDEX to see the themed table of contents',
          body: Text(
            'Search field, dividers, page numbers, the current-page '
            'bookmark — all recoloured by the preset.',
            style: theme.tocItemTitleStyle,
          ),
        ),
        const FlipBookPage(
          title: 'Make it yours',
          tagline: 'copyWith adjusts any field',
          body: Center(child: FlutterLogo(size: 120)),
        ),
      ],
    );
  }
}

// ── Magazine book ─────────────────────────────────────────────────────────────

/// Body-only pages designed like a real magazine: cover, feature spread with
/// two text columns and a pull quote, and a drawn "photo" mosaic. No image
/// assets and no licensed content — every block is painted by Flutter and
/// all text is original to this example.
class MagazineBook extends StatefulWidget {
  const MagazineBook({super.key});

  @override
  State<MagazineBook> createState() => _MagazineBookState();
}

class _MagazineBookState extends State<MagazineBook> {
  final _reader = _Reader();

  static const _spokenTexts = [
    'The paper issue. A magazine about pages. Why screens still copy '
        'paper. Six themes inside.',
    'Feature: why screens still copy paper. A page you can peel is a page '
        'you believe in.',
    'In pictures: the spine, the curl, the mark, and the type. No '
        'photographs were licensed for this issue — every block is drawn '
        'by Flutter.',
  ];

  @override
  void dispose() {
    _reader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlipBook(
      theme: FlipBookTheme.magazine,
      pageColor: FlipBookTheme.magazinePaper,
      onReadAloud: (page) => _reader.read(_spokenTexts[page], 'en-US'),
      onReadAloudStop: _reader.stop,
      onReadAloudPause: _reader.pause,
      onReadAloudResume: _reader.resume,
      onClose: () => Navigator.of(context).pop(),
      pages: const [
        FlipBookPage(
          title: 'Cover',
          showTitleOnPage: false,
          body: _MagazineCover(),
        ),
        FlipBookPage(
          title: 'Feature',
          showTitleOnPage: false,
          body: _MagazineFeature(),
        ),
        FlipBookPage(
          title: 'In pictures',
          showTitleOnPage: false,
          body: _MagazineMosaic(),
        ),
      ],
    );
  }
}

class _MagazineCover extends StatelessWidget {
  const _MagazineCover();

  static const _red = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: _red,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: const Text(
            'FLIP — A MAGAZINE ABOUT PAGES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
        ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'THE\nPAPER\nISSUE',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              height: 0.95,
              letterSpacing: -2,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          height: 4,
          width: 72,
          color: _red,
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Text(
            'Why screens still copy paper · six themes inside · '
            'no photographs were harmed',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF757575),
            ),
          ),
        ),
      ],
    );
  }
}

class _MagazineFeature extends StatelessWidget {
  const _MagazineFeature();

  static const _columnText = TextStyle(
    fontSize: 12.5,
    height: 1.55,
    color: Color(0xFF303030),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FEATURE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Why screens still copy paper',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '“A page you can peel is a page\nyou believe in.”',
            style: TextStyle(
              fontSize: 17,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 14),
          const Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Fifty years after the first screens, our interfaces are '
                    'still full of paper: pages, margins, bookmarks, folders. '
                    'The metaphor survived because hands remember it. A '
                    'reader who has never opened this app already knows what '
                    'the corner of a page is for.',
                    style: _columnText,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'That is what a curl animation buys: not decoration, but '
                    'memory. The eye reads the bend of the cylinder, the '
                    'shadow under the fold, the brief shine along the crease '
                    '— and the brain files the screen under “book”, where '
                    'things are kept and found again.',
                    style: _columnText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MagazineMosaic extends StatelessWidget {
  const _MagazineMosaic();

  static const _tiles = [
    (color: Color(0xFF163832), icon: Icons.menu_book, label: 'the spine'),
    (color: Color(0xFFD32F2F), icon: Icons.gesture, label: 'the curl'),
    (color: Color(0xFF103A6B), icon: Icons.bookmark, label: 'the mark'),
    (color: Color(0xFFC9A96A), icon: Icons.text_fields, label: 'the type'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IN PICTURES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final tile in _tiles)
                  Container(
                    color: tile.color,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(tile.icon, color: Colors.white70, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          tile.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No photographs were licensed for this issue — every block '
              'above is drawn by Flutter.',
              style: TextStyle(fontSize: 11, color: Color(0xFF757575)),
            ),
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

// ── English book (LTR) ────────────────────────────────────────────────────────

/// Left-to-right book. Every page is deliberately different from the last:
/// a public-domain poem, an image page, a page with its own background
/// colour, and a page in a serif font. The read-aloud button speaks the
/// current page through the device's TTS engine.
class EnglishBook extends StatefulWidget {
  const EnglishBook({super.key});

  @override
  State<EnglishBook> createState() => _EnglishBookState();
}

class _EnglishBookState extends State<EnglishBook> {
  final _reader = _Reader();

  // "Hope" is the thing with feathers — Emily Dickinson, published 1891,
  // author died 1886: public domain worldwide.
  static const _poem =
      '"Hope" is the thing with feathers -\n'
      'That perches in the soul -\n'
      'And sings the tune without the words -\n'
      'And never stops - at all -\n\n'
      'And sweetest - in the Gale - is heard -\n'
      'And sore must be the storm -\n'
      'That could abash the little Bird\n'
      'That kept so many warm -\n\n'
      '— Emily Dickinson, 1891 (public domain)';

  /// Which parts the voice reads — entirely the user's choice: title only,
  /// tagline and body, everything… flip any of the three switches.
  static const _readTitle = true;
  static const _readTagline = true;
  static const _readBody = true;

  Future<void> _readAloud(int page) => _reader.read(
    _pages[page].speechText(
      title: _readTitle,
      tagline: _readTagline,
      body: _readBody,
    ),
    'en-US',
  );

  @override
  void dispose() {
    _reader.dispose();
    super.dispose();
  }

  static const _pages = <FlipBookPage>[
    FlipBookPage(
      title: 'A Tiny Book',
      tagline: 'flip with NEXT · jump from INDEX (bottom-left)',
      body: Text(_poem, style: TextStyle(fontSize: 15, height: 1.6)),
      bodyText:
          'Hope is the thing with feathers, that perches in the soul, '
          'and sings the tune without the words, and never stops at all. '
          'By Emily Dickinson.',
    ),
    FlipBookPage(
      title: 'An image page',
      tagline: 'the body is any widget',
      body: Center(child: FlutterLogo(size: 160)),
      bodyText:
          'The body of a page can be any widget, like this Flutter '
          'logo.',
    ),
    FlipBookPage(
      title: 'Coloured page',
      showTitleOnPage: false, // this page draws everything itself
      bodyText:
          'This page brought its own background colour and its own '
          'text colour.',
      body: ColoredBox(
        color: Color(0xFF163832),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'This page brought its own background colour '
              'and its own text colour.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFE8F5E9), fontSize: 18),
            ),
          ),
        ),
      ),
    ),
    FlipBookPage(
      title: 'Different font',
      showTitleOnPage: false, // brings its own serif heading
      bodyText:
          'This page is set in a serif face, italic. Fonts come from '
          'normal text styles, so any font your app bundles works.',
      body: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A different font',
              style: TextStyle(
                fontSize: 28,
                fontStyle: FontStyle.italic,
                fontFamily: 'serif',
                fontFamilyFallback: ['Georgia', 'Times New Roman'],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'This page is set in a serif face, italic. Fonts come '
              'from normal TextStyles — use any font your app bundles.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'serif',
                fontFamilyFallback: ['Georgia', 'Times New Roman'],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    ),
    FlipBookPage(
      title: 'Handwritten notes',
      showTitleOnPage: false, // the ruled paper carries its own title
      bodyText:
          'Handwritten notes on ruled paper. The whole page, lines '
          'and all, is drawn by the body widget.',
      body: _NotebookPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FlipBook(
      onClose: () => Navigator.of(context).pop(),
      onReadAloud: _readAloud,
      onReadAloudStop: _reader.stop,
      onReadAloudPause: _reader.pause,
      onReadAloudResume: _reader.resume,
      pages: _pages,
    );
  }
}

// ── Notebook page ─────────────────────────────────────────────────────────────

/// A page that looks like a sheet from a real ruled notebook: cream paper,
/// blue rule lines, a red margin, and handwriting-style text sitting on the
/// lines. Everything is drawn by the body — the book itself adds nothing.
class _NotebookPage extends StatelessWidget {
  const _NotebookPage();

  static const _lineHeight = 32.0;
  static const _handwriting = TextStyle(
    fontSize: 16,
    height: _lineHeight / 16,
    color: Color(0xFF2B3A67),
    fontStyle: FontStyle.italic,
    fontFamilyFallback: ['Marker Felt', 'Bradley Hand', 'casual', 'cursive'],
  );

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _RuledPaperPainter(lineHeight: _lineHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(56, _lineHeight, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My travel notes',
              style: _handwriting.copyWith(
                fontSize: 20,
                height: _lineHeight / 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'saw the sea today — bluer than the postcards.\n'
              'the bakery on the corner opens at six,\n'
              'the good bread is gone by seven.\n'
              'remember: come back in autumn.',
              style: _handwriting,
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints cream paper with horizontal rule lines and a red margin line.
class _RuledPaperPainter extends CustomPainter {
  const _RuledPaperPainter({required this.lineHeight});

  final double lineHeight;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFDFBF3),
    );

    final rule = Paint()
      ..color = const Color(0x338BA7D4)
      ..strokeWidth = 1;
    for (var y = lineHeight * 1.5; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rule);
    }

    final margin = Paint()
      ..color = const Color(0x55D46A6A)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(44, 0), Offset(44, size.height), margin);
  }

  @override
  bool shouldRepaint(_RuledPaperPainter old) => old.lineHeight != lineHeight;
}

// ── Arabic book (RTL) ─────────────────────────────────────────────────────────

/// Right-to-left book: `textDirection: TextDirection.rtl` mirrors the whole
/// layout and the flip direction, and every label is Arabic. (When the app's
/// locale is Arabic this happens automatically — the override is only needed
/// because this demo runs inside an English app.) Read-aloud speaks Arabic —
/// note that some devices have no Arabic voice installed.
class ArabicBook extends StatefulWidget {
  const ArabicBook({super.key});

  @override
  State<ArabicBook> createState() => _ArabicBookState();
}

class _ArabicBookState extends State<ArabicBook> {
  final _reader = _Reader();

  Future<void> _readAloud(int page) async {
    if (!await _reader.isAvailable('ar')) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('لا يوجد صوت عربي — no Arabic voice'),
            content: const SingleChildScrollView(
              child: Text(
                'This device has no Arabic voice installed. To listen in '
                'Arabic (or any language):\n\n'
                'Android\n'
                '1. Install "Speech Recognition & Synthesis" by Google from '
                'the Play Store.\n'
                '2. Open Settings → General management (or System) → '
                'Text-to-speech.\n'
                '3. Choose "Speech Services by Google" as the engine, tap '
                'its ⚙ settings → Install voice data.\n'
                '4. Pick Arabic — or any language — and download it.\n'
                '5. Come back and tap play.\n\n'
                'iPhone / iPad\n'
                '1. Open Settings → Accessibility → Spoken Content → '
                'Voices.\n'
                '2. Choose Arabic and download a voice.\n'
                '3. Come back and tap play.',
                textDirection: TextDirection.ltr,
              ),
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
    await _reader.read(_pages[page].speechText(), 'ar');
  }

  @override
  void dispose() {
    _reader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlipBook(
      textDirection: TextDirection.rtl,
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
      ),
      onClose: () => Navigator.of(context).pop(),
      onReadAloud: _readAloud,
      onReadAloudStop: _reader.stop,
      onReadAloudPause: _reader.pause,
      onReadAloudResume: _reader.resume,
      pages: _pages,
    );
  }

  static const _pages = <FlipBookPage>[
    FlipBookPage(
      title: 'كتاب صغير',
      bodyText:
          'هذه الصفحة تُقلب في الاتجاه المعاكس، تمامًا كما يُقرأ '
          'كتاب عربي حقيقي.',
      tagline: 'يُقرأ من اليمين إلى اليسار',
      body: Text(
        'هذه الصفحة تُقلب في الاتجاه المعاكس، تمامًا كما يُقرأ كتاب عربي '
        'حقيقي. كل الأزرار والقوائم معكوسة أيضًا.',
        style: TextStyle(fontSize: 16, height: 1.8),
      ),
    ),
    FlipBookPage(
      title: 'صفحة ثانية',
      bodyText:
          'زر التالي الآن في الجهة اليسرى، والفهرس في الجهة '
          'اليمنى.',
      body: Text(
        'زر «التالي» الآن في الجهة اليسرى، والفهرس في الجهة اليمنى — '
        'الاتجاه كله ينعكس تلقائيًا.',
        style: TextStyle(fontSize: 16, height: 1.8),
      ),
    ),
    FlipBookPage(
      title: 'تثبيت الصوت',
      tagline: 'how to hear this book in Arabic',
      bodyText:
          'لتثبيت صوت عربي، ثبّت خدمات النطق من جوجل، ثم حمّل '
          'اللغة العربية من إعدادات تحويل النص إلى كلام.',
      body: Text(
        'If the play button says no Arabic voice is installed:\n\n'
        'Android — install "Speech Recognition & Synthesis" by Google '
        'from the Play Store, then Settings → Text-to-speech → engine '
        '"Speech Services by Google" → ⚙ → Install voice data → '
        'Arabic.\n\n'
        'iPhone — Settings → Accessibility → Spoken Content → Voices → '
        'Arabic → download.\n\n'
        'The same steps work for any language.',
        textDirection: TextDirection.ltr,
        style: TextStyle(fontSize: 14, height: 1.7),
      ),
    ),
    FlipBookPage(
      title: 'النهاية',
      body: Center(child: FlutterLogo(size: 120)),
    ),
  ];
}

// ── Reader ────────────────────────────────────────────────────────────────────

/// Minimal wrapper around the device text-to-speech engine, shaped for
/// `FlipBook.onReadAloud`: [read] completes when speaking finishes (so the
/// book can show its "listen again" hint) and [stop] halts mid-sentence.
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
    // Makes speak() return only when the utterance has finished.
    await _tts.awaitSpeakCompletion(true);
    // Tracks how far the voice has come, so pause/resume can continue from
    // the right word.
    _tts.setProgressHandler((text, start, end, word) {
      _position = _base + start;
    });
    _configured = true;
  }

  /// Whether the device has a voice for [language] installed.
  Future<bool> isAvailable(String language) async =>
      await _tts.isLanguageAvailable(language) == true;

  /// Reads [text] in [language]; completes when speech ends or is stopped.
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

  /// Pauses by stopping while remembering the last spoken word — Android's
  /// speech engine has no native pause, so this works on every platform.
  Future<void> pause() => _tts.stop();

  /// Continues from the word where [pause] cut the voice off; completes
  /// when the remaining text has been read.
  Future<void> resume() async {
    if (_position == 0) {
      // Some engines emit no word-progress events; resume then has no
      // offset to continue from and restarts the page.
      debugPrint(
        '[page_curl_flip example] this TTS engine reported no '
        'progress — resuming from the beginning of the page',
      );
    }
    _base = _position;
    await _tts.setLanguage(_language);
    await _tts.speak(_text.substring(_position.clamp(0, _text.length)));
  }

  /// Stops speech immediately.
  Future<void> stop() => _tts.stop();

  void dispose() {
    _tts.stop();
  }
}
