// nexaburst/lib/model_view/room/game/levels/level_factory/game_levels_factory_manager.dart

import 'package:nexaburst/model_view/room/game/Levels/level_factory/game_level.dart';
import 'package:nexaburst/model_view/room/game/Levels/level_factory/game_level_iterface.dart';
import 'package:nexaburst/debug/helpers/fake_game_levels_factory.dart';

/// Manages a singleton `GameLevelIterface`, choosing fake or real
/// factory based on debug flag.
class GameLevelsFactoryManager {
  static late final GameLevelIterface _instance;

  /// Configures the factory implementation.
  ///
  /// [isDebug]: when true, uses `FakeGameLevelsFactory`; otherwise `LevelLogicFactory`.
  static void init({required bool isDebug}) {
    _instance = isDebug ? FakeGameLevelsFactory() : LevelLogicFactory();
  }

  /// Accessor for the configured level factory singleton.
  static GameLevelIterface get instance => _instance;
}
