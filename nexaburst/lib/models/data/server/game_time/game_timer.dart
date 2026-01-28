// nexaburst/lib/models/server/game_time/game_time.dart

import 'dart:async';

/// Interface defining a countdown timer:
/// provides a stream of remaining seconds and lifecycle controls.
abstract class GameTimer {
  /// Emits the current remaining time in seconds whenever it changes.
  Stream<int> getTime();

  /// Begins a countdown from [seconds], broadcasting each tick.
  ///
  /// Completes when the timer reaches zero.
  Future<void> start(int seconds);

  /// Restarts the countdown using the last start value.
  ///
  /// Completes when the timer reaches zero.
  Future<void> reStart();

  /// Cancels the active countdown and emits a sentinel value (e.g., –1).
  void stop();

  /// Releases all timer and stream resources permanently.
  void dispose();
}
