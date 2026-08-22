// The demo's content and look, in one place.
//
// One magazine theme across three pages, each naming a different part of the
// package. Three colours used as blocks rather than accents, shapes that run
// off the page edge, circles that break the column, and quotes lifted out of
// the flow. The stock is a shade off white so the sheen has something to be
// brighter than.
//
// Every page is built the same way: `bodySegments` for the words, `background`
// for the paper, `style` for the type. That combination is what keeps marking,
// read-aloud and auto-scroll working — a `body:` widget would give the same
// look and lose all three, because the package would no longer own the text.

import 'package:flutter/material.dart';
import 'package:page_curl_flip/page_curl_flip.dart';

// ── The palette ───────────────────────────────────────────────────────────

const kPink = Color(0xFFEE4C7C);
const kTeal = Color(0xFF2CB7AE);
const kStock = Color(0xFFF3F1EC); // paper, not #FFF — #FFF reads as a screen
const kInk = Color(0xFF2A2A2A);
const kInkSoft = Color(0xFF6E6E6E);
const kOnColour = Color(0xFFFFFFFF);
const kOnColourDim = Color(0xBFFFFFFF); // white at 75%, for secondary bar text

// ── Page one ──────────────────────────────────────────────────────────────

const kTitle1 = 'PAPER\nTHAT BENDS';
const kStand1 = 'PAGE CURL FLIP · ONE OF THREE';
const kQuote1 = 'DRAWN SLICE BY SLICE, SO IT BENDS INSTEAD OF SLIDING';

const kPage1 = <String>[
  'The curl is built from slices of the page, each mapped onto a cylinder, so '
      'the paper bends rather than slides. Set the pace with a preset — slow, '
      'medium, fast — or hand it any duration you like.',
  'Turn a page with a swipe or with the arrows. A flick up or down scrolls the '
      'page; only a sideways one turns it, so reading a long page never costs '
      'you your place.',
  'The whole book mirrors itself for right-to-left text. Arrows, swipes and '
      'the hint all flip, because the reading direction comes from the text '
      'itself and not from a setting anyone has to remember.',
  'A page can be plain, or carry its own background and its own type — this '
      'one does both, and the paper scrolls with the words rather than sitting '
      'behind them like wallpaper.',
  'Give the flip a sound and it plays one; give it none and the book is '
      'silent, with no speaker button left over to explain away.',
];

// ── Page two ──────────────────────────────────────────────────────────────

const kTitle2 = 'A BOOK\nTHAT SPEAKS';
const kStand2 = 'PAGE CURL FLIP · TWO OF THREE';
const kQuote2 = 'THE MARK MOVES WHEN THE VOICE FINISHES A SENTENCE, '
    'NOT ON A TIMER';

const kPage2 = <String>[
  'Press play and the book reads aloud, marking each sentence as it speaks. '
      'The voice is yours to supply — any engine at all — and the book asks '
      'only to be told when a sentence has finished.',
  'One press can read the entire book, turning its own pages as it goes and '
      'holding the screen awake, so a long listen never dies to a timeout.',
  'Because the mark moves on completion rather than on a clock, it cannot '
      'drift out of step: not at half speed, not at one and a half, and not on '
      'a device that speaks slower than the one it was written on.',
  'Choose the pace — slower to follow every word, faster when you already know '
      'them. The change takes effect at the next sentence, because restarting '
      'one mid-word sounds broken.',
  'On a page longer than the screen the view scrolls itself, following the '
      'voice down the page so the reader never has to chase it.',
  'Pause holds mid-sentence and resume continues that same sentence. Leaving '
      'the app stops the voice outright — a book should not keep talking from '
      'inside your pocket.',
];

// ── Page three ────────────────────────────────────────────────────────────

const kTitle3 = 'MADE\nYOURS';
const kStand3 = 'PAGE CURL FLIP · THREE OF THREE';
const kQuote3 = 'IT STORES NOTHING. YOUR MARKS GO WHEREVER YOUR APP KEEPS THEM';

const kPage3 = <String>[
  'Take the pencil and drag across a passage. The range grows out to whole '
      'words, then save keeps it and cancel drops it without leaving marking '
      'mode, so a second try costs one gesture.',
  'The marks are yours. The book hands every change to your app and keeps no '
      'database of its own — a reading widget has no business choosing where '
      'your words live.',
  'Bookmark the one page you carry on from, and collect the many pages worth '
      'returning to. Two different jobs, two different controls, and neither '
      'interrupts the voice.',
  'Open the contents to see the whole book at once, search it by title, and '
      'jump straight there. Clearing marks clears the page you are on, never '
      'the ones you are not.',
  'Export what matters: the pages you kept, the passages you marked, or the '
      'whole book. It hands over plain text and lets your app decide what a '
      'file should be.',
  'Every control names itself when you tap it, because an icon cannot explain '
      'itself and nobody long-presses a phone. And it brings nothing else with '
      'it — zero dependencies, on any platform.',
];

// ── Arabic ────────────────────────────────────────────────────────────────

