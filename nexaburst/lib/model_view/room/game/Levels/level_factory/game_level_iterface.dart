// nexaburst/lib/model_view/room/game/levels/level_factory/game_level_iterface.dart

import 'package:nexaburst/model_view/room/game/Levels/levels_interface.dart';

/// Defines the factory interface for creating level logic controllers.
abstract class GameLevelIterface {
  /// Instantiates and initializes a `LevelLogic` for the specified level.
  ///
  /// Parameters:
  /// - `levelName`: unique key of the level.
  /// - `roomId`: current game room identifier.
  /// - `isDrinkingMode`: whether drinking penalties are enabled.
  ///
  /// Returns a fully initialized `LevelLogic` instance.
  Future<LevelLogic> create({
    required String levelName,
    required String roomId,
    required bool isDrinkingMode,
  });
}
