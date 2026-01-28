// nexaburst/lib/models/server/levels/level4/Lv04_social.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/server/levels/level4/lv04.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:nexaburst/models/structures/levels/level4/Lv04_model.dart';
import 'package:nexaburst/models/structures/levels/level4/lv04_loader.dart';
import 'package:tuple/tuple.dart';

/// Level 4 “Social” implementation.
/// Manages random target selection, scenario prompts, guesses, and scoring.
class Lv04Social extends Lv04 {
  /// Unique ID of the current user.
  final String playerId = UserData.instance.user!.id;

  /// Firestore document ID for the current game room.
  late String roomId;

  /// Whether incorrect guesses incur drinking penalties.
  bool isDrinkingMode = false;

  /// Prevents re-initialization after first setup.
  bool _initialized = false;

  /// True when this client is the designated target player.
  bool curretTargetPlayer = false;

  /// Firestore document key for this level from the translation service.
  static String levelName = TranslationService.instance.levelKeys[3];

  /// Singleton Firestore instance for database operations.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reference to the room’s document in Firestore.
  DocumentReference get _roomDoc => _firestore.collection('rooms').doc(roomId);

  /// Reference to this level’s document under the room.
  DocumentReference get _levelDoc =>
      _roomDoc.collection('levels').doc(levelName);

  /// Performs one‑time setup: sets [roomId], [isDrinkingMode], resets
  /// target flag, marks initialized, and loads scenario data.
  @override
  Future<void> initialization({
    required String roomId,
    required bool isDrinkingMode,
  }) async {
    if (_initialized) return;
    this.roomId = roomId;
    this.isDrinkingMode = isDrinkingMode;
    curretTargetPlayer = false;
    _initialized = true;
    await Lv04Loader.load();
  }

