// nexaburst/lib/models/server/levels/level5/Lv05_whack_a_mole.dart

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/models/data/server/levels/level5/lv05.dart';
import 'package:nexaburst/models/data/server/safe_call.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:rxdart/rxdart.dart';
import 'package:nexaburst/models/structures/levels/level5/Lv05_model.dart';
import 'package:tuple/tuple.dart';

/// Concrete implementation of Level 5 using Firestore.
/// Manages streams for UI and coordinates game state updates.
class Lv05WhackAMole extends Lv05 {
  /// Unique ID of the current user.
  final String playerId = UserData.instance.user!.id;

  /// Firestore document ID for this game room.
  late String roomId;

  /// Whether incorrect hits trigger drinking penalties.
  late bool isDrinkingMode;

  /// Guard to prevent concurrent hit attempts.
  bool _hittingHole = false;

  /// Marks when the level has ended.
  bool levelFinished = false;

  /// Tracks if initialization has occurred.
  bool _initialized = false;

  /// Indicates if listeners have been started.
  bool _started = false;

  /// Firestore document key for Level 5, from translation service.
  static String levelName = TranslationService.instance.levelKeys[4];

  /// Firestore instance for database operations.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reference to the room document in Firestore.
  late DocumentReference<Map<String, dynamic>> _roomDoc;

  /// Reference to this level’s document under the room.
  DocumentReference get _levelDoc =>
      _roomDoc.collection('levels').doc(levelName);

  // Streams exposed to UI:
  /// See [Lv05.liveStreamingText].
  @override
  Stream<String> get liveStreamingText => _liveStreamSubject.stream;

  /// See [Lv05.moleOrder].
  @override
  Stream<Tuple2<List<String>, int>> get moleOrder => _moleOrderSubject.stream;

  /// See [Lv05.holes].
  @override
  Stream<List<HoleModel>> get holes => _holesSubject.stream;

  /// See [Lv05.playerMole].
  @override
  Stream<bool> get playerMole => _isMoleSubject.stream;

  // Internal model_view
  late BehaviorSubject<String> _liveStreamSubject;
  late BehaviorSubject<Tuple2<List<String>, int>> _moleOrderSubject;

  late BehaviorSubject<List<HoleModel>> _holesSubject;
  late BehaviorSubject<bool> _isMoleSubject;

  StreamSubscription? _levelDocSub, _holesSub;

  /// Allocates subjects, sets [roomId] and [isDrinkingMode],
  /// and starts Firestore listeners.
  @override
  void initialization({required String roomId, required bool isDrinkingMode}) {
    if (_initialized) {
      debugPrint("Lv05WhackAMole already initialized.");
      return;
    }
    _liveStreamSubject = BehaviorSubject<String>();
    _moleOrderSubject = BehaviorSubject<Tuple2<List<String>, int>>();
    _holesSubject = BehaviorSubject<List<HoleModel>>();
    _isMoleSubject = BehaviorSubject<bool>();
    this.roomId = roomId;
    _roomDoc = _firestore.collection('rooms').doc(roomId);
    _initialized = true;
    _started = false;
    this.isDrinkingMode = isDrinkingMode;
    levelFinished = false;
    _startListeners();
    debugPrint("Lv05WhackAMole initialized.");
  }

  /// See [Lv05.getInstruction].
  @override
  String getInstruction() {
    return isDrinkingMode && _initialized
        ? TranslationService.instance.t('game.levels.$levelName.instructions') +
              TranslationService.instance.t(
                'game.levels.$levelName.drinking_instructions',
              )
        : TranslationService.instance.t('game.levels.$levelName.instructions');
  }

