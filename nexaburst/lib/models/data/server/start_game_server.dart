// nexaburst/lib/models/server/start_game_server.dart

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:nexaburst/models/structures/levels/level5/Lv05_model.dart';
import 'package:nexaburst/models/structures/levels/levels_factory.dart';
import 'package:nexaburst/models/structures/player_model.dart';
import 'package:nexaburst/models/structures/room_model.dart';
import 'package:nexaburst/models/structures/sync_model.dart';
import 'package:nexaburst/models/structures/word_event.dart';
import 'package:tuple/tuple.dart';

/// Server‐side orchestration for room lifecycle:
/// - fetching initial state
/// - real‑time streams
/// - room creation and joining logic
/// - forbidden‐words setup
/// - error‐safe operations
class StartGameModel {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Retrieves the room document once for [roomId] and returns its [Room] model.
  static Future<Room> getFirstRoomValue(String roomId) async {
    // 1) read the room document once
    final doc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .get();
    final room = Room.fromJson(doc.data()!);
    return room;
  }

  /// Fetches the initial list of player usernames in [roomId].
  static Future<List<String>> getFirstPlayersValue(String roomId) async {
    // now for players you might want to read the players collection once:
    final initialPlayersSnap = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('players')
        .get();
    final initialNames = initialPlayersSnap.docs
        .map((d) => Player.fromJson(d.data()).username)
        .toList();
    return List<String>.from(initialNames);
  }

  /// Real‑time stream of [Room] updates for [roomId], emitting only existing docs.
  static Stream<Room> roomStream(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .where((snap) => snap.exists)
        .map((snap) => Room.fromJson(snap.data()!));
  }

