// nexaburst/lib/models/server/modes/drinking/drink_game.dart

import 'dart:async';
import 'package:rxdart/rxdart.dart';

/// Interface for the “drinking” game mode:
/// provides a stream of player‑to‑drink mappings and lifecycle methods.
abstract class DrinkingGame {
  /// Emits the current mapping of player IDs to drink states.
  BehaviorSubject<Map<String, String>> get stream;

  /// Starts any asynchronous setup required for syncing state.
  ///
  /// [roomId]: identifier of the room to sync.
  void initialization({required String roomId});

  /// Completes when the first valid state is available.
  Future<void> waitUntilInitialized();

  /// Releases resources and stops any ongoing listeners.
  void dispose();

  /// Removes the local player from the drink‑state mapping.
  Future<void> removeFromPlayersToDrink();
}
