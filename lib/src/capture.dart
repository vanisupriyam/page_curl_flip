import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captures the render tree under [key] as a bitmap, synchronously, or
/// `null` when the boundary is absent, unpainted, or capture fails.
///
/// Uses [RenderRepaintBoundary.toImageSync]: the image stays GPU-resident
/// (no CPU round-trip) and the call returns in the same frame, which removes
/// the await-gaps the old async capture had to guard against.
///
/// Failures are reported through [FlutterError.reportError] so they surface
/// in debug consoles and crash reporters without ever throwing into the
/// animation pipeline — a failed capture degrades to plain-paper strips,
/// which is the intended fallback.
ui.Image? capturePage(GlobalKey key, {required double pixelRatio}) {
  final context = key.currentContext;
  if (context == null) {
    return null;
  }
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    return null;
  }
  var needsPaint = false;
  assert(() {
    needsPaint = renderObject.debugNeedsPaint;
    return true;
  }());
  if (needsPaint) {
    return null;
  }
  try {
    return renderObject.toImageSync(pixelRatio: pixelRatio);
  } catch (error, stackTrace) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'page_curl_flip',
      context: ErrorDescription('while capturing a page bitmap'),
    ));
    return null;
  }
}

/// The pixel ratio to capture at for [context]: the device's own ratio,
/// **capped at 2.0** — a page in mid-curl cannot show 3× detail, and the
/// uncapped bitmap on a flagship costs ~12–16 MB per flip. Falls back to 1.0
/// when no view is attached (tests, headless use).
double captureRatioOf(BuildContext context) =>
    math.min(View.maybeOf(context)?.devicePixelRatio ?? 1.0, 2.0);
