// nexaburst/lib/models/server/levels/level1/Lv01.dart

import 'dart:async';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:tuple/tuple.dart';

/// An abstract base class representing a game level (Level 01).
/// Defines the required interface for managing initialization, data fetching,
/// user interaction, and scoring logic during a game round.
abstract class Lvo1 {
  /// The identifier key for this level, based on the first translation entry.
  /// Used to reference Firestore level documents and localization data.
  static String levelName = TranslationService.instance.levelKeys[0];

  /// Prepares the level by loading necessary resources and storing context.
  ///
  /// Parameters:
  /// - [roomId]: The Firestore room ID where the game is taking place.
  /// - [isDrinkingMode]: Whether the game is currently in drinking mode.
  Future<void> initialization({
    required String roomId,
    required bool isDrinkingMode,
  });

  /// Returns the localized instruction string for this level.
  /// If drinking mode is active, an additional instruction is appended.
  String getInstruction();

  /// Retrieves the next question data and updates internal round state.
  ///
  /// Returns a map containing:
  /// - `question`: The question text.
  /// - `answers`: Answer choices.
  /// - `correct_answer`: The expected correct answer.
  /// - `questionId`: The ID of the current question.
  /// If the level is complete, returns `{"done": true}`.
  Future<Map<String, dynamic>> fetchNextRoundDataAndUpdate();

  /// Records the player's answer result in Firestore.
  ///
  /// Parameters:
  /// - [result]: Positive value indicates correct (time taken); -1 indicates incorrect or timeout.
  Future<void> updatePlayerAnswer(double result);

  /// Waits until all players in the room have submitted their answers for the current round.
  Future<void> loading();

  /// Processes and scores all player answers for the current question.
  ///
  /// Returns a map of player IDs to a tuple of (username, points earned).
  /// In drinking mode, updates the list of players who need to drink.
  Future<Map<String, Tuple2<String, int>>> processQuestionResults();

  /// Advances to the next round by incrementing the question index and clearing previous answers.
  /// Only the designated host should call this.
  Future<void> resetRound();
}
