// The page-flip sound. An app asset, not the package's — the package makes
// no sound of its own.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/widgets.dart';

/// The flip sound is this app's, not the package's. The 1.15-second sample
/// matches the flip duration, and pre-loading keeps it in sync with the
/// curl.
class FlipSound with WidgetsBindingObserver {
  FlipSound() {
    WidgetsBinding.instance.addObserver(this);
  }

  final _player = AudioPlayer();
  Future<void>? _ready;

  Future<void> _prime() => _ready ??= () async {
    // Android: the silent/vibrate gate lives on the PLAYER's audio
    // attributes (respectSilence → ringtone usage), not on the global
    // context — set it once here. iOS is handled by the global session
    // assert in play() below.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _player.setAudioContext(
        AudioContextConfig(respectSilence: true).build(),
      );
    }
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setSource(AssetSource('sounds/page_flip.m4a'));
  }();

  /// iOS interrupts the audio session when the app leaves the foreground
  /// and resumes interrupted players when it returns — which replayed the
  /// flip sound on background AND on relaunch. Stopping the player the
  /// moment the app stops being active leaves nothing to resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _player.stop();
    }
  }

  /// Plays from the start; safe to call on every flip.
  Future<void> play() async {
    await _prime();
    // Respect the iPhone ring/silent switch: audioplayers defaults the iOS
    // audio session to the `playback` category, which by Apple's rules
    // ignores the switch. `respectSilence` swaps it for `ambient` — a UI
    // effect sound should obey silent mode. Re-asserted on every flip
    // because the session is one shared object and read-aloud switches it
    // to `playback` for itself (a deliberate listen must sound regardless).
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(respectSilence: true).build(),
    );
    await _player.stop();
    try {
      await _player.seek(Duration.zero);
    } catch (_) {
      // stop() already reset the position on this platform.
    }
    await _player.resume();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
  }
}
