import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'capture.dart';
import 'curl_overlay.dart';
import 'flip_book_icons.dart';
import 'flip_book_page.dart';
import 'flip_book_strings.dart';
import 'flip_book_theme.dart';
import 'flip_speed.dart';

/// Drives a [FlipBook] from outside the widget — flip, jump, open the table
/// of contents, mute — so an app can hide the built-in buttons
/// ([FlipBook.showControls] = `false`) and draw its own controls anywhere:
///
/// ```dart
/// final controller = FlipBookController();
///
/// FlipBook(
///   controller: controller,
///   showControls: false,
///   pages: [...],
///   onClose: () {},
/// );
///
/// // Your own button, any position, any style:
/// FloatingActionButton(onPressed: controller.nextPage);
/// ```
///
/// The controller shares this file with [FlipBook] — the same pattern Flutter
/// uses for `ExpansionTileController` — because it operates directly on the
/// widget's private state.
class FlipBookController {
  // Attach order, oldest first. The last entry is the book being driven;
  // when it is disposed the previous one automatically takes over (EDG-08).
  final List<_FlipBookState> _attached = [];

  _FlipBookState? get _state => _attached.isEmpty ? null : _attached.last;

  void _attach(_FlipBookState state) {
    _attached
      ..remove(state)
      ..add(state);
  }

  void _detach(_FlipBookState state) {
    _attached.remove(state);
  }

  /// Whether a [FlipBook] is currently attached to this controller.
  bool get isAttached => _state != null;

  /// Index of the page the book is showing; 0 while detached.
  int get page => _state?._pageIndex ?? 0;

  /// Whether the flip sound is currently muted.
  bool get isMuted => _state?._muted ?? false;

  /// Flips forward one page with the curl animation, honouring the book's
  /// reading direction. Does nothing on the last page or while detached.
  Future<void> nextPage() async => _state?._goNext();

  /// Flips back one page with the curl animation, honouring the book's
  /// reading direction. Does nothing on the first page or while detached.
  Future<void> previousPage() async => _state?._goPrev();

  /// Jumps straight to the page at [index] with no animation — the same move
  /// as tapping an entry in the table of contents. Out-of-range indices are
  /// ignored.
  void jumpToPage(int index) {
    final state = _state;
    if (state == null || index < 0 || index >= state._pageCount) {
      return;
    }
    state._jumpToPage(index);
  }

  /// Opens the table of contents. Needs at least one page with a title.
  /// Ignored while a flip is in progress (EDG-05) — the TOC opening over a
  /// half-finished animation would show inconsistent page state.
  void openIndex() {
    final state = _state;
    if (state == null ||
        !state._hasIndex ||
        state._showIndex ||
        state._flipPhase != _FlipPhase.idle) {
      return;
    }
    state._toggleIndex();
  }

  /// Closes the table of contents if it is open.
  void closeIndex() {
    final state = _state;
    if (state == null || !state._showIndex) {
      return;
    }
    state._toggleIndex();
  }

  /// Mutes or unmutes the flip sound.
  void toggleMute() => _state?._toggleMute();
}

/// A multi-page book widget with a cylindrical page-curl transition.
///
/// Supply [pages] as [FlipBookPage] objects — all navigation, animation,
/// table-of-contents, and sound control are handled internally. Every visual
/// style comes from [theme] and every built-in label from [strings], so the
/// widget carries no design-system or language assumptions.
///
/// ```dart
/// FlipBook(
///   onClose: () => Navigator.of(context).pop(),
///   pages: const [
///     FlipBookPage(title: 'My Book', tagline: 'a cover page'),
///     FlipBookPage(title: 'Chapter 1', body: ChapterWidget()),
///   ],
/// )
/// ```
///
/// The package ships no audio: provide [onPageFlip] to play your own flip
/// sound (see the example for an `audioplayers` wiring) and a mute button
/// appears in the footer. No callback — or [enableSound] set to `false` —
/// means a silent book with no speaker button.
///
/// The flip direction follows the ambient [Directionality]: in RTL locales
/// "next" curls the opposite way, matching how a real book reads.
///
/// To draw your own buttons instead of the built-in ones, hide them with
/// [showControls] = `false` and drive the book through a [FlipBookController].
class FlipBook extends StatefulWidget {
  /// Creates a flip book.
  const FlipBook({
    super.key,
    required this.pages,
    required this.onClose,
    this.theme = const FlipBookTheme(),
    this.strings = const FlipBookStrings(),
    this.icons = const FlipBookIcons(),
    this.flipSpeed = FlipSpeed.medium,
    this.pageColor = Colors.white,
    this.enableSound = true,
    this.showMuteButton = true,
    this.showControls = true,
    this.showNavButtons = true,
    this.swipeToFlip = true,
    this.showSwipeHint = true,
    this.swipeHintDelay = const Duration(seconds: 20),
    this.swipeHintDuration = const Duration(seconds: 3),
    this.swipeHintMaxSwipes = 3,
    this.controller,
    this.initialPage = 0,
    this.onPageChanged,
    this.showPageNumber = false,
    this.textDirection,
    this.headerAction,
    this.onPageFlip,
    this.onReadAloud,
    this.onReadAloudStop,
    this.onReadAloudPause,
    this.onReadAloudResume,
    this.shine,
    this.shadow,
  });

