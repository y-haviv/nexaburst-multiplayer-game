// nexaburst/lib/models/server/levels/level2/lv02_model_manager.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/debug/fake_models/fake_levels/level02/fake_lv02_luck.dart';
import 'package:nexaburst/debug/fake_models/fake_levels/level02/fake_lv02_wheel.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/models/data/server/levels/level2/Lv02.dart';
import 'package:nexaburst/models/data/server/levels/level2/Lv02_luck.dart';
import 'package:nexaburst/models/data/server/levels/level2/Lv02_luck_weel.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';

/// Central manager for Level 2 that coordinates the wheel and luck models.
/// Provides unified init, accessor, and reset APIs.
class Lv02ModelManager {
  /// Singleton instance of the wheel sub‑model implementation.
  static late Lv02Weel _instanceWeel;

  /// Singleton instance of the luck sub‑model implementation.
  static late Lv02Luck _instanceLuck;

  /// Tracks whether the model manager has performed its first init().
  static bool initialized1 = false;

  /// Tracks whether sub‑models have been initialized.
  static bool initialized2 = false;

  /// Chooses fake or real implementations based on [isDebug]
  /// and prevents re-initialization.
  static void init({required bool isDebug}) {
    if (initialized1) return;
    initialized1 = true;
    _instanceWeel = isDebug ? FakeLv02Wheel() : Lv02LuckWeel();
    _instanceLuck = isDebug ? FakeLv02Luck() : Lv02LuckModel();
  }

  /// Calls initialization on both wheel and luck models with [roomId]
  /// and [isDrinkingMode], after the main init().
  static Future<void> initialization({
    required String roomId,
    required bool isDrinkingMode,
  }) async {
    if (!initialized1) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      debugPrint("Lv02ModelManager not initialized. Call init() first.");
      return;
    }
    if (initialized2) {
      return;
    }
    initialized2 = true;
    await _instanceWeel.initialization(
      roomId: roomId,
      isDrinkingMode: isDrinkingMode,
    );
    _instanceLuck.initialization(
      roomId: roomId,
      isDrinkingMode: isDrinkingMode,
    );
  }

  /// Returns the initialized wheel model, reporting errors if not ready.
  static Lv02Weel instanceWeel() {
    if (!initialized1 || !initialized2) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      debugPrint("Lv02ModelManager not initialized. Call init() first.");
    }
    return _instanceWeel;
  }

  /// Returns the initialized luck model, reporting errors if not ready.
  static Lv02Luck instanceLuck() {
    if (!initialized1 || !initialized2) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      debugPrint("Lv02ModelManager not initialized. Call init() first.");
    }
    return _instanceLuck;
  }

  /// Disposes and resets both sub‑models to allow a fresh session.
  static void reset() {
    if (!initialized1 || !initialized2) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      debugPrint("Lv02ModelManager not initialized. Call init() first.");
    }
    initialized2 = false;
    _instanceWeel.dispose();
    _instanceLuck.dispose();
  }
}