  /// See [Lv05.holeStream].
  @override
  Stream<HoleModel> holeStream(int holeId) {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
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

  /// Cancels subscriptions and closes all behavior subjects.
  @override
  void dispose() {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    levelFinished = true;
    if (_started) {
      _holesSub?.cancel();
      _levelDocSub?.cancel();
    }
    _started = false;
    _initialized = false;
    _liveStreamSubject.close();
    _moleOrderSubject.close();
    _holesSubject.close();
    _isMoleSubject.close();
  }

  /// Begins listening to Firestore updates for level state and holes.
  void _startListeners() {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    if (_started) {
      debugPrint("Listeners already started, ignoring duplicate call.");
      return;
    }
    _started = true;
    // Single listener on the level document:
    _levelDocSub = _levelDoc.snapshots().listen(
      (snap) {
        if (!snap.exists) {
          ErrorService.instance.report(error: ErrorType.notFound);
          return;
        }
        final data = snap.data() as Map<String, dynamic>? ?? {};

        // a) live streaming + mole lists + mole index
        final live = data['liveStreaming'] as String? ?? '';
        final ids = (data['playersMoleIds'] as List?)?.cast<String>() ?? [];
        final names = (data['playersMoleNames'] as List?)?.cast<String>() ?? [];
        final moleIndex = data['molePlayerIndex'] as int? ?? 0;
        if (_liveStreamSubject.valueOrNull != live) {
          _liveStreamSubject.add(live);
        }

        final prev = _moleOrderSubject.valueOrNull;
        if (prev == null ||
            !listEquals(prev.item1, names) ||
            prev.item2 != moleIndex) {
          _moleOrderSubject.add(Tuple2(names, moleIndex));
        }
        // b) derive “is my turn” from the above need to add only if index or ids or name changed
        final isMine = (ids.isNotEmpty && ids[moleIndex] == playerId);
        if (_isMoleSubject.valueOrNull != isMine) {
          _isMoleSubject.add(isMine);
        }
        // c) end‐of‐level flag
        levelFinished =
            data['endLevel'] as bool? ??
            levelFinished; // only if there is change - this been handle by manager logic of the game not UI screens
      },
      onError: (e) {
        debugPrint("Error listening to level document: $e");
        ErrorService.instance.report(error: ErrorType.firestore);
      },
    );

    // One listener on the holes subcollection:
    _holesSub = _levelDoc
        .collection('holes')
        .orderBy('id')
        .snapshots()
        .map(
          (q) => q.docs.map((d) => HoleModel.fromMap(d.id, d.data())).toList(),
        )
        .listen(
          _holesSubject.add,
          onError: (e) {
            debugPrint("Error listening to holes subcollection: $e");
            ErrorService.instance.report(error: ErrorType.firestore);
          },
        );
  }

  /// See [Lv05.initializeGame].
  @override
  Future<void> initializeGame() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    final roomSnap = await _roomDoc.get();
    if (!roomSnap.exists) {
      ErrorService.instance.report(error: ErrorType.notFound);
      return;
    }

    final playersSnap = await _roomDoc.collection('players').get();
    final players = playersSnap.docs
        .map((d) => Tuple2(d.id, d.get('username') as String))
        .toList();
    // Shuffle order
    players.shuffle(Random());
    final ids = players.map((t) => t.item1).toList();
    final names = players.map((t) => t.item2).toList(); // same order
    // Zero scores
    final scoreMap = {for (var t in players) t.item1: 0};

    await _levelDoc.update({
      'playersMoleIds': ids,
      'playersMoleNames': names,
      'playerScores': scoreMap,
      'molePlayerIndex': 0,
      'sumOccupiedHoles': 0,
      'liveStreaming': '',
      'endLevel': false,
    });
  }

  /// See [Lv05.resetRound].
  @override
  Future<void> resetRound() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    await _firestore.runTransaction((tx) async {
      final lvlSnap = await tx.get(_levelDoc);
      if (!lvlSnap.exists) {
        ErrorService.instance.report(error: ErrorType.notFound);
        return;
      }
      final data = lvlSnap.data()! as Map<String, dynamic>? ?? {};
      final ids = (data['playersMoleIds'] as List).cast<String>();

      int idx = (data)['molePlayerIndex'] as int? ?? 0;
      idx++;
      final reset = idx >= ids.length;
      if (reset) idx = 0;
      tx.update(_levelDoc, {
        'molePlayerIndex': idx,
        'endLevel': reset,
        'sumOccupiedHoles': 0,
      });
      // Reset all hole docs
      final holesCol = _levelDoc.collection('holes');
      final holesSnap = await holesCol.get();
      for (var h in holesSnap.docs) {
        tx.update(h.reference, {
          'state': 'empty',
          'gotHit': false,
          'whacking': false,
        });
      }
    });

