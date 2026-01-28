import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/debug/helpers/command_registry.dart';
import 'package:nexaburst/debug/helpers/fake_data.dart';
import 'package:nexaburst/models/data/server/levels/level5/lv05.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:nexaburst/models/structures/levels/level5/Lv05_model.dart';
import 'package:tuple/tuple.dart';

class FakeLv05 extends Lv05 {
  final String playerId = UserData.instance.user!.id;
  Lv05WhackMoleModel levelR =
      FakeRoomData.levelsData[levelName] is Lv05WhackMoleModel
      ? FakeRoomData.levelsData[levelName] as Lv05WhackMoleModel
      : Lv05WhackMoleModel(rounds: 2);
  List<String> names = [];

  late bool isDrinkingMode;
  bool levelFinished = false;
  bool _listenerStarted = false;

  static String levelName = TranslationService.instance.levelKeys[4];

  // Streams exposed to UI:
  @override
  Stream<String> get liveStreamingText => _liveStreamSubject.stream;
  @override
  Stream<Tuple2<List<String>, int>> get moleOrder => _moleOrderSubject.stream;
  @override
  Stream<List<HoleModel>> get holes => _holesSubject.stream;
  @override
  Stream<bool> get playerMole => _isMoleSubject.stream;

  // Internal model_view
  late BehaviorSubject<String> _liveStreamSubject;
  late BehaviorSubject<Tuple2<List<String>, int>> _moleOrderSubject;

  late BehaviorSubject<List<HoleModel>> _holesSubject;
  late BehaviorSubject<bool> _isMoleSubject;
  bool _initialized = false;

  @override
  void initialization({required String roomId, required bool isDrinkingMode}) {
    if (_initialized) return;
    _initialized = true;
    this.isDrinkingMode = isDrinkingMode;
    _liveStreamSubject = BehaviorSubject<String>();
    _moleOrderSubject = BehaviorSubject<Tuple2<List<String>, int>>();
    _holesSubject = BehaviorSubject<List<HoleModel>>();
    _isMoleSubject = BehaviorSubject<bool>();
    levelFinished = false;
    _startListeners();
  }

 @override
  String getInstruction() {
    return isDrinkingMode
        ? TranslationService.instance.t('game.levels.$levelName.instructions') +
            TranslationService.instance.t('game.levels.$levelName.drinking_instructions')
        : TranslationService.instance.t('game.levels.$levelName.instructions');
  }

  @override
  Stream<HoleModel> holeStream(int holeId) {
    if (!_initialized) {
      debugPrint("init model error");
      return Stream.empty();
    }
    return _holesSubject.stream
        .map((allHoles) => allHoles.firstWhere((h) => h.id == holeId))
        .distinct(
          (prev, next) =>
              prev.state == next.state &&
              prev.whacking == next.whacking &&
              prev.gotHit == next.gotHit,
        );
  }

  @override
  void dispose() {
    if (!_initialized) {
      debugPrint("init model error");
      return;
    }
    _initialized = false;
    CommandRegistry.instance.unregister('molePlayer');
    CommandRegistry.instance.unregister('hitPlayer');
    CommandRegistry.instance.unregister('hit');
    CommandRegistry.instance.unregister('show');
    CommandRegistry.instance.unregister('hide');
    CommandRegistry.instance.unregister('finish');
    CommandRegistry.instance.unregister('write');
    _liveStreamSubject.close();
    _moleOrderSubject.close();
    _holesSubject.close();
    _isMoleSubject.close();
    levelFinished = true;
  }

