// nexaburst/lib/models/server/game_manager_models/game_manager_model.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/models/data/server/game_manager_models/game_manager_interface.dart';
import 'package:nexaburst/models/data/server/safe_call.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:nexaburst/models/structures/room_model.dart';

/// Manages the Firestore room lifecycle:
/// loads initial state, streams status changes, and exposes game actions.
class MainGameModel implements GameManagerInterface {
  /// Indicates whether `initialize()` has been successfully called.
  bool _initialized = false;

  /// Identifier of the Firestore room being managed.
  late String roomId;

  /// Cached snapshot of the current room data.
  Room? room;

  /// Subscription for real‑time room document updates.
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSub;

  /// Broadcasts room status changes to listeners.
  late StreamController<RoomStatus> _statusController;

  /// Stream emitting new [RoomStatus] whenever it changes.
  @override
  Stream<RoomStatus> get statusStream => _statusController.stream;

  /// Firestore client for room operations.
  final _firestore = FirebaseFirestore.instance;

  /// Reference to the Firestore `/rooms/{roomId}` document.
  late DocumentReference<Map<String, dynamic>> _roomDoc;

  /// Loads the room once for initial state and marks the model ready.
  ///
  /// Returns the loaded [Room], or `null` if not found or already initialized.
  @override
  Future<Room?> initialize({required String roomId}) async {
    if (_initialized) return null;

    this.roomId = roomId;
    _statusController = StreamController<RoomStatus>.broadcast();
    _roomDoc = _firestore.collection('rooms').doc(roomId);
    return await safeCall(() async {
      final snap = await _roomDoc.get();
      if (!snap.exists) {
        debugPrint('MainGameModel.initialize: room $roomId does not exist');
        ErrorService.instance.report(error: ErrorType.notFound);
        return null;
      }
      room = Room.fromJson(snap.data()!);
      _initialized = true;
      return room;
    }, fallbackValue: null);
  }

  /// Subscribes to real‑time updates on the room document,
  /// emitting status changes and caching new data.
  @override
  void startListener() {
    if (!_initialized) {
      debugPrint('Cannot startListener before initialize() has completed');
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }

    RoomStatus? lastStatus = room?.status;

    _roomSub = _roomDoc.snapshots().listen(
      (snap) {
        if (!snap.exists) {
          ErrorService.instance.report(error: ErrorType.notFound);
          return;
        }
        final updated = Room.fromJson(snap.data()!);

        // cache
        room = updated;

        // emit only when status changed
        if (updated.status != lastStatus) {
          lastStatus = updated.status;
          _statusController.add(updated.status);
        }
      },
      onError: (err) {
        debugPrint('MainGameModel.startListener error: $err');
        ErrorService.instance.report(error: ErrorType.firestore);
        return;
      },
    );
  }

  /// Cancels all subscriptions and closes the status stream.
  @override
  Future<void> clean() async {
    if (!_initialized) return;

    _initialized = false;
    await _roomSub?.cancel();
    _roomSub = null;

    if (!_statusController.isClosed) {
      await _statusController.close();
    }
  }

  /// Fetches the `/players` subcollection once,
  /// returning a map of `playerId` to player data.
  @override
  Future<Map<String, dynamic>?> getPlayers() async {
    if (!_initialized) {
      debugPrint('Cannot getPlayers before initialize() has completed');
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return null;
    }
    return await safeCall(() async {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('players')
          .get();

      // Build a map where the key is playerId and the value is the document data.
      Map<String, dynamic> players = {};
      for (var doc in snapshot.docs) {
        players[doc.id] = doc.data();
      }
      return players;
    }, fallbackValue: null);
  }

  /// Updates the room’s `status` field to [status] on the server.
  @override
  Future<void> endGame(RoomStatus status) async {
    if (!_initialized) {
      debugPrint('Cannot endGame before initialize() has completed');
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    await safeCall(() => _roomDoc.update({'status': status.toServerString()}));
  }

  /// Deletes the room document if the current user is the host.
  @override
  Future<void> deleteRoomIfHost() async {
    await safeCall(() async {
      final snap = await _roomDoc.get();
      if (!snap.exists) {
        ErrorService.instance.report(error: ErrorType.notFound);
        return;
      }
      await _roomDoc.delete();
    });
  }
}