const kTitle1Ar = 'ورقٌ\nينثني';
const kStand1Ar = 'page curl flip · الأولى من ثلاث';
const kQuote1Ar = 'يُرسم شريحةً شريحة، فينحني ولا ينزلق';

const kPage1Ar = <String>[
  'يُبنى الانثناء من شرائح الصفحة، كل شريحة مسقطة على أسطوانة، فينحني الورق '
      'ولا ينزلق. اضبط الإيقاع بإعداد جاهز — بطيء أو متوسط أو سريع — أو أعطه '
      'أي مدة تشاء.',
  'اقلب الصفحة بسحبة أو بالأسهم. السحب لأعلى ولأسفل يمرّر الصفحة، ولا يقلبها '
      'إلا السحب الجانبي، فلا تفقد موضعك في صفحة طويلة.',
  'ينقلب الكتاب كله للنص الذي يُقرأ من اليمين. تنعكس الأسهم والسحبات '
      'والتلميح، لأن اتجاه القراءة يأتي من النص نفسه لا من إعداد يتذكره أحد.',
  'قد تكون الصفحة سادة، وقد تحمل خلفيتها وخطها — وهذه تحمل الاثنين، ويبقى '
      'الورق يتحرك مع الكلمات لا خلفها كورق حائط.',
  'أعطِ القلب صوتاً فيصدح، ولا تعطه فيصمت الكتاب دون زر مكبّر يحتاج تفسيراً.',
];

const kTitle2Ar = 'كتابٌ\nينطق';
const kStand2Ar = 'page curl flip · الثانية من ثلاث';
const kQuote2Ar = 'تتحرك العلامة حين ينتهي الصوت من الجملة، لا بمؤقّت';

const kPage2Ar = <String>[
  'اضغط زر التشغيل فيقرأ لك الكتاب، ويعلّم كل جملة وهو ينطقها. الصوت صوتك '
      'أنت — أي محرّك كان — ولا يطلب الكتاب إلا أن يُخبَر متى انتهت الجملة.',
  'وضغطة واحدة قد تقرأ الكتاب كله، تقلب صفحاته بنفسها وتُبقي الشاشة صاحية، '
      'فلا ينقطع استماع طويل بانطفاء الشاشة.',
  'ولأن العلامة تتحرك عند الانتهاء لا بالساعة، فلا سبيل إلى أن تفقد التزامن: '
      'لا في نصف السرعة، ولا في واحد ونصف، ولا على جهاز ينطق أبطأ من الذي '
      'كُتبت عليه.',
  'اختر الإيقاع: أبطأ لتتابع كل كلمة، أو أسرع إن كنت تعرفها. ويسري التغيير من '
      'الجملة التالية، لأن إعادة جملة من منتصف كلمة تبدو عطباً.',
  'وفي صفحة أطول من الشاشة يتحرك العرض من تلقاء نفسه متتبعاً الصوت، فلا '
      'يلاحقه القارئ.',
  'يمسك «الإيقاف المؤقت» بالجملة في منتصفها، ويكمل «الاستئناف» الجملة نفسها. '
      'ومغادرة التطبيق توقف الصوت تماماً — لا ينبغي لكتاب أن يظل يتكلم في '
      'جيبك.',
];

const kTitle3Ar = 'صار\nلك';
const kStand3Ar = 'page curl flip · الثالثة من ثلاث';
const kQuote3Ar = 'لا يخزّن شيئاً. علاماتك تذهب حيث يحفظها تطبيقك';

const kPage3Ar = <String>[
  'خذ القلم واسحب فوق مقطع. يتّسع المدى ليشمل الكلمات كاملة، ثم يحفظه «حفظ» '
      'ويسقطه «إلغاء» دون أن تغادر وضع التعليم، فتكلّفك المحاولة الثانية حركة '
      'واحدة.',
  'العلامات علاماتك. يسلّم الكتاب كل تغيير إلى تطبيقك ولا يحتفظ بقاعدة بيانات '
      'خاصة به — فلا شأن لمكوّن قراءة باختيار مكان كلماتك.',
  'ضع إشارة على الصفحة الواحدة التي تتابع منها، واجمع الصفحات الكثيرة التي '
      'تستحق العودة. مهمتان مختلفتان وزرّان مختلفان، ولا يقاطع أيّهما الصوت.',
  'افتح «جدول المحتويات» لترى الكتاب كله، وابحث بالعنوان، وانتقل مباشرة. ومسح '
      'العلامات يمسح صفحتك وحدها، لا الصفحات التي لست فيها.',
  'صدّر ما يهمّك: الصفحات التي حفظتها، أو المقاطع التي علّمتها، أو الكتاب '
      'كاملاً. يسلّم نصاً عادياً ويترك لتطبيقك تقرير شكل الملف.',
  'وكل زر يسمّي نفسه حين تلمسه، فالأيقونة لا تشرح نفسها ولا أحد يضغط مطولاً '
      'على هاتفه. ولا يجلب معه شيئاً آخر — بلا أي تبعيات، على أي منصة.',
];

// ── The paper ─────────────────────────────────────────────────────────────

