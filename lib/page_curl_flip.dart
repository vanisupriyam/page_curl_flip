/// A realistic cylindrical page-curl animation for Flutter.
///
/// Three entry points, lowest level first:
///
/// * [CurlOverlay] — the raw curl, driven by a single `progress` value.
/// * [PageCurlRoute] — a page transition that peels the old screen away.
/// * [FlipBook] — a complete multi-page book with table of contents.
library;

export 'src/curl_overlay.dart';
export 'src/flip_book.dart';
export 'src/flip_book_page.dart';
export 'src/flip_book_strings.dart';
export 'src/flip_book_theme.dart';
export 'src/flip_speed.dart';
export 'src/page_curl_route.dart';
