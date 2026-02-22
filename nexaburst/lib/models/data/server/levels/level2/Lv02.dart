// nexaburst/lib/models/server/levels/level2/Lv02.dart

import 'dart:async';
import 'package:tuple/tuple.dart';

/// Defines the interface for the Level 2 “wheel” sub‑model.
/// Handles initialization, data fetch, updates, syncing, and teardown.
abstract class Lv02Weel {
  /// [initialization]: Prepares the model with [roomId] and [isDrinkingMode].
  Future<void> initialization({
    required String roomId,
    required bool isDrinkingMode,
  });

  /// [getInstruction]: Returns the localized level instruction string.
  String getInstruction();

  /// [fetchWeelData]: Fetches wheel options as (id, label, isSpecial).
  Future<List<Tuple3<int, String, bool>>> fetchWeelData();

  /// [updateForPlayer]: Applies a wheel result for the given (id, player) and returns turn modifiers.
  Future<Tuple2<bool, bool>> updateForPlayer(Tuple2<int, String> result);

  /// [loading]: Waits for all players’ wheel submissions.
  Future<void> loading();

  /// [processResults]: Retrieves finalized result messages.
  Future<List<String>> processResults();

  /// [resetRound]: Clears results for the next round.
  Future<void> resetRound();

  /// [dispose]: Releases initialization lock.
  Future<void> dispose();
}

/// Defines the interface for the Level 2 “luck” sub‑model.
/// Handles board data, answer collection, scoring, syncing, and teardown.
abstract class Lv02Luck {
  /// [initialization]: Prepares the model with [roomId] and [isDrinkingMode].
  void initialization({required String roomId, required bool isDrinkingMode});

  /// [getInstruction]: Returns the localized level instruction string.
  String getInstruction();

  /// [fetchNextRoundDataAndUpdate]: Retrieves next positions without advancing index.
  Future<Map<String, dynamic>> fetchNextRoundDataAndUpdate();

  /// [updatePlayerAnswer]: Records the player’s answer.
  Future<void> updatePlayerAnswer(int result);

  /// [loading]: Waits for all players’ answers.
  Future<void> loading();

  /// [processResults]: Calculates and returns score deltas for answers.
  Future<Map<String, Tuple2<String, int>>> processResults(
    int black,
    int gold, {
    bool skip = false,
  });

  /// [resetRound]: Advances index and clears answers.
  Future<void> resetRound();

  /// [dispose]: Releases initialization lock.
  Future<void> dispose();
}
