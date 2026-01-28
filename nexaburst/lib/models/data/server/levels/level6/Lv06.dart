// nexaburst/lib/models/server/levels/level6/Lv06.dart

import 'dart:async';

/// Abstract base class representing a level 6 game logic structure.
/// Defines the required interface for level initialization, player updates,
/// result processing, and lifecycle management.
abstract class Lv06 {
  /// Initializes the level with the given room ID and game mode.
  ///
  /// Parameters:
  /// - `roomId`: The unique identifier of the current game room.
  /// - `isDrinkingMode`: Indicates whether the drinking game mode is active.
  void initialization({required String roomId, required bool isDrinkingMode});

  /// A stream that emits the current number of active players in the room.
  Stream<int> get playerCountStream;

  /// Returns the instruction text for the level, adjusted for game mode.
  ///
  /// Returns:
  /// A localized instruction string, potentially including drinking instructions.
  String getInstruction();

  /// Awards bonus points at the end of the level to players with the highest
  /// number of correct guesses.
  Future<void> EndLevelBonus();

  /// Updates the player's choice and optional guess for the current round.
  ///
  /// Parameters:
  /// - `result`: The player's choice (e.g., steal or not).
  /// - `guess`: The player's guess for the number of others who chose to steal.
  Future<void> updatePlayerAnswer(bool result, int guess);

  /// Waits for all players to submit their answers before proceeding.
  Future<void> loading();

  /// Processes all players' choices and guesses, calculates scores, and updates Firestore.
  ///
  /// Returns:
  /// A map containing:
  /// - `"add_to_score"`: Points added to the current player.
  /// - `"bonusGuessCorrect"`: Whether the player's guess was correct.
  /// - `"playersInfo"`: A map of player names to a tuple of their choice and guess.
  Future<Map<String, dynamic>> processResults();

  /// Resets the round state by clearing player answers and guesses, and
  /// conditionally resetting the accumulated points.
  Future<void> resetRound();
}
