// nexaburst/lib/model_view/room/waiting_room/start_game_interface.dart

import 'package:nexaburst/models/structures/room_model.dart';
import 'package:tuple/tuple.dart';

/// Defines the contract for creating or joining a waiting‑room and starting a game.
/// Exposes methods to manage room lifecycle, observe state, and launch the game.
abstract class IStartGameService {
  /// Creates a new game room on the server.
  ///
  /// Parameters:
  /// - `levels`: map of level IDs to difficulty/order.
  /// - `forbiddenWords`: words to ban in gameplay.
  /// - `isDrinkingMode`: whether drinking penalties are active.
  /// - `lang`: selected language code.
  ///
  /// Returns `true` if creation succeeded.
  Future<bool> createRoom({
    required Map<String, int> levels,
    required List<String> forbiddenWords,
    required bool isDrinkingMode,
    required String lang,
  });

  /// Performs local setup with the assigned [roomId].
  void initialization({required String roomId});

  /// Returns the current room’s unique identifier.
  String getRoomId();

  /// Attempts to join the previously initialized room.
  ///
  /// Returns `true` on successful join.
  Future<bool> joinRoom();

  /// Stream emitting the current host’s player ID as it changes.
  Stream<String> watchRoomHost();

  /// Stream emitting the room’s status (waiting/playing/completed).
  Stream<RoomStatus> watchRoomStatus();

  /// Stream emitting the list of players’ usernames in the room.
  Stream<List<String>> watchPlayers();

  /// Performs checks before allowing microphone access.
  ///
  /// Returns a tuple of (forbiddenWordsList, languageCode).
  Future<Tuple2<List<String>, String>> preJoiningMicPremission();

  /// Signals the server to transition the room into the playing state.
  Future<void> start();

  /// Cleans up any resources or listeners held by the service.
  void dispose();
}
