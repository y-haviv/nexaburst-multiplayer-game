// nexaburst/lib/models/server/sync_players/real_game_sync.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/room/game/modes/drinking/drinking_manager.dart';
import 'package:nexaburst/models/data/server/safe_call.dart';
import 'package:nexaburst/models/data/server/sync_players/game_sync.dart';
import 'package:nexaburst/models/data/service/loading_controller.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:synchronized/synchronized.dart';

/// Concrete implementation of [GameSync] using Firestore and
/// a lock to coordinate multi‑player round progression.
class RealGameSync implements GameSync {
  /// Tracks whether `init` has been called.
  bool _initialized = false;

  /// Firestore room document ID used for synchronization.
  late String _roomId;

  /// Local counter of how many rounds this player has synchronized.
  int _myRound = 0;

  String saidForbiddenWord = "";

  /// Prepares the sync instance for use by setting [roomId]
  /// and resetting the local round counter.
  @override
  void init({required String roomId}) {
    _roomId = roomId;
    _myRound = 0;
    _initialized = true;
    saidForbiddenWord = "";
  }

  /// Clears initialization state so this instance can be re‑initialized.
  @override
  void clear() {
    _initialized = false;
    _roomId = '';
    _myRound = 0;
    saidForbiddenWord = "";
  }

  /// Firestore client used for reading and writing sync data.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reference to the `/rooms/{roomId}` document.
  DocumentReference? get _roomDoc {
    if (!_initialized || _roomId.isEmpty) return null;
    return _firestore.collection('rooms').doc(_roomId);
  }

  /// Reference to the `/rooms/{roomId}/sync/game_sync` document.
  DocumentReference? get _syncDoc {
    final room = _roomDoc;
    if (room == null) return null;
    return room.collection('sync').doc('game_sync');
  }

  /// Maximum wait time for various Firestore snapshot listeners.
  final Duration _timeout = const Duration(seconds: 15);

  /// Ensures only one `synchronizePlayers` call runs concurrently.
  final Lock _syncLock = Lock();

  /// Public entrypoint for player synchronization:
  /// - Verifies `init` was called
  /// - Acquires [_syncLock]
  /// - Delegates to `_runSync` with error handling via `safeCall`
  ///
  /// Returns `true` on success, `false` on handled failure.
  @override
  Future<bool> synchronizePlayers([Future<void> Function()? resetLogic]) async {
    if (!_initialized) {
      ErrorService.instance.report(error: ErrorType.notInitialized);
    }
    return _syncLock.synchronized(() async {
      return await safeCall(() => _runSync(resetLogic), fallbackValue: false);
    });
  }

