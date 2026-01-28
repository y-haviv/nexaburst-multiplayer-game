// nexaburst/lib/models/server/modes/drinking/drink_model.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/server/modes/drinking/drinking_game.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:rxdart/rxdart.dart';

/// Real implementation of [DrinkingGame], syncing the
/// `players_to_drink` map from Firestore and exposing it as a stream.
class DrinkModel implements DrinkingGame {
  /// Maximum time to wait for the first non‑empty players map.
  Duration timeout = const Duration(seconds: 10);

  /// Firestore client for reading and updating room documents.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Emits the current `players_to_drink` mapping whenever it changes.
  late BehaviorSubject<Map<String, String>> _controller;

  /// Subscription to the room document snapshots.
  late StreamSubscription _roomDocSub;

  /// ID of the room whose drinking state is synced.
  String? roomId; // Unique identifier of the room (as a string)
  /// Tracks whether initialization has completed.
  bool _initialized = false;

  /// Stream of the latest `players_to_drink` map keyed by player ID.
  @override
  BehaviorSubject<Map<String, String>> get stream => _controller;

  /// Begins listening to Firestore for `players_to_drink` updates.
  ///
  /// [roomId]: the Firestore room document ID to watch.
  @override
  void initialization({required String roomId}) {
    if (_initialized) return;
    _controller = BehaviorSubject<Map<String, String>>();
    this.roomId = roomId; // במקום roomId = roomId;
    final docRef = _firestore.collection('rooms').doc(roomId);
    _roomDocSub = docRef.snapshots().listen((snap) {
      if (!snap.exists) {
        ErrorService.instance.report(error: ErrorType.notFound);
      }
      final data = snap.data() ?? {};
      final raw = (data['players_to_drink'] as Map?) ?? {};
      final map = raw.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );

      _controller.add(map);
      if (!_initialized) {
        _initialized = true;
      }
    });
  }

  /// Awaits until the first non‑empty map is emitted, or [timeout] elapses.
  @override
  Future<void> waitUntilInitialized() async {
    if (_initialized) return;

    await Future.any([
      stream.firstWhere((map) => map.isNotEmpty),
      Future.delayed(timeout),
    ]);
  }

  /// Cancels Firestore subscription and closes the stream.
  @override
  void dispose() {
    if (!_initialized) return;
    _roomDocSub.cancel();
    _controller.close();
    _initialized = false;
  }

  /// Deletes this player’s entry from the room’s `players_to_drink` map
  /// in Firestore via a transaction.
  ///
  /// No‑op if not initialized.
  @override
  Future<void> removeFromPlayersToDrink() async {
    if (!_initialized) return;
    try {
      final docRef = _firestore.collection('rooms').doc(roomId);
      final userId = UserData.instance.user?.id;
      if (userId == null) {
        ErrorService.instance.report(error: ErrorType.invalidInput);
        return;
      }

      await _firestore.runTransaction((tx) async {
        tx.update(docRef, {'players_to_drink.$userId': FieldValue.delete()});
      });
    } catch (e) {
      debugPrint("problem server drink model: $e");
      ErrorService.instance.report(error: ErrorType.firestore);
    }
  }
}
