// nexaburst/lib/models/server/presence/presence_manager.dart

import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/models/data/server/presence/pesence_manager_interface.dart';
import 'package:nexaburst/models/data/server/safe_call.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';

/// Real‐time implementation of [IPresenceManager] using
/// Firebase Realtime Database for connection events and Firestore
/// for cleanup of room data when players disconnect.
class realPresence implements IPresenceManager {
  /// Tracks whether `initialize()` has completed.
  bool _initialized = false;

  /// Tracks whether `start()` has been called.
  bool _started = false;

  /// Identifier of the Firestore room document.
  late String roomId;

  /// ID of the local player for presence and cleanup operations.
  late String playerId = UserData.instance.user!.id;

  /// Names of game levels loaded from the room document.
  List<String>? _levels;

  /// Reference to the Firestore `/rooms/{roomId}` document.
  late final DocumentReference<Map<String, dynamic>> _roomDoc;

  /// Reference to the Firestore `/rooms/{roomId}/sync/game_sync` document.
  late final DocumentReference<Map<String, dynamic>> _syncDoc;

  /// Realtime Database reference for this player’s presence under `/games/{roomId}/players/{playerId}`.
  late final DatabaseReference _rtdbPlayerRef;

  /// Subscription to child‐changed events for detecting peer disconnects.
  StreamSubscription<DatabaseEvent>? _disconnectListener;

  /// Creates a presence manager for [roomId], initializing Firestore
  /// and RTDB references and validating inputs.
  ///
  /// Throws [ArgumentError] if [roomId] is empty, or [StateError]
  /// if no user is logged in.
  realPresence({required this.roomId})
    : _roomDoc = FirebaseFirestore.instance.collection('rooms').doc(roomId),
      _syncDoc = FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('sync')
          .doc('game_sync'),
      _rtdbPlayerRef = FirebaseDatabase.instance.ref(
        'games/$roomId/players/${UserData.instance.user!.id}',
      ) {
    if (roomId.isEmpty) {
      throw ArgumentError('Room ID cannot be empty');
    }
    if (UserData.instance.user == null) {
      throw StateError('User must be logged in to create PresenceManager');
    }
    debugPrint('[Presence] Created for player $playerId in room $roomId');
  }

  /// Asynchronously loads room levels and sets up onDisconnect handlers.
  /// Safe to call only once before `start()`.
  @override
  Future<void> initialize() async {
    if (_initialized || _started) return;
    await _initStages();
    await _setupPresence();
    _initialized = true;
    debugPrint('[Presence] is inittionlized');
  }

  /// Loads the room’s `Levels` array from Firestore and updates RTDB hostId
  /// if this player is the host.
  Future<void> _initStages() async {
    try {
      final snap = await _roomDoc.get();
      if (!snap.exists) {
        ErrorService.instance.report(error: ErrorType.notFound);
        debugPrint('[Presence][Error] failed to load');
        return;
      }
      final data = snap.data();
      _levels = List<String>.from(data?['Levels'] as List<dynamic>? ?? []);
      if ((snap.data()?['hostId'] as String) == playerId) {
        await FirebaseDatabase.instance
            .ref('games/$roomId/hostId')
            .set(playerId);
        debugPrint('[Presence] RTDB hostId updated to me');
      }
      debugPrint('[Presence] Loaded stages: ${_levels?.join(", ")}');
    } catch (e, st) {
      debugPrint('[Presence][Error] failed to load stages: $e');
      debugPrint(st.toString());
      _levels = [];
    }
  }

  /// Registers RTDB onDisconnect cleanup and marks the player as connected.
  Future<void> _setupPresence() async {
    try {
      await _rtdbPlayerRef.onDisconnect().update({
        'isConnected': false,
        'disconnectedAt': ServerValue.timestamp,
      });

      await _rtdbPlayerRef.update({
        'isConnected': true,
        'connectedAt': ServerValue.timestamp,
      });
      debugPrint('[Presence] Initialized for player $playerId');
    } catch (e, st) {
      debugPrint('[Presence][Error] setup failed: $e');
      debugPrint(st.toString());
    }
  }

  /// Begins listening for other players’ disconnect events via RTDB.
  /// Only effective after `initialize()`.
  @override
  void start() {
    if (!_initialized) {
      debugPrint('[Presence][Error] Cannot start before initialization');
      return;
    }
    if (_started) {
      debugPrint('[Presence] Already started for player $playerId');
      return;
    }
    _started = true;
    _disconnectListener = FirebaseDatabase.instance
        .ref('games/$roomId/players')
        .onChildChanged
        .listen(
          (event) {
            final isConnected =
                event.snapshot.child('isConnected').value == true;
            final disconnectedId = event.snapshot.key;

            if (!isConnected && disconnectedId != null) {
              _cleaningUp(false, disconnectedId);
            }
          },
          onError: (e) {
            debugPrint('[Presence][Error] listener failed: $e');
          },
        );
  }

