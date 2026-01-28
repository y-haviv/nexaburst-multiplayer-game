// nexaburst/lib/models/server/levels/level2/Lv02_luck.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/server/levels/level2/Lv02.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:tuple/tuple.dart';

/// Implements the “luck” phase of Level 2.
/// Handles drawing positions, collecting answers, scoring, and resets.
class Lv02LuckModel extends Lv02Luck {
  /// The current user’s unique player ID.
  final String playerId = UserData.instance.user!.id;

  /// The Firestore document ID for the current game room.
  late String roomId;

  /// Whether to enforce drinking penalties for incorrect answers.
  bool isDrinkingMode = false;

  /// Prevents re-initialization after first setup.
  bool _initialized = false;

  /// Firestore document key for this level from the translation service.
  static String levelName = TranslationService.instance.levelKeys[1];

  /// Singleton Firestore instance for all reads and writes.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reference to the current room document in Firestore.
  DocumentReference get _roomDoc => _firestore.collection('rooms').doc(roomId);

  /// Reference to this level’s document within the room.
  DocumentReference get _levelDoc =>
      _roomDoc.collection('levels').doc(levelName);

  /// Sets room ID and mode flags; no I/O performed.
  ///
  /// [roomId] — the Firestore room document ID.<br>
  /// [isDrinkingMode] — whether drinking rules apply.
  @override
  void initialization({required String roomId, required bool isDrinkingMode}) {
    if (_initialized) return; // Prevent re-initialization.
    _initialized = true;
    this.roomId = roomId;
    this.isDrinkingMode = isDrinkingMode;
  }

  /// Returns the localized instruction string for this level,
  /// appending drinking instructions when applicable.
  @override
  String getInstruction() {
    return isDrinkingMode && _initialized
        ? TranslationService.instance.t('game.levels.$levelName.instructions') +
              TranslationService.instance.t(
                'game.levels.$levelName.drinking_instructions',
              )
        : TranslationService.instance.t('game.levels.$levelName.instructions');
  }

  /// Retrieves the next board positions (“gold” and “black”) from Firestore
  /// without advancing the index.
  ///
  /// Returns `{ "done": true }` if no more positions remain.
  @override
  Future<Map<String, dynamic>> fetchNextRoundDataAndUpdate() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return {"done": true};
    }
    try {
      DocumentSnapshot levelSnapshot = await _levelDoc.get();
      Map<String, dynamic> levelData =
          levelSnapshot.data() as Map<String, dynamic>? ?? {};

      int currentIndex = levelData['currentIndex'] ?? 0;

      // Since Firestore stores positions as a map of string -> object:
      final rawPositions =
          levelData['positions'] as Map<String, dynamic>? ?? {};
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
    } catch (e) {
      debugPrint("Error model level 02: $e");
      ErrorService.instance.report(error: ErrorType.firestore);
      return {"done": true};
    }
  }

  /// Records the current player’s answer for this round in Firestore.
  ///
  /// [result] — the chosen position ID.
  @override
  Future<void> updatePlayerAnswer(int result) async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    // Update the "answers" field in the level document.
    await _levelDoc.update({'answers.$playerId': result});
  }

  /// Stream that emits how many players have submitted answers.
  Stream<int> get _answeredCountStream {
    return _levelDoc.snapshots().map((snapshot) {
      Map<String, dynamic> data =
          snapshot.data() as Map<String, dynamic>? ?? {};
      Map answers = data['answers'] ?? {};
      return answers.length;
    });
  }

  /// Waits until all players have answered before proceeding.
  @override
  Future<void> loading() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    int totalPlayers = await _roomDoc
        .collection('players')
        .get()
        .then((snapshot) => snapshot.docs.length);
    await for (int answeredCount in _answeredCountStream) {
      debugPrint(
        "Stream update: Answered $answeredCount / Total $totalPlayers",
      );
      if (answeredCount >= totalPlayers) break;
    }
  }

  /// Compares collected answers to [black] and [gold], calculates
  /// score adjustments (incl. double points), updates Firestore,
  /// and returns a map of playerId → (username, pointsDelta).
  ///
  /// If `skip` is true, correct opponents may be skipped.
  @override
  Future<Map<String, Tuple2<String, int>>> processResults(
    int black,
    int gold, {
    bool skip = false,
  }) async {
    Map<String, Tuple2<String, int>> results = {};
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return results;
    }
    DocumentSnapshot levelSnapshot = await _levelDoc.get();
    Map<String, dynamic> levelData =
        levelSnapshot.data() as Map<String, dynamic>? ?? {};

    // Get the answers map.
    Map<String, dynamic> answersMap = Map<String, dynamic>.from(
      levelData['answers'] ?? {},
    );

    int goldScore = answersMap.values.where((value) => value != gold).length;

    final filtered = answersMap.entries
        .where((entry) => entry.value == gold || entry.value == black)
        .toList();
    //..sort((a, b) => b.value.compareTo(a.value)); // Sort from high to low

    final QuerySnapshot<Map<String, dynamic>> roomPlayerSnapshot =
        await _roomDoc.collection('players').get();

    for (final entry in filtered) {
      final playerIdEntry = entry.key;

      final matchingDocs = roomPlayerSnapshot.docs
          .where((doc) => doc.id == playerIdEntry)
          .toList();
      if (matchingDocs.isEmpty) continue;

      final playerDoc = matchingDocs.first;

      final String playerName = playerDoc.data()['username'] ?? 'Unknown';
      final int currentScore = playerDoc.data()['total_score'] ?? 0;
      final bool doublePoints =
          levelData['doublePoints'] != null &&
          levelData['doublePoints'].contains(playerIdEntry);
      int pointsToAdd = entry.value == gold
          ? goldScore
          : (entry.value == black
                ? -1
                : 0); // If the answer is black, subtract 1 point.
      if (doublePoints) {
        pointsToAdd *= 2;
      }

      results[playerIdEntry] = Tuple2(playerName, pointsToAdd);

      if (playerIdEntry == playerId) {
        if (isDrinkingMode && pointsToAdd < 0) {
          // If the player answered black, they need to drink.
          final String playerName = playerDoc.data()['username'] ?? 'Unknown';
          await _roomDoc.update({'players_to_drink.$playerId': playerName});
        }
        final int newScore = currentScore + pointsToAdd;
        await _roomDoc.collection('players').doc(playerId).update({
          'total_score': newScore,
        });
      }
    }

    return results;
  }

  /// Advances the question index, clears answers and point multipliers
  /// in a Firestore transaction.
  @override
  Future<void> resetRound() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot levelSnapshot = await transaction.get(_levelDoc);
      if (!levelSnapshot.exists) {
        ErrorService.instance.report(error: ErrorType.notFound);
        debugPrint("Level document does not exist!");
        return;
      }
      int currentIndex = levelSnapshot.get('currentIndex') as int? ?? 0;
      transaction.update(_levelDoc, {
        'currentIndex': currentIndex + 1,
        'answers': {},
        'doublePoints': [],
      });
    });
    debugPrint("Reset complete: question index incremented and answers reset.");
  }

  /// Marks this model as uninitialized, allowing a fresh init later.
  @override
  Future<void> dispose() async {
    if (!_initialized) return;
    _initialized = false;
  }
}
