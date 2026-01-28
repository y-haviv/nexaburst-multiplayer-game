

import 'dart:async';

import 'package:nexaburst/model_view/room/players_view_model/players_interface.dart';
import 'package:nexaburst/debug/helpers/fake_data.dart';
import 'package:nexaburst/models/structures/player_model.dart';

class FakePlayersView extends Players {
  late StreamController<List<Player>> _playersController;
  bool _initialized = false;

  @override
  Future<void> initialization({required String roomId}) async {
    if(_initialized) return;
    _initialized = true;
    _playersController = StreamController<List<Player>>.broadcast(
      onListen: () {
        // re-emit the “initial” fake list whenever someone starts listening:
        _playersController.add(FakeRoomData.otherPlayers);
      },
    );
    return;
  }

  @override
  Future<Stream<List<Player>>> players() async {
    if(!_initialized) await initialization(roomId: "");
    return _playersController.stream;
  }

  @override
  void dispose() {
    _initialized = false;
    _playersController.close();
  }
}
