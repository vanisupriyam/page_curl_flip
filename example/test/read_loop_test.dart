import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip_example/read_loop.dart';

/// A stand-in engine that records what it was asked to say.
///
/// Every assertion below is about behaviour you cannot see without a phone
/// in your hand and a stopwatch, which is exactly why it is faked here.
class _FakeEngine implements SpeechEngine {
  final spoken = <String>[];
  final rates = <double>[];

  /// Word boundaries the engine will report, one per utterance.
  final List<int> boundaries;

  _FakeEngine({this.boundaries = const []});

  int _utterance = 0;
  Completer<void>? _current;

  @override
  int get wordOffset => _utterance - 1 < boundaries.length && _utterance > 0
      ? boundaries[_utterance - 1]
      : 0;

  @override
  Future<void> setRate(double rate) async => rates.add(rate);

  @override
  Future<void> speak(String text) {
    spoken.add(text);
    _utterance++;
    return (_current = Completer<void>()).future;
  }

  @override
  Future<void> stop() async => finish();

  /// Completes the utterance in flight, as a real engine does when it
  /// reaches the end or is stopped.
  void finish() {
    final c = _current;
    _current = null;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
  }
}

void main() {
  const unit = 'The quick brown fox jumps over the lazy dog and keeps going.';

  test(
    'SPD-06: with no speed change, the unit is spoken once, whole',
    () async {
      final engine = _FakeEngine();
      final loop = ReadLoop(engine);

      final done = loop.read(unit, rate: 1);
      await Future<void>.delayed(Duration.zero);
      engine.finish();
      await done;

      expect(engine.spoken, [unit]);
      expect(engine.rates, [1.0]);
      expect(loop.speaking, isFalse);
    },
  );

  test('SPD-07: a speed change carries on from the next WORD, not from the '
      'start of the paragraph', () async {
    // The engine reports it had reached character 20 — inside the unit.
    final engine = _FakeEngine(boundaries: [20]);
    final loop = ReadLoop(engine);

    final done = loop.read(unit, rate: 1);
    await Future<void>.delayed(Duration.zero);

    // The reader taps a faster speed mid-paragraph.
    await loop.setRate(1.5);
    await Future<void>.delayed(Duration.zero);
    engine.finish();
    await done;

    expect(engine.spoken.length, 2, reason: 'stopped and spoke again');
    expect(engine.spoken.first, unit);
    // The whole point: the remainder, not the paragraph over again.
    expect(engine.spoken[1], unit.substring(20));
    expect(engine.rates, [1.0, 1.5], reason: 'the new rate was applied');
    // And the book sees ONE unit: the future only completes at the end.
    expect(loop.speaking, isFalse);
  });

  test('SPD-08: an engine that reports no word progress repeats the '
      'remainder instead of hanging', () async {
    // boundaries empty → wordOffset is always 0, the Samsung case.
    final engine = _FakeEngine();
    final loop = ReadLoop(engine);

    final done = loop.read(unit, rate: 1);
    await Future<void>.delayed(Duration.zero);
    await loop.setRate(0.5);
    await Future<void>.delayed(Duration.zero);
    engine.finish();
    await done;

    expect(engine.spoken, [
      unit,
      unit,
    ], reason: 'no progress to resume from, so the unit repeats');
    expect(engine.rates, [1.0, 0.5]);
  });

  test('SPD-09: pause or a page flip abandons the unit without speaking '
      'again', () async {
    final engine = _FakeEngine(boundaries: [20]);
    final loop = ReadLoop(engine);

    final done = loop.read(unit, rate: 1);
    await Future<void>.delayed(Duration.zero);
    await loop.abort();
    await done;

    expect(engine.spoken, [unit], reason: 'nothing more was spoken');
    expect(loop.speaking, isFalse);
  });

  test(
    'SPD-10: changing speed while nothing is being read just sets it',
    () async {
      final engine = _FakeEngine();
      final loop = ReadLoop(engine);

      await loop.setRate(1.5);
      expect(engine.spoken, isEmpty, reason: 'nothing to interrupt');

      final done = loop.read(unit, rate: 1.5);
      await Future<void>.delayed(Duration.zero);
      engine.finish();
      await done;
      expect(engine.rates, [1.5]);
    },
  );
}
