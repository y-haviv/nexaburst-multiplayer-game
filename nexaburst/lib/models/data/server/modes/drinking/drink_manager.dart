// nexaburst/lib/models/server/modes/drinking/drink_manager.dart

import 'package:nexaburst/debug/fake_models/fake_drink_model.dart';
import 'package:nexaburst/models/data/server/modes/drinking/drink_model.dart';
import 'package:nexaburst/models/data/server/modes/drinking/drinking_game.dart';

/// Provides a global [DrinkingGame] instance, selecting either a
/// fake or real implementation based on debug mode.
class DrinkManager {
  static late final DrinkingGame _instance;

  /// Initializes the shared [DrinkingGame] instance.
  ///
  /// [isDebug]: when true, uses [FakeDrinkModel]; otherwise uses [DrinkModel].
  static void init({required bool isDebug}) {
    _instance = isDebug ? FakeDrinkModel() : DrinkModel();
  }

  /// Returns the initialized [DrinkingGame] singleton.
  ///
  /// Call `init(...)` before accessing this.
  static DrinkingGame get instance => _instance;
}
