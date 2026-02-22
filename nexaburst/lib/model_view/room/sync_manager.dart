// nexaburst/lib/model_view/room/sync_manager.dart

import 'package:nexaburst/debug/fake_models/fake_game_sync.dart';
import 'package:nexaburst/models/data/server/sync_players/game_sync.dart';
import 'package:nexaburst/models/data/server/sync_players/real_game_sync.dart';

/// Manages a singleton `GameSync`, choosing fake or real implementation.
class SyncManager {
  static late final GameSync _instance;

  /// Initializes the shared `GameSync` instance.
  ///
  /// - `isDebug`: if true, uses `FakeGameSync`; otherwise `RealGameSync`.
  static void init({required bool isDebug}) {
    _instance = isDebug ? FakeGameSync() : RealGameSync();
  }

  /// Returns the configured `GameSync` singleton.
  static GameSync get instance => _instance;
}
