
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/debug/helpers/fake_data.dart';
import 'package:nexaburst/models/data/server/game_manager_models/game_manager_interface.dart';
import 'package:nexaburst/models/structures/player_model.dart';
import 'package:nexaburst/models/structures/room_model.dart';

 class FakeMainManager implements GameManagerInterface {

  /// Controller broadcasting only when status actually changes
  late StreamController<RoomStatus> _statusController;
  bool _intialized = false;

  /// Public stream for ViewModels to listen on
  @override
  Stream<RoomStatus> get statusStream => _statusController.stream;
  
  @override
  Future<Room?> initialize({required String roomId}) async {
    _statusController = StreamController<RoomStatus>.broadcast();
    _intialized = true;
    return FakeRoomData.room;
  }

  void _emitCurrentState() {
    final r = FakeRoomData.room;
    if(_intialized&&!_statusController.isClosed) _statusController.add(r.status);
  }
  
  @override
  void startListener() {_emitCurrentState();}

  @override
  Future<void> clean() async {
    _intialized = false;
    _statusController.close();
  }

  @override
  Future<Map<String, dynamic>?> getPlayers() async {
    List<Player> players = FakeRoomData.otherPlayers;
    Map<String, dynamic> mapPlayers = {};
    for(int i=0; i<players.length; i++) {
      mapPlayers[players[i].id] = players[i].toJson();
    }
    debugPrint("fake players for player screen: $mapPlayers");
    return mapPlayers;
  }

  @override
  Future<void> endGame(RoomStatus status) async {
    FakeRoomData.changeRoomSetting(status: status);
    _emitCurrentState();
  }

  @override
  Future<void> deleteRoomIfHost() async {debugPrint("delete room");}
}
