

// skillrush/lib/model_view/stages/level_controller_factory.dart

import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/Levels/level1/Lv01_manager.dart';
import 'package:nexaburst/model_view/room/game/Levels/level2/Lv02_manager.dart';
import 'package:nexaburst/model_view/room/game/Levels/level3/Lv03_manager.dart';
import 'package:nexaburst/model_view/room/game/Levels/level4/Lv04_manager.dart';
import 'package:nexaburst/model_view/room/game/Levels/level5/Lv05_manager.dart';
import 'package:nexaburst/model_view/room/game/Levels/level6/Lv06_manager.dart';
import 'package:nexaburst/model_view/room/game/Levels/level_factory/game_level_iterface.dart';
import 'package:nexaburst/model_view/room/game/Levels/levels_interface.dart';
import 'package:nexaburst/debug/fake_models/fake_levels/level01/fake_lv01.dart';
import 'package:nexaburst/debug/fake_models/fake_levels/level03/fake_lv03.dart';
import 'package:nexaburst/debug/fake_models/fake_levels/level04/fake_lv04.dart';
import 'package:nexaburst/debug/fake_models/fake_levels/level05/fake_lv05.dart';
import 'package:nexaburst/debug/fake_models/fake_levels/level06/fake_lev06.dart';
import 'package:nexaburst/debug/helpers/fake_data.dart';
import 'package:nexaburst/models/data/server/levels/level1/Lvo1.dart';
import 'package:nexaburst/models/data/server/levels/level2/lv02_model_manager.dart';
import 'package:nexaburst/models/data/server/levels/level3/Lv03.dart';
import 'package:nexaburst/models/data/server/levels/level4/lv04.dart';
import 'package:nexaburst/models/data/server/levels/level5/lv05.dart';
import 'package:nexaburst/models/data/server/levels/level6/Lv06.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';


class FakeGameLevelsFactory extends GameLevelIterface {

  @override
  Future<LevelLogic> create(
      {required String levelName,
      required String roomId,
      required bool isDrinkingMode,
      }) async {
    int rounds = FakeRoomData.levelsData[levelName]?.toJson()['rounds'] ??
          LevelsRounds.defaultlevelRounds;
    int levelId = 0;
    for (int i = 0; i < TranslationService.instance.levelKeys.length; i++) {
      if (TranslationService.instance.levelKeys[i] == levelName) {
        levelId = i;
      }
    }
    switch (levelId) {
      case 0:
        Lvo1 model = FakeLv01();
        await model.initialization(roomId: roomId, isDrinkingMode: isDrinkingMode);
        return Lv01knowledgeStageManager(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
          lv01Knowledge: model,
          rounds: rounds,
        );
      case 1:
        Lv02ModelManager.init(isDebug: true);
        await Lv02ModelManager.initialization(roomId: roomId, isDrinkingMode: isDrinkingMode);
        return Lv02LuckStageManager(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
          rounds: rounds,
        );
      case 2:
        Lv03 model = FakeLv03();
        await model.initialization(roomId: roomId, isDrinkingMode: isDrinkingMode);
        return Lv03IntelligenceStageManager(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
          rounds: rounds,
          lv03intelligence: model,
        );
      case 3:
        Lv04 model = FakeLv04();
        await model.initialization(roomId: roomId, isDrinkingMode: isDrinkingMode);
        return Lv04SocialStageManager(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
          lv04social: model,
          rounds: rounds,
        );
      case 4:
      Lv05 model = FakeLv05();
      model.initialization(roomId: roomId, isDrinkingMode: isDrinkingMode);
        return Lv05ReflexStageManager(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
          controller: model,
          rounds: rounds,
        );
      case 5:
        Lv06 model = FakeLev06();
        return Lv06TrustStageManager(
          roomId: roomId,
          isDrinkingMode: isDrinkingMode,
          rounds: rounds,
          lv06trust: model,
        );
      // TODO: Add future cases like:
      default:
        throw UnimplementedError('Stage not implemented: $levelName');
    }
  }
}
