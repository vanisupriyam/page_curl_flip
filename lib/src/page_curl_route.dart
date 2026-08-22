import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'capture.dart';
import 'curl_overlay.dart';

/// A [PageRoute] that reveals the destination by peeling the previous screen
/// away like a page of a book.
///
/// With a [coverChild] the transition first shows that widget full-screen,
/// captures it, and then curls the captured bitmap away — mirroring how
/// `FlipBook` flips between its pages. Without one, the curl is driven
/// directly by the route animation over plain paper.
///
/// Since 0.2.0 the curl **mirrors under RTL**, matching `FlipBook`: an Arabic
/// screen peels the opposite way to an English one, because a page travels
/// the way its script reads. [mirror] overrides the automatic choice.
///
/// ```dart
/// Navigator.of(context).push(
///   PageCurlRoute(
///     coverChild: const CoverPage(),
///     builder: (_) => const DetailScreen(),
///   ),
/// );
/// ```
class PageCurlRoute<T> extends PageRouteBuilder<T> {
  /// Creates a page-curl route.
  PageCurlRoute({
    required WidgetBuilder builder,
    this.coverChild,
    this.pageColor = Colors.white,
    this.shine,
    this.shadow,
    super.transitionDuration = const Duration(milliseconds: 1100),
    super.reverseTransitionDuration = const Duration(milliseconds: 750),
    this.curlDuration = const Duration(milliseconds: 900),
    this.curlReverseDuration = const Duration(milliseconds: 600),
    this.mirror,
  }) : super(
          opaque: true,
          pageBuilder: (context, _, __) => builder(context),
        );

  /// Widget shown full-screen and captured before the curl starts.
  /// When null, the curl peels plain paper driven by the route animation.
  final Widget? coverChild;

  /// Paper colour of the peeling page. Match it to [coverChild]'s background
  /// — the curl's sheen adapts to it, so dark covers peel without glare.
  final Color pageColor;

  /// Sheen strength 0–1; `null` adapts to [pageColor], `0` removes it.
  final double? shine;

  /// Depth-shadow strength 0–1; `null` uses the default, `0` removes it.
  final double? shadow;

  /// Forward duration of the curl itself. Keep it shorter than
  /// `transitionDuration` — the difference buffers the cover capture.
  final Duration curlDuration;

  /// Reverse duration of the curl when the route is popped.
  final Duration curlReverseDuration;

  /// Forces the peel direction instead of taking it from [Directionality].
  ///
  /// `null` mirrors automatically: left-to-right under LTR, right-to-left
  /// under RTL. Set it only when the screen's direction is not the direction
  /// the page should travel.
  final bool? mirror;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _PageCurlTransition(
      animation: animation,
      coverChild: coverChild,
      pageColor: pageColor,
      shine: shine,
      shadow: shadow,
      curlDuration: curlDuration,
      curlReverseDuration: curlReverseDuration,
      mirror: mirror,
      child: child,
    );
  }
}

class _PageCurlTransition extends StatefulWidget {
  const _PageCurlTransition({
    required this.animation,
    required this.child,
    required this.pageColor,
    required this.shine,
    required this.shadow,
    required this.curlDuration,
    required this.curlReverseDuration,
    required this.mirror,
    this.coverChild,
  });

  final Animation<double> animation;
  final Widget child;
  final Color pageColor;
  final double? shine;
  final double? shadow;
  final Duration curlDuration;
  final Duration curlReverseDuration;
  final bool? mirror;
  final Widget? coverChild;

  @override
  State<_PageCurlTransition> createState() => _PageCurlTransitionState();
}