  /// The book's pages, in reading order.
  final List<FlipBookPage> pages;

  /// Called when the × close button is tapped.
  final VoidCallback onClose;

  /// Visual styling; defaults to neutral colours for white paper.
  final FlipBookTheme theme;

  /// Built-in labels; defaults to English. Override for localization.
  final FlipBookStrings strings;

  /// Every icon the book draws; defaults to Material icons. Override any of
  /// them — the package is the skeleton, decoration is yours.
  final FlipBookIcons icons;

  /// Duration preset of the flip animation.
  final FlipSpeed flipSpeed;

  /// Paper colour of every page.
  final Color pageColor;

  /// Master switch for the flip sound. While `true` (default) each flip
  /// fires [onPageFlip] and a mute button shows; `false` silences the book
  /// and hides the button — without removing your callback wiring.
  final bool enableSound;

  /// Whether the mute button is shown while [enableSound] is `true`.
  /// Set `false` to keep the flip sound but hide the speaker button.
  final bool showMuteButton;

  /// Whether the built-in controls render at all: the × close button, the
  /// INDEX button, the mute button, and PREV/NEXT. Set `false` to show pure
  /// pages and drive the book yourself through a [FlipBookController].
  final bool showControls;

  /// Whether the PREV/NEXT buttons render. Turn off for a swipe-only book —
  /// swiping ([swipeToFlip]) and the controller keep working.
  final bool showNavButtons;

  /// Whether a horizontal swipe turns the page (default on). The gesture
  /// drives the same curl animation as the buttons, honouring the reading
  /// direction: in LTR swipe left for next; in RTL swipe right.
  final bool swipeToFlip;

  /// Shows the swipe hint — the hint text between two runs of chevrons
  /// that fade away from the words, no background, no container. It appears
  /// the moment a page is entered, fades after [swipeHintDuration], and
  /// returns every [swipeHintDelay] for as long as the reader stays on the
  /// page. On by default; set `false` to remove it. After
  /// [swipeHintMaxSwipes] swipes the gesture counts as learned and the hint
  /// retires for the life of the book. Customize the text via
  /// `FlipBookStrings.swipeHint`, the colour / size / font via
  /// `FlipBookTheme.swipeHintStyle`, and the chevrons via
  /// `FlipBookTheme.swipeHintArrowSize`.
  final bool showSwipeHint;

  /// How long after the hint fades before it comes back on the same page.
  final Duration swipeHintDelay;

  /// How long the hint stays visible each time it appears.
  final Duration swipeHintDuration;

  /// How many swipes until the hint considers the gesture learned and stops
  /// appearing for the rest of the book's life.
  final int swipeHintMaxSwipes;

  /// Drives the book from outside the widget — see [FlipBookController].
  final FlipBookController? controller;

  /// The page the book opens at (clamped into range) — restore your
  /// reader's place with `initialPage: prefs.getInt('lastPage') ?? 0`.
  final int initialPage;

  /// Fires whenever the shown page changes (flip, jump, TOC tap) with the
  /// new index — persist it to restore via [initialPage].
  final ValueChanged<int>? onPageChanged;

  /// Shows a small "3 / 12" position indicator in the footer.
  final bool showPageNumber;

  /// Overrides the book's reading direction. When `null` (default) the book
  /// follows the ambient [Directionality]: left-to-right under English,
  /// Dutch, German and other LTR locales, right-to-left automatically under
  /// Arabic, Hebrew and other RTL locales. Set it to force a direction
  /// regardless of the app's locale.
  final TextDirection? textDirection;

  /// Optional widget shown at the trailing edge of the header.
  final Widget? headerAction;

  /// Your flip sound: called at the start of every flip. The package plays
  /// nothing itself — bring any audio plugin or service you like. Ignored
  /// while [enableSound] is `false`.
  final Future<void> Function()? onPageFlip;

  /// When set, a read-aloud button appears in the footer; tapping it calls
  /// this with the index of the page being shown. The package plays nothing
  /// itself — hook up any text-to-speech engine or service you like.
  ///
  /// The returned future should complete when reading finishes. While it is
  /// pending the centre control shows pause (when [onReadAloudPause] and
  /// [onReadAloudResume] are provided) and stop buttons. Reading stops
  /// automatically when the user flips or jumps to another page.
  final Future<void> Function(int pageIndex)? onReadAloud;

  /// Called when the user taps the read-aloud button while reading is in
  /// progress, or navigates away mid-read — stop your speech engine here.
  final VoidCallback? onReadAloudStop;

  /// Called when the user taps pause while reading. The pause button only
  /// appears when both this and [onReadAloudResume] are provided.
  final VoidCallback? onReadAloudPause;

