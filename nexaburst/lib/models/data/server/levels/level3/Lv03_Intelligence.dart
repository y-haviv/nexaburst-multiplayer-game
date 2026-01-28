// nexaburst/lib/models/server/levels/level3/Lv03_intelligence.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/server/levels/level3/Lv03.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:nexaburst/models/structures/levels/level3/Lv03_model.dart';
import 'package:nexaburst/models/structures/levels/level3/lv03_loader.dart';
import 'package:tuple/tuple.dart';

/// Level 3 “Intelligence” implementation.
/// Fetches questions from JSON, collects answers, scores, and handles drinking mode.
class Lv03Intelligence extends Lv03 {
  /// Unique ID of the current user.
  final String playerId = UserData.instance.user!.id;

  /// Firestore document ID for the current game room.
  late String roomId;

  /// Whether incorrect answers trigger a drinking penalty.
  bool isDrinkingMode = false;

  /// Guards against repeated initialization.
  bool _initialized = false;

  /// Firestore document key for this level from the translation service.
  static String levelName = TranslationService.instance.levelKeys[2];

  /// Singleton Firestore instance for database operations.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reference to the room’s document in Firestore.
  DocumentReference get _roomDoc => _firestore.collection('rooms').doc(roomId);

  /// Reference to this level’s document under the room.
  DocumentReference get _levelDoc =>
      _roomDoc.collection('levels').doc(levelName);

  /// Performs one‑time setup: sets [roomId], [isDrinkingMode], marks initialized,
  /// and loads question data via `Lv03Loader`.
  @override
  Future<void> initialization({
    required String roomId,
    required bool isDrinkingMode,
  }) async {
    if (_initialized) return;
    this.roomId = roomId;
    this.isDrinkingMode = isDrinkingMode;
    _initialized = true;
    await Lv03Loader.load();
  }

  /// Returns localized Level 3 prompt, appending drinking instructions if enabled.
  @override
  String getInstruction() {
    return isDrinkingMode && _initialized
        ? TranslationService.instance.t('game.levels.$levelName.instructions') +
              TranslationService.instance.t(
                'game.levels.$levelName.drinking_instructions',
              )
        : TranslationService.instance.t('game.levels.$levelName.instructions');
  }

