import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'capture.dart';

/// A page-curl overlay driven by a single [progress] value.
///
/// Tiles the screen with vertical polygon slices transformed by a cylindrical
/// projection so the ensemble looks like a physical page peeling away from left
/// to right. Place it on top of the page being revealed.
///
/// ## Usage modes
///
/// **Manual capture** — capture the page yourself and pass [pageImage]:
/// ```dart
/// CurlOverlay(progress: value, pageImage: capturedBitmap)
/// ```
///
/// **Auto-capture** — pass a [child] and the widget captures it internally:
/// ```dart
/// CurlOverlay(
///   progress: value,
///   pageColor: Colors.white,
///   padding: EdgeInsets.all(24),
///   child: MyPageContent(),
/// )
/// ```
/// Set [pageColor] to match your page background so the single-frame capture
/// transition is invisible.
///
/// The [child] is captured **once per widget lifetime**, right after the first
/// frame. To re-capture updated content, give the overlay a new [key]. (The
/// overlay deliberately does not re-capture when [child] changes: parents that
/// rebuild every animation frame create a new child instance every frame, and
/// re-capturing on each of them would thrash the GPU.)
///
/// ## progress range
///   0.0 → page lies flat, covering the screen completely.
///   0.5 → maximum curl (tightest cylinder).
///   1.0 → all slices peeled away, underlying content fully visible.
class CurlOverlay extends StatefulWidget {
  /// Creates a page-curl overlay.
  const CurlOverlay({
    super.key,
    required this.progress,
    this.pageImage,
    this.pageColor = Colors.white,
    this.backgroundImage,
    this.child,
    this.padding = EdgeInsets.zero,
    this.shine,
    this.shadow,
  })  : assert(shine == null || (shine >= 0 && shine <= 1),
            'shine must be between 0 and 1'),
        assert(shadow == null || (shadow >= 0 && shadow <= 1),
            'shadow must be between 0 and 1');

  /// Animation progress. Values are clamped into [0, 1], so overshooting
  /// curves (springs) are safe to feed directly.
  final double progress;

  /// Pre-captured page bitmap. Takes priority over [child] auto-capture.
  /// When both are absent strips render as plain [pageColor] paper.
  final ui.Image? pageImage;

  /// Colour of the paper backing rendered in every curl strip.
  /// Match this to your page background so the animation starts seamlessly.
  /// Defaults to [Colors.white].
  final Color pageColor;

  /// Optional background texture drawn behind the content in every strip.
  /// Sliced with the same cylindrical mapping as [pageImage] so it bends
  /// correctly around the cylinder.
  final ui.Image? backgroundImage;

  /// Page content widget. When supplied (and [pageImage] is null) the widget
  /// is captured once after the first frame and the bitmap is used to texture
  /// the curl strips, so the actual content bends with the page.
  ///
  /// At [progress] = 0 the flat strips tile the full page width and hide this
  /// layer completely, making the capture transition invisible.
  final Widget? child;

  /// Padding applied inside the page surface around [child].
  final EdgeInsetsGeometry padding;

  /// Strength of the specular sheen that sweeps the curling paper, 0–1.
  /// `null` (default) adapts automatically to [pageColor]: full sheen on
  /// white paper, only a trace on dark paper. `0` removes the light
  /// completely.
  final double? shine;

  /// Strength of the diffuse shadow that darkens slices at grazing angles,
  /// 0–1. `null` (default) uses the standard depth shadow; `0` removes it.
  final double? shadow;

  @override
  State<CurlOverlay> createState() => _CurlOverlayState();
}

// ── State ─────────────────────────────────────────────────────────────────────

class _CurlOverlayState extends State<CurlOverlay> {
  ui.Image? _autoCapture;
  bool _capturedOnce = false;
  final _captureKey = GlobalKey();

  // ── Constants ───────────────────────────────────────────────────────────────

  static const int _slices = 28;
  static const double _focalLength = 2000;
  static const double _shadowFloor = 0.25;
  static const double _shine = 0.50;
  static const double _deg2rad = math.pi / 180;
  static const double _rad2deg = 180 / math.pi;
  static const double _fullTurn = math.pi * 2;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  bool get _needsAutoCapture =>
      widget.child != null && widget.pageImage == null;

  @override
  void initState() {
    super.initState();
    if (_needsAutoCapture) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _captureChild());
    }
  }

  void _captureChild() {
    if (!mounted) {
      return;
    }
    final img = capturePage(_captureKey, pixelRatio: captureRatioOf(context));
    if (img == null) {
      return;
    }
    final prev = _autoCapture;
    setState(() {
      _autoCapture = img;
      _capturedOnce = true;
    });
    prev?.dispose();
  }

  @override
  void dispose() {
    _autoCapture?.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final contentImage = widget.pageImage ?? _autoCapture;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Child page surface ───────────────────────────────────────────────
        // Rendered only until the first capture completes. At progress = 0
        // the flat strips tile the full page width and cover this layer, so
        // the capture transition is invisible to the user.
        if (_needsAutoCapture && !_capturedOnce)
          RepaintBoundary(
            key: _captureKey,
            child: _PageSurface(
              color: widget.pageColor,
              padding: widget.padding,
              child: widget.child!,
            ),
          ),

        // ── Curl strips ──────────────────────────────────────────────────────
        LayoutBuilder(
          builder: (_, constraints) {
            final pageW = constraints.maxWidth;
            final pageH = constraints.maxHeight;
            final sliceW = (pageW / _slices + 1).ceilToDouble();

            final slices = _computeSlices(pageW, sliceW)
              ..sort((a, b) {
                final d = a.depth.compareTo(b.depth);
                return d != 0 ? d : a.index.compareTo(b.index);
              });

            return Stack(
              clipBehavior: Clip.none,
              children: [
                const SizedBox.expand(),
                for (final s in slices)
                  if (s.visible)
                    _buildSlice(s, sliceW, pageH, pageW, contentImage),
              ],
            );
          },
        ),
      ],
    );
  }

  // ── Cylinder geometry ───────────────────────────────────────────────────────

  /// EDG-07: callers animate [CurlOverlay.progress] with arbitrary curves;
  /// out-of-range values (spring overshoot) must not produce a negative
  /// cylinder radius, so all geometry reads this clamped value.
  double get _progress => widget.progress.clamp(0.0, 1.0);

  double get _arcAngle {
    final raw = _progress < 0.5
        ? _progress * _fullTurn
        : (1 - (_progress - 0.5) * 2) * math.pi;
    return raw < 1e-9 ? 1e-9 : raw;
  }

  double get _flipOffset =>
      _progress > 0.5 ? -(_progress - 0.5) * 2 * 180 : 0.0;

  /// Specular strength: the caller's [CurlOverlay.shine] when given,
  /// otherwise adapted to the paper. White paper keeps the full sheen; dark
  /// paper reflects almost nothing, so the glint drops to a whisper —
  /// without this, the white highlight reads as a glaring light sweeping
  /// across dark pages.
  double get _shineStrength =>
      widget.shine ??
      _shine * (0.05 + 0.95 * widget.pageColor.computeLuminance());

  /// Diffuse shadow strength: the caller's [CurlOverlay.shadow] when given,
  /// otherwise the standard depth shadow.
  double get _shadowStrength => widget.shadow ?? (1 - _shadowFloor);

  List<_CurlSlice> _computeSlices(double pageW, double sliceW) {
    final arc = _arcAngle;
    final cylinderR = pageW / arc;
    final dAngle = arc / _slices;
    final dDeg = dAngle * _rad2deg;
    final baseRot = _flipOffset;
    final shine = _shineStrength;
    final shadow = _shadowStrength;
    final perspMat = Matrix4.identity()..setEntry(3, 2, -1 / _focalLength);

    return List.generate(_slices, (i) {
      final cumAngle = i * dAngle;
      final cumDeg = (i + 0.5) * dDeg;
      final sx = math.sin(cumAngle) * cylinderR;
      final sz = (1 - math.cos(cumAngle)) * cylinderR;

      final mat = perspMat.clone()
        ..translate(sx, 0.0, sz)
        ..rotateY(-cumDeg * _deg2rad);

      final faceDeg = baseRot - cumDeg;
      final viewAngle = ((faceDeg + 180) % 360) - 180;

      return _CurlSlice(
        index: i,
        matrix: mat,
        depth: sz.abs().round(),
        visible: viewAngle.abs() <= 90,
        shadow: _shadowGradient(faceDeg, dDeg, shadow),
        glint: _glintGradient(faceDeg, dDeg, shine),
      );
    });
  }

  // ── Slice widget ────────────────────────────────────────────────────────────

  Widget _buildSlice(
    _CurlSlice s,
    double sliceW,
    double pageH,
    double pageW,
    ui.Image? contentImage,
  ) {
    return Positioned(
      left: 0,
      top: 0,
      width: sliceW,
      height: pageH,
      child: IgnorePointer(
        child: Transform(
          alignment: Alignment.topLeft,
          transform: s.matrix,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1 ── Paper backing (pageColor) — always opaque, prevents
              //      transparency bleed from bitmap regions.
              ColoredBox(color: widget.pageColor),

              // 2 ── Background image texture (optional).
              if (widget.backgroundImage != null)
                CustomPaint(
                  painter: _PageSlicePainter(
                    image: widget.backgroundImage!,
                    sliceIndex: s.index,
                    totalSlices: _slices,
                    sliceW: sliceW,
                    pageW: pageW,
                    pageH: pageH,
                  ),
                ),

              // 3 ── Content image (pageImage or auto-captured child).
              if (contentImage != null)
                CustomPaint(
                  painter: _PageSlicePainter(
                    image: contentImage,
                    sliceIndex: s.index,
                    totalSlices: _slices,
                    sliceW: sliceW,
                    pageW: pageW,
                    pageH: pageH,
                  ),
                ),

              // 4 ── Diffuse shadow — darkens slices at grazing angles.
              if (s.shadow != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        for (final v in s.shadow!)
                          Colors.black.withValues(alpha: v),
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),

              // 5 ── Specular glint — rounded-paper sheen at highlight angles.
              if (s.glint != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        for (final v in s.glint!)
                          Colors.white.withValues(alpha: v),
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Lighting ────────────────────────────────────────────────────────────────

  List<double>? _shadowGradient(
      double faceDeg, double sliceDeg, double strength) {
    if (strength <= 0.01) {
      return null;
    }
    const sampleOffsets = [-0.5, -0.25, 0.0, 0.25, 0.5];
    return [
      for (final t in sampleOffsets)
        ((1 - math.cos((faceDeg - sliceDeg * t) * _deg2rad)) * strength)
            .clamp(0.0, 1.0),
    ];
  }

  List<double>? _glintGradient(double faceDeg, double sliceDeg, double shine) {
    if (shine <= 0.01) {
      return null;
    }
    const lobeOffset = 30.0;
    const hardness = 200;
    const sampleOffsets = [-0.5, -0.25, 0.0, 0.25, 0.5];
    return [
      for (final t in sampleOffsets)
        (math.max(
                  math
                      .pow(
                        math.cos(
                            (faceDeg + lobeOffset - sliceDeg * t) * _deg2rad),
                        hardness,
                      )
                      .toDouble(),
                  math
                      .pow(
                        math.cos(
                            (faceDeg - lobeOffset - sliceDeg * t) * _deg2rad),
                        hardness,
                      )
                      .toDouble(),
                ) *
                shine)
            .clamp(0.0, 1.0),
    ];
  }
}

// ── Page surface ──────────────────────────────────────────────────────────────

/// Styled page container used as the auto-capture target when `child` is set.
class _PageSurface extends StatelessWidget {
  const _PageSurface({
    required this.color,
    required this.padding,
    required this.child,
  });

  final Color color;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      // Material supplies a DefaultTextStyle so plain Text children never
      // fall back to the red/yellow-underline error style when the overlay
      // is used outside a Scaffold.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _CurlSlice {
  const _CurlSlice({
    required this.index,
    required this.matrix,
    required this.depth,
    required this.visible,
    required this.shadow,
    required this.glint,
  });

  final int index;
  final Matrix4 matrix;
  final int depth;
  final bool visible;
  final List<double>? shadow;
  final List<double>? glint;
}

// ── Painter ───────────────────────────────────────────────────────────────────

/// Paints the horizontal strip of [image] that corresponds to [sliceIndex].
class _PageSlicePainter extends CustomPainter {
  const _PageSlicePainter({
    required this.image,
    required this.sliceIndex,
    required this.totalSlices,
    required this.sliceW,
    required this.pageW,
    required this.pageH,
  });

  final ui.Image image;
  final int sliceIndex;
  final int totalSlices;
  final double sliceW;
  final double pageW;
  final double pageH;

  @override
  void paint(Canvas canvas, Size size) {
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    final pxPerPt = imgW / pageW;
    final originPt = sliceIndex * pageW / totalSlices;
    final srcLeft = (originPt * pxPerPt).clamp(0.0, imgW);
    final srcRight = ((originPt + sliceW) * pxPerPt).clamp(0.0, imgW);

    if (srcRight <= srcLeft) {
      return;
    }

    canvas.drawImageRect(
      image,
      Rect.fromLTRB(srcLeft, 0, srcRight, imgH),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_PageSlicePainter old) =>
      old.image != image || old.sliceIndex != sliceIndex;
}
