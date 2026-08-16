import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captures the render tree under [key] as a bitmap at the device's real
/// pixel ratio, or `null` when the boundary is absent or capture fails.
///
/// Failures are reported through [FlutterError.reportError] so they surface
/// in debug consoles and crash reporters without ever throwing into the
/// animation pipeline — a failed capture degrades to plain-paper strips,
/// which is the intended fallback.
Future<ui.Image?> capturePage(GlobalKey key,
    {required double pixelRatio}) async {
  final context = key.currentContext;
  if (context == null) {
    return null;
  }
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    return null;
  }
  try {
    return await renderObject.toImage(pixelRatio: pixelRatio);
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

/// The device pixel ratio for [context], falling back to 1.0 when no view is
/// attached (never happens in a real app; keeps tests and headless use safe).
double devicePixelRatioOf(BuildContext context) =>
    View.maybeOf(context)?.devicePixelRatio ?? 1.0;
