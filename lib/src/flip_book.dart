import 'dart:async';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'capture.dart';
import 'curl_overlay.dart';
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
/// A page-flip sound ships with the package and plays on every flip, with a
/// mute button in the footer. Set [enableSound] to `false` for a silent book
/// with no mute button, [showMuteButton] to `false` to keep the sound but
/// hide the button, or pass [onPageFlip] to play your own sound instead.
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
    this.flipSpeed = FlipSpeed.medium,
    this.pageColor = Colors.white,
    this.enableSound = true,
    this.showMuteButton = true,
    this.showControls = true,
    this.controller,
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

  /// Duration preset of the flip animation.
  final FlipSpeed flipSpeed;

  /// Paper colour of every page.
  final Color pageColor;

  /// Whether flips make a sound. `true` (default) plays the built-in
  /// page-flip sound — or [onPageFlip] if given — and shows a mute button.
  /// `false` keeps the book silent and hides the mute button entirely.
  final bool enableSound;

  /// Whether the mute button is shown while [enableSound] is `true`.
  /// Set `false` to keep the flip sound but hide the speaker button.
  final bool showMuteButton;

  /// Whether the built-in controls render at all: the × close button, the
  /// INDEX button, the mute button, and PREV/NEXT. Set `false` to show pure
  /// pages and drive the book yourself through a [FlipBookController].
  final bool showControls;

  /// Drives the book from outside the widget — see [FlipBookController].
  final FlipBookController? controller;

  /// Overrides the book's reading direction. When `null` (default) the book
  /// follows the ambient [Directionality]: left-to-right under English,
  /// Dutch, German and other LTR locales, right-to-left automatically under
  /// Arabic, Hebrew and other RTL locales. Set it to force a direction
  /// regardless of the app's locale.
  final TextDirection? textDirection;

  /// Optional widget shown at the trailing edge of the header.
  final Widget? headerAction;

  /// Replaces the built-in sound: called at the start of every flip so you
  /// can play your own. Ignored while [enableSound] is `false`.
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

  ui.Image? _capturedImage;
  final _repaintKey = GlobalKey();
  final _prevCaptureKey = GlobalKey();

  late final AnimationController _ctrl;
  late final CurvedAnimation _curved;

  // Primed when the book opens so the first flip's sound is not late.
  AudioPlayer? _player;
  Future<void>? _playerReady;

  int get _pageCount => widget.pages.length;
  bool get _hasIndex =>
      widget.pages.any((p) => p.title?.trim().isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.flipSpeed.duration,
    );
    _curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    widget.controller?._attach(this);
    if (widget.enableSound && widget.onPageFlip == null && !_inTestHarness) {
      unawaited(_primePlayer());
    }
  }

  /// Widget tests have no audio plugin, and the player constructor reports
  /// its missing platform channel asynchronously — uncatchably. Priming is
  /// a latency optimisation only, so it is skipped under the test binding;
  /// behaviour is unchanged, tests exercise the same code paths silently.
  static bool get _inTestHarness =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  /// Creates the player once and pre-loads the flip sound, so that playback
  /// at flip time is a rewind + resume instead of a load — this is what
  /// keeps the sound in sync with the start of the curl.
  Future<void> _primePlayer() async {
    if (_player != null) {
      return _playerReady;
    }
    final player = AudioPlayer()..audioCache = AudioCache(prefix: '');
    _player = player;
    _playerReady = () async {
      // Low latency uses Android's sound-effect pool; other platforms
      // silently keep their default pipeline.
      await player.setPlayerMode(PlayerMode.lowLatency);
      // Keep the source loaded after it finishes, so replays are instant.
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(
        AssetSource('packages/page_curl_flip/assets/sounds/page_flip.mp3'),
      );
    }();
    return _playerReady;
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
    }
    if (_nextIndex > maxIndex) {
      _nextIndex = maxIndex;
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    // Reverse order of creation: the curve listens to the controller, so it
    // must detach before the controller goes away.
    _curved.dispose();
    _ctrl.dispose();
    _capturedImage?.dispose();
    _player?.dispose();
    super.dispose();
  }

  /// Plays [FlipBook.onPageFlip] when given, else the bundled flip sound.
  /// Best-effort: audio failure must never interrupt the animation.
  Future<void> _playFlipSound() async {
    if (widget.onPageFlip != null) {
      return widget.onPageFlip!();
    }
    try {
      await _primePlayer();
      final player = _player!;
      // Rewind-and-resume on the pre-loaded source: no file I/O at flip
      // time, so the sound starts with the curl instead of after it.
      await player.stop();
      await player.seek(Duration.zero);
      await player.resume();
    } catch (_) {
      // No audio backend (tests, unsupported platform) — flip silently.
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
    setState(() {
      _flipPhase = _FlipPhase.idle;
      _capturedImage = null;
      _pageIndex = index;
      _showIndex = false;
    });
    abandoned?.dispose();
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
    setState(() {
      _pageIndex = _nextIndex;
      _flipPhase = _FlipPhase.idle;
      _capturedImage = null;
    });
    toDispose?.dispose();
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
    return _FlipBookScaffold(
      content: _pageContent(page),
      theme: widget.theme,
      strings: widget.strings,
      headerAction: widget.headerAction,
      hasIndex: _hasIndex,
      isMuted: _muted,
      showControls: widget.showControls,
      onClose: widget.onClose,
      onNext: index < _pageCount - 1 ? _goNext : null,
      onPrev: index > 0 ? _goPrev : null,
      onMuteToggle:
          widget.enableSound && widget.showMuteButton ? _toggleMute : null,
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
      body: SafeArea(
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
          ],
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
    required this.isMuted,
    required this.hasIndex,
    required this.showControls,
    required this.readPhase,
    required this.canPauseReading,
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
  final bool isMuted;
  final bool hasIndex;
  final bool showControls;
  final _ReadPhase readPhase;
  final bool canPauseReading;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FlipBookHeader(
          closeIconColor: theme.closeIconColor,
          closeLabel: strings.close,
          onClose: onClose,
          headerAction: headerAction,
        ),

        // ── Content ───────────────────────────────────────────────────────────
        Expanded(child: content),

        // ── Footer ────────────────────────────────────────────────────────────
        Padding(
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
                  icon: isMuted ? Icons.volume_off : Icons.volume_up,
                  label: isMuted ? strings.unmute : strings.mute,
                  color: theme.muteIconColor,
                  onTap: onMuteToggle!,
                ),

              const Spacer(),

              // Centre: the read-aloud control. Idle → play. Playing →
              // pause (when supported) + stop. Paused → play + stop.
              if (onReadPlay != null) ...[
                if (readPhase != _ReadPhase.playing)
                  _FooterIconButton(
                    icon: Icons.play_arrow,
                    label: strings.readAloud,
                    color: theme.muteIconColor,
                    onTap: onReadPlay!,
                  ),
                if (readPhase == _ReadPhase.playing && canPauseReading)
                  _FooterIconButton(
                    icon: Icons.pause,
                    label: strings.pauseReading,
                    color: theme.muteIconColor,
                    onTap: onReadPause!,
                  ),
                if (readPhase != _ReadPhase.idle)
                  _FooterIconButton(
                    icon: Icons.stop,
                    label: strings.stopReading,
                    color: theme.muteIconColor,
                    onTap: onReadStop!,
                  ),
                const Spacer(),
              ],

              // Right group: PREV · NEXT
              if (onPrev != null)
                _FooterButton(
                  label: strings.previous,
                  style: theme.navButtonStyle,
                  leadingIcon: Icons.chevron_left,
                  iconColor: theme.navButtonIconColor,
                  onTap: onPrev!,
                ),
              if (onPrev != null && onNext != null) const SizedBox(width: 16),
              if (onNext != null)
                _FooterButton(
                  label: strings.next,
                  style: theme.navButtonStyle,
                  trailingIcon: Icons.chevron_right,
                  iconColor: theme.navButtonIconColor,
                  onTap: onNext!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _FlipBookHeader extends StatelessWidget {
  const _FlipBookHeader({
    required this.closeIconColor,
    required this.closeLabel,
    this.onClose,
    this.headerAction,
  });

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
            icon: Icon(Icons.close, size: 20, semanticLabel: closeLabel),
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
    this.leadingIcon,
    this.trailingIcon,
    this.iconColor,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? iconColor;

  /// Chevron glyphs must point with the reading direction: under RTL the
  /// button positions already mirror via the Row, so the glyphs swap too.
  static IconData _mirrored(IconData icon, BuildContext context) {
    if (Directionality.of(context) != TextDirection.rtl) {
      return icon;
    }
    if (icon == Icons.chevron_left) {
      return Icons.chevron_right;
    }
    if (icon == Icons.chevron_right) {
      return Icons.chevron_left;
    }
    return icon;
  }

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(_mirrored(leadingIcon!, context),
                    size: 16, color: iconColor),
                const SizedBox(width: 4),
              ],
              Text(label, style: style),
              if (trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(_mirrored(trailingIcon!, context),
                    size: 16, color: iconColor),
              ],
            ],
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
    required this.onSelect,
    required this.onClose,
    this.headerAction,
  });

  final List<FlipBookPage> pages;
  final int currentPage;
  final FlipBookTheme theme;
  final FlipBookStrings strings;
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
                      Icons.search,
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
                                  Icons.bookmark,
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