  /// Loads scenario text and options for [model.currentScenarioIndex]
  /// from locally cached JSON, handling localization and errors.
  Future<Map<String, dynamic>> _getScenarioById(Lv04SocialModel model) async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return {
        'scenario': "problem getting scenario...",
        'options': {"a": "", "b": "", "c": "", "d": ""},
      };
    }
    try {
      // find the raw question entry from the loaded JSON
      final questionsList = await Lv04Loader.data;
      final entry = questionsList.firstWhere(
        (q) => q['ID'] == model.scenarios[model.currentScenarioIndex],
        orElse: () => {},
      );
      if (entry.isEmpty) return {};

      // pick the node for the current language, or fallback to English
      final lang = TranslationService.instance.currentLanguage;
      final localized =
          entry[lang] as Map<String, dynamic>? ??
          entry['en'] as Map<String, dynamic>;

      return {
        'scenario': localized['scenario'] as String,
        'options': localized['options'] as Map<String, dynamic>,
      };
    } catch (e) {
      debugPrint("problem getting local data -> function _getScenarioById");
      return {
        'scenario': "problem getting scenario...",
        'options': {"a": "", "b": "", "c": "", "d": ""},
      };
    }
  }

  /// Returns localized Level 4 prompt, appending drinking instructions if enabled.
  @override
  String getInstruction() {
    return isDrinkingMode && _initialized
        ? TranslationService.instance.t('game.levels.$levelName.instructions') +
              TranslationService.instance.t(
                'game.levels.$levelName.drinking_instructions',
              )
        : TranslationService.instance.t('game.levels.$levelName.instructions');
  }

  /// Marks this player as not yet synchronized for the next round.
  @override
  Future<void> allPlayersStartLoop() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    await _roomDoc.collection('players').doc(playerId).update({
      'Synchronized': false,
    });
  }

  /// Selects and records a new target player, resets guesses,
  /// and advances the scenario index in Firestore.
  @override
  Future<void> chooseRandomPlayer() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    DocumentReference roomDoc = _firestore.collection('rooms').doc(roomId);
    DocumentSnapshot roomSnapshot = await roomDoc.get();
    if (!roomSnapshot.exists) {
      debugPrint("Room document does not exist.");
      ErrorService.instance.report(error: ErrorType.notFound);
      return;
    }

    final playersRef = _roomDoc.collection('players');
    final playerDocs = (await playersRef.get()).docs;

    final levelSnapshot = await _levelDoc.get();
    final levelData = levelSnapshot.data() as Map<String, dynamic>? ?? {};

    final prevTarget = levelData['targetPlayer'] as String?;
    final eligiblePlayers = playerDocs
        .where((doc) => doc.id != prevTarget)
        .toList();

    if (eligiblePlayers.isEmpty) return;

    eligiblePlayers.shuffle();
    final selectedDoc = eligiblePlayers.first;

    final selectedId = selectedDoc.id;
    final selectedName = selectedDoc.get('username') as String? ?? "Unknown";

    curretTargetPlayer = (selectedId == playerId);

    await _levelDoc.update({
      'targetPlayer': selectedId,
      'targetPlayerName': selectedName,
      'target_answer': null,
      'players_guesses': {},
      'currentScenarioIndex': FieldValue.increment(1),
    });
  }

  /// Retrieves next scenario payload and target info from Firestore.
  /// Returns map with `"done"`, `"targetPlayer"`, `"scenario"`, `"options"`, and `"scenarioId"`.
  @override
  Future<Map<String, dynamic>> fetchNextRoundDataAndUpdate() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return {"done": true};
    }
    try {
      final levelData =
          (await _levelDoc.get()).data() as Map<String, dynamic>? ?? {};

      final rawQs = levelData['scenarios'] as List<dynamic>? ?? [];
      final scenarios = rawQs.map((e) => e as int).toList();
      final currentIndex = levelData['currentScenarioIndex'] ?? 0;

      if (currentIndex >= scenarios.length) return {"done": true};

      final scenarioId = scenarios[currentIndex];
      final model = Lv04SocialModel(
        currentScenarioIndex: currentIndex,
        scenarios: scenarios,
        rounds: 0,
      );
      final scenarioDetails = await _getScenarioById(model);

      final targetPlayerId = levelData['targetPlayer'] as String? ?? "";
      curretTargetPlayer = (targetPlayerId == playerId);

      return {
        "done": false,
        "targetPlayer": targetPlayerId,
        "targetPlayerName": levelData['targetPlayerName'] ?? "",
        "scenario": scenarioDetails["scenario"],
        "options": scenarioDetails["options"],
        "scenarioId": scenarioId,
      };
    } catch (e) {
      debugPrint("Error level 04 model: $e");
      ErrorService.instance.report(error: ErrorType.firestore);
      return {"done": true};
    }
  }

  /// Returns whether this client is the current round’s target.
  @override
  Future<bool> isTargetPlayer() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return false;
    }
    return curretTargetPlayer;
  }

  /// Submits [result] as either the target’s answer or a guess,
  /// then marks the player unsynchronized.
  @override
  Future<void> updatePlayerAnswer(String result) async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    final isTarget = await isTargetPlayer();
    if (isTarget) {
      await _levelDoc.update({'target_answer': result});
    } else {
      await _levelDoc.update({'players_guesses.$playerId': result});
    }

    await _roomDoc.collection('players').doc(playerId).update({
      'Synchronized': false,
    });
  }

  /// Stream emitting the count of guesses submitted by non‑targets.
  Stream<int> get _answeredCountStream {
    return _levelDoc.snapshots().map((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>? ?? {};
      final answers = data['players_guesses'] ?? {};
      return (answers as Map).length;
    });
  }

  /// Stream emitting whether the target player has answered.
  Stream<bool> get _targetAnsweredStream {
    return _levelDoc.snapshots().map((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>? ?? {};
      return data['target_answer'] != null;
    });
  }

  /// Waits until the target and all other players have submitted responses,
  /// with periodic polling and timeout reporting.
  @override
  Future<void> loading() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    final totalPlayers =
        (await _roomDoc.collection('players').get()).docs.length;

    bool allAnswered = false;
    await for (final _ in Stream.periodic(Duration(milliseconds: 300))) {
      final targetAnswered = await _targetAnsweredStream.first;
      final guesses = await _answeredCountStream.first;

      debugPrint(
        "Waiting: guesses=$guesses / total=${totalPlayers - 1}, targetAnswered=$targetAnswered",
      );

      if (guesses >= totalPlayers - 1 && targetAnswered) {
        allAnswered = true;
        break;
      }
    }

    if (!allAnswered) {
      debugPrint("Loading timeout or incomplete answers.");
      ErrorService.instance.report(error: ErrorType.timeout);
    }
  }

  /// Compares guesses to the target’s answer, awards points,
  /// applies drinking penalties, and returns playerId→(username,points).
  @override
  Future<Map<String, Tuple2<String, int>>> processQuestionResults() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return {};
    }
    final Map<String, Tuple2<String, int>> playersResults = {};

    final levelData =
        (await _levelDoc.get()).data() as Map<String, dynamic>? ?? {};
    final answersMap = Map<String, dynamic>.from(
      levelData['players_guesses'] ?? {},
    );
    final targetAnswer = levelData['target_answer'] ?? "";
    final isTarget = await isTargetPlayer();

    // Get the answers map and filter only positive answers.
    final Map<String, int> intAnswersMap = {};

    bool iGuessedCorrectly = isTarget;
    int addedPoints = 0;

    answersMap.forEach((key, value) {
      if (value == targetAnswer) {
        intAnswersMap[key] = 1; // Correct answer
        if (key == playerId) {
          iGuessedCorrectly = true;
          addedPoints = 1;
        }
      }
    });

    bool needToDrink = isDrinkingMode && !iGuessedCorrectly;

    if (answersMap.length == intAnswersMap.length) {
      intAnswersMap[levelData['targetPlayer'] as String? ?? "player"] = 1;
      intAnswersMap.forEach((key, value) {
        if (key != (levelData['targetPlayer'] as String? ?? "player")) {
          intAnswersMap[key] = 0; // Incorrect answer
        }
      });
      if (isTarget) {
        addedPoints = 1;
      } else {
        addedPoints = 0;
      }
    }

    final QuerySnapshot<Map<String, dynamic>> roomPlayerSnapshot =
        await _roomDoc.collection('players').get();

    for (final entry in intAnswersMap.entries) {
      final playerIdEntry = entry.key;

      final matchingDocs = roomPlayerSnapshot.docs
          .where((doc) => doc.id == playerIdEntry)
          .toList();
      if (matchingDocs.isEmpty) continue;

      final playerDoc = matchingDocs.first;

      final String playerName = playerDoc.data()['username'] ?? 'Unknown';
      final int currentScore = playerDoc.data()['total_score'] ?? 0;
      final int pointsToAdd = entry.value;

      playersResults[playerIdEntry] = Tuple2(playerName, pointsToAdd);

      if (playerIdEntry == playerId) {
        final int newScore = currentScore + addedPoints;
        await _roomDoc.collection('players').doc(playerId).update({
          'total_score': newScore,
        });
      }
    }

    if (needToDrink) {
      await _addToDrinkList();
    }

    return playersResults;
  }

  /// Adds the current player to the room’s `players_to_drink` list,
  /// optionally using [nameOverride].
  Future<void> _addToDrinkList([String? nameOverride]) async {
    final playerData =
        (await _roomDoc.collection('players').doc(playerId).get()).data() ?? {};
    final username = nameOverride ?? playerData['username'] ?? "Unknown";

    await _roomDoc.update({'players_to_drink.$playerId': username});
  }
}
