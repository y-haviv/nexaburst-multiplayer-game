// nexaburst/lib/models/server/levels/level5/Lv05.dart

import 'dart:async';
import 'package:nexaburst/models/structures/levels/level5/Lv05_model.dart';
import 'package:tuple/tuple.dart';

/// Represents the state of a hole in Whack‑a‑Mole:
/// - `empty`: no mole present
/// - `occupied`: mole is present
enum HoleStates { empty, occupied }

/// Interface for Level 5 “Whack‑a‑Mole” logic.
/// Defines streams and operations for game flow and scoring.
abstract class Lv05 {
  /// Emits the current live‑update text (e.g. hit/miss messages).
  Stream<String> get liveStreamingText;

  /// Emits the list of player IDs/names in mole order and the current index.
  Stream<Tuple2<List<String>, int>> get moleOrder;

  /// Emits the current state of all holes (occupied, hit, etc.).
  Stream<List<HoleModel>> get holes;

  /// Emits whether the local player is currently the mole.
  Stream<bool> get playerMole;

  /// Prepares the model with [roomId] and [isDrinkingMode].
  /// Must be called before any other operations.
  void initialization({required String roomId, required bool isDrinkingMode});

  /// Returns the localized instructions for Level 5,
  /// including drinking rules if [isDrinkingMode] is true.
  String getInstruction();

  /// Emits state updates for the hole with [holeId].
  Stream<HoleModel> holeStream(int holeId);

  /// Tears down all listeners and closes streams.
  void dispose();

  /// Sets up initial mole order, hole states, and scores in Firestore.
  Future<void> initializeGame();

  /// Advances mole turn, resets holes, and ends level when complete.
  Future<void> resetRound();

  /// Adjusts the local player’s Whack‑a‑Mole score by [delta].
  Future<void> updatePlayerScore(int delta);

  /// Retrieves the local player’s current in‑level score.
  Future<int> getPlayerScore();

  /// Toggles occupancy of hole [holeId] for the current mole,
  /// awarding points when toggling off.
  Future<void> updateHoleState(int holeId);

  /// Attempts to whack a mole in hole [holeId],
  /// awarding hit points on success.
  Future<void> tryHitHole(int holeId);

  /// Returns true if the level has finished and no further rounds occur.
  bool checkEndLevel();
}
