// nexaburst/lib/models/server/levels/level4/Lv04.dart

import 'dart:async';
import 'package:tuple/tuple.dart';

/// Interface for Level 4 game logic.
/// Defines methods for random targeting, rounds, and scoring.
abstract class Lv04 {
  /// Prepares the model with [roomId] and [isDrinkingMode].
  Future<void> initialization({
    required String roomId,
    required bool isDrinkingMode,
  });

  /// Returns the localized instruction for Level 4.
  String getInstruction();

  /// Signals all players to synchronize at the start of a loop/round.
  Future<void> allPlayersStartLoop();

  /// Selects a new target player at random (excluding last) and updates Firestore.
  Future<void> chooseRandomPlayer();

  /// Retrieves next scenario and target info, advancing any index as needed.
  /// Returns map with scenario payload or `{"done": true}`.
  Future<Map<String, dynamic>> fetchNextRoundDataAndUpdate();

  /// Records either the target’s answer or a guess from other players.
  ///
  /// [result] — the submitted answer string.
  Future<void> updatePlayerAnswer(String result);

  /// Waits until the target and all guessers have submitted their responses.
  Future<void> loading();

  /// Returns whether the local player is the current target.
  Future<bool> isTargetPlayer();

  /// Evaluates guesses against the target’s answer, updates scores and drinks,
  /// and returns a map of playerId→(username,points).
  Future<Map<String, Tuple2<String, int>>> processQuestionResults();
}
