// nexaburst/lib/models/server/levels/level6/Lv06_trust.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/server/levels/level6/Lv06.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:tuple/tuple.dart';

/// Concrete implementation of `Lv06` for the "Trust" game phase.
/// Manages game logic, player input, and scoring for level 6 using Firestore.
class Lv06Trust extends Lv06 {
  /// The unique identifier of the current player.
  final String playerId = UserData.instance.user!.id;

  /// The ID of the current game room.
  late String roomId;

  /// Indicates whether drinking mode is enabled for this level.
  late bool isDrinkingMode;

  /// Tracks whether the level has been initialized to prevent reinitialization.
  bool _initialized = false;

  /// Bonus points awarded to players with most correct guesses at end of level.
  final int EndLevelBonusPoints = 2;

  /// Points awarded for correctly guessing the number of thieves during a round.
  final int midLevelBonusPoints = 1;

  /// The document name of this level, derived from the translation keys.
  static String levelName = TranslationService.instance.levelKeys[5];

  /// Firestore instance used for database operations.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reference to the current room document in Firestore.
  DocumentReference get _roomDoc => _firestore.collection('rooms').doc(roomId);

  /// Reference to the current level document inside the room.
  DocumentReference get _levelDoc =>
      _roomDoc.collection('levels').doc(levelName);

  /// A stream that returns the current number of players in the room
  /// by monitoring the `players` map in the `game_sync` document.
  @override
  Stream<int> get playerCountStream {
    return _roomDoc
        .collection('sync')
        .doc('game_sync')
        .snapshots()
        .map(
          (snap) =>
              ((snap.data()?['players'] as Map<String, bool>?)?.length) ?? 0,
        );
  }

  /// Initializes the level with room ID and mode. Safe-guards against reinitialization.
  @override
  void initialization({required String roomId, required bool isDrinkingMode}) {
    if (_initialized) return; // Prevent re-initialization
    this.roomId = roomId;
    this.isDrinkingMode = isDrinkingMode;
    _initialized = true;
  }

  /// Returns the appropriate game instruction, appending drinking mode text if needed.
  @override
  String getInstruction() {
    return isDrinkingMode && _initialized
        ? TranslationService.instance.t('game.levels.$levelName.instructions') +
              TranslationService.instance.t(
                'game.levels.$levelName.drinking_instructions',
              )
        : TranslationService.instance.t('game.levels.$levelName.instructions');
  }

  /// Grants bonus points to all players with the highest number of correct guesses.
  /// Uses a Firestore transaction to ensure consistency.
  @override
  Future<void> EndLevelBonus() async {
    if (!_initialized) {
      debugPrint("EndLevelBonus called before initialization.");
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    // Retrieve the level document.
    DocumentSnapshot levelSnapshot = await _levelDoc.get();
    if (!levelSnapshot.exists) {
      debugPrint("Level document does not exist!");
      ErrorService.instance.report(error: ErrorType.notFound);
      return;
    }
    // Get the correctGuessCount map; default to empty if missing.
    Map<String, dynamic> guessCountMap = Map<String, dynamic>.from(
      levelSnapshot.get('correctGuessCount') ?? {},
    );

    // If there are no guesses, nothing to do.
    if (guessCountMap.isEmpty) return;

    // Determine the maximum number of correct guesses.
    int maxCount = guessCountMap.values
        .map((v) => v as int)
        .reduce((a, b) => a > b ? a : b);

    // Identify all players with the maximum count (even if there's a tie).
    List<String> bonusWinners = guessCountMap.keys
        .where((pid) => (guessCountMap[pid] as int) == maxCount)
        .toList();

    // Use a transaction to update each winning player's total score.
    await _firestore.runTransaction((transaction) async {
      for (String winnerId in bonusWinners) {
        DocumentReference playerDoc = _roomDoc
            .collection('players')
            .doc(winnerId);
        DocumentSnapshot playerSnapshot = await transaction.get(playerDoc);
        int currentScore =
            ((playerSnapshot.data() as Map<String, dynamic>)['total_score'] ??
                    0)
                as int;
        transaction.update(playerDoc, {
          'total_score': currentScore + EndLevelBonusPoints,
        });
      }
    });
    debugPrint("End level bonus awarded to winners: $bonusWinners");
  }

  /// Records the player's action (steal/keep) and optional guess in Firestore.
  @override
  Future<void> updatePlayerAnswer(bool result, int guess) async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    await _levelDoc.update({'playerChoices.$playerId': result});
    if (guess != -1) {
      await _levelDoc.update({'playerGuesses.$playerId': guess});
    }
  }

  /// A private stream that emits the number of players who submitted answers
  /// by counting keys in the `playerChoices` map.
  Stream<int> get _answeredCountStream {
    return _levelDoc.snapshots().map((snapshot) {
      Map<String, dynamic> data =
          snapshot.data() as Map<String, dynamic>? ?? {};
      Map answers = data['playerChoices'] ?? {};
      return answers.length;
    });
  }

  /// Awaits until all players have submitted answers before progressing.
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

