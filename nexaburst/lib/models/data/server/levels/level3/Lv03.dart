// nexaburst/lib/models/server/levels/level3/Lv03.dart

import 'dart:async';
import 'package:tuple/tuple.dart';

/// Interface for Level 3 game logic.
/// Defines lifecycle methods for initialization, data flow, and teardown.
abstract class Lv03 {
  /// Prepares the model with [roomId] and [isDrinkingMode] flags.
  /// Should perform any one‑time setup (e.g. data loading).
  Future<void> initialization({
    required String roomId,
    required bool isDrinkingMode,
  });

  /// Returns the localized instruction text for Level 3.
  String getInstruction();

  /// Retrieves the next question payload from the server and
  /// advances any internal index or flags as needed.
  /// Returns a map with question data or `{"done": true}` when complete.
  Future<Map<String, dynamic>> fetchNextRoundDataAndUpdate();

  /// Records the current player’s answer time or result value.
  ///
  /// [result] — positive for time taken, negative (e.g. –1) for incorrect/timeout.
  Future<void> updatePlayerAnswer(double result);

  /// Waits until all players have submitted their answers.
  Future<void> loading();

  /// Computes and returns each player’s score delta after a round.
  /// Map of playerId → (username, pointsAwarded).
  Future<Map<String, Tuple2<String, int>>> processQuestionResults();

  /// Resets any per‑round state (e.g. clears answers, increments index).
  Future<void> resetRound();

  /// Disposes and resets both sub‑models to allow a fresh session.
  void dispose();
}
