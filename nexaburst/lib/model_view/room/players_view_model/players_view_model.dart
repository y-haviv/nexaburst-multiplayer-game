// nexaburst/lib/model_view/room/players_view_model/players_view_model.dart

import 'dart:async';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/room/players_view_model/players_interface.dart';
import 'package:nexaburst/models/data/server/players_stream.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:nexaburst/models/structures/player_model.dart';
import 'package:rxdart/rxdart.dart';

/// Real‑time players view‑model that listens to `PlayersModel`
/// and exposes a BehaviorSubject stream for the UI.
class PlayersViewModel extends Players {
  /// Underlying data model delivering player list updates.
  PlayersModel? _model;

  /// Subject that emits the latest list of players to the UI.
  late BehaviorSubject<List<Player>> _playersController;

  /// Subscription to the underlying model’s player stream.
  StreamSubscription<List<Player>>? _modelSub;

  /// Ensures one‑time initialization of the view‑model.
  bool _initialized = false;

  /// Creates the `PlayersModel` for [roomId], subscribes to its stream,
  /// and forwards data into `_playersController`.
  @override
  Future<void> initialization({required String roomId}) async {
    if (_initialized) {
      // already initialized, no need to do it again
      return;
    }
    _initialized = true;
    _model = PlayersModel(roomId);
    _playersController = BehaviorSubject();
    // subscribe once to the Model, forward into our own controller
    _modelSub = _model!.playersStream.listen(
      (players) => _playersController.add(players),
      onError: (e, st) {
        ErrorService.instance.report(error: ErrorType.unknown);
        _playersController.addError(e, st);
      },
    );
    return;
  }

  /// Returns the BehaviorSubject’s stream, or an empty stream if not initialized.
  @override
  Future<Stream<List<Player>>> players() async {
    if (_initialized) {
      return _playersController.stream;
    } else {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return Stream.empty();
    }
  }

  /// Cancels the model subscription and closes the controller.
  @override
  void dispose() {
    if (!_initialized) return;
    _initialized = false;
    _modelSub?.cancel();
    _playersController.close();
  }
}