  /// Called when the user taps play while paused — continue the speech from
  /// where it stopped. The returned future should complete when reading
  /// finishes.
  final Future<void> Function()? onReadAloudResume;

  /// Strength of the sheen on the curling paper, 0–1. `null` (default)
  /// adapts to [pageColor] — full sheen on white paper, a whisper on dark
  /// paper. `0` removes the light completely.
  final double? shine;

  /// Strength of the curl's depth shadow, 0–1. `null` (default) uses the
  /// standard shadow; `0` removes it.
  final double? shadow;

  @override
  State<FlipBook> createState() => _FlipBookState();
}

class _FlipBookState extends State<FlipBook>
    with SingleTickerProviderStateMixin {
  int _pageIndex = 0;
  int _nextIndex = 0;
  _FlipPhase _flipPhase = _FlipPhase.idle;
  bool _muted = false;
  bool _showIndex = false;

  _ReadPhase _readPhase = _ReadPhase.idle;
  int _readSession = 0;
  bool _swipeHintVisible = false;
  int _swipeHintSwipeCount = 0;
  Timer? _swipeHintTimer;

  ui.Image? _capturedImage;
  final _repaintKey = GlobalKey();
  final _prevCaptureKey = GlobalKey();

  late final AnimationController _ctrl;
  late final CurvedAnimation _curved;

  int get _pageCount => widget.pages.length;
  bool get _hasIndex =>
      widget.pages.any((p) => p.title?.trim().isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    if (widget.pages.isNotEmpty) {
      _pageIndex = widget.initialPage.clamp(0, widget.pages.length - 1);
      _nextIndex = _pageIndex;
    }
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.flipSpeed.duration,
    );
    _curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    widget.controller?._attach(this);
    if (_swipeHintEligible) {
      _swipeHintVisible = true;
      _armSwipeHintHide();
    }
  }

  bool get _swipeHintEligible =>
      widget.showSwipeHint &&
      widget.swipeToFlip &&
      _swipeHintSwipeCount < widget.swipeHintMaxSwipes;

  /// The hint cycle: the hint is already visible when this is called (a
  /// page was just entered, or the cycle brought it back). It fades after
  /// [FlipBook.swipeHintDuration] and returns every
  /// [FlipBook.swipeHintDelay] for as long as the reader stays on the page.
  /// After [FlipBook.swipeHintMaxSwipes] swipes the cycle retires for good.
  void _armSwipeHintHide() {
    _swipeHintTimer?.cancel();
    _swipeHintTimer = Timer(widget.swipeHintDuration, () {
      if (mounted) {
        setState(() => _swipeHintVisible = false);
      }
      _swipeHintTimer = Timer(widget.swipeHintDelay, () {
        if (!mounted || !_swipeHintEligible) {
          return;
        }
        setState(() => _swipeHintVisible = true);
        _armSwipeHintHide();
      });
    });
  }

  /// Counts a swipe toward retiring the hint. Until the reader reaches
  /// [FlipBook.swipeHintMaxSwipes] the hint keeps greeting new pages; after
  /// that the gesture counts as learned and the cycle never returns.
  void _countSwipeForHint() {
    _swipeHintSwipeCount++;
    _swipeHintTimer?.cancel();
    if (_swipeHintVisible) {
      setState(() => _swipeHintVisible = false);
    }
  }

  /// The hint line: `‹‹‹‹ Swipe ››››` — chevrons darkest at the outer ends,
  /// fading step by step toward the text for a fade-away look. The chevrons
  /// overlap into a tight, broad train. Text, colour, size, and font all
  /// come from `strings.swipeHint` / `theme.swipeHintStyle` /
  /// `theme.swipeHintArrowSize`.
  Widget _buildSwipeHint() {
    final style = widget.theme.swipeHintStyle;
    final color = style.color ?? const Color(0xFF555555);
    // Outermost chevron (dark) → the one touching the text (lightest).
    const fades = [1.0, 0.7, 0.45, 0.2];
    Widget arrow(IconData glyph, double fade) => Align(
          widthFactor: 0.6, // overlap neighbours into a tight ‹‹‹‹ train
          child: Icon(
            glyph,
            size: widget.theme.swipeHintArrowSize,
            color: color.withValues(alpha: color.a * fade),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      // Scale down rather than overflow when a long hint text meets a
      // narrow phone — the line always fits on one row.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Directionality(
          // Visual order is fixed: left-pointing chevrons sit left, in
          // every locale. RTL scripts inside the Text still render
          // correctly.
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final fade in fades) arrow(widget.icons.previous, fade),
              const SizedBox(width: 10),
              Text(widget.strings.swipeHint, style: style),
              const SizedBox(width: 10),
              for (final fade in fades.reversed) arrow(widget.icons.next, fade),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(FlipBook old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      old.controller?._detach(this);
      widget.controller?._attach(this);
    }
    // EDG-03: a rebuilt flipSpeed must take effect, not stay frozen at
    // whatever initState saw.
    if (widget.flipSpeed != old.flipSpeed) {
      _ctrl.duration = widget.flipSpeed.duration;
    }
    // EDG-02: a shrunken pages list must never leave the shown index past
    // the new end.
    final maxIndex = _pageCount == 0 ? 0 : _pageCount - 1;
    if (_pageIndex > maxIndex) {
      _pageIndex = maxIndex;
      // The shown page really changed — the persistence seam must hear it,
      // or an app restoring via onPageChanged keeps a stale index forever.
      widget.onPageChanged?.call(_pageIndex);
    }
    if (_nextIndex > maxIndex) {
      _nextIndex = maxIndex;
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _swipeHintTimer?.cancel();
    // Reverse order of creation: the curve listens to the controller, so it
    // must detach before the controller goes away.
    _curved.dispose();
    _ctrl.dispose();
    _capturedImage?.dispose();
    super.dispose();
  }

  /// Fires the caller's [FlipBook.onPageFlip] — the package ships no sound
  /// of its own. Best-effort: a failing sound must never interrupt the flip.
  Future<void> _playFlipSound() async {
    try {
      await widget.onPageFlip?.call();
    } catch (_) {
      // Sound is decoration; the flip goes on.
    }
  }

  void _toggleMute() => setState(() => _muted = !_muted);
  void _toggleIndex() => setState(() => _showIndex = !_showIndex);

  /// EDG-04: an explicit jump is the user's latest intent, so it wins over
  /// any flip in flight — the animation is aborted, its bitmap released, and
  /// the pending flip continuation sees a changed phase and gives up.
  void _jumpToPage(int index) {
    _stopReading();
    if (_flipPhase == _FlipPhase.animatingForward ||
        _flipPhase == _FlipPhase.animatingBackward) {
      _ctrl.stop();
    }
    final abandoned = _capturedImage;
    final changed = _pageIndex != index;
    setState(() {
      _flipPhase = _FlipPhase.idle;
      _capturedImage = null;
      _pageIndex = index;
      _showIndex = false;
      _swipeHintVisible = _swipeHintEligible; // the hint greets every page
    });
    abandoned?.dispose();
    if (_swipeHintEligible) {
      _armSwipeHintHide();
    }
    if (changed) {
      widget.onPageChanged?.call(_pageIndex);
    }
  }

  // ── Read-aloud ─────────────────────────────────────────────────────────────
  // Idle shows a single play button. Playing shows pause (when the caller
  // supports it) and stop. Paused shows play (resume) and stop. _readSession
  // guards against a stale future's completion overwriting a newer state:
  // pause and stop both invalidate the session, so the previous await's
  // continuation is ignored.

  bool get _canPauseReading =>
      widget.onReadAloudPause != null && widget.onReadAloudResume != null;

  Future<void> _awaitReading(int session, Future<void> future) async {
    try {
      await future;
    } catch (_) {
      // The speech engine failed — fall through to the idle transition.
    }
    if (!mounted || session != _readSession) {
      return;
    }
    setState(() => _readPhase = _ReadPhase.idle);
  }

  void _playReading(int page) {
    // EDG-06: two taps inside one frame must not start two speech sessions.
    if (_readPhase != _ReadPhase.idle) {
      return;
    }
    final session = ++_readSession;
    setState(() => _readPhase = _ReadPhase.playing);
    unawaited(_awaitReading(session, widget.onReadAloud!(page)));
  }

  void _pauseReading() {
    if (_readPhase != _ReadPhase.playing) {
      return;
    }
    _readSession++;
    widget.onReadAloudPause?.call();
    setState(() => _readPhase = _ReadPhase.paused);
  }

  void _resumeReading() {
    final session = ++_readSession;
    setState(() => _readPhase = _ReadPhase.playing);
    unawaited(_awaitReading(session, widget.onReadAloudResume!()));
  }

  void _stopReading() {
    if (_readPhase == _ReadPhase.idle) {
      return;
    }
    _readSession++;
    widget.onReadAloudStop?.call();
    setState(() => _readPhase = _ReadPhase.idle);
  }

  // ── Forward flip (NEXT) ────────────────────────────────────────────────────
  // Captures the current page, shows the target page underneath, then peels
  // the captured snapshot away left→right (progress 0→1).

  Future<void> _flipToNext(int target) async {
    if (_flipPhase != _FlipPhase.idle || target < 0 || target >= _pageCount) {
      return;
    }
    _stopReading();

    if (widget.enableSound && !_muted) {
      unawaited(_playFlipSound());
    }

    // Capture the current page as bitmap so it can curl away — synchronous,
    // so there is no gap between deciding to flip and starting to animate.
    final captured = capturePage(
      _repaintKey,
      pixelRatio: captureRatioOf(context),
    );

    setState(() {
      _nextIndex = target;
      _capturedImage = captured;
      _flipPhase = _FlipPhase.animatingForward;
    });

    await _animateCurl(forward: true);

    if (!mounted || _flipPhase != _FlipPhase.animatingForward) {
      // Disposed, or a jump aborted this flip and owns the state now.
      return;
    }

    _finishFlip();
  }

  // ── Backward flip (PREV) ───────────────────────────────────────────────────
  // Phase 1: renders the target page below the current page for one frame and
  // captures it as a bitmap (invisible to the user — current page covers it).
  // Phase 2: animates the captured bitmap descending onto the current page
  // (progress 1→0) so strips carry the prev-page texture as they settle flat.

  Future<void> _flipToPrev(int target) async {
    if (_flipPhase != _FlipPhase.idle || target < 0 || target >= _pageCount) {
      return;
    }
    _stopReading();

    if (widget.enableSound && !_muted) {
      unawaited(_playFlipSound());
    }

    // Phase 1: render target page hidden below current page for capture.
    setState(() {
      _nextIndex = target;
      _flipPhase = _FlipPhase.capturingPrev;
    });

    // Wait one frame so the capture target is laid out and painted.
    final frameDone = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => frameDone.complete());
    await frameDone.future;

    if (!mounted || _flipPhase != _FlipPhase.capturingPrev) {
      // Disposed, or a jump aborted this flip during the frame wait.
      return;
    }

    final captured = capturePage(
      _prevCaptureKey,
      pixelRatio: captureRatioOf(context),
    );

    // Phase 2: animate the captured bitmap descending (progress 1→0).
    setState(() {
      _capturedImage = captured;
      _flipPhase = _FlipPhase.animatingBackward;
    });

    await _animateCurl(forward: false);

    if (!mounted || _flipPhase != _FlipPhase.animatingBackward) {
      return;
    }

    _finishFlip();
  }

  /// Runs the curl animation. If the widget is disposed mid-flight the
  /// returned [TickerFuture] simply never completes and `dispose()` has
  /// already released the captured image — no cleanup is missed.
  Future<void> _animateCurl({required bool forward}) =>
      forward ? _ctrl.forward(from: 0) : _ctrl.reverse(from: 1.0);

  void _finishFlip() {
    final toDispose = _capturedImage;
    final changed = _pageIndex != _nextIndex;
    setState(() {
      _pageIndex = _nextIndex;
      _flipPhase = _FlipPhase.idle;
      _capturedImage = null;
      _swipeHintVisible = _swipeHintEligible; // the hint greets every page
    });
    toDispose?.dispose();
    if (_swipeHintEligible) {
      _armSwipeHintHide();
    }
    if (changed) {
      widget.onPageChanged?.call(_pageIndex);
    }
  }

  /// Lays out a page from its optional parts. Without a printed title or
  /// tagline the body fills the paper edge-to-edge (full layout control stays
  /// with the caller); otherwise the book applies its own layout.
  Widget _pageContent(FlipBookPage page) {
    final printedTitle = page.showTitleOnPage ? page.title : null;
    if (printedTitle == null && page.tagline == null) {
      return page.body ?? const SizedBox.shrink();
    }
    return Padding(
      padding: widget.theme.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // maxLines bounds the header so a long title at large text scale
          // can never push the body into a RenderFlex overflow (LAY-06).
          if (printedTitle != null)
            Text(
              printedTitle,
              style: widget.theme.pageTitleStyle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          if (printedTitle != null && page.tagline != null)
            const SizedBox(height: 6),
          if (page.tagline != null)
            Text(
              page.tagline!,
              style: widget.theme.pageTaglineStyle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          if (page.body != null) ...[
            const SizedBox(height: 20),
            Expanded(child: page.body!),
          ],
        ],
      ),
    );
  }

  TextDirection get _direction =>
      widget.textDirection ?? Directionality.of(context);

  /// A horizontal fling turns the page — the same smooth animation the
  /// buttons trigger, direction-aware: in LTR a leftward swipe goes
  /// forward; in RTL a rightward swipe does.
  void _onSwipe(DragEndDetails details) {
    if (!widget.swipeToFlip || _showIndex || _flipPhase != _FlipPhase.idle) {
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 80) {
      return; // Too gentle to be a page turn.
    }
    final backward = _direction == TextDirection.rtl
        ? velocity < 0 // RTL: leftward swipe goes back.
        : velocity > 0; // LTR: rightward swipe goes back.
    // Only a swipe that actually turns a page counts toward "learned" —
    // a fling at the edge of the book flips nothing and proves nothing.
    final canFlip = backward ? _pageIndex > 0 : _pageIndex < _pageCount - 1;
    if (!canFlip) {
      return;
    }
    _countSwipeForHint(); // One swipe closer to "gesture learned".
    unawaited(backward ? _goPrev() : _goNext());
  }

  /// Direction-aware navigation: in RTL the forward flip uses the backward
  /// animation so the page curls the way an RTL book actually turns.
  Future<void> _goNext() {
    final target = _pageIndex + 1;
    if (target >= _pageCount) {
      return Future<void>.value();
    }
    return _direction == TextDirection.rtl
        ? _flipToPrev(target)
        : _flipToNext(target);
  }

  Future<void> _goPrev() {
    final target = _pageIndex - 1;
    if (target < 0) {
      return Future<void>.value();
    }
    return _direction == TextDirection.rtl
        ? _flipToNext(target)
        : _flipToPrev(target);
  }

  Widget _buildPage(int index) {
    // EDG-01: an empty pages list renders blank paper, never a RangeError —
    // apps that build pages from async data show the book before the fetch.
    final page = _pageCount == 0
        ? const FlipBookPage()
        : widget.pages[index.clamp(0, _pageCount - 1)];
    // A page that prints nothing above its body owns the WHOLE screen —
    // the chrome floats on top instead of reserving cream strips above and
    // below (the "80% dark page" bug).
    final fullBleed = (page.title == null || !page.showTitleOnPage) &&
        page.tagline == null &&
        page.body != null;
    return _FlipBookScaffold(
      fullBleed: fullBleed,
      content: _pageContent(page),
      theme: widget.theme,
      strings: widget.strings,
      icons: widget.icons,
      pageNumber: widget.showPageNumber ? '${index + 1} / $_pageCount' : null,
      headerAction: widget.headerAction,
      hasIndex: _hasIndex,
      isMuted: _muted,
      showControls: widget.showControls,
      onClose: widget.onClose,
      onNext: widget.showNavButtons && index < _pageCount - 1 ? _goNext : null,
      onPrev: widget.showNavButtons && index > 0 ? _goPrev : null,
      onMuteToggle: widget.enableSound &&
              widget.showMuteButton &&
              widget.onPageFlip != null
          ? _toggleMute
          : null,
      readPhase: _readPhase,
      canPauseReading: _canPauseReading,
      onReadPlay: widget.onReadAloud != null
          ? () => _readPhase == _ReadPhase.paused
              ? _resumeReading()
              : _playReading(index)
          : null,
      onReadPause: _pauseReading,
      onReadStop: _stopReading,
      onToggleIndex: _toggleIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = Scaffold(
      backgroundColor: widget.pageColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _onSwipe,
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // PREV capture target — rendered below the current page so it is
              // painted (toImage works) but invisible to the user.
              // ColoredBox gives it a solid background so it can be captured
              // correctly (page content on pageColor, no transparency).
              if (_flipPhase == _FlipPhase.capturingPrev)
                RepaintBoundary(
                  key: _prevCaptureKey,
                  child: ColoredBox(
                    color: widget.pageColor,
                    child: _buildPage(_nextIndex),
                  ),
                ),

              if (_showIndex && _hasIndex)
                _IndexPage(
                  pages: widget.pages,
                  currentPage: _pageIndex,
                  headerAction: widget.headerAction,
                  theme: widget.theme,
                  strings: widget.strings,
                  icons: widget.icons,
                  onSelect: _jumpToPage,
                  onClose: _toggleIndex,
                )
              else if (_flipPhase == _FlipPhase.animatingForward)
                // NEXT: destination page shows through as the current page peels
                // away. IgnorePointer keeps layout identical (buttons present)
                // so there is no footer shift when animation ends.
                IgnorePointer(
                  child: _buildPage(_nextIndex),
                )
              else
                // PREV (animating or idle): ColoredBox makes this page opaque so
                // it fully hides the capture target stacked below during
                // _capturingPrev. IgnorePointer blocks touches during animation
                // without changing the widget tree, so no layout shift occurs.
                IgnorePointer(
                  ignoring: _flipPhase == _FlipPhase.animatingBackward,
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: ColoredBox(
                      color: widget.pageColor,
                      child: _buildPage(_pageIndex),
                    ),
                  ),
                ),

              if ((_flipPhase == _FlipPhase.animatingForward ||
                      _flipPhase == _FlipPhase.animatingBackward) &&
                  !_showIndex)
                AnimatedBuilder(
                  animation: _curved,
                  builder: (_, __) => CurlOverlay(
                    progress: _curved.value,
                    pageImage: _capturedImage,
                    pageColor: widget.pageColor,
                    shine: widget.shine,
                    shadow: widget.shadow,
                  ),
                ),

              // Transient swipe hint — no pill, no background: just the
              // text with fading chevrons. It greets every page and returns
              // on a FlipBook.swipeHintDelay cycle while the reader stays.
              if (widget.showSwipeHint && widget.swipeToFlip && !_showIndex)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 96,
                  child: IgnorePointer(
                    child: Center(
                      // AnimatedSwitcher rather than AnimatedOpacity so the
                      // hint leaves the tree entirely while hidden — its
                      // chevrons must not pollute icon finders or semantics.
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        child: _swipeHintVisible
                            ? _buildSwipeHint()
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final dir = widget.textDirection;
    return dir == null ? book : Directionality(textDirection: dir, child: book);
  }
}

// ── Read phase ────────────────────────────────────────────────────────────────

/// Lifecycle of the centre read-aloud control.
enum _ReadPhase { idle, playing, paused }

/// Lifecycle of a page flip. One value instead of four booleans: illegal
/// combinations (capturing while animating, busy while idle) are
/// unrepresentable, and every guard reads a single field.
enum _FlipPhase {
  /// No flip in progress.
  idle,

  /// PREV phase 1: the target page renders hidden for one frame so it can
  /// be captured.
  capturingPrev,

  /// The captured page is peeling away (NEXT).
  animatingForward,

  /// The captured page is descending back (PREV).
  animatingBackward,
}

// ── Scaffold ──────────────────────────────────────────────────────────────────

class _FlipBookScaffold extends StatelessWidget {
  const _FlipBookScaffold({
    required this.content,
    required this.theme,
    required this.strings,
    required this.icons,
    required this.isMuted,
    required this.hasIndex,
    required this.showControls,
    required this.readPhase,
    required this.canPauseReading,
    required this.fullBleed,
    this.pageNumber,
    this.headerAction,
    this.onClose,
    this.onNext,
    this.onPrev,
    this.onMuteToggle,
    this.onReadPlay,
    this.onReadPause,
    this.onReadStop,
    this.onToggleIndex,
  });

  final Widget content;
  final FlipBookTheme theme;
  final FlipBookStrings strings;
  final FlipBookIcons icons;
  final bool isMuted;
  final bool hasIndex;
  final bool showControls;
  final _ReadPhase readPhase;
  final bool canPauseReading;
  final bool fullBleed;
  final String? pageNumber;
  final Widget? headerAction;
  final VoidCallback? onClose;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final VoidCallback? onMuteToggle;
  final VoidCallback? onReadPlay;
  final VoidCallback? onReadPause;
  final VoidCallback? onReadStop;
  final VoidCallback? onToggleIndex;

  @override
  Widget build(BuildContext context) {
    if (!showControls) {
      // Chrome-free book: pure pages, driven by a FlipBookController.
      return content;
    }
    if (fullBleed) {
      // Body-only page: the body paints edge to edge — dark pages are
      // fully dark — and the chrome floats above it.
      return Stack(
        fit: StackFit.expand,
        children: [
          content,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const Spacer(),
              _footer(),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),

        // ── Content ───────────────────────────────────────────────────────────
        Expanded(child: content),

        // ── Footer ────────────────────────────────────────────────────────────
        _footer(),
      ],
    );
  }

  Widget _header() {
    return _FlipBookHeader(
      closeIcon: icons.close,
      closeIconColor: theme.closeIconColor,
      closeLabel: strings.close,
      onClose: onClose,
      headerAction: headerAction,
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left group: INDEX · mute. The icon buttons carry their own
          // padding as tap area, so the visible gap stays small while the
          // touch targets do not overlap the INDEX button.
          if (hasIndex && onToggleIndex != null)
            _FooterButton(
              label: strings.index,
              style: theme.indexButtonStyle,
              onTap: onToggleIndex!,
            ),
          if (hasIndex && onToggleIndex != null && onMuteToggle != null)
            const SizedBox(width: 4),
          if (onMuteToggle != null)
            _FooterIconButton(
              icon: isMuted ? icons.volumeOff : icons.volumeOn,
              label: isMuted ? strings.unmute : strings.mute,
              color: theme.muteIconColor,
              onTap: onMuteToggle!,
            ),

          const Spacer(),

          // Centre: optional "3 / 12" indicator, then the read-aloud
          // control. Idle → play. Playing → pause (when supported) +
          // stop. Paused → play + stop.
          if (pageNumber != null) ...[
            Text(pageNumber!, style: theme.pageNumberStyle),
            if (onReadPlay == null) const Spacer(),
          ],
          if (pageNumber != null && onReadPlay != null)
            const SizedBox(width: 10),
          if (onReadPlay != null) ...[
            if (readPhase != _ReadPhase.playing)
              _FooterIconButton(
                icon: icons.play,
                label: strings.readAloud,
                color: theme.muteIconColor,
                onTap: onReadPlay!,
              ),
            if (readPhase == _ReadPhase.playing && canPauseReading)
              _FooterIconButton(
                icon: icons.pause,
                label: strings.pauseReading,
                color: theme.muteIconColor,
                onTap: onReadPause!,
              ),
            if (readPhase != _ReadPhase.idle)
              _FooterIconButton(
                icon: icons.stop,
                label: strings.stopReading,
                color: theme.muteIconColor,
                onTap: onReadStop!,
              ),
            const Spacer(),
          ],

          // Right group (mirrored to the left under RTL): PREV · NEXT
          if (onPrev != null)
            _NavButton(
              label: strings.previous,
              style: theme.navButtonStyle,
              icon: icons.previous,
              iconColor: theme.navButtonIconColor,
              isNext: false,
              onTap: onPrev!,
            ),
          if (onPrev != null && onNext != null) const SizedBox(width: 16),
          if (onNext != null)
            _NavButton(
              label: strings.next,
              style: theme.navButtonStyle,
              icon: icons.next,
              iconColor: theme.navButtonIconColor,
              isNext: true,
              onTap: onNext!,
            ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _FlipBookHeader extends StatelessWidget {
  const _FlipBookHeader({
    required this.closeIcon,
    required this.closeIconColor,
    required this.closeLabel,
    this.onClose,
    this.headerAction,
  });

  final IconData closeIcon;
  final Color closeIconColor;
  final String closeLabel;
  final VoidCallback? onClose;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            // The explicit semanticLabel is what screen readers announce;
            // the tooltip alone only fills the tooltip attribute (ACC-01).
            icon: Icon(closeIcon, size: 20, semanticLabel: closeLabel),
            color: closeIconColor,
            tooltip: closeLabel,
          ),
          const Spacer(),
          if (headerAction != null) headerAction!,
        ],
      ),
    );
  }
}

// ── Footer icon button ────────────────────────────────────────────────────────

/// A small footer icon with a generous tap area: the 16 px glyph sits inside
/// symmetric padding and an opaque hit box, so fingers land reliably without
/// the icons drifting visually apart.
class _FooterIconButton extends StatelessWidget {
  const _FooterIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ── Footer button ─────────────────────────────────────────────────────────────

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    required this.style,
    required this.onTap,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label, style: style),
        ),
      ),
    );
  }
}

