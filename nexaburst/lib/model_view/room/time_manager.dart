// nexaburst/lib/model_view/room/time_manager.dart

import 'package:nexaburst/debug/fake_view_model/fake_game_timer.dart';
import 'package:nexaburst/models/data/server/game_time/game_timer.dart';
import 'package:nexaburst/models/data/server/game_time/real_game_timer.dart';

/// Manages a singleton `GameTimer`, choosing fake or real implementation.
class TimerManager {
  static late final GameTimer _instance;

  /// Initializes the shared `GameTimer` instance.
  ///
  /// - `isDebug`: if true, uses `FakeGameTimer`; otherwise `RealGameTimer`.
  static void init({required bool isDebug}) {
    _instance = isDebug ? FakeGameTimer() : RealGameTimer();
  }

  /// Returns the configured `GameTimer` singleton.
  static GameTimer get instance => _instance;
}
