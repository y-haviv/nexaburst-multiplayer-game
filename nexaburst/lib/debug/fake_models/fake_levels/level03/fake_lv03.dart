import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/debug/helpers/fake_data.dart';
import 'package:nexaburst/models/data/server/levels/level3/Lv03.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/levels/level3/Lv03_model.dart';
import 'package:nexaburst/models/structures/levels/level3/lv03_loader.dart';
import 'package:nexaburst/models/structures/player_model.dart';
import 'package:tuple/tuple.dart';

/// Debug implementation of the Level 03 intelligence mode.
class FakeLv03 extends Lv03 {
  final String playerId = UserData.instance.user!.id;

  late String roomId;
  bool isDrinkingMode = false;
  int currentIndex = 0;
  double playerAns = -1;

  /// Localized level key used for instruction lookup.
  static String levelName = TranslationService.instance.levelKeys[2];

  @override
  Future<void> initialization({
    required String roomId,
    required bool isDrinkingMode,
  }) async {
    currentIndex = 0;
    this.roomId = roomId;
    this.isDrinkingMode = isDrinkingMode;
    await Lv03Loader.load();
  }

  @override
  String getInstruction() {
    return isDrinkingMode
        ? TranslationService.instance.t('game.levels.$levelName.instructions') +
              TranslationService.instance.t(
                'game.levels.$levelName.drinking_instructions',
              )
        : TranslationService.instance.t('game.levels.$levelName.instructions');
  }

  Future<Map<String, dynamic>> _getQuestionById(Lv03Model model) async {
    // Resolve the current question in the loaded fixture payload.
    final questionsList = await Lv03Loader.data;
    final entry = questionsList.firstWhere(
      (q) => q['ID'] == model.questions[model.currentQuestionIndex],
      orElse: () => {},
    );
    if (entry.isEmpty) return {};

    // Prefer current language and fall back to English when unavailable.
    final lang = TranslationService.instance.currentLanguage;
    final localized =
        entry[lang] as Map<String, dynamic>? ??
        entry['en'] as Map<String, dynamic>;

    return {
      'question': localized['question'] as String,
      'answers': localized['answers'] as Map<String, dynamic>,
      'correct_answer': entry['correct_answer'] as String,
    };
  }

  @override
  Future<Map<String, dynamic>> fetchNextRoundDataAndUpdate() async {
    Map<String, dynamic> levelData =
        FakeRoomData.levelsData[levelName]?.toJson() ?? {};

    // Convert raw serialized IDs into a strongly typed question list.
    final rawQs = levelData['questions'];
    final questions = <int>[];
    if (rawQs is Iterable) {
      questions.addAll(rawQs.map((e) => e as int));
    }

    // Stop when all configured questions have been consumed.
    if (currentIndex >= questions.length) {
      return {"done": true};
    }

    // Build the current round response payload.
    int questionId = questions[currentIndex];

    // Pull localized question details from the loader source.
    Lv03Model model = Lv03Model(
      currentQuestionIndex: currentIndex,
      questions: questions,
      rounds: 0,
    );
    Map<String, dynamic> questionDetails = await _getQuestionById(model);

    return {
      "done": false,
      "question": questionDetails["question"],
      "answers": questionDetails["answers"],
      "correct_answer": questionDetails["correct_answer"],
      "questionId": questionId,
    };
  }

  @override
  Future<void> updatePlayerAnswer(double result) async {
    playerAns = result;
  }

  @override
  Future<void> loading() async {
    return;
  }

  int _getRandomIntInRange(int min, int max) {
    final random = Random();
    return min + random.nextInt(max - min + 1);
  }

  @override
  Future<Map<String, Tuple2<String, int>>> processQuestionResults() async {
    Map<String, Tuple2<String, int>> ans = {};
    for (Player p in FakeRoomData.otherPlayers) {
      ans[p.id] = Tuple2(
        p.username,
        _getRandomIntInRange(1, FakeRoomData.otherPlayers.length),
      );
    }

    return ans;
  }

  @override
  Future<void> resetRound() async {
    currentIndex += 1;
    debugPrint("Reset complete: question index incremented and answers reset.");
  }

  @override
  void dispose() {}
}
