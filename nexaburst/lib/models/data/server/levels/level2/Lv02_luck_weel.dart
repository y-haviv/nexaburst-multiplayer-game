// nexaburst/lib/models/server/levels/level2/Lv02_luck_weel.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/server/levels/level2/Lv02.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:nexaburst/models/structures/levels/level2/Lv02_Game.dart';
import 'package:nexaburst/models/structures/levels/level2/lv02_loader.dart';
import 'package:tuple/tuple.dart';

/// Implements the “luck wheel” phase of Level 2.
/// Manages fetching options, applying results, and synchronizing with Firestore.
class Lv02LuckWeel extends Lv02Weel {
  /// The current user’s unique player ID.
  final String playerId = UserData.instance.user!.id;

  /// The Firestore document ID for the current game room.
  late String roomId;

  /// Controls whether “drinking” rules are applied for this session.
  bool isDrinkingMode = false;

  /// Tracks whether this model has been initialized to prevent re-entry.
  bool _initialized = false;

  /// Firestore document key for this level, from the translation service.
  static String levelName = TranslationService.instance.levelKeys[1];

  /// Singleton Firestore instance for all reads and writes.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reference to the current room document in Firestore.
  DocumentReference get _roomDoc => _firestore.collection('rooms').doc(roomId);

  /// Reference to this level’s document within the room.
  DocumentReference get _levelDoc =>
      _roomDoc.collection('levels').doc(levelName);

