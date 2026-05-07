import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/debug/helpers/fake_data.dart';
import 'package:nexaburst/models/data/server/modes/forbidden_words/forbidden_words_detector_interface.dart';
import 'package:nexaburst/models/structures/player_model.dart';
import 'package:nexaburst/models/structures/room_model.dart';

/// Debug detector that emits synthetic forbidden-word events on a timer.
class FakeForbiddenWordsDetector implements IForbiddenWordsDetector {
  final Room room;
  final _rand = Random();
  late StreamController<Map<String, dynamic>> _controller;
  Timer? _timer;

  FakeForbiddenWordsDetector(this.room);

  @override
  Future<bool> initialize() async {
    // Debug implementation only needs a broadcast stream.
    _controller = StreamController<Map<String, dynamic>>.broadcast();
    return true;
  }

  @override
  void startDetection() {
    // No local speech engine in debug mode; only emit synthetic events.
    _scheduleNext();
  }

  /// Schedules and emits the next simulated forbidden-word event.
  void _scheduleNext() {
    // Use randomized delay to mimic irregular real speech detections.
    final delay = Duration(seconds: 10 + _rand.nextInt(11));
    _timer = Timer(delay, () {
      final random = Random();

      int indexP = random.nextInt(FakeRoomData.otherPlayers.length);
      int indexW = random.nextInt(FakeRoomData.room.forbiddenWords.length);

      Player p = FakeRoomData.otherPlayers[indexP];
      String w = FakeRoomData.room.forbiddenWords[indexW];
      debugPrint('Fake forbidden word detected: $w by player ${p.username}');

      final event = {
        'word': w,
        'playerId': '(fake_player: ${p.id})',
        'playerName': '(FakePlayer: ${p.username})',
        'timestamp': DateTime.now(),
      };
      _controller.add(event);
      _scheduleNext();
    });
  }

  @override
  Future<void> stopDetection() async {
    _timer?.cancel();
    _timer = null;
    await _controller.close();
  }

  @override
  void startListeningToForbiddenEvents() {
    // Fake implementation has no server-side bootstrap step.
  }

  @override
  Stream<Map<String, dynamic>> get forbiddenEventStream => _controller.stream;
}
