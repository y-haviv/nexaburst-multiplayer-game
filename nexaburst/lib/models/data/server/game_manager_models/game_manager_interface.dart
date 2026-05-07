// nexaburst/lib/models/server/game_manager_models/game_manager_interface.dart

import 'dart:async';
import 'package:nexaburst/models/structures/room_model.dart';

/// Contract for room-level game lifecycle operations.
///
/// Implementations coordinate room initialization, player snapshots,
/// status streaming, and end-of-game cleanup.
abstract class GameManagerInterface {
  /// Loads initial room data for the provided [roomId].
  ///
  /// Returns the room when found, or `null` when initialization fails.
  Future<Room?> initialize({required String roomId});

  /// Starts background listeners for room status and related updates.
  void startListener();

  /// Stops listeners and releases resources owned by this manager.
  Future<void> clean();

  /// Returns the current players map snapshot for the active room.
  Future<Map<String, dynamic>?> getPlayers();

  /// Persists the final room [status] when a game session ends.
  Future<void> endGame(RoomStatus status);

  /// Deletes the room if the current player is still the host.
  Future<void> deleteRoomIfHost();

  /// Emits room status transitions in real time.
  Stream<RoomStatus> get statusStream;
}
