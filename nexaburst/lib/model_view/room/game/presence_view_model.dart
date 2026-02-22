// nexaburst/lib/model_view/room/game/presence_manager.dart

import 'dart:async';
import 'package:nexaburst/debug/fake_models/fake_presence_manager.dart';
import 'package:nexaburst/models/data/server/presence/pesence_manager_interface.dart';
import 'package:nexaburst/models/data/server/presence/presence_manager.dart';

/// Configures and provides a singleton presence manager.
/// Can operate in debug mode with faked behavior or real mode.
class PresenceManager {
  static bool _isDebug = false;
  static IPresenceManager? _instance;

  /// Sets debug/prod mode before any instance is created.
  ///
  /// [debugMode]: When true, uses the fake presence manager.
  static void configure({required bool debugMode}) {
    _isDebug = debugMode;
    _instance = null;
  }

  /// Initializes the singleton with the given [roomId].
  /// Chooses fake or real implementation based on debug mode.
  static Future<void> init({required String roomId}) async {
    if (_isDebug) {
      _instance = FakePresenceManager();
    } else {
      _instance = realPresence(roomId: roomId);
    }
    await _instance?.initialize();
  }

  /// Returns the initialized presence manager instance.
  /// Throws if called before `init()`.
  static IPresenceManager get instance {
    if (_instance == null) {
      throw Exception('PresenceManager not initialized. Call init() first.');
    }
    return _instance!;
  }

  /// Disposes and clears the singleton presence manager.
  static Future<void> dispose() async {
    if (_instance != null) {
      await _instance!.dispose();
      _instance = null;
    }
  }
}
