// nexaburst/lib/models/server/user_service/audio_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:audioplayers/audioplayers.dart';

/// Manages background music and sound effects, persisting user preferences
/// via secure storage and supporting web and mobile platforms.
class AudioService {
  /// Whether background music playback is enabled.
  bool _musicEnabled = true;

  /// Whether sound effects playback is enabled.
  bool _soundEnabled = true;

  /// Path or URL of the currently loaded music file.
  String? _file;

  /// Player instance used for background music.
  final AudioPlayer _musicPlayer = AudioPlayer();

  /// Player instance used for one‑off sound effects.
  final AudioPlayer _sfxPlayer = AudioPlayer();

  /// Secure storage for persisting audio preferences and file path.
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  /// Creates the service and initializes settings from secure storage.
  AudioService() {
    _init();
  }

  /// Loads saved preferences (`musicEnabled`, `soundEnabled`, `filePath`)
  /// from secure storage into local fields.
  Future<void> _init() async {
    final musicEnabledStr = await storage.read(key: 'musicEnabled');
    final soundEnabledStr = await storage.read(key: 'soundEnabled');
    final filePathStr = await storage.read(key: 'filePath');

    _musicEnabled = musicEnabledStr == null
        ? true
        : musicEnabledStr.toLowerCase() == 'true';
    _soundEnabled = soundEnabledStr == null
        ? true
        : soundEnabledStr.toLowerCase() == 'true';
    _file = filePathStr;
  }

  /// Starts looping playback of [filePath] if music is enabled,
  /// persists [filePath], and handles web vs. mobile sources.
  ///
  /// - [filePath]: URL or asset path to play.
  Future<void> playBackgroundMusic(String filePath) async {
    _file = filePath;
    await storage.write(key: 'filePath', value: filePath);

    if (!_musicEnabled) return;

    await _musicPlayer.setReleaseMode(ReleaseMode.loop);

    if (kIsWeb) {
      await _musicPlayer.play(UrlSource(filePath));
    } else {
      await _musicPlayer.play(AssetSource(filePath));
    }
  }

  /// Stops background music. If [clearFile] is true, also clears the
  /// persisted file path.
  ///
  /// - [clearFile]: whether to delete stored filePath.
  Future<void> stopBackgroundMusic({bool clearFile = true}) async {
    await _musicPlayer.stop();
    if (clearFile) {
      await storage.delete(key: 'filePath');
      _file = null;
    }
  }

  /// Plays a single sound effect from [filePath] if sound is enabled,
  /// handling web vs. mobile sources.
  ///
  /// - [filePath]: URL or asset path of the sound.
  Future<void> playSound(String filePath) async {
    if (!_soundEnabled) return;

    if (kIsWeb) {
      await _sfxPlayer.play(UrlSource(filePath));
    } else {
      await _sfxPlayer.play(AssetSource(filePath));
    }
  }

  /// Toggles music enabled state, persists it, and starts or stops
  /// playback accordingly.
  Future<void> setMusicEnabled() async {
    _musicEnabled = !_musicEnabled;
    await storage.write(key: 'musicEnabled', value: _musicEnabled.toString());

    if (!_musicEnabled) {
      await stopBackgroundMusic(clearFile: false);
    } else if (_file != null) {
      await playBackgroundMusic(_file!);
    }
  }

  /// Toggles sound effects enabled state and persists the new setting.
  Future<void> setSoundEnabled() async {
    _soundEnabled = !_soundEnabled;
    await storage.write(key: 'soundEnabled', value: _soundEnabled.toString());
  }

  /// Resets all audio settings and clears secure storage entries.
  Future<void> clear() async {
    _musicEnabled = true;
    _soundEnabled = true;
    _file = null;
    await storage.deleteAll();
    await storage.write(key: 'musicEnabled', value: 'true');
    await storage.write(key: 'soundEnabled', value: 'true');
  }

  /// Returns whether background music is currently enabled.
  bool get isMusicEnabled => _musicEnabled;

  /// Returns whether sound effects are currently enabled.
  bool get isSoundEnabled => _soundEnabled;
}
