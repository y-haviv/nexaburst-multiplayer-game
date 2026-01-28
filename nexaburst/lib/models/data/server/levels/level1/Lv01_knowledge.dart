// nexaburst/lib/models/server/levels/level1/Lv01_knowledge.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/models/data/server/levels/level1/Lvo1.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:nexaburst/models/structures/levels/level1/lv01_questions_loader.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/structures/levels/level1/Trivia_level.dart';
import 'package:tuple/tuple.dart';

/// Implementation of the Level 01 logic, handling a trivia-based round.
/// Extends [Lvo1] and interacts with Firestore to manage questions,
/// responses, scoring, and progression.
class Lv01Knowledge extends Lvo1 {
  /// The ID of the current player, fetched from the shared user data instance.
  final String playerId = UserData.instance.user!.id;

  /// The Firestore room document ID for this game session.
  String? roomId;

  /// Whether the game is currently in drinking mode (affects scoring/penalties).
  bool isDrinkingMode = false;

  /// Whether the level has been initialized to prevent re-initialization.
  bool _initialized = false;

  /// The Firestore instance used to access game data.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reference to the room document in Firestore for the current game session.
  DocumentReference get _roomDoc => _firestore.collection('rooms').doc(roomId);

  /// Reference to the level document for this specific level within the room.
  DocumentReference get _levelDoc =>
      _roomDoc.collection('levels').doc(Lvo1.levelName);

  @override
  Future<void> initialization({
    required String roomId,
    required bool isDrinkingMode,
  }) async {
    if (_initialized) return;
    this.roomId = roomId;
    this.isDrinkingMode = isDrinkingMode;
    _initialized = true;
    await Lv01QuestionsLoader.load();
  }

  @override
  String getInstruction() {
    return isDrinkingMode && _initialized
        ? TranslationService.instance.t(
                'game.levels.${Lvo1.levelName}.instructions',
              ) +
              TranslationService.instance.t(
                'game.levels.${Lvo1.levelName}.drinking_instructions',
              )
        : TranslationService.instance.t(
            'game.levels.${Lvo1.levelName}.instructions',
          );
  }

  /// Fetches a localized question entry by ID from the loaded question set.
  ///
  /// Parameters:
  /// - [model]: The current trivia level model including the question index.
  ///
  /// Returns a map with:
  /// - `question`: Localized question string.
  /// - `answers`: Map of choices.
  /// - `correct_answer`: The correct answer key.
  ///
  /// Returns a fallback map if the question cannot be found or an error occurs.
  Future<Map<String, dynamic>> _getQuestionById(TriviaLevel model) async {
    try {
      // find the raw question entry from the loaded JSON
      final questionsList = await Lv01QuestionsLoader.questions;
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
      debugPrint("Error fetching question by ID: $e");
      return {
        'question': "problem fetching question",
        'answers': {'a': "", 'b': "", 'c': "", 'd': ""},
        'correct_answer': "",
      };
    }
  }

  /// Fetches the next round's question data and updates the current question index.
  /// Uses a transaction to ensure that only one designated player increments the index.
  @override
  Future<Map<String, dynamic>> fetchNextRoundDataAndUpdate() async {
    if (!_initialized) {
      debugPrint("Lv01Knowledge not initialized.");
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return {"done": true};
    }

    // Get the level document snapshot.
    DocumentSnapshot levelSnapshot = await _levelDoc.get();
    if (!levelSnapshot.exists) {
      debugPrint("Level document does not exist!");
      ErrorService.instance.report(error: ErrorType.notFound);
      return {"done": true};
    }
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

  /// Updates the player's answer time in the level's answers map.
  /// A positive [result] indicates a correct answer (with the time taken),
  /// while a negative value (typically -1) indicates an incorrect answer or timeout.
  @override
  Future<void> updatePlayerAnswer(double result) async {
    if (!_initialized) return;
    try {
      // Update the answers map in the level document.
      await _levelDoc.update({'answers.$playerId': result});
    } catch (e) {
      debugPrint("Error lv01 model: $e");
      ErrorService.instance.report(error: ErrorType.firestore);
    }
  }

  /// A stream that listens for changes in the number of players who answered.
  /// Emits the current count of answered players in real-time.
  Stream<int> get _answeredCountStream {
    return _levelDoc.snapshots().map((snapshot) {
      Map<String, dynamic> data =
          snapshot.data() as Map<String, dynamic>? ?? {};
      Map answers = data['answers'] ?? {};
      return answers.length;
    });
  }

  /// Waits until the number of answered players matches the total number of players.
  @override
  Future<void> loading() async {
    if (!_initialized) return;
    try {
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
    } catch (e) {
      debugPrint("Error lv1 model: $e");
      ErrorService.instance.report(error: ErrorType.firestore);
    }
  }

  /// Processes the answers for the current round and calculates the player's score.
  /// For correct answers, points are awarded based on ranking (faster gets more points).
  /// For incorrect answers, if drinking mode is enabled, the player's info is added to players_to_drink.
  /// Finally, one designated player should reset the round data.
  @override
  Future<Map<String, Tuple2<String, int>>> processQuestionResults() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return {};
    }

    try {
      final Map<String, Tuple2<String, int>> playersResults = {};

      // Retrieve the current level data.
      DocumentSnapshot levelSnapshot = await _levelDoc.get();
      if (levelSnapshot.exists == false) {
        debugPrint("Level document does not exist!");
        ErrorService.instance.report(error: ErrorType.notFound);
        return {};
      }
      final Map<String, dynamic> levelData =
          levelSnapshot.data() as Map<String, dynamic>? ?? {};

      // Get the answers map and filter only positive answers.
      debugPrint("Answers raw: ${levelData['answers']}");
      final Map<String, double> intAnswersMap = Map<String, dynamic>.from(
        levelData['answers'] ?? {},
      ).map((key, value) => MapEntry(key, value as double));

      final filtered =
          intAnswersMap.entries.where((entry) => entry.value > 0).toList()
            ..sort(
              (a, b) => b.value.compareTo(a.value),
            ); // Sort from high to low

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
            await _levelDoc.update({
              'player_before_drink.$playerId': playerName,
            });
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
    } catch (e) {
      debugPrint("problem processing after q model server level 01: $e");
      ErrorService.instance.report(error: ErrorType.firestore);
      return {};
    }
  }

  /// Resets the round by incrementing currentQuestionIndex and clearing the answers.
  /// Only the designated reset manager (host) is allowed to perform this action.
  @override
  Future<void> resetRound() async {
    // Use a transaction to atomically update the level document.
    if (!_initialized) {
      debugPrint("Lv01Knowledge not initialized.");
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot levelSnapshot = await transaction.get(_levelDoc);
      if (!levelSnapshot.exists) {
        debugPrint("Level document does not exist!");
        ErrorService.instance.report(error: ErrorType.notFound);
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
}
