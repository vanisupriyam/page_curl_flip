// Everything the reader owns — marks, places, learned gestures — and the
// file it all survives in. The package stores none of it; these stores are
// the app's side of that seam.

import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io';

import 'package:page_curl_flip/page_curl_flip.dart';
import 'package:path_provider/path_provider.dart';

// ── Swipe memory ──────────────────────────────────────────────────────────────

/// The package keeps no state between opens; remembering that the reader has
/// learned the swipe gesture is the app's job.
///
/// Persisted to the same file as the marks and bookmarks, so the hint's
/// appearances count against the reader's LIFETIME, not per launch — a
/// gesture a reader has learned stays learned.
class SwipeMemory {
  static bool learned = false;

  static void retire() {
    learned = true;
    Persist.save();
  }
}

// ── Storing the reader's marks ────────────────────────────────────────────────

/// Where the reader's marks live — **in the app, never in the package.**
///
/// `FlipBook` draws marks and reports every change through
/// `onMarksChanged`; it deliberately owns no database. A reading widget
/// that bundled Hive would force Hive on every app that uses it, including
/// the ones already running Drift, Isar, or SharedPreferences.
///
/// This store keeps them in memory so the example has no extra dependency.
/// With Hive the whole thing is the five commented lines below — a
/// `ReaderMark` is plain primitives through [ReaderMark.toMap] and
/// [ReaderMark.fromMap], so any store takes it as-is.
///
/// ```dart
/// // pubspec.yaml:  hive_flutter: ^1.1.0
/// // main():        await Hive.initFlutter();
/// //                await Hive.openBox<String>('marks');
///
/// static List<ReaderMark> load() {
///   final raw = Hive.box<String>('marks').get('ltr') ?? '[]';
///   return [
///     for (final m in jsonDecode(raw) as List)
///       ReaderMark.fromMap(Map<String, dynamic>.from(m as Map)),
///   ];
/// }
///
/// static void save(List<ReaderMark> marks) => Hive.box<String>('marks')
///     .put('ltr', jsonEncode([for (final m in marks) m.toMap()]));
/// ```
class MarkStore {
  static final Map<String, List<ReaderMark>> _byBook = {};

  static List<ReaderMark> load({bool rtl = false}) =>
      _byBook[rtl ? 'rtl' : 'ltr'] ?? const [];

  static void save(List<ReaderMark> marks, {bool rtl = false}) {
    _byBook[rtl ? 'rtl' : 'ltr'] = List.unmodifiable(marks);
    Persist.save();
  }

  static Map<String, Object?> toMap() => _byBook.map(
    (k, v) => MapEntry(k, v.map((m) => m.toMap()).toList()),
  );

  static void fromMap(Map<String, Object?> m) {
    _byBook.clear();
    m.forEach((k, v) {
      _byBook[k] = ((v as List?) ?? const [])
          .map((e) => ReaderMark.fromMap(Map<String, Object?>.from(e as Map)))
          .toList();
    });
  }
}

/// Writes the reader's marks, places and learned gestures to a file.
///
/// The package genuinely stores nothing, so showing that the seam works is
/// the example's job — an in-memory map would prove nothing, because it
/// cannot survive a restart.
///
/// A plain JSON file: the point is that ANY store works. `path_provider`
/// is here only to find a writable directory — the PACKAGE still has zero
/// dependencies, and an example dependency is not counted against it.
class Persist {
  static File? _file;
  static bool _loading = false;

  static Future<void> init() async {
    _loading = true;
    try {
      final dir = await getApplicationSupportDirectory();
      _file = File('${dir.path}/page_curl_flip_demo.json');
      if (await _file!.exists()) {
        final map = jsonDecode(await _file!.readAsString()) as Map<String, Object?>;
        SwipeMemory.learned = (map['swipeLearned'] as bool?) ?? false;
        MarkStore.fromMap(
          Map<String, Object?>.from((map['marks'] as Map?) ?? const {}),
        );
        PlaceStore.ltr.fromMap(
          Map<String, Object?>.from((map['place_ltr'] as Map?) ?? const {}),
        );
        PlaceStore.rtl.fromMap(
          Map<String, Object?>.from((map['place_rtl'] as Map?) ?? const {}),
        );
      }
    } catch (_) {
      // A demo must open even if its own scratch file is unreadable.
    } finally {
      _loading = false;
    }
  }

  static void save() {
    if (_loading || _file == null) return;
    final data = {
      'swipeLearned': SwipeMemory.learned,
      'marks': MarkStore.toMap(),
      'place_ltr': PlaceStore.ltr.toMap(),
      'place_rtl': PlaceStore.rtl.toMap(),
    };
    unawaited(_file!.writeAsString(jsonEncode(data)));
  }
}

/// Where the reader stopped, and which pages they kept.
///
/// In memory here so the example stays dependency-free; in a real app this
/// is one Hive box. The book never stores either — it reports, the app
/// remembers, and the app hands the values back on the next build.
class PlaceStore {
  // ONE STORE PER BOOK. Sharing a single set of statics would let one book's
  // place, bookmark and kept pages overwrite the other's.
  PlaceStore._(this._key);

  static final ltr = PlaceStore._('ltr');
  static final rtl = PlaceStore._('rtl');

  final String _key;

  /// Where the reader stopped, updated silently on every page turn. A
  /// POSITION: overwritten constantly, meaningless on its own.
  int resume = 0;

  /// The one page the reader chose to carry on from. Theirs — nothing here
  /// ever clears it.
  int? bookmark;

  /// Every page the reader kept, by id. Plural on purpose.
  Set<String> saved = const {};

  /// The page to open at: the bookmark when there is one, else wherever they
  /// stopped reading.
  int get openAt => bookmark ?? resume;

  Map<String, Object?> toMap() => {
    'resume': resume,
    'bookmark': bookmark,
    'saved': saved.toList(),
  };

  void fromMap(Map<String, Object?> m) {
    resume = (m['resume'] as int?) ?? 0;
    bookmark = m['bookmark'] as int?;
    saved = ((m['saved'] as List?)?.cast<String>() ?? const []).toSet();
  }

  String get storeKey => 'place_$_key';
}
