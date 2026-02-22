// nexaburst/lib/models/server/presence/pesence_manager_interface.dart

import 'dart:async';

/// Contract for managing player presence in a multiplayer room.
/// Supports initialization, listening for disconnects, manual cleanup,
/// and disposal of resources.
abstract class IPresenceManager {
  /// Performs any asynchronous setup required before presence tracking.
  Future<void> initialize();

  /// Begins presence monitoring and registers disconnect handlers.
  void start();

  /// Manually triggers disconnect cleanup logic as if the player lost connection.
  Future<void> disconnect();

  /// Releases any listeners and resources used for presence tracking.
  Future<void> dispose();
}