  /// Loads level assets (once) and sets up room ID and mode.
  ///
  /// [roomId] — the Firestore room document ID.<br>
  /// [isDrinkingMode] — whether drinking penalties apply.
  @override
  Future<void> initialization({
    required String roomId,
    required bool isDrinkingMode,
  }) async {
    if (_initialized) return;
    _initialized = true;
    this.roomId = roomId;
    this.isDrinkingMode = isDrinkingMode;
    await Lv02Loader.load();
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

  /// Retrieves option IDs from Firestore, resolves them via the model,
  /// and returns a list of (ID, description, isSpecial) tuples.
  ///
  /// Returns an empty list if uninitialized or on error.
  @override
  Future<List<Tuple3<int, String, bool>>> fetchWeelData() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return [];
    }
    try {
      DocumentSnapshot levelSnapshot = await _levelDoc.get();
      Map<String, dynamic> levelData =
          levelSnapshot.data() as Map<String, dynamic>? ?? {};

      List<dynamic>? rawOptions = levelData['options'] as List<dynamic>?;
      List<int> options = rawOptions?.map((e) => e as int).toList() ?? [];

      if (options.isEmpty) {
        debugPrint("Error expected list of ID is empty");
      }

      final data = await Lv02Model.getOptionsMapByIds(options);
      return data;
    } catch (e) {
      debugPrint("error geting data for luck - weel : level 2");
      ErrorService.instance.report(error: ErrorType.localDatabase);
      return [];
    }
  }

  /// Applies the chosen option’s effect for [result]:
  /// (optionId, targetPlayerId).
  /// Updates scores, drinking lists, or turn modifiers in Firestore.
  ///
  /// Returns a tuple (skipNextTurn, doubleNextTurn).
  @override
  Future<Tuple2<bool, bool>> updateForPlayer(Tuple2<int, String> result) async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return Tuple2(false, false);
    }
    final int optionId = result.item1;
    final String thePlayerId = result.item2;
    bool skipNextTurn = false;
    bool doubleNextTurn = false;
    // Get player's username from their document.
    DocumentSnapshot roomPlayerSnapshot = await _roomDoc
        .collection('players')
        .doc(playerId)
        .get();
    String PlayerName1 =
        (roomPlayerSnapshot.data() as Map<String, dynamic>?)?["username"] ??
        "Unknown";
    int currentScore1 =
        ((roomPlayerSnapshot.data() as Map<String, dynamic>?)?["total_score"] ??
                0)
            as int;
    String PlayerName2 = "";
    switch (optionId) {
      // +2 Points to this player - playerId
      case 1:
        // Update the player total score.
        int newScore = currentScore1 + 2;
        await _roomDoc.collection('players').doc(playerId).update({
          "total_score": newScore,
        });
        break;
      // -1 Point to other player - thePlayerId
      case 2:
        try {
          // Update the other player total score.
          DocumentSnapshot roomPlayerSnapshot2 = await _roomDoc
              .collection('players')
              .doc(thePlayerId)
              .get();
          int currentScore2 =
              ((roomPlayerSnapshot2.data()
                          as Map<String, dynamic>?)?["total_score"] ??
                      0)
                  as int;
          PlayerName2 =
              (roomPlayerSnapshot2.data()
                  as Map<String, dynamic>?)?["username"] ??
              "Unknown";
          int newScore = currentScore2 - 1;
          await _roomDoc.collection('players').doc(thePlayerId).update({
            "total_score": newScore,
          });
        } catch (e) {
          debugPrint("problem weel level 2 - update result - case 2 : $e");
        }
        break;
      // case 3 Skip Next Turn this player - playerId
      case 3:
        skipNextTurn = true;
        break;
      // case 4 is more spining so handle by UI
      // case 5 this player - playerId -> Swap Points with -> other player - thePlayerId
      case 5:
        // Update the players total score.
        DocumentSnapshot roomPlayerSnapshot2 = await _roomDoc
            .collection('players')
            .doc(thePlayerId)
            .get();
        int currentScore2 =
            ((roomPlayerSnapshot2.data()
                        as Map<String, dynamic>?)?["total_score"] ??
                    0)
                as int;
        PlayerName2 =
            (roomPlayerSnapshot.data() as Map<String, dynamic>?)?["username"] ??
            "Unknown";
        await _roomDoc.collection('players').doc(playerId).update({
          "total_score": currentScore2,
        });
        await _roomDoc.collection('players').doc(thePlayerId).update({
          "total_score": currentScore1,
        });

        break;
      // case 6 this player get double point on next round
      case 6:
        await _levelDoc.update({
          "doublePoints": FieldValue.arrayUnion([playerId]),
        });
        doubleNextTurn = true;
        break;
      // case 7 this player - playerId -> Steal 1 Point from -> other player - thePlayerId
      case 7:
        // Update the players total score.
        DocumentSnapshot roomPlayerSnapshot2 = await _roomDoc
            .collection('players')
            .doc(thePlayerId)
            .get();
        int currentScore2 =
            ((roomPlayerSnapshot2.data()
                        as Map<String, dynamic>?)?["total_score"] ??
                    0)
                as int;
        PlayerName2 =
            (roomPlayerSnapshot2.data()
                as Map<String, dynamic>?)?["username"] ??
            "Unknown";
        await _roomDoc.collection('players').doc(playerId).update({
          "total_score": currentScore1 + 1,
        });
        await _roomDoc.collection('players').doc(thePlayerId).update({
          "total_score": currentScore2 - 1,
        });

        break;
      // case 8 this player - playerId -> Give 1 Point to -> other player - thePlayerId
      case 8:
        // Update the players total score.
        DocumentSnapshot roomPlayerSnapshot2 = await _roomDoc
            .collection('players')
            .doc(thePlayerId)
            .get();
        int currentScore2 =
            ((roomPlayerSnapshot2.data()
                        as Map<String, dynamic>?)?["total_score"] ??
                    0)
                as int;
        PlayerName2 =
            (roomPlayerSnapshot.data() as Map<String, dynamic>?)?["username"] ??
            "Unknown";
        await _roomDoc.collection('players').doc(playerId).update({
          "total_score": currentScore1 - 1,
        });
        await _roomDoc.collection('players').doc(thePlayerId).update({
          "total_score": currentScore2 + 1,
        });
        break;
      // case 9 this player - playerId need to drink
      case 9:
        // Add the player to players_to_drink in the room document.
        await _roomDoc.update({'players_to_drink.$playerId': PlayerName1});
        break;
      // case 10 add other player - thePlayerId to drink
      case 10:
        // Get player's username from their document.
        DocumentSnapshot roomPlayerSnapshot2 = await _roomDoc
            .collection('players')
            .doc(thePlayerId)
            .get();
        PlayerName2 =
            (roomPlayerSnapshot2.data()
                as Map<String, dynamic>?)?["username"] ??
            "Unknown";
        // Add the player to players_to_drink in the room document.
        await _roomDoc.update({'players_to_drink.$thePlayerId': PlayerName2});
        break;
      // in case of problem or if player did not span the luck weel
      default:
        debugPrint("problem or if player did not span the luck weel");
        ErrorService.instance.report(error: ErrorType.unknown);
        break;
    }

    String resultServer = await Lv02Model.getResultStringById(
      optionId,
      PlayerName1,
      PlayerName2,
    );

    // Update the "weel_result" field in the level document.
    await _levelDoc.update({
      'weel_result': FieldValue.arrayUnion([resultServer]),
    });

    return Tuple2(skipNextTurn, doubleNextTurn);
  }

  /// Stream that emits the current count of wheel results submitted
  /// for this level.
  Stream<int> get _resultCountStream {
    return _levelDoc.snapshots().map((snapshot) {
      Map<String, dynamic> data =
          snapshot.data() as Map<String, dynamic>? ?? {};
      List<dynamic> answers = data['weel_result'] ?? [];
      return answers.length;
    });
  }

  /// Waits until all players have submitted their wheel result
  /// before proceeding.
  @override
  Future<void> loading() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    try {
      int totalPlayers = await _roomDoc
          .collection('players')
          .get()
          .then((snapshot) => snapshot.docs.length);
      await for (int answeredCount in _resultCountStream) {
        debugPrint(
          "Stream update: result $answeredCount / Total $totalPlayers",
        );
        if (answeredCount >= totalPlayers) break;
      }
    } catch (e) {
      debugPrint("Error model 02: $e");
      ErrorService.instance.report(error: ErrorType.firestore);
      return;
    }
  }

  /// Fetches and returns the list of localized result messages.
  ///
  /// Returns an empty list if uninitialized or on error.
  @override
  Future<List<String>> processResults() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return [];
    }
    DocumentSnapshot levelSnapshot = await _levelDoc.get();
    Map<String, dynamic> levelData =
        levelSnapshot.data() as Map<String, dynamic>? ?? {};

    // Get the result map.
    List<dynamic>? rawResult = levelData['weel_result'] as List<dynamic>?;
    List<String> resultList = rawResult?.map((e) => e as String).toList() ?? [];

    if (resultList.isEmpty) {
      debugPrint("Error while getting luck weel result from server...");
    }

    return resultList;
  }

  /// Clears the accumulated wheel results via a Firestore transaction,
  /// preparing for the next round.
  @override
  Future<void> resetRound() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot levelSnapshot = await transaction.get(_levelDoc);
      if (!levelSnapshot.exists) {
        throw Exception("Level document does not exist!");
      }
      transaction.update(_levelDoc, {'weel_result': []});
    });
    debugPrint("Reset complete: luck weel result reset.");
  }

  /// Marks this model as uninitialized, allowing a fresh init later.
  @override
  Future<void> dispose() async {
    if (!_initialized) return;
    _initialized = false;
  }
}