  /// Evaluates game round results, assigns scores, updates player states,
  /// and returns structured data about the round outcome.
  ///
  /// Returns:
  /// A map with keys:
  /// - `"add_to_score"`: Player's earned score.
  /// - `"bonusGuessCorrect"`: If the bonus guess was accurate.
  /// - `"playersInfo"`: Tuple map of player actions and guesses.
  @override
  Future<Map<String, dynamic>> processResults() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return {};
    }
    // Retrieve the level data.
    DocumentSnapshot levelSnapshot = await _levelDoc.get();
    Map<String, dynamic> levelData =
        levelSnapshot.data() as Map<String, dynamic>? ?? {};

    // Extract player choices and guesses and accumulatedPoints.
    Map<String, dynamic> playerChoices = Map<String, dynamic>.from(
      levelData['playerChoices'] ?? {},
    );
    Map<String, dynamic> playerGuesses = Map<String, dynamic>.from(
      levelData['playerGuesses'] ?? {},
    );
    int accumulatedPoints = levelData['accumulatedPoints'] ?? 0;

    int totalPlayers = playerChoices.length;
    int numThieves = playerChoices.values
        .where((v) => v == true)
        .length; // "steal" = true
    int numNonThieves = totalPlayers - numThieves;

    int additionalScore = 0;
    bool bonusGuessCorrect = false;

    // Get current player's own choice and guess.
    bool myChoice = playerChoices[playerId] ?? false;
    int myGuess = playerGuesses[playerId] ?? -1;

    bool needToDrink = false;

    // Determine base score according to the logic:
    if (numNonThieves == 0) {
      needToDrink = isDrinkingMode;
    } else if (numThieves == 0) {
      // Everyone left: each player receives a share = accumulatedPoints divided by totalPlayers.
      additionalScore = (accumulatedPoints ~/ totalPlayers);
    } else {
      // Some stole and some did not.
      if (myChoice == true) {
        // If I stole, I get share = accumulatedPoints divided by number of thieves.
        additionalScore = (accumulatedPoints ~/ numThieves);
      }
      // If I left, no base score is added.
    }

    // Process bonus guess if the player provided one.
    if (myGuess != -1) {
      if (myGuess == numThieves) {
        bonusGuessCorrect = true;
        additionalScore += midLevelBonusPoints;
      } else {
        needToDrink = isDrinkingMode;
      }
    }

    Map<String, Tuple2<String, String>> playersInfo = {};

    final QuerySnapshot<Map<String, dynamic>> roomPlayerSnapshot =
        await _roomDoc.collection('players').get();

    for (final entry in playerChoices.entries) {
      final playerIdEntry = entry.key;

      final matchingDocs = roomPlayerSnapshot.docs
          .where((doc) => doc.id == playerIdEntry)
          .toList();
      if (matchingDocs.isEmpty) continue;

      final playerDoc = matchingDocs.first;

      final String playerName = playerDoc.data()['username'] ?? 'Unknown';
      final int currentScore = playerDoc.data()['total_score'] ?? 0;

      String guessStr = "Didn't guess";
      if (playerGuesses.containsKey(playerIdEntry) &&
          (playerGuesses[playerIdEntry] as int) != -1) {
        guessStr = (playerGuesses[playerIdEntry] as int).toString();
      }
      playersInfo[playerName] = Tuple2(playerChoices[playerIdEntry], guessStr);

      if (playerIdEntry == playerId) {
        final int newScore = currentScore + additionalScore;
        await _roomDoc.collection('players').doc(playerId).update({
          'total_score': newScore,
        });
        if (needToDrink) {
          await _roomDoc.update({'players_to_drink.$playerId': playerName});
        }
        if (bonusGuessCorrect) {
          await _levelDoc.update({
            'correctGuessCount.$playerId': FieldValue.increment(1),
          });
        }
      }
    }

    return {
      "add_to_score": additionalScore,
      "bonusGuessCorrect": bonusGuessCorrect,
      "playersInfo": playersInfo,
    };
  }

  /// Resets all relevant fields in the level document to prepare for the next round.
  /// Retains `accumulatedPoints` if all players chose to keep.
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
      int currentRound = levelSnapshot.get('currentRound') as int? ?? 0;
      // Retrieve the current player choices.
      Map<String, dynamic> choices = Map<String, dynamic>.from(
        levelSnapshot.get('playerChoices') ?? {},
      );
      // Check if every player chose to leave (false).
      bool allLeft = choices.values.every((v) => v == false);
      // If all left, leave accumulatedPoints unchanged; otherwise, reset to 0.
      int newAccumulatedPoints = allLeft
          ? (levelSnapshot.get('accumulatedPoints') ?? 0)
          : 0;

      transaction.update(_levelDoc, {
        'currentRound': currentRound + 1,
        'playerChoices': {},
        'playerGuesses': {},
        'accumulatedPoints': newAccumulatedPoints,
      });
    });
    debugPrint(
      "Reset complete: currentRound incremented, answers reset, and accumulatedPoints updated as needed.",
    );
  }
}
