// nexaburst/lib/model_view/room/game/levels/level_factory/game_level.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/Levels/level1/Lv01_manager.dart';
import 'package:nexaburst/model_view/room/game/Levels/level2/Lv02_manager.dart';
import 'package:nexaburst/model_view/room/game/Levels/level3/Lv03_manager.dart';
import 'package:nexaburst/model_view/room/game/Levels/level4/Lv04_manager.dart';
import 'package:nexaburst/model_view/room/game/Levels/level5/Lv05_manager.dart';
import 'package:nexaburst/model_view/room/game/Levels/level6/Lv06_manager.dart';
import 'package:nexaburst/model_view/room/game/Levels/level_factory/game_level_iterface.dart';
import 'package:nexaburst/model_view/room/game/Levels/levels_interface.dart';
import 'package:nexaburst/models/data/server/levels/level1/Lv01_knowledge.dart';
import 'package:nexaburst/models/data/server/levels/level1/Lvo1.dart';
import 'package:nexaburst/models/data/server/levels/level2/lv02_model_manager.dart';
import 'package:nexaburst/models/data/server/levels/level3/Lv03.dart';
import 'package:nexaburst/models/data/server/levels/level3/Lv03_Intelligence.dart';
import 'package:nexaburst/models/data/server/levels/level4/Lv04_social.dart';
import 'package:nexaburst/models/data/server/levels/level4/lv04.dart';
import 'package:nexaburst/models/data/server/levels/level5/Lv05_whack_a_mole.dart';
import 'package:nexaburst/models/data/server/levels/level5/lv05.dart';
import 'package:nexaburst/models/data/server/levels/level6/Lv06.dart';
import 'package:nexaburst/models/data/server/levels/level6/Lv06_trust.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// Concrete factory that loads level configuration from Firestore
/// then dispatches to the appropriate level manager.
class LevelLogicFactory extends GameLevelIterface {
  /// Fetches the configured number of rounds for [levelName] from Firestore.
  ///
  /// Returns the stored `'rounds'` value or `defaultlevelRounds` on error.
  Future<int> fetLevelRounds(String levelName, String roomId) async {
    try {
      // Fetch the number of rounds for the current level from Firestore.
      DocumentSnapshot levelSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('levels')
          .doc(levelName)
          .get();
      return levelSnapshot['rounds'] ??
          LevelsRounds.defaultlevelRounds; // Default to 1 if not found.
    } catch (e) {
      debugPrint("Error fetching level rounds: $e");
      return LevelsRounds
          .defaultlevelRounds; // Default to 1 if an error occurs.
    }
  }

  /// Creates and initializes a `LevelLogic` based on [levelName].
  /// Determines the level index, reads rounds, and calls the respective manager.
  ///
  /// Returns the configured stage manager ready for gameplay.
  @override
  Future<LevelLogic> create({
    required String levelName,
    required String roomId,
    required bool isDrinkingMode,
  }) async {
    int rounds = await fetLevelRounds(levelName, roomId);
    int levelId = 0;
    for (int i = 0; i < TranslationService.instance.levelKeys.length; i++) {
      if (TranslationService.instance.levelKeys[i] == levelName) {
        levelId = i;
      }
    }
    switch (levelId) {
      case 0:
        Lvo1 model = Lv01Knowledge();
        await model.initialization(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
        );
        return Lv01knowledgeStageManager(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
          lv01Knowledge: model,
          rounds: rounds,
        );
      case 1:
        Lv02ModelManager.init(isDebug: false);
        await Lv02ModelManager.initialization(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
        );
        return Lv02LuckStageManager(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
          rounds: rounds,
        );
      case 2:
        Lv03 model = Lv03Intelligence();
        await model.initialization(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
        );
        return Lv03IntelligenceStageManager(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
          rounds: rounds,
          lv03intelligence: model,
        );
      case 3:
        Lv04 model = Lv04Social();
        await model.initialization(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
        );
        return Lv04SocialStageManager(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
          lv04social: model,
          rounds: rounds,
        );
      case 4:
        Lv05 model = Lv05WhackAMole();
        model.initialization(roomId: roomId, isDrinkingMode: isDrinkingMode);
        return Lv05ReflexStageManager(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
          rounds: rounds,
          controller: model,
        );
      case 5:
        Lv06 model = Lv06Trust();
        return Lv06TrustStageManager(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
          rounds: rounds,
          lv06trust: model,
        );
      default:
        throw UnimplementedError('Level not implemented: $levelName');
    }
  }
}
