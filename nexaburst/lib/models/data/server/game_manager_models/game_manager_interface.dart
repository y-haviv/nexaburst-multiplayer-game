

// nexaburst/lib/models/server/game_manager_models/game_manager_interface.dart

import 'dart:async';
import 'package:nexaburst/models/structures/room_model.dart';


abstract class GameManagerInterface {
  
  Future<Room?> initialize({required String roomId});
  void startListener();
  Future<void> clean();
  Future<Map<String, dynamic>?> getPlayers();
  Future<void> endGame(RoomStatus status);
  Future<void> deleteRoomIfHost();
  Stream<RoomStatus> get statusStream;
}