/// One magazine page. [variant] shifts where the blocks sit, so three pages in
/// a row are the same magazine without being the same picture.
class MagazinePaper extends StatelessWidget {
  const MagazinePaper({super.key, required this.quote, this.variant = 0});

  final String quote;
  final int variant;

  @override
  Widget build(BuildContext context) {
    final tucked = variant == 1;
    final accent = variant == 2 ? kPink : kTeal;
    final counter = variant == 2 ? kTeal : kPink;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const Positioned.fill(child: ColoredBox(color: kStock)),

        // The quote circle, running off a corner.
        PositionedDirectional(
          top: tucked ? -54 : -76,
          end: tucked ? -92 : -64,
          child: Container(
            width: 236,
            height: 236,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                tucked ? 58 : 34,
                tucked ? 52 : 66,
                22,
                0,
              ),
              child: Text(
                quote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kOnColour,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ),

        // The counterweight off the opposite corner.
        PositionedDirectional(
          bottom: -96,
          start: tucked ? -112 : -56,
          child: SizedBox(
            width: 264,
            height: 264,
            child: DecoratedBox(
              decoration: BoxDecoration(color: counter, shape: BoxShape.circle),
            ),
          ),
        ),

        const Positioned.fill(child: IgnorePointer(child: _Sheen())),

        // Weight at the fold, so the sheet reads as stock and not as screen.
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  stops: [0.0, 0.06, 1.0],
                  colors: [
                    Color(0x1A000000),
                    Color(0x08000000),
                    Color(0x00000000),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


/// One specular sweep as a page settles, then a resting highlight.
///
/// A single pass, never a loop: paper catches light while it moves and then
/// stops. A repeating shimmer reads as a web banner, not a magazine.
class _Sheen extends StatefulWidget {
  const _Sheen();

  @override
  State<_Sheen> createState() => _SheenState();
}

class _SheenState extends State<_Sheen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final Animation<double> _sweep =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _sweep,
        builder: (context, _) {
          final t = -1.6 + (_sweep.value * 2.4);
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(t - 0.9, -1.2),
                end: Alignment(t + 0.9, 1.2),
                stops: const [0.0, 0.42, 0.5, 0.58, 1.0],
                colors: const [
                  Color(0x00FFFFFF),
                  Color(0x24FFFFFF),
                  Color(0x8AFFFFFF),
                  Color(0x24FFFFFF),
                  Color(0x00FFFFFF),
                ],
              ),
            ),
          );
        },
      );
}

// ── The type ──────────────────────────────────────────────────────────────

const magazineStyle = FlipBookPageStyle(
  titleStyle: TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.8,
    height: 0.94,
    color: kPink,
  ),
  taglineStyle: TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.6,
    color: kInkSoft,
  ),
  bodyStyle: TextStyle(fontSize: 14, height: 1.85, color: kInk),
  // Clears the quote circle above and the block at the foot.
  padding: EdgeInsetsDirectional.fromSTEB(26, 128, 26, 150),
);

// ── Things that break the column ──────────────────────────────────────────

/// A quote lifted out of the flow, the way print does it.
class PullQuote extends StatelessWidget {
  const PullQuote({super.key, required this.text, this.color = kPink});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Container(
          padding: const EdgeInsets.all(22),
          color: color,
          child: Text(
            text,
            style: const TextStyle(
              color: kOnColour,
              fontSize: 19,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
}

enum Doodle { flutter, android, apple }

/// A circle with words beside it — the magazine's picture-and-caption block.
///
/// The caption belongs to the picture, so it is decoration: not read aloud and
/// not markable, exactly like a printed one. The paragraphs around it stay
/// laid out by the package and keep every feature.
class CircleCut extends StatelessWidget {
  const CircleCut({
    super.key,
    this.doodle = Doodle.flutter,
    required this.caption,
    this.logoOnEnd = true,
  });

  final Doodle doodle;
  final String caption;
  final bool logoOnEnd;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kTeal.withValues(alpha: 0.14),
        border: Border.all(color: kTeal, width: 3),
      ),
      alignment: Alignment.center,
      child: switch (doodle) {
        Doodle.flutter => const FlutterLogo(size: 52),
        Doodle.android =>
          const Icon(Icons.android, size: 52, color: Color(0xFF3DDC84)),
        Doodle.apple => const Icon(Icons.apple, size: 52, color: kInk),
      },
    );
    final words = Expanded(
      child: Text(
        caption,
        style: const TextStyle(fontSize: 13, height: 1.55, color: kInkSoft),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: logoOnEnd
            ? [words, const SizedBox(width: 18), circle]
            : [circle, const SizedBox(width: 18), words],
      ),
    );
  }
}

// ── Hint bar ──────────────────────────────────────────────────────────────

/// The swipe hint dressed like the footer: same grey bar, same radius.
///
/// The package draws the hint as bare text with chevrons; anything richer
/// is the app's business, which is what the `child` slot is for.
class HintBar extends StatelessWidget {
  const HintBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF0EEEEEE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: DefaultTextStyle(
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: kInk,
          ),
          child: child,
        ),
      ),
    );
  }
}