  /// Core implementation of the sync protocol:
  /// 1. Wait for round alignment
  /// 2. Wait for releaseFlag = false
  /// 3. Mark this player ready
  /// 4. Host waits and advances round, non-host unsets ready
  /// 5. Increment `_myRound`
  ///
  /// Returns `true` if this player advanced successfully.
  Future<bool> _runSync([Future<void> Function()? resetLogic]) async {
    resetLogic ??= () async {};
    final roomDoc = _roomDoc;
    final syncDoc = _syncDoc;
    if (roomDoc == null || syncDoc == null) {
      debugPrint('SyncManager error: roomId is not set, skipping sync.');
      return false;
    }
    final loading = LoadingService();
    loading.show(TranslationService.instance.t('game.loadingSynchronization'));

    try {
      if (saidForbiddenWord.isNotEmpty) {
        // If the player said a forbidden word, update drinking status
        await roomDoc.update({
          'players_to_drink.${UserData.instance.user!.id}':
              UserData.instance.user!.username,
        });
        await DrinkingStageManager().saidForbidden(saidForbiddenWord);
        saidForbiddenWord = "";
      }

      // Load current sync state
      final initialSnap = await syncDoc.get();
      if (!initialSnap.exists) {
        debugPrint('Sync document missing in Firestore.');
        ErrorService.instance.report(error: ErrorType.notFound);
        return false;
      }
      final data = initialSnap.data()! as Map<String, dynamic>;
      final int currentRound = data['round'] as int;

      bool timedOut = false;
      // If we're behind, skip; if ahead, wait for round catch-up
      if (_myRound < currentRound) {
        _myRound = currentRound;
        return false;
      } else if (_myRound > currentRound) {
        await Future.any([
          syncDoc
              .snapshots()
              .timeout(_timeout * 3)
              .firstWhere(
                (s) =>
                    (s.data() as Map<String, dynamic>?)?['round'] == _myRound,
              ),
          Future.delayed(_timeout).then((_) => timedOut = true),
        ]);
        if (timedOut) {
          debugPrint('Timeout waiting for round $_myRound.');
          timedOut = false;
        }
      }

      // STEP 1: Wait for previous releaseFlag = false
      await Future.any([
        syncDoc
            .snapshots()
            .timeout(_timeout)
            .firstWhere(
              (s) =>
                  (s.data() as Map<String, dynamic>?)?['releaseFlag'] == false,
            ),
        Future.delayed(_timeout).then((_) => timedOut = true),
      ]);
      if (timedOut) {
        debugPrint('Timeout waiting for releaseFlag false.');
        timedOut = false;
      }

      // STEP 2: Mark this player as ready
      await _firestore.runTransaction((tx) async {
        tx.update(syncDoc, {'players.${UserData.instance.user!.id}': true});
      });

      // STEP 3: Wait until host releases or if I'm host
      bool isHost = false;
      final completer = Completer<void>();
      final subSync = syncDoc.snapshots().listen((snap) {
        final data = snap.data() as Map<String, dynamic>?;
        if (data == null) {
          debugPrint('Document deleted, aborting sync.');
          completer.complete();
          return;
        }
        if ((data['releaseFlag'] ?? false) == true) {
          completer.complete();
        }
      });
      final subRoom = roomDoc.snapshots().listen((snap) {
        final data = snap.data() as Map<String, dynamic>?;
        if (data == null) {
          debugPrint('Document deleted, aborting sync.');
          completer.complete();
          return;
        }
        if ((data['hostId'] ?? '') == UserData.instance.user!.id) {
          isHost = true;
          completer.complete();
        }
      });
      await Future.any([
        completer.future,
        Future.delayed(_timeout).then((_) => timedOut = true),
      ]).whenComplete(() {
        subSync.cancel();
        subRoom.cancel();
      });

      // STEP 4: Host vs non-host branching
      if (isHost) {
        await _waitForAllPlayers(true);
        await resetLogic();
        // Advance round and release others
        await _firestore.runTransaction((tx) async {
          final snap = await tx.get(syncDoc);
          final int round =
              ((snap.data()! as Map<String, dynamic>)['round'] ?? 0) as int;
          tx.update(syncDoc, {
            'releaseFlag': true,
            'players.${UserData.instance.user!.id}': false,
            'round': round + 1,
          });
        });
        await _waitForAllPlayers(false);
        await syncDoc.update({'releaseFlag': false});
      } else {
        // Non-host: simply unset ready
        await _firestore.runTransaction((tx) async {
          tx.update(syncDoc, {'players.${UserData.instance.user!.id}': false});
        });
      }

      _myRound += 1;
      debugPrint('Player ${UserData.instance.user!.id} synchronized.');
      return true;
    } catch (e, st) {
      debugPrint('SyncManager error: $e\n$st');
      ErrorService.instance.report(error: ErrorType.firestore);
      rethrow;
    } finally {
      loading.clear();
    }
  }

  /// Listens to the sync document until every player’s
  /// `players.{id}` flag equals [readyState], then returns.
  Future<void> _waitForAllPlayers(bool readyState) async {
    final syncDoc = _syncDoc;
    if (syncDoc == null) {
      debugPrint('SyncManager error: roomId is not set, skipping sync.');
      return;
    }
    await for (final snap in syncDoc.snapshots()) {
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) {
        debugPrint('Document deleted, aborting sync.');
        return;
      }
      final players = (data['players'] ?? {}) as Map<String, dynamic>;
      if (players.values.map((v) => v as bool).every((v) => v == readyState)) {
        break;
      }
    }
  }

  @override
  void playerSaidForbiddenWord(String word) {
    saidForbiddenWord = word;
  }
}