class _PageCurlTransitionState extends State<_PageCurlTransition>
    with SingleTickerProviderStateMixin {
  // Drives the curl visual independently of the route animation so the
  // animation only starts after the cover bitmap is ready — matching
  // FlipBook's forward flip, which always has its bitmap from frame 1.
  late final AnimationController _curlCtrl;
  late final CurvedAnimation _curlCurved;

  final _coverKey = GlobalKey();
  ui.Image? _coverImage;

  // True while the cover child is shown full-screen (pre-capture phase).
  // Flipped to false once the bitmap is captured and the curl starts.
  bool _covering = false;

  @override
  void initState() {
    super.initState();
    _curlCtrl = AnimationController(
      vsync: this,
      duration: widget.curlDuration,
      reverseDuration: widget.curlReverseDuration,
    );
    _curlCurved = CurvedAnimation(parent: _curlCtrl, curve: Curves.easeInOut);

    if (widget.coverChild != null) {
      // Phase 1: show cover on top, capture it, then start curl.
      _covering = true;
      widget.animation.addStatusListener(_onRouteStatus);
      // Two nested callbacks: outer fires after layout (key attached),
      // inner fires after the following paint (GPU layer flushed, toImage safe).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _captureThenAnimate());
      });
    } else {
      // No cover — mirror the route animation directly.
      widget.animation.addListener(_syncFromRoute);
    }
  }

  // Fallback for no coverChild: keep local controller in sync with the route.
  void _syncFromRoute() => _curlCtrl.value = widget.animation.value;

  // When the route is popped, reverse the curl so the cover folds back.
  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      _curlCtrl.reverse();
    }
  }

  Future<void> _captureThenAnimate() async {
    if (!mounted) {
      return;
    }
    final img = capturePage(_coverKey, pixelRatio: captureRatioOf(context));
    // Route already popping — abort; cover stays visible until the route exits.
    if (widget.animation.status == AnimationStatus.reverse) {
      img?.dispose();
      return;
    }
    setState(() {
      _coverImage = img;
      _covering = false;
    });
    await _curlCtrl.forward();
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onRouteStatus);
    widget.animation.removeListener(_syncFromRoute);
    _curlCurved.dispose();
    _curlCtrl.dispose();
    _coverImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The curl geometry itself only peels one way. Mirroring the whole
    // overlay horizontally is what makes an Arabic screen travel the way its
    // script reads — the same rule FlipBook already follows for its flips.
    final rtl = widget.mirror ??
        (Directionality.maybeOf(context) == TextDirection.rtl);
    Widget curl(Widget child) => rtl
        ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
            child: child,
          )
        : child;

    return Stack(
      children: [
        // Destination — always rendered below the curl overlay.
        widget.child,

        if (widget.coverChild != null) ...[
          // Phase 1: cover child visible while capture is pending.
          // SafeArea matches the FlipBook's SafeArea so the captured bitmap
          // and the curl overlay share identical dimensions. The Material
          // gives the cover's text a DefaultTextStyle — without it, plain
          // Text widgets render in the red/yellow-underline error style.
          if (_covering)
            Positioned.fill(
              child: SafeArea(
                child: RepaintBoundary(
                  key: _coverKey,
                  child: Material(
                    type: MaterialType.transparency,
                    child: widget.coverChild!,
                  ),
                ),
              ),
            ),

          // Phase 2: curl overlay peels the captured cover away.
          // SafeArea keeps the animation within the safe area — identical to
          // how FlipBook wraps its CurlOverlay inside SafeArea via the Scaffold.
          if (!_covering)
            Positioned.fill(
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: _curlCurved,
                  builder: (_, __) => curl(
                    CurlOverlay(
                      progress: _curlCurved.value,
                      pageImage: _coverImage,
                      pageColor: widget.pageColor,
                      shine: widget.shine,
                      shadow: widget.shadow,
                    ),
                  ),
                ),
              ),
            ),
        ] else
          // No cover: drive curl from route animation (fallback path).
          Positioned.fill(
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _curlCurved,
                builder: (_, __) => curl(
                  CurlOverlay(
                    progress: _curlCurved.value,
                    pageColor: widget.pageColor,
                    shine: widget.shine,
                    shadow: widget.shadow,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