  /// Orchestrates cleanup when a player disconnects:
  /// invokes `_handleDisconnect` and `_cleanUpPlayerData`,
  /// and if needed, `_cleanUpRoom`.
  ///
  /// [disconnected]: true if this player themselves disconnected.
  /// [disconnectedPlayerId]: ID of the player to clean up.
  Future<void> _cleaningUp(
    bool disconnected,
    String disconnectedPlayerId,
  ) async {
    if (!_initialized) {
      debugPrint('[Presence][Error] Cannot clean up before initialization');
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    try {
      bool host = disconnected;
      if (!disconnected) {
        host = await safeCall(
          () => _handleDisconnect(disconnectedPlayerId),
          fallbackValue: false,
        );
      }
      if (host) {
        bool deleteRoom = await safeCall(
          () => _cleanUpPlayerData(disconnectedPlayerId),
          fallbackValue: false,
        );
        if (deleteRoom) {
          await _cleanUpRoom();
        }
      }
    } catch (e, st) {
      debugPrint('[Presence][Error] cleanup failed: $e');
      debugPrint(st.toString());
      ErrorService.instance.report(error: ErrorType.firestore);
    }
  }

  /// Host‐only logic to decide if the room remains:
  /// - Checks room existence and player membership
  /// - Elects new host if needed
  ///
  /// Returns `true` if cleanup should proceed, `false` to abort.
  Future<bool> _handleDisconnect(String disconnectedPlayerId) async {
    try {
      // Only the current host continues
      final snap = await _roomDoc.get();
      if (!snap.exists) {
        debugPrint('[Presence][Error] Room does not exist: $roomId');
        ErrorService.instance.report(error: ErrorType.notFound);
        return false;
      }

      final data = snap.data()!;
      final Map<String, dynamic> players = Map.from(data['players'] ?? {});
      if (!players.containsKey(playerId)) {
        debugPrint(
          '[Cleanup] Player $disconnectedPlayerId not found in room $roomId',
        );
        ErrorService.instance.report(error: ErrorType.notFound);
        return false;
      }
      String? currentHost = data['hostId'] as String?;

      // 1) Host change if needed
      String? newHost = currentHost;
      if (disconnectedPlayerId == currentHost) {
        newHost = _selectNewHost(players, data);
        currentHost = newHost;
      }
      if (currentHost != playerId) return false;

      // 2.5) Host change if needed
      if (newHost != null) {
        _roomDoc.update({'hostId': newHost});
        await FirebaseDatabase.instance
            .ref('games/$roomId/hostId')
            .set(newHost);
      }

      return true;
    } catch (e, st) {
      debugPrint('[Cleanup][Error] failed: $e');
      debugPrint(st.toString());
      return false;
    }
  }

  /// Picks a new host by selecting the player with the earliest `connectedAt` timestamp.
  ///
  /// [remaining]: map of playerIds to presence data
  /// [roomData]: complete room document data
  String _selectNewHost(
    Map<String, dynamic> remaining,
    Map<String, dynamic> roomData,
  ) {
    String selected = remaining.keys.first;
    int? earliest;

    for (final id in remaining.keys) {
      final user = roomData['players'][id] as Map?;
      final ts = user?['connectedAt'] as int?;
      if (ts != null && (earliest == null || ts < earliest)) {
        earliest = ts;
        selected = id;
      }
    }
    return selected;
  }

  /// Manual entry point to perform clean‐up steps as if this player lost connection.
  /// Updates host assignment if needed before cleanup.
  @override
  Future<void> disconnect() async {
    if (!_initialized) {
      debugPrint('[Presence][Error] Cannot disconnect before initialization');
      return;
    }
    _initialized = false;
    _started = false;
    await _disconnectListener?.cancel();
    try {
      final snap = await _roomDoc.get();
      if (!snap.exists) {
        debugPrint('[Presence][Error] Room does not exist: $roomId');
        ErrorService.instance.report(error: ErrorType.notFound);
        return;
      }

      final data = snap.data()!;
      final Map<String, dynamic> players = Map.from(data['players'] ?? {});
      if (!players.containsKey(playerId)) {
        ErrorService.instance.report(error: ErrorType.notFound);
        return;
      }
      String? currentHost = data['hostId'] as String?;

      // 1) Host change if needed
      if (playerId == currentHost) {
        String newHost = _selectNewHost(players, data);
        _roomDoc.update({'hostId': newHost});
        await FirebaseDatabase.instance
            .ref('games/$roomId/hostId')
            .set(newHost);
      }

      await _cleaningUp(true, playerId);
      debugPrint('[Presence] Disconnected for player $playerId');
    } catch (e) {
      debugPrint('[Presence][Error] disconnect failed: $e');
    }
  }

  /// Removes disconnected player’s data from:
  /// - Firestore sync flags
  /// - `players_to_drink` map
  /// - Level‐specific fields in each level document
  /// - `/players` subcollection
  /// - RTDB presence node
  ///
  /// Returns `true` if the entire room should be deleted (no players left),
  /// otherwise `false`.
  Future<bool> _cleanUpPlayerData(String disconnectedPlayerId) async {
    if (!_initialized || disconnectedPlayerId.isEmpty) return false;
    try {
      // Only the current host continues
      final snap = await _roomDoc.get();
      if (!snap.exists) {
        debugPrint('[Presence][Error] Room does not exist: $roomId');
        ErrorService.instance.report(error: ErrorType.notFound);
        return false;
      }

      final data = snap.data()!;
      final Map<String, dynamic> players = Map.from(data['players'] ?? {});
      if (!players.containsKey(playerId)) {
        debugPrint(
          '[Cleanup] Player $disconnectedPlayerId not found in room $roomId',
        );
        ErrorService.instance.report(error: ErrorType.notFound);
        return false;
      }

      // Determine remaining players
      players.remove(disconnectedPlayerId);
      if (players.isEmpty || (_started && players.length < 2)) {
        debugPrint('[Cleanup] Less than 2 players, deleting room $roomId');
        return true;
      }
      // 2)
      await FirebaseFirestore.instance.runTransaction((tx) async {
        tx.update(_syncDoc, {'players.$playerId': FieldValue.delete()});
      });

      final batch = FirebaseFirestore.instance.batch();

      // 3) Remove from players_to_drink map
      batch.update(_roomDoc, {
        'players_to_drink.$disconnectedPlayerId': FieldValue.delete(),
      });

      // 4) Level-specific cleanup
      for (final level in _levels!) {
        final levelRef = _roomDoc.collection('levels').doc(level);
        if (TranslationService.instance.levelKeys.contains(level)) {
          int index = TranslationService.instance.levelKeys.indexOf(level);
          switch (index) {
            case 0:
              batch.update(levelRef, {
                'answers.$disconnectedPlayerId': FieldValue.delete(),
                'player_before_drink.$disconnectedPlayerId':
                    FieldValue.delete(),
              });
              break;
            case 1:
              batch.update(levelRef, {
                'weel_result.$disconnectedPlayerId': FieldValue.delete(),
              });
              break;
            case 2:
              batch.update(levelRef, {
                'answers.$disconnectedPlayerId': FieldValue.delete(),
                'player_before_drink.$disconnectedPlayerId':
                    FieldValue.delete(),
              });

            case 3:
              final levelData = (await levelRef.get()).data() ?? {};
              final targetPlayerId = levelData['targetPlayer'] as String? ?? "";
              final targetAnswer = levelData['target_answer'] ?? "";
              if (targetPlayerId == disconnectedPlayerId &&
                  targetAnswer == "") {
                final items = ['a', 'b', 'c', 'd'];
                final rnd = Random();

                final pick1 = items[rnd.nextInt(items.length)];
                batch.update(levelRef, {'target_answer': pick1});
              } else {
                batch.update(levelRef, {
                  'players_guesses.$disconnectedPlayerId': FieldValue.delete(),
                });
              }
              break;
            case 4:
              final levelData = (await levelRef.get()).data() ?? {};
              final ids = (levelData['playersMoleIds'] as List).cast<String>();
              final names = (levelData['playersMoleNames'] as List)
                  .cast<String>();
              for (int i = 0; i < ids.length; i++) {
                if (ids[i] == disconnectedPlayerId) {
                  ids.remove(ids[i]);
                  names.remove(names[i]);
                }
              }
              batch.update(levelRef, {
                'playersMoleIds': ids,
                'playersMoleNames': names,
                'playerScores.$disconnectedPlayerId': FieldValue.delete(),
              });
              break;
          }
        }
      }

      // 5) Remove from Firestore players subcollection
      batch.delete(_roomDoc.collection('players').doc(disconnectedPlayerId));

      await batch.commit();

      await FirebaseDatabase.instance
          .ref('games/$roomId/players/$disconnectedPlayerId')
          .remove();
      debugPrint('[Presence] Removed RTDB presence for $disconnectedPlayerId');

      debugPrint('[Presence] Cleaned up data for player $playerId');
      return false; // Indicate room should not be deleted
    } catch (e, st) {
      debugPrint('[Presence][Error] cleanup failed: $e');
      debugPrint(st.toString());
      return false; // Indicate room should not be deleted
    }
  }

  /// Deletes the entire Firestore room document and its RTDB subtree
  /// for `/games/{roomId}`.
  Future<void> _cleanUpRoom() async {
    if (!_initialized) return;
    try {
      // Remove the entire room document
      await _roomDoc.delete();
      debugPrint('[Presence] Cleaned up room $roomId');
      // 2) Now delete the RTDB subtree for this room’s players
      final roomRtdbRef = FirebaseDatabase.instance.ref(
        'games/$roomId',
      ); // or wherever your root is
      await roomRtdbRef.remove();
      debugPrint('[Presence] Cleaned up RTDB room $roomId');
    } catch (e, st) {
      debugPrint('[Presence][Error] cleanup failed: $e');
      debugPrint(st.toString());
    }
  }

  /// Cancels subscriptions, triggers disconnect cleanup for self,
  /// and resets internal state.
  @override
  Future<void> dispose() async {
    if (!_initialized) {
      debugPrint('[Presence][Error] Cannot dispose before initialization');
      return;
    }
    await disconnect();
    debugPrint('[Presence] Disposed for player $playerId');
  }
}
