// nexaburst/lib/models/structures/levels/levels_factory.dart

import 'package:nexaburst/constants.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/levels/level3/Lv03_model.dart';
import 'package:nexaburst/models/structures/levels/level2/Lv02_Game.dart';
import 'package:nexaburst/models/structures/levels/level4/Lv04_model.dart';
import 'package:nexaburst/models/structures/levels/level5/Lv05_model.dart';
import 'package:nexaburst/models/structures/levels/level6/Lv06_trust_model.dart';
import 'package:nexaburst/models/structures/levels/level1/Trivia_level.dart';

/// Defines the interface for per‑level game data:
/// supports asynchronous initialization and JSON (de)serialization.
abstract class GameModels {
  /// Performs all asynchronous setup required before gameplay,
  /// such as loading assets or shuffling data.
  Future<void> initialization();

  /// Serializes this level’s state to a JSON‑compatible map.
  Map<String, dynamic> toJson();

  /// Creates the concrete [GameModels] instance for [levelIndex]
  /// by delegating to the corresponding level’s `fromJson`.
  /// Throws if [levelIndex] is unrecognized.
  factory GameModels.fromJson(Map<String, dynamic> json, int levelIndex) {
    switch (levelIndex) {
      case 1:
        return TriviaLevel.fromJson(json);
      case 2:
        return Lv02Model.fromJson(json);
      case 3:
        return Lv03Model.fromJson(json);
      case 4:
        return Lv04SocialModel.fromJson(json);
      case 5:
        return Lv05WhackMoleModel.fromJson(json);
      case 6:
        return Lv06TrustModel.fromJson(json);
      default:
        throw Exception("Unknown level index: $levelIndex");
    }
  }
}

/// Factory for instantiating a new, empty level model
/// by level name, with optional drinking mode and round count.
class GameLevelsInitializationFactory {
  /// Looks up [levelName] in the translation keys to determine
  /// the level index, validates [levelRound], and returns
  /// a fresh level model with those settings.
  ///
  /// - [isDrinkingMode]: enables drinking‐mode rules if true
  /// - [levelRound]: number of rounds to play (clamped by [LevelsRounds])
  static GameModels createLevel(
    String levelName, {
    bool isDrinkingMode = false,
    int levelRound = LevelsRounds.defaultlevelRounds,
  }) {
    int levelId = 0;
    for (int i = 0; i < TranslationService.instance.levelKeys.length; i++) {
      if (TranslationService.instance.levelKeys[i] == levelName) {
        levelId = i;
      }
    }
    levelRound = LevelsRounds.checkRoundInput(levelRound);
    switch (levelId) {
      case 0:
        return TriviaLevel(rounds: levelRound);
      case 1:
        return Lv02Model(isDrinking: isDrinkingMode, rounds: levelRound);
      case 2:
        return Lv03Model(rounds: levelRound);
      case 3:
        return Lv04SocialModel(rounds: levelRound);
      case 4:
        return Lv05WhackMoleModel(rounds: levelRound);
      case 5:
        return Lv06TrustModel(rounds: levelRound);
      default:
        throw Exception("Unknown stage type: $levelName");
    }
  }
}
