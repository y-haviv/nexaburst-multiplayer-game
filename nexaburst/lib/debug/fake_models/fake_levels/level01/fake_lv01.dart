

// skillrush/lib/model_view/room/Lv01_knowledge.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/debug/helpers/fake_data.dart';
import 'package:nexaburst/models/data/server/levels/level1/Lvo1.dart';
import 'package:nexaburst/models/structures/levels/level1/lv01_questions_loader.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/structures/levels/level1/Trivia_level.dart';
import 'package:nexaburst/models/structures/player_model.dart';
import 'package:tuple/tuple.dart';

class FakeLv01 extends Lvo1{

  final String playerId = UserData.instance.user!.id;
  bool isDrinkingMode = false;
  int currentIndex = 0;
  double playerAns = -1;

  // Constant for the level document name.
  static String levelName = TranslationService.instance.levelKeys[0];
  

  @override
  Future<void> initialization({required String roomId, required bool isDrinkingMode}) async {
    this.isDrinkingMode = isDrinkingMode;
    currentIndex = 0;
    playerAns = -1;
  }

  @override
  String getInstruction() {
    return isDrinkingMode
        ? TranslationService.instance.t('game.levels.$levelName.instructions') + TranslationService.instance.t('game.levels.$levelName.drinking_instructions')
        : TranslationService.instance.t('game.levels.$levelName.instructions');
  }

  
  // inside Lv01Knowledge
  Future<Map<String, dynamic>> _getQuestionById(TriviaLevel model) async {
    // find the raw question entry from the loaded JSON
    final questionsList = await Lv01QuestionsLoader.questions;
    final entry = questionsList.firstWhere(
      (q) => q['ID'] == model.questions[model.currentQuestionIndex],
      orElse: () => {},
    );
    if (entry.isEmpty) return {};
    if (entry.isEmpty) return {};

    // pick the node for the current language, or fallback to English
    final lang = TranslationService.instance.currentLanguage;
    final localized = entry[lang] as Map<String, dynamic>? ??
        entry['en'] as Map<String, dynamic>;

    return {
      'question': localized['question'] as String,
      'answers': localized['answers'] as Map<String, dynamic>,
      'correct_answer': entry['correct_answer'] as String,
    };
  }

  /// Fetches the next round's question data and updates the current question index.
  /// Uses a transaction to ensure that only one designated player increments the index.
  @override
  Future<Map<String, dynamic>> fetchNextRoundDataAndUpdate() async {
    
    // Get the level document snapshot.
    Map<String, dynamic> levelData = FakeRoomData.levelsData[levelName]?.toJson() ?? {};
    
    // QUESTIONS: convert raw questions array into List<int>
    final rawQs = levelData['questions'];
    final questions = <int>[];
    if (rawQs is Iterable) {
      questions.addAll(rawQs.map((e) => e as int));
    }

    // If there are no more questions, signal done.
    if (currentIndex >= questions.length) {
      return {"done": true};
    }

    // Create your model structure
    final model = TriviaLevel.fromJson(levelData);

    // Pull out the localized question + answers
    final qa = await _getQuestionById(model);

    return {
      'done': false,
      'question': qa['question'],
      'answers': qa['answers'],
      'correct_answer': qa['correct_answer'],
      'questionId': model.questions[model.currentQuestionIndex],
    };
  }

  
  @override
  Future<void> updatePlayerAnswer(double result) async {
    // Update the answers map in the level document.
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
    for(Player p in FakeRoomData.otherPlayers) {
      ans[p.id] = Tuple2(p.username,_getRandomIntInRange(1,FakeRoomData.otherPlayers.length));
    }

    return ans;
  }


  /// Resets the round by incrementing currentQuestionIndex and clearing the answers.
  /// Only the designated reset manager (host) is allowed to perform this action.
  @override
  Future<void> resetRound() async {
    currentIndex += 1;
    playerAns = -1;
    debugPrint("Reset complete: question index incremented and answers reset.");
  }
}