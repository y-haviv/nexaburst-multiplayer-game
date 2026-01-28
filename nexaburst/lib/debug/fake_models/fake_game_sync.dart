import 'dart:async';

import 'package:nexaburst/models/data/server/sync_players/game_sync.dart';

class FakeGameSync implements GameSync {
  /// Must be called once before using synchronizePlayers
  @override
  void init({required String roomId}) {}

  /// Optionally reset internal state
  @override
  void clear() {}

  /// Ensures only one invocation runs at a time.
  @override
  Future<bool> synchronizePlayers([Future<void> Function()? resetLogic]) async {
    if (resetLogic != null) await resetLogic();
    return true;
  }

  @override
  void playerSaidForbiddenWord(String word) {}
}