  /// Loads question text and answer options for [model.currentQuestionIndex]
  /// from locally cached JSON, handling localization and errors.
  Future<Map<String, dynamic>> _getQuestionById(Lv03Model model) async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return {
        'question': "problem getting question",
        'answers': {"a": "", "b": "", "c": "", "d": ""},
        'correct_answer': "",
      };
    }
    try {
      // find the raw question entry from the loaded JSON
      final questionsList = await Lv03Loader.data;
      final entry = questionsList.firstWhere(
        (q) => q['ID'] == model.questions[model.currentQuestionIndex],
        orElse: () => {},
      );
      if (entry.isEmpty) return {};

      // pick the node for the current language, or fallback to English
      final lang = TranslationService.instance.currentLanguage;
      final localized =
          entry[lang] as Map<String, dynamic>? ??
          entry['en'] as Map<String, dynamic>;

      return {
        'question': localized['question'] as String,
        'answers': localized['answers'] as Map<String, dynamic>,
        'correct_answer': entry['correct_answer'] as String,
      };
    } catch (e) {
      debugPrint("problem getting local data");
      ErrorService.instance.report(error: ErrorType.localDatabase);
      return {
        'question': "problem getting question",
        'answers': {"a": "", "b": "", "c": "", "d": ""},
        'correct_answer': "",
      };
    }
  }

  /// Retrieves next question ID and payload from Firestore.
  /// Returns map with keys `"done"`, `"question"`, `"answers"`, `"correct_answer"`, and `"questionId"`.
  @override
  Future<Map<String, dynamic>> fetchNextRoundDataAndUpdate() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return {"done": true};
    }
    try {
      // Get the level document snapshot.
      DocumentSnapshot levelSnapshot = await _levelDoc.get();
      Map<String, dynamic> levelData =
          levelSnapshot.data() as Map<String, dynamic>? ?? {};

      // Retrieve the current question index and the list of questions.
      int currentIndex = levelData['currentQuestionIndex'] ?? 0;

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

      // Get the question ID for the current round.
      int questionId = questions[currentIndex];

      // Create a model instance and retrieve question details.
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
    } catch (e) {
      debugPrint("Error model level 03: $e");
      ErrorService.instance.report(error: ErrorType.firestore);
      return {"done": true};
    }
  }

  /// Saves the player’s answer result into Firestore.
  ///
  /// [result] — the reported answer time or error code.
  @override
  Future<void> updatePlayerAnswer(double result) async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    // Update the answers map in the level document.
    await _levelDoc.update({'answers.$playerId': result});
  }

  /// Stream emitting the current count of players who have answered.
  Stream<int> get _answeredCountStream {
    return _levelDoc.snapshots().map((snapshot) {
      Map<String, dynamic> data =
          snapshot.data() as Map<String, dynamic>? ?? {};
      Map answers = data['answers'] ?? {};
      return answers.length;
    });
  }

  /// Waits until all players in `/players` subcollection have answered.
  @override
  Future<void> loading() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    // Retrieve total players from the /players subcollection.
    int totalPlayers = await _roomDoc
        .collection('players')
        .get()
        .then((snapshot) => snapshot.docs.length);

    // Listen to the answeredCountStream until the count equals totalPlayers.
    await for (int answeredCount in _answeredCountStream) {
      debugPrint(
        "Stream update: Answered $answeredCount / Total $totalPlayers",
      );
      if (answeredCount >= totalPlayers) break;
    }
  }

  /// Calculates score deltas for each player based on answer times,
  /// applies drinking penalties if enabled, and returns playerId→(username,points).
  @override
  Future<Map<String, Tuple2<String, int>>> processQuestionResults() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return {};
    }

    final Map<String, Tuple2<String, int>> playersResults = {};

    // Retrieve the current level data.
    DocumentSnapshot levelSnapshot = await _levelDoc.get();
    final Map<String, dynamic> levelData =
        levelSnapshot.data() as Map<String, dynamic>? ?? {};

    // Get the answers map and filter only positive answers.
    final Map<String, int> intAnswersMap = Map<String, dynamic>.from(
      levelData['answers'] ?? {},
    ).map((key, value) => MapEntry(key, value as int));

    final filtered =
        intAnswersMap.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value)); // Sort from high to low

    // אם אין תשובות חיוביות, בדוק אם השחקן צריך לשתות
    if (filtered.isEmpty) {
      if (isDrinkingMode) {
        final Map<String, dynamic> beforeDrink = Map<String, dynamic>.from(
          levelData['player_before_drink'] ?? {},
        );

        final DocumentSnapshot playerSnapshot = await _roomDoc
            .collection('players')
            .doc(playerId)
            .get();

        final String playerName =
            (playerSnapshot.data() as Map<String, dynamic>?)?["username"] ??
            "Unknown";

        if (beforeDrink.containsKey(playerId)) {
          await _levelDoc.update({
            'player_before_drink.$playerId': FieldValue.delete(),
          });
          await _roomDoc.update({'players_to_drink.$playerId': playerName});
        } else {
          await _levelDoc.update({'player_before_drink.$playerId': playerName});
        }
      }
      return playersResults;
    }

    final QuerySnapshot<Map<String, dynamic>> roomPlayerSnapshot =
        await _roomDoc.collection('players').get();

    bool needToDrink = true;
    int addedPoints = filtered.length;

    for (final entry in filtered) {
      final playerIdEntry = entry.key;

      final matchingDocs = roomPlayerSnapshot.docs
          .where((doc) => doc.id == playerIdEntry)
          .toList();
      if (matchingDocs.isEmpty) continue;

      final playerDoc = matchingDocs.first;

      final String playerName = playerDoc.data()['username'] ?? 'Unknown';
      final int currentScore = playerDoc.data()['total_score'] ?? 0;
      final int pointsToAdd = addedPoints;

      playersResults[playerIdEntry] = Tuple2(playerName, pointsToAdd);

      if (playerIdEntry == playerId) {
        needToDrink = false;
        final int newScore = currentScore + pointsToAdd;
        await _roomDoc.collection('players').doc(playerId).update({
          'total_score': newScore,
        });
      }

      addedPoints -= 1;
    }

    if (isDrinkingMode && needToDrink) {
      final Map<String, dynamic> beforeDrink = Map<String, dynamic>.from(
        levelData['player_before_drink'] ?? {},
      );

      final playerDocs = roomPlayerSnapshot.docs
          .where((doc) => doc.id == playerId)
          .toList();

      if (playerDocs.isEmpty) return {};

      final playerDoc = playerDocs.first;

      final String playerName = playerDoc.data()["username"] ?? "Unknown";

      if (beforeDrink.containsKey(playerId)) {
        await _levelDoc.update({
          'player_before_drink.$playerId': FieldValue.delete(),
        });
        await _roomDoc.update({'players_to_drink.$playerId': playerName});
      } else {
        await _levelDoc.update({'player_before_drink.$playerId': playerName});
      }
    }

    final sortedResults = {
      for (final e
          in (playersResults.entries.toList()
            ..sort((a, b) => b.value.item2.compareTo(a.value.item2))))
        e.key: e.value,
    };

    return sortedResults;
  }

  /// Atomically increments `currentQuestionIndex` and clears `answers` in Firestore.
  @override
  Future<void> resetRound() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    // Use a transaction to atomically update the level document.
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot levelSnapshot = await transaction.get(_levelDoc);
      if (!levelSnapshot.exists) {
        debugPrint("Level document does not exist!");
        ErrorService.instance.report(error: ErrorType.notFound);
        return;
      }
      int currentQuestionIndex =
          levelSnapshot.get('currentQuestionIndex') as int? ?? 0;
      transaction.update(_levelDoc, {
        'currentQuestionIndex': currentQuestionIndex + 1,
        'answers': {},
      });
    });
    debugPrint("Reset complete: question index incremented and answers reset.");
  }

  /// Disposes and resets both sub‑models to allow a fresh session.
  @override
  void dispose() {
    _initialized = false;
  }
}