// ── Nav button ────────────────────────────────────────────────────────────────

/// PREV/NEXT with an EXPLICIT visual layout — no inherited-direction
/// surprises. The moment the book is RTL, icon and text swap positions and
/// the glyph mirrors, producing exactly:
///
///   LTR:  ‹ PREV        NEXT ›
///   RTL:  ‹التالي       السابق›
///
/// i.e. the arrow always sits on the outside, pointing the way the page
/// travels. The inner Row is pinned to LTR so its child order IS the
/// on-screen order, whatever the ambient direction.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.style,
    required this.icon,
    required this.iconColor,
    required this.isNext,
    required this.onTap,
  });

  final String label;
  final TextStyle style;
  final IconData icon;
  final Color iconColor;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    Widget iconWidget = Icon(icon, size: 16, color: iconColor);
    if (isRtl) {
      // Mirror the glyph so any custom arrow points with the page travel.
      iconWidget = Transform.flip(flipX: true, child: iconWidget);
    }
    final text = Text(label, style: style);
    // Visual order, left→right on screen:
    //   LTR: prev = [icon, text]   next = [text, icon]
    //   RTL: next = [icon, text]   prev = [text, icon]
    final iconFirst = isRtl ? isNext : !isNext;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: iconFirst
                  ? [iconWidget, const SizedBox(width: 4), text]
                  : [text, const SizedBox(width: 4), iconWidget],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Index / TOC ───────────────────────────────────────────────────────────────

class _IndexPage extends StatefulWidget {
  const _IndexPage({
    required this.pages,
    required this.currentPage,
    required this.theme,
    required this.strings,
    required this.icons,
    required this.onSelect,
    required this.onClose,
    this.headerAction,
  });

  final List<FlipBookPage> pages;
  final int currentPage;
  final FlipBookTheme theme;
  final FlipBookStrings strings;
  final FlipBookIcons icons;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;
  final Widget? headerAction;

  @override
  State<_IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<_IndexPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = [
      for (int i = 0; i < widget.pages.length; i++)
        if (widget.pages[i].title != null &&
            widget.pages[i].title!.toLowerCase().contains(_query.toLowerCase()))
          (index: i, title: widget.pages[i].title!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FlipBookHeader(
          closeIcon: widget.icons.close,
          closeIconColor: widget.theme.closeIconColor,
          closeLabel: widget.strings.close,
          onClose: widget.onClose,
          headerAction: widget.headerAction,
        ),

        // ── Content ───────────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.strings.tableOfContents,
                  style: widget.theme.tocHeadingStyle,
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: widget.theme.tocSearchStyle,
                  decoration: InputDecoration(
                    hintText: widget.strings.searchHint,
                    hintStyle: widget.theme.tocSearchHintStyle,
                    prefixIcon: Icon(
                      widget.icons.search,
                      size: 16,
                      color: widget.theme.tocSearchIconColor,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    filled: true,
                    fillColor: widget.theme.tocSearchFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: widget.theme.tocSearchFocusBorderColor,
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: widget.theme.tocDividerColor),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: widget.theme.tocDividerColor, height: 1),
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      final isCurrent = item.index == widget.currentPage;
                      return InkWell(
                        onTap: () => widget.onSelect(item.index),
                        splashColor: widget.theme.tocSplashColor,
                        highlightColor: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '${item.index + 1}',
                                  style: widget.theme.tocItemNumberStyle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: isCurrent
                                      ? widget.theme.tocItemCurrentStyle
                                      : widget.theme.tocItemTitleStyle,
                                ),
                              ),
                              if (isCurrent)
                                Icon(
                                  widget.icons.bookmark,
                                  size: 14,
                                  color: widget.theme.tocItemCurrentIconColor,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