  void _startListeners() {
    if (!_initialized) {
      debugPrint("init model error");
      return;
    }
    if (_listenerStarted) return;
    _listenerStarted = true;

    _liveStreamSubject.add("..started debug level 05 - hit the mole..");
    names = [];
    for (int i = 0; i < FakeRoomData.otherPlayers.length; i++) {
      names.add(FakeRoomData.otherPlayers[i].username);
    }
    _moleOrderSubject.add(Tuple2(names, 0));

    levelR.initialization();
    _holesSubject.add(List.from(levelR.holes));

    CommandRegistry.instance.register(
      'molePlayer',
      'to be in /"mole player/"',
      (arg) async {
        _isMoleSubject.add(true);
        int myIndex = FakeRoomData.otherPlayers.indexWhere(
          (me) => me.id == playerId,
        );
        _moleOrderSubject.add(Tuple2(names, myIndex));
        _liveStreamSubject.add("changing mole... it is you now");
      },
    );
    CommandRegistry.instance.register('hitPlayer', 'to be in /"hit player/"', (
      arg,
    ) async {
      _isMoleSubject.add(false);
      int myIndex = FakeRoomData.otherPlayers.indexWhere(
        (me) => me.id != playerId,
      );
      _moleOrderSubject.add(Tuple2(names, myIndex));
      _liveStreamSubject.add("fuck you stop changing shit...");
    });
    CommandRegistry.instance.register(
      'hit',
      '(follows by hole id) to see hit animate in the hole',
      (arg) async {
        int? index = 0;
        try {
          index = int.tryParse(arg!);
          if (index == null) {
            debugPrint("1. problem - so will show at hole 0");
            index = 0;
          }
        } catch (e) {
          debugPrint("2. problem - so will show at hole 0");
          index = 0;
        }
         levelR.holes[index] = levelR.holes[index].copyWith(whacking:true);
        _holesSubject.add(List.from(levelR.holes));
        _liveStreamSubject.add("fake hit...");
        await Future.delayed(Duration(seconds: 1));
        levelR.holes[index] = levelR.holes[index].copyWith(whacking:false);
        _holesSubject.add(List.from(levelR.holes));
      },
    );
    CommandRegistry.instance.register(
      'show',
      '(follows by hole id) to see show charcter animate in the hole',
      (arg) async {
        int? index = 0;
        try {
          index = int.tryParse(arg!);
          if (index == null) {
            debugPrint("1. problem - so will show at hole 0");
            index = 0;
          }
        } catch (e) {
          debugPrint("2. problem - so will show at hole 0");
          index = 0;
        }
         levelR.holes[index] = levelR.holes[index].copyWith(state:"occupied");
        _holesSubject.add(List.from(levelR.holes));
        _liveStreamSubject.add("fake showing...");
      },
    );
    CommandRegistry.instance.register(
      'hide',
      '(follows by hole id) to see hide charcter animate in the hole',
      (arg) async {
        int? index = 0;
        try {
          index = int.tryParse(arg!);
          if (index == null) {
            debugPrint("1. problem - so will show at hole 0");
            index = 0;
          }
        } catch (e) {
          debugPrint("2. problem - so will show at hole 0");
          index = 0;
        }
        levelR.holes[index] = levelR.holes[index].copyWith(state:"empty");
        _holesSubject.add(List.from(levelR.holes));
        _liveStreamSubject.add("fake hiding...");
      },
    );
    CommandRegistry.instance.register('finish', 'to finish level', (arg) async {
      levelFinished = true;
    });
    CommandRegistry.instance.register(
      'write:',
      'and the some string to add live string',
      (arg) async {
        _liveStreamSubject.add(arg ?? "some problem...");
      },
    );
  }

  @override
  Future<void> initializeGame() async {}

  @override
  Future<void> resetRound() async {
    if (!_initialized) {
      debugPrint("init model error");
      return;
    }
    _startListeners();
  }

  @override
  Future<void> updatePlayerScore(int delta) async {}

  @override
  Future<int> getPlayerScore() async {
    return FakeRoomData.currentPlayerDefault.totalScore;
  }

  @override
  Future<void> updateHoleState(int holeId) async {
    if (!_initialized) {
      debugPrint("init model error");
      return;
    }
    if (levelR.holes[holeId].state == "occupied") {
      levelR.holes[holeId] = levelR.holes[holeId].copyWith(state:"empty");
      _liveStreamSubject.add("hide...");
    } else {
      levelR.holes[holeId] = levelR.holes[holeId].copyWith(state:"occupied");
      _liveStreamSubject.add("showing...");
    }
    _holesSubject.add(List.from(levelR.holes));
  }

  /// Player attempts to hit a mole
  @override
  Future<void> tryHitHole(int holeId) async {
    if (!_initialized) {
      debugPrint("init model error");
      return;
    }
    levelR.holes[holeId] = levelR.holes[holeId].copyWith(whacking: true);
    _holesSubject.add(List.from(levelR.holes));
    _liveStreamSubject.add("fake hit...");
    await Future.delayed(Duration(seconds: 1));
    levelR.holes[holeId] = levelR.holes[holeId].copyWith(whacking: false);
    _holesSubject.add(List.from(levelR.holes));
  }

  @override
  bool checkEndLevel() {
    return levelFinished;
  }
}

extension on HoleModel {
  HoleModel copyWith({String? state, bool? whacking, bool? gotHit}) {
    return HoleModel(
      id,
      state ?? this.state,
      whacking ?? this.whacking,
      gotHit ?? this.gotHit,
      syncPlayers,
    );
  }
}
