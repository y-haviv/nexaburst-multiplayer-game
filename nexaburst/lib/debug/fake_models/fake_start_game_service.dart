// lib/debug/fake_game_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nexaburst/debug/helpers/command_registry.dart';
import 'package:nexaburst/debug/helpers/fake_data.dart';
import 'package:tuple/tuple.dart';
import 'package:nexaburst/model_view/room/waiting_room/start_game_interface.dart';
import 'package:nexaburst/models/structures/room_model.dart';

/// Debug waiting-room service that simulates room updates via local commands.
class FakeStartGameService implements IStartGameService {
  /// Broadcast streams mirroring the production waiting-room service contract.
  final _hostController = StreamController<String>.broadcast();
  final _playersController = StreamController<List<String>>.broadcast();
  final _statusController = StreamController<RoomStatus>.broadcast();

  bool _listenerStarted = false;

  /// Starts command listeners and emits the initial fake room snapshot.
  Future<void> _startListener() async {
    if (_listenerStarted) return;
    _listenerStarted = true;

    // Seed UI with current fake room values before command-driven changes.
    _emitCurrentState();

    CommandRegistry.instance.register(
      'changeHost',
      'changing to new host for the game',
      (arg) async {
        _changeHost();
      },
    );
    CommandRegistry.instance.register('setStatus', 'nothing yet', (arg) async {
      if (arg != null) {
        final status = RoomStatus.values.firstWhere(
          (st) => st.toString().split('.').last == arg,
          orElse: () => FakeRoomData.room.status,
        );
        FakeRoomData.changeRoomSetting(status: status);
        _emitCurrentState();
        debugPrint('💡 [FakeService] Status changed to $status');
      }
    });
  }

  // IStartGameService implementation.

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
    // Build fake level data so downstream managers can run end-to-end.
    await FakeRoomData.levelsInitialization(
      levels,
      forbiddenWords,
      isDrinkingMode,
    );
    _startListener();
    return true;
  }

  @override
  Future<bool> joinRoom() async {
    // Reuse deterministic fake room setup for predictable debug sessions.
    FakeRoomData.levelsInitialization({'level1': 2}, [], false);
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
    // Mirror the host action by transitioning to the playing state.
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

  // Internal helpers.

  void _emitCurrentState() {
    final r = FakeRoomData.room;
    _hostController.add(r.hostId);
    _playersController.add(
      FakeRoomData.otherPlayers.map((player) => player.username).toList(),
    );
    _statusController.add(r.status);
    debugPrint("\nRoom data:");
    debugPrint("${r.toJson()}");
  }

  void _changeHost() {
    // Toggle host ownership to test host-dependent UI and permissions.
    final currentHost = FakeRoomData.room.hostId;
    String newHost;
    if (currentHost == FakeRoomData.currentPlayerDefault.id) {
      // Promote the first non-local player to host.
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
