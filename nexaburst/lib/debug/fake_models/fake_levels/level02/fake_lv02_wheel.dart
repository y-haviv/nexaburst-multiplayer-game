import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/debug/helpers/fake_data.dart';
import 'package:nexaburst/models/data/server/levels/level2/Lv02.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/levels/level2/Lv02_Game.dart';
import 'package:nexaburst/models/structures/levels/level2/lv02_loader.dart';
import 'package:tuple/tuple.dart';

class FakeLv02Wheel extends Lv02Weel {
  final String playerId = UserData.instance.user!.id;

  bool isDrinkingMode = false;

  // Constant for the level document name.
  static String levelName =
      TranslationService.instance.levelKeys[1];

  @override
  Future<void> initialization({
    required String roomId,
    required bool isDrinkingMode,
  }) async {
    this.isDrinkingMode = isDrinkingMode;
    await Lv02Loader.load();
  }

  @override
  String getInstruction() {
    return isDrinkingMode
        ? TranslationService.instance.t('game.levels.$levelName.instructions') +
            TranslationService.instance.t('game.levels.$levelName.drinking_instructions')
        : TranslationService.instance.t('game.levels.$levelName.instructions');
  }

  /// The function receives a list of ints from the server (the IDs of the options to roll),
  /// passes it to the function in the model, and returns the response it received from it.
  @override
  Future<List<Tuple3<int, String, bool>>> fetchWeelData() async {
    Map<String, dynamic> levelData =
        FakeRoomData.levelsData[levelName]?.toJson() ?? {};

    List<dynamic>? rawOptions = levelData['options'] as List<dynamic>?;
    List<int> options = rawOptions?.map((e) => e as int).toList() ?? [];

    if (options.isEmpty) {
      debugPrint("Error expected list of ID is empty");
    }

    final data = await Lv02Model.getOptionsMapByIds(options);
    return data;
  }

  @override
  Future<Tuple2<bool, bool>> updateForPlayer(Tuple2<int, String> result) async {
    final int optionId = result.item1;
    bool skipNextTurn = false;
    bool doubleNextTurn = false;    
    switch (optionId) {
      // +2 Points to this player - playerId
      case 1:
        // Update the player total score.
        debugPrint("+2 Points to this player - playerId");
        break;
      // -1 Point to other player - thePlayerId
      case 2:
        debugPrint("-1 Point to other player - thePlayerId");
        break;
      // case 3 Skip Next Turn this player - playerId
      case 3:
        skipNextTurn = true;
        debugPrint("Skip Next Turn this player - playerId");
        break;
      // case 4 is more spining so handle by UI
      // case 5 this player - playerId -> Swap Points with -> other player - thePlayerId
      case 5:
        debugPrint(
            "this player - playerId -> Swap Points with -> other player - thePlayerId");
        break;
      // case 6 this player get double point on next round
      case 6:
        doubleNextTurn = true;
        debugPrint("this player get double point on next round");
        break;
      // case 7 this player - playerId -> Steal 1 Point from -> other player - thePlayerId
      case 7:
        debugPrint("this player - playerId -> Steal 1 Point from -> other player - thePlayerId");
        break;
      // case 8 this player - playerId -> Give 1 Point to -> other player - thePlayerId
      case 8:
        debugPrint("this player - playerId -> Give 1 Point to -> other player - thePlayerId");
        break;
      // case 9 this player - playerId need to drink
      case 9:
        debugPrint("this player - playerId need to drink");
        break;
      // case 10 add other player - thePlayerId to drink
      case 10:
        debugPrint(" add other player - thePlayerId to drink");
        break;
      // in case of problem or if player did not span the luck weel
      default:
        debugPrint("problem or if player did not span the luck weel");
        break;
    }

    return Tuple2(skipNextTurn, doubleNextTurn);
  }

  /// Waits until the number of result players equals the total number of players.
  @override
  Future<void> loading() async {
    return;
  }

  @override
  Future<List<String>> processResults() async {
    
    List<String> resultList = ["some result", "other result", "more resulr"];

    return resultList;
  }

  @override
  Future<void> resetRound() async {
    debugPrint("Reset complete: luck weel result reset.");
  }

  @override
  Future<void> dispose() async {
    debugPrint("FakeLv02Wheel disposed.");
  }
}
