import 'dart:async';
import 'dart:math';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/debug/helpers/command_registry.dart';
import 'package:nexaburst/debug/helpers/fake_data.dart';
import 'package:nexaburst/models/data/server/levels/level4/lv04.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/levels/level4/Lv04_model.dart';
import 'package:nexaburst/models/structures/levels/level4/lv04_loader.dart';
import 'package:nexaburst/models/structures/player_model.dart';
import 'package:tuple/tuple.dart';

class FakeLv04 extends Lv04 {
  final String playerId = UserData.instance.user!.id;

  bool isDrinkingMode = false;
  bool curretTargetPlayer = false;
  bool beenChoose = false;
  int currentIndex = 0;

  static String levelName =
      TranslationService.instance.levelKeys[3];

  @override
  Future<void> initialization({
    required String roomId,
    required bool isDrinkingMode,
  }) async {
    this.isDrinkingMode = isDrinkingMode;
    curretTargetPlayer = false;
    beenChoose = false;
    currentIndex = 0;
    await Lv04Loader.load();
  }

  @override
  @override
  String getInstruction() {
    return isDrinkingMode
        ? TranslationService.instance.t('game.levels.$levelName.instructions') +
            TranslationService.instance.t('game.levels.$levelName.drinking_instructions')
        : TranslationService.instance.t('game.levels.$levelName.instructions');
  }

  @override
  Future<void> allPlayersStartLoop() async {}

  @override
  Future<void> chooseRandomPlayer() async {
    beenChoose = false;
    CommandRegistry.instance.register('y', 'to be in /"target player/"',
        (arg) async {
      curretTargetPlayer = true;
      beenChoose = true;
    });
    CommandRegistry.instance.register('n', 'to be in /"NOT target player/"',
        (arg) async {
      curretTargetPlayer = false;
      beenChoose = true;
    });

    while (!beenChoose) {
      await Future.delayed(Duration(seconds: 2));
    }
  }

   Future<Map<String, dynamic>> _getScenarioById(Lv04SocialModel model) async {
    // find the raw question entry from the loaded JSON
    final questionsList = await Lv04Loader.data;
    final entry = questionsList.firstWhere(
      (q) => q['ID'] == model.scenarios[model.currentScenarioIndex],
      orElse: () => {},
    );
    if (entry.isEmpty) return {};

    // pick the node for the current language, or fallback to English
    final lang = TranslationService.instance.currentLanguage;
    final localized = entry[lang] as Map<String, dynamic>? ??
        entry['en'] as Map<String, dynamic>;

    return {
      'scenario': localized['scenario'] as String,
      'options': localized['options'] as Map<String, dynamic>,
    };
  }

  @override
  Future<Map<String, dynamic>> fetchNextRoundDataAndUpdate() async {
    final levelData = FakeRoomData.levelsData[levelName]?.toJson() ?? {};

    final rawQs = levelData['scenarios'] as List<dynamic>? ?? [];
    final scenarios = rawQs.map((e) => e as int).toList();

    if (currentIndex >= scenarios.length) return {"done": true};

    final scenarioId = scenarios[currentIndex];
    final model = Lv04SocialModel(
        currentScenarioIndex: currentIndex, scenarios: scenarios, rounds: 0);
    final scenarioDetails = await _getScenarioById(model);
    currentIndex += 1;

    return {
      "done": false,
      "targetPlayer": curretTargetPlayer ? playerId : "",
      "targetPlayerName": levelData['targetPlayerName'] ?? "",
      "scenario": scenarioDetails["scenario"],
      "options": scenarioDetails["options"],
      "scenarioId": scenarioId,
    };
  }

  @override
  Future<bool> isTargetPlayer() async {
    return curretTargetPlayer;
  }

  @override
  Future<void> updatePlayerAnswer(String result) async {}

  @override
  Future<void> loading() async {}

  int _getRandomIntInRange(int min, int max) {
  final random = Random();
  return min + random.nextInt(max - min + 1);
}

   @override
  Future<Map<String, Tuple2<String, int>>> processQuestionResults() async {
     CommandRegistry.instance.unregister('y');
    CommandRegistry.instance.unregister('n');
    Map<String, Tuple2<String, int>> ans = {};
    for(Player p in FakeRoomData.otherPlayers) {
      ans[p.id] = Tuple2(p.username,_getRandomIntInRange(1,FakeRoomData.otherPlayers.length));
    }

    return ans;
  }

  
}
