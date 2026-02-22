import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/debug/helpers/fake_data.dart';
import 'package:nexaburst/models/data/server/levels/level2/Lv02.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/player_model.dart';
import 'package:tuple/tuple.dart';

class FakeLv02Luck extends Lv02Luck {
  final String playerId = UserData.instance.user!.id;

  bool isDrinkingMode = false;
  int currentIndex = 0;

  // Constant for the level document name.
  static String levelName = TranslationService.instance.levelKeys[1];

  @override
  void initialization({required String roomId, required bool isDrinkingMode}) {
    this.isDrinkingMode = isDrinkingMode;
    currentIndex = 0;
  }

  @override
  String getInstruction() {
    return isDrinkingMode
        ? TranslationService.instance.t('game.levels.$levelName.instructions') +
              TranslationService.instance.t('game.levels.$levelName.drinking_instructions')
        : TranslationService.instance.t('game.levels.$levelName.instructions');
  }

  @override
  Future<Map<String, dynamic>> fetchNextRoundDataAndUpdate() async {
    Map<String, dynamic> levelData =
        FakeRoomData.levelsData[levelName]?.toJson() ?? {};

    final rawPositions = levelData['positions'] as Map<String, dynamic>? ?? {};
    final List<Map<String, dynamic>> positions = rawPositions.entries
        .map((entry) => Map<String, dynamic>.from(entry.value))
        .toList();

    if (currentIndex >= positions.length) {
      return {"done": true};
    }

    Map<String, dynamic> currentPosition = positions[currentIndex];
    return {
      "done": false,
      "gold": currentPosition["gold"],
      "black": currentPosition["black"],
    };
  }

  @override
  Future<void> updatePlayerAnswer(int result) async {}

  @override
  Future<void> loading() async {
    return;
  }

  int _getRandomIntInRange(int min, int max) {
    final random = Random();
    return min + random.nextInt(max - min + 1);
  }

  @override
  Future<Map<String, Tuple2<String, int>>> processResults(
    int black,
    int gold, {
    bool skip = false,
  }) async {
    Map<String, Tuple2<String, int>> ans = {};
    for (Player p in FakeRoomData.otherPlayers) {
      ans[p.id] = Tuple2(
        p.username,
        _getRandomIntInRange(1, FakeRoomData.otherPlayers.length),
      );
    }

    return ans;
  }

  /// Resets the round by incrementing the currentIndex in the level document and clearing answers.
  /// Only the designated reset manager (stored in the room document as resetManager) can perform this action.
  @override
  Future<void> resetRound() async {
    currentIndex += 1;
  }

  @override
  Future<void> dispose() async {
    debugPrint("Disposing FakeLv02Luck");
  }
}