    if ((await _levelDoc.get()).get('endLevel') as bool) {
      await _endGame();
    }
  }

  /// See [Lv05.updatePlayerScore].
  @override
  Future<void> updatePlayerScore(int delta) async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    await _firestore.runTransaction((tx) async {
      final lvlSnap = await tx.get(_levelDoc);
      if (!lvlSnap.exists) {
        ErrorService.instance.report(error: ErrorType.notFound);
        return;
      }
      final scores = Map<String, dynamic>.from(
        lvlSnap.get('playerScores') as Map<String, dynamic>,
      );
      final current = (scores[playerId] as int?) ?? 0;
      scores[playerId] = current + delta;
      tx.update(_levelDoc, {'playerScores': scores});
    });
  }

  /// See [Lv05.getPlayerScore].
  @override
  Future<int> getPlayerScore() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return 0;
    }
    final lvlSnap = await _levelDoc.get();
    final scores = Map<String, dynamic>.from(
      lvlSnap.get('playerScores') as Map<String, dynamic>,
    );
    return (scores[playerId] as int?) ?? 0;
  }

  /// Finalizes scores, persists to total_score, and enforces drinking
  /// for lowest scorer.
  Future<void> _endGame() async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    // 1. Retrieve level scores
    final lvlSnap = await _levelDoc.get();
    final data = lvlSnap.data() as Map<String, dynamic>? ?? {};
    final scores = Map<String, dynamic>.from(data['playerScores'] ?? {});

    // 2. Persist my level score to my total_score
    final myScore = (scores[playerId] as int?) ?? 0;
    final userRef = _roomDoc.collection('players').doc(playerId);
    await _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final currentTotal = (userSnap.get('total_score') as int?) ?? 0;
      tx.update(userRef, {'total_score': currentTotal + myScore});
    });

    if (isDrinkingMode) {
      // 3. Determine minimum score among all players
      if (scores.isEmpty) return;
      final minScore = scores.values
          .map((v) => v as int)
          .reduce((a, b) => a < b ? a : b);

      // 4. If I'm among the lowest scorers, add myself to players_to_drink
      if (myScore == minScore) {
        final playerData =
            (await _roomDoc.collection('players').doc(playerId).get()).data() ??
            {};
        final username = playerData['username'] ?? "Unknown";

        await _roomDoc.update({'players_to_drink.$playerId': username});
      }
    }
  }

  /// See [Lv05.updateHoleState].
  @override
  Future<void> updateHoleState(int holeId) async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    await safeCall(() async {
      final playerData =
          (await _roomDoc.collection('players').doc(playerId).get()).data() ??
          {};
      final username = playerData['username'] ?? "Unknown";
      await _firestore.runTransaction((tx) async {
        final lvlSnap = await tx.get(_levelDoc);
        final data = lvlSnap.data() as Map<String, dynamic>;
        final ids = (data['playersMoleIds'] as List).cast<String>();

        final idx = data['molePlayerIndex'] as int;

        if (ids[idx] != playerId) return;

        final holeRef = _levelDoc.collection('holes').doc(holeId.toString());
        final holeSnap = await tx.get(holeRef);
        final h = holeSnap.data() as Map<String, dynamic>;
        final sum =
            data['sumOccupiedHoles'] as int? ??
            0; // only one mole exists so only this player can change the state
        if (h['state'] == 'empty') {
          if (sum < 2) {
            tx.update(holeRef, {'state': 'occupied', 'gotHit': false});
            tx.update(_levelDoc, {'sumOccupiedHoles': FieldValue.increment(1)});
          }
        } else {
          // remove
          if (!(h['gotHit'] as bool? ?? false)) {
            final scores = Map<String, dynamic>.from(
              lvlSnap.get('playerScores'),
            );
            final current = (scores[playerId] as int? ?? 0);
            scores[playerId] = current + Lv05WhackMoleModel.scoreIncrementMole;
            String live = Lv05WhackMoleModel.updateLive(true, username);
            tx.update(_levelDoc, {
              'playerScores': scores,
              'liveStreaming': live,
            });
          }
          tx.update(holeRef, {'state': 'empty', 'gotHit': false});
          tx.update(_levelDoc, {'sumOccupiedHoles': FieldValue.increment(-1)});
        }
      });
    });
  }

  /// See [Lv05.tryHitHole].
  @override
  Future<void> tryHitHole(int holeId) async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    await safeCall(() async {
      if (_hittingHole) return;
      _hittingHole = true;
      final playerData =
          (await _roomDoc.collection('players').doc(playerId).get()).data() ??
          {};
      final username = playerData['username'] ?? "Unknown";

      final lvlData = (await _levelDoc.get()).data() as Map<String, dynamic>;
      final ids = (lvlData['playersMoleIds'] as List).cast<String>();
      final idx = lvlData['molePlayerIndex'] as int;
      if (ids[idx] == playerId) {
        _hittingHole = false;
        return;
      }

      final holeRef = _levelDoc.collection('holes').doc(holeId.toString());
      bool greateHit = false;
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(holeRef);
        final h = snap.data() as Map<String, dynamic>;
        if (h['whacking'] as bool? ?? false) {
          _hittingHole = false;
          return;
        }
        tx.update(holeRef, {'whacking': true});

        if (h['state'] == 'occupied' && !(h['gotHit'] as bool? ?? false)) {
          tx.update(holeRef, {'gotHit': true});
          greateHit = true;
          String live = Lv05WhackMoleModel.updateLive(false, username);
          tx.update(_levelDoc, {'liveStreaming': live});
        }
      });

      if (greateHit) {
        await updatePlayerScore(Lv05WhackMoleModel.scoreIncrementHit);
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        holeRef.update({'whacking': false});
        _hittingHole = false;
      });
    });
  }

  /// See [Lv05.checkEndLevel].
  @override
  bool checkEndLevel() {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return true;
    }
    return levelFinished;
  }
}