  /// Real‑time stream of player lists in [roomId], filtering out invalid entries.
  static Stream<List<Player>> playersStream(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('players')
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((d) {
                final data = d.data();
                if (!data.containsKey('username')) return null;
                try {
                  return Player.fromJson(data);
                } catch (_) {
                  return null;
                }
              })
              .whereType<Player>() // filters out nulls
              .toList();
        });
  }

  /// Generates a random 6‑digit room ID and ensures it does not already exist.
  ///
  /// Retries until a unique ID is found.
  static Future<String> generateUniqueRoomId() async {
    String roomId;
    bool exists;
    do {
      roomId = (100000 + Random().nextInt(900000)).toString();
      exists = (await _db.collection('rooms').doc(roomId).get()).exists;
    } while (exists);
    return roomId;
  }

  /// Creates a new room with host [player], initial [room], and per‑level [levels].
  ///
  /// - Writes room and host player documents
  /// - Initializes each level via [GameLevelsInitializationFactory]
  /// - Optionally sets up forbidden‑words docs
  /// - Commits HoleModel docs for Level 5 if detected
  ///
  /// Returns the created room’s ID.
  static Future<String> createRoom({
    /// Host player’s profile for room creation.
    required Player player,

    /// Initial room settings and metadata.
    required Room room,

    /// Mapping of level names to their round counts.
    required Map<String, int> levels,
  }) async {
    final roomRef = _db.collection('rooms').doc(room.roomId);
    final batch = _db.batch();

    bool isLevel05 = false;
    String level05Name = "";
    List<HoleModel> holes = [];

    debugPrint('Room created with ID: $room.roomId');
    debugPrint('Room details: ${room.toJson()}');
    batch.set(roomRef, room.toJson());

    // 2) Create host player document in the /players subcollection with presence data.
    debugPrint('Creating player document for host: ${player.toJson()}');
    final playerDoc = roomRef.collection('players').doc(player.id);
    batch.set(playerDoc, player.toJson());

    // 3) Create level sub-documents.
    for (final levelName in room.levels) {
      debugPrint('Creating level document for: $levelName');
      final levelRef = roomRef.collection('levels').doc(levelName);
      final lv = GameLevelsInitializationFactory.createLevel(
        levelName,
        isDrinkingMode: room.isDrinkingMode,
        levelRound: levels[levelName] ?? 0,
      );
      await lv.initialization();
      if (lv is Lv05WhackMoleModel) {
        debugPrint("level 05 detected...");
        isLevel05 = true;
        level05Name = levelName;
        holes = lv.holes;
      }
      batch.set(levelRef, lv.toJson());
    }

    // 4) Create forbidden words documents if Forbidden Word mode is active.
    if (room.forbiddenWords.isNotEmpty) {
      for (final word in room.forbiddenWords) {
        final lowerCasedWord = word.toLowerCase();
        WordEvent w = WordEvent(word: word);
        debugPrint('Initializing forbidden word document for: $lowerCasedWord');
        // Each forbidden word gets its own document under the 'forbidden_events' subcollection.
        // The document is initialized with an empty 'events' map.
        final forbiddenDocRef = roomRef
            .collection('forbidden_events')
            .doc(lowerCasedWord);
        batch.set(forbiddenDocRef, w.toMap());
      }
    }

    DocumentReference syncDoc = roomRef.collection('sync').doc('game_sync');
    SyncModel model = SyncModel(players: {player.id: false});
    await syncDoc.set(model.toMap());

    // Commit all batched writes at once.
    try {
      await batch.commit();
      if (isLevel05) {
        final levelRef = roomRef.collection('levels').doc(level05Name);
        final batch = _db.batch();
        for (final hole in holes) {
          final holeDoc = levelRef.collection('holes').doc(hole.id.toString());
          batch.set(holeDoc, hole.toJson());
        }

        // 5) Commit atomically
        await batch.commit();
      }
      debugPrint(
        'Room, player, levels, and forbidden word documents created successfully!',
      );

      // For debugging: Fetch the room data after creation and debugPrint it.
      final roomSnap = await roomRef.get();
      if (roomSnap.exists) {
        final roomData = roomSnap.data() as Map<String, dynamic>;
        debugPrint('Room data after creation: $roomData');
      } else {
        debugPrint('Room data not found!');
        ErrorService.instance.report(error: ErrorType.notFound);
      }
    } catch (e) {
      debugPrint('🔥 Batch commit failed: $e');
      ErrorService.instance.report(error: ErrorType.firestore);
    }
    return room.roomId;
  }

  /// Adds or updates [player] in the `/players` subcollection of [roomId].
  ///
  /// Returns a map with:
  /// - `'joined'`: success flag
  /// - `'levels'`: list of level names
  /// - `'isDrinkingMode'`: room’s drinking mode setting
  static Future<Map<String, dynamic>> joinRoom({
    /// Identifier of the room to join.
    required String roomId,

    /// Player profile to add or update.
    required Player player,
  }) async {
    final roomRef = _db.collection('rooms').doc(roomId);
    final roomSnap = await roomRef.get();

    if (!roomSnap.exists) {
      ErrorService.instance.report(error: ErrorType.notFound);
      return {'joined': false, 'levels': [], 'isDrinkingMode': false};
    }

    // Pull current room data.
    final room = Room.fromJson(roomSnap.data()!);

    // Create or update the player's document in the /players subcollection, merging in presence information.
    final playerDocRef = roomRef.collection('players').doc(player.id);
    await playerDocRef.set(player.toJson(), SetOptions(merge: true));

    await roomRef.collection('sync').doc('game_sync').update({
      'players.${player.id}': false,
    });

    return {
      'joined': true,
      'levels': room.levels,
      'isDrinkingMode': room.isDrinkingMode,
    };
  }

  /// Retrieves the forbidden words list and language for [roomId].
  ///
  /// Returns a tuple of `(forbiddenWords, languageCode)`.
  static Future<Tuple2<List<String>, String>> forbiddenWordsCheck({
    /// Identifier of the room to inspect.
    required String roomId,
  }) async {
    final roomRef = _db.collection('rooms').doc(roomId);
    final roomSnap = await roomRef.get();

    if (!roomSnap.exists) {
      ErrorService.instance.report(error: ErrorType.notFound);
      return Tuple2([], 'en');
    }

    // Pull current room data.
    final room = Room.fromJson(roomSnap.data()!);

    return Tuple2(room.forbiddenWords, room.lang);
  }
}
