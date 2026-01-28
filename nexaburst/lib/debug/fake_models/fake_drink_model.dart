



// skillrush/lib/model_view/room/game/drinking/drinking_manager.dart


import 'dart:async';


import 'package:nexaburst/debug/helpers/command_registry.dart';
import 'package:nexaburst/debug/helpers/fake_data.dart';
import 'package:nexaburst/models/data/server/modes/drinking/drinking_game.dart';
import 'package:nexaburst/models/structures/player_model.dart';
import 'package:rxdart/rxdart.dart';


class FakeDrinkModel implements DrinkingGame {
  Duration timeout = const Duration(seconds: 10);
  late BehaviorSubject<Map<String, String>> _controller;

  bool _initialized = false;
  Map<String,String> drinkPlayers = FakeRoomData.room.playersToDrink;

  @override
  BehaviorSubject<Map<String, String>> get stream => _controller;

  void _fakeStreamUpdate(bool toDrink) {
    if (!_initialized) return;
    if (toDrink && !drinkPlayers.containsKey(FakeRoomData.currentPlayerDefault.id)) {
      drinkPlayers[FakeRoomData.currentPlayerDefault.id] = FakeRoomData.currentPlayerDefault.username;
    } else if (!toDrink && drinkPlayers.containsKey(FakeRoomData.currentPlayerDefault.id)) {
      drinkPlayers.remove(FakeRoomData.currentPlayerDefault.id);
    }
    _controller.add(drinkPlayers);
  }

  @override
  void initialization({required String roomId}) {
    // 1. הקמת ה־BehaviorSubject
    _controller = BehaviorSubject<Map<String, String>>();

    // 2. רישום הפקודות שיגרמו לשינוי (ישן)
    CommandRegistry.instance.register('drink',
      'to be in /"player who need to drink screen/"',
      (arg) async {
        if (!_initialized) return;
        _fakeStreamUpdate(true);
      }
    );
    CommandRegistry.instance.register('waitDrink',
      'to be in player who /"need to wait screen/"',
      (arg) async {
        if (!_initialized) return;
        _fakeStreamUpdate(false);
      }
    );

    // 3. בודקים אם יש שחקנים קיימים מה־FakeRoomData ומכניסים אותם ל־map
    for (Player p in FakeRoomData.otherPlayers) {
      drinkPlayers[p.id] = p.username;
    }

    // 4. מסמנים שהתחלנו – רק עכשיו מותר לשלוח אירועים
    _initialized = true;

    // 5. שולחים את הערך ההתחלתי (כולל כל השחקנים הקיימים ב־drinkPlayers)
    _controller.add(drinkPlayers);
  }

  @override
  Future<void> waitUntilInitialized() async {
    if (_initialized) return;

    await Future.any([
      stream.firstWhere((map) => map.isNotEmpty),
      Future.delayed(timeout),
    ]);
  }

  @override
  void dispose() {
    if (!_initialized) return;
    CommandRegistry.instance.unregister('drink');
    CommandRegistry.instance.unregister('waitDrink');
    _initialized = false;
    _controller.close();
    // מנקים את ה־map לערך ההתחלתי של FakeRoomData
    drinkPlayers = FakeRoomData.room.playersToDrink;
  }

  @override
  Future<void> removeFromPlayersToDrink() async {
    if (!_initialized) return;
    _fakeStreamUpdate(false);
  }
}
