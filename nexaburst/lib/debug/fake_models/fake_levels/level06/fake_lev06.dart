import 'dart:async';
import 'dart:math';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/debug/helpers/fake_data.dart';
import 'package:nexaburst/models/data/server/levels/level6/Lv06.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:tuple/tuple.dart';

class FakeLev06 extends Lv06 {
  final String playerId = UserData.instance.user!.id;

  late bool isDrinkingMode;
  bool stole = false;
  int geuss = -1;

  // Constant for the level document name.
  static String levelName =
      TranslationService.instance.levelKeys[5];

  @override
  Stream<int> get playerCountStream async* {
    // Simulate a stream that emits the number of players in the room.
    while (true) {
      await Future.delayed(Duration(seconds: 5));
      yield FakeRoomData.otherPlayers.length + 1; // +1 for the current player
    }
  }

  @override
  void initialization({
    required String roomId,
    required bool isDrinkingMode,
  }) {
    this.isDrinkingMode = isDrinkingMode;
    stole = false;
    geuss = -1;
  }

  @override
  String getInstruction() {
    return isDrinkingMode
        ? TranslationService.instance.t('game.levels.$levelName.instructions') +
            TranslationService.instance.t('game.levels.$levelName.drinking_instructions')
        : TranslationService.instance.t('game.levels.$levelName.instructions');
  }

  @override
  Future<void> EndLevelBonus() async {}

  @override
  Future<void> updatePlayerAnswer(bool result, int guess) async {
    stole = result;
    guess = geuss;
  }

  @override
  Future<void> loading() async {}

  @override
  Future<Map<String, dynamic>> processResults() async {
    Map<String, Tuple2<String, String>> playersInfo = {};
    int count = 0;
    for (int i = 0; i < FakeRoomData.otherPlayers.length; i++) {
      String pid = FakeRoomData.otherPlayers[i].id;
      if(geuss == -1) {
        geuss = Random().nextInt(FakeRoomData.otherPlayers.length + 1);
      }
      if (pid == playerId) {
        if (stole) {
          count += 1;
        }
        playersInfo[pid] = Tuple2(stole.toString(), geuss!=-1 ? geuss.toString() : "Didn't guess");
      } else {
        final random = Random();
        bool booleanStill = random.nextInt(2) == 1;
        if (booleanStill) {
          count += 1;
        }
        playersInfo[pid] = Tuple2(booleanStill.toString(), geuss!=-1 ? geuss.toString() : "Didn't guess");
      }
      if(geuss == -1) {
        geuss = Random().nextInt(FakeRoomData.otherPlayers.length + 1);
      } else {
        geuss = -1;
      }
    }

    return {
      "add_to_score": 2,
      "bonusGuessCorrect": geuss == count ? false : true,
      "playersInfo": playersInfo,
    };
  }

  @override
  Future<void> resetRound() async {}
}
