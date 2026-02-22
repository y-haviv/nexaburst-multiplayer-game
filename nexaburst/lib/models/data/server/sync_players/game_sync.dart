// nexaburst/lib/models/server/sync_players/game_sync.dart

import 'dart:async';

/// Defines the interface for synchronizing player readiness and
/// round progression within a game room.
abstract class GameSync {
  /// Initializes internal state for synchronization operations.
  ///
  /// [roomId]: Identifier of the Firestore room to sync against.
  void init({required String roomId});

  /// Resets all internal synchronization state, making the instance
  /// ready for a fresh `init`.
  void clear();

  /// Ensures only one sync operation runs at a time and performs
  /// the full player‑synchronization protocol.
  ///
  /// [resetLogic]: Optional callback invoked by the host before
  /// advancing to the next round.
  ///
  /// Returns `true` if synchronization completed successfully,
  /// `false` on timeout or error.
  Future<bool> synchronizePlayers([Future<void> Function()? resetLogic]);

  void playerSaidForbiddenWord(String word);
}
