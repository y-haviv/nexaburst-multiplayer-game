// nexaburst/lib/models/server/game_time/real_game_time.dart

import 'dart:async';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/models/data/server/game_time/game_timer.dart';

/// Concrete countdown timer implementation:
/// uses a periodic [Timer] and a broadcast [StreamController].
class RealGameTimer implements GameTimer {
  /// Broadcasts remaining seconds to all subscribers.
  final StreamController<int> _controller = StreamController<int>.broadcast();

  /// Completes when the countdown reaches zero or is stopped.
  Completer<void>? _doneCompleter;

  /// Underlying periodic timer driving the countdown ticks.
  Timer? _timer;

  /// Tracks the current remaining seconds (null if stopped).
  int? _remaining;

  /// Stores the last started duration for restart operations.
  int _startingTimer = ScreenDurations.defaultTime;

  /// Returns a stream of remaining seconds.
  @override
  Stream<int> getTime() {
    return _controller.stream;
  }

  /// Starts or restarts the countdown from [seconds].
  ///
  /// Returns a future that completes when the timer hits zero.
  @override
  Future<void> start(int seconds) {
    _cancelTimer();
    _startingTimer = seconds;
    _remaining = seconds;
    _doneCompleter = Completer<void>();

    _controller.add(_remaining!);

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _remaining = (_remaining! - 1).clamp(0, seconds);
      _controller.add(_remaining!);

      if (_remaining == 0) {
        _cancelTimer();
        if (!_doneCompleter!.isCompleted) {
          _doneCompleter!.complete();
        }
      }
    });

    return _doneCompleter!.future;
  }

  /// Convenience to restart the countdown using [_startingTimer].
  @override
  Future<void> reStart() {
    return start(_startingTimer);
  }

  /// Cancels the countdown, emits –1, and completes the done future.
  @override
  void stop() {
    _cancelTimer();
    if (_remaining != null) {
      _remaining = null;
      _controller.add(-1);
    }
    if (_doneCompleter != null && !_doneCompleter!.isCompleted) {
      _doneCompleter!.complete();
    }
  }

  /// Cancels the timer and closes the stream controller.
  @override
  void dispose() {
    _cancelTimer();
    _controller.close();
  }

  /// Helper to cancel the internal [Timer] if active.
  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
