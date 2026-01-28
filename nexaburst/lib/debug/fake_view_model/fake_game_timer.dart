

import 'dart:async';

import 'package:nexaburst/constants.dart';
import 'package:nexaburst/debug/helpers/command_registry.dart';
import 'package:nexaburst/models/data/server/game_time/game_timer.dart';

class FakeGameTimer implements GameTimer {
  
  final StreamController<int> _controller = StreamController<int>.broadcast();
  

  Completer<void>? _doneCompleter;
  Timer? _timer;
  int? _remaining;
  int _startingTimer = ScreenDurations.defaultTime;
  bool stoped = true;


  @override
  Stream<int> getTime() {
    return _controller.stream;
  }

  void _listenInputStop() {
      CommandRegistry.instance.register('time', 'reset and stop timer (simulate end of time)', (arg) async {
      stoped = true;
    });
  }

  
  @override
  Future<void> start(int seconds) async {
    if(!stoped) return; 
    stoped = false;
    _startingTimer = seconds;
    _remaining = seconds;
    _doneCompleter = Completer<void>();

    _controller.add(_remaining!);

    _listenInputStop();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _remaining = (_remaining! - 1).clamp(0, seconds);
      _controller.add(_remaining!);
      if(stoped) {
        stop();
        return;
      }
      else if (_remaining! <= 1) {
        _remaining = _startingTimer;
      }
    });

    return _doneCompleter!.future;
  }

  @override
  Future<void> reStart() async {
    stop();
    start(_startingTimer);
  }

  @override
  void stop() {
    _cancelTimer();
    CommandRegistry.instance.unregister('time');
    if (_remaining != null) {
      _remaining = null;
      _controller.add(-1); 
    }
    if (_doneCompleter != null && !_doneCompleter!.isCompleted) {
      _doneCompleter!.complete(); 
    }
    stoped = true;
  }

  /// Dispose the stream controller and cancel timer if needed.
  @override
  void dispose() {
    stop();
    _controller.close();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}



