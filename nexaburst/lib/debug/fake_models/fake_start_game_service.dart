// lib/debug/fake_game_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nexaburst/debug/helpers/command_registry.dart';
import 'package:nexaburst/debug/helpers/fake_data.dart';
import 'package:tuple/tuple.dart';
import 'package:nexaburst/model_view/room/waiting_room/start_game_interface.dart';
import 'package:nexaburst/models/structures/room_model.dart';

class FakeStartGameService implements IStartGameService {
  // Stream model_view
  final _hostController = StreamController<String>.broadcast();
  final _playersController = StreamController<List<String>>.broadcast();
  final _statusController = StreamController<RoomStatus>.broadcast();
  

  bool _listenerStarted = false;

  Future<void> _startListener() async {
    if (_listenerStarted) return;
    _listenerStarted = true;

    // Seed initial values
    _emitCurrentState();

    CommandRegistry.instance.register('changeHost', 'changing to new host for the game', (arg) async {
      _changeHost();
    });
    CommandRegistry.instance.register('setStatus', 'nothing yet', (arg) async {
      if (arg != null) {
        final status = RoomStatus.values.firstWhere(
            (st) => st.toString().split('.').last == arg,
            orElse: () => FakeRoomData.room.status);
        FakeRoomData.changeRoomSetting(status: status);
        _emitCurrentState();
        debugPrint('💡 [FakeService] Status changed to $status');
      }
    });
  }

  // --- IStartGameService methods ---

  @override
  void initialization({String? roomId}) {}

  @override
  String getRoomId() {
    return FakeRoomData.room.roomId;
  }

  @override
  Future<bool> createRoom({
    required Map<String, int> levels,
    required List<String> forbiddenWords,
    required bool isDrinkingMode,
    required String lang,
  }) async {
    // Initialize fake room data
    await FakeRoomData.levelsInitialization(levels, forbiddenWords, isDrinkingMode);
    _startListener();
    return true;
  }

  @override
  Future<bool> joinRoom() async {
    // Simply re-emit existing fake data
    FakeRoomData.levelsInitialization({'level1':2}, [], false);
    _startListener();
    return true;
  }

  @override
  Stream<String> watchRoomHost() => _hostController.stream;

  @override
  Stream<RoomStatus> watchRoomStatus() => _statusController.stream;

  @override
  Stream<List<String>> watchPlayers() => _playersController.stream;

  @override
  Future<Tuple2<List<String>, String>> preJoiningMicPremission() async {
    final r = FakeRoomData.room;
    return Tuple2(r.forbiddenWords, r.lang);
  }

  @override
  Future<void> start() async {
    // Host starts the game
    FakeRoomData.changeRoomSetting(status: RoomStatus.playing);
    _emitCurrentState();
  }

  @override
  void dispose() {
    CommandRegistry.instance.unregister('changeHost');
    CommandRegistry.instance.unregister('setStatus');
    _hostController.close();
    _playersController.close();
    _statusController.close();
  }

  // --- Internal helpers ---

  void _emitCurrentState() {
    final r = FakeRoomData.room;
    _hostController.add(r.hostId);
    _playersController.add(FakeRoomData.otherPlayers.map((player) => player.username).toList()); 
    _statusController.add(r.status);
    debugPrint("\nRoom data:");
    debugPrint("${r.toJson()}");
  }

  void _changeHost() {
    // Swap host between current player and someone else
    final currentHost = FakeRoomData.room.hostId;
    String newHost;
    if (currentHost == FakeRoomData.currentPlayerDefault.id) {
      // pick first other player
      newHost = FakeRoomData.otherPlayers
          .firstWhere((p) => p.id != FakeRoomData.currentPlayerDefault.id)
          .id;
    } else {
      newHost = FakeRoomData.currentPlayerDefault.id;
    }
    FakeRoomData.changeRoomSetting(hostId: newHost);
    _emitCurrentState();
    debugPrint('💡 [FakeService] Host changed to $newHost');
  }
}
