// nexaburst/lib/model_view/room/waiting_room/start_game_view_model.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/room/waiting_room/start_game_interface.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/server/safe_call.dart';
import 'package:nexaburst/models/data/server/start_game_server.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:nexaburst/models/structures/player_model.dart';
import 'package:nexaburst/models/structures/room_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

/// Concrete logic for waiting‑room interactions.
/// Implements room creation, joining, and real‑time updates via Firestore.
class StartGameViewModelLogic extends IStartGameService {
  /// Local representation of the current user as a `Player` object.
  final Player player = Player(
    id: UserData.instance.user!.id,
    username: UserData.instance.user!.username,
    avatar: UserData.instance.user!.avatar,
    wins: UserData.instance.user!.wins,
  );

  /// The unique ID of the current game room.
  late String roomId;

  /// Prevents repeated initialization of listeners and streams.
  bool _initialized = false;

  /// Guards against multiple subscriptions to Firestore streams.
  bool _startedListener = false;

  late Stream<Room> room$;
  late Stream<List<Player>> players$;

  /// Subjects exposing live updates for host ID, player list, and room status.
  late BehaviorSubject<String> hostId$;
  late BehaviorSubject<List<String>> playerNames$;
  late BehaviorSubject<RoomStatus> status$;

  StreamSubscription<RoomStatus>? _subStatus;
  StreamSubscription<String>? _subHost;
  StreamSubscription<List<String>>? _subPlayers;

  StartGameViewModelLogic();

  /// Sets up local state and prepares subjects. Must be called with a valid [roomId].
  @override
  void initialization({required String roomId}) {
    if (_initialized) return;
    this.roomId = roomId;
    hostId$ = BehaviorSubject<String>();
    playerNames$ = BehaviorSubject<List<String>>();
    status$ = BehaviorSubject<RoomStatus>();
    _initialized = true;
  }

  /// Returns the current [roomId] or empty string if uninitialized.
  @override
  String getRoomId() {
    if (!_initialized) return '';
    return roomId;
  }

  /// Internal helper that subscribes to room, players, and status streams
  /// and pushes updates into the corresponding subjects.
  Future<void> _startListener() async {
    if (!_initialized) {
      debugPrint(
        'StartGameViewModelLogic not initialized. Call initialization() first.',
      );
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    if (_startedListener) return;
    _startedListener = true;

    final Room? initialRoom = await safeCall<Room?>(
      () => StartGameModel.getFirstRoomValue(roomId),
      fallbackValue: null,
    );
    if (initialRoom == null) {
      return;
    }

    final List<String>? initialNames = await safeCall<List<String>?>(
      () => StartGameModel.getFirstPlayersValue(roomId),
      fallbackValue: <String>[],
    );

    hostId$.add(initialRoom.hostId);
    status$.add(initialRoom.status);
    playerNames$.add(List<String>.from(initialNames ?? <String>[]));

    room$ = StartGameModel.roomStream(roomId).asBroadcastStream();
    players$ = StartGameModel.playersStream(roomId).asBroadcastStream();

    // Subscribe to reactive room updates after seeding initial values.
    _subHost = room$
        .map((r) => r.hostId)
        .distinct()
        .listen(
          hostId$.add,
          onError: (error) {
            // Handle errors from the room stream
            ErrorService.instance.report(error: ErrorType.firestore);
          },
        );

    _subPlayers = players$
        .map((list) => list.map((p) => p.username).toList())
        .distinct((prev, next) {
          if (prev.length != next.length) return false;
          for (int i = 0; i < prev.length; i++) {
            if (prev[i] != next[i]) return false;
          }
          return true;
        })
        .listen(
          (names) {
            try {
              playerNames$.add(List<String>.from(names));
            } catch (e) {
              ErrorService.instance.report(error: ErrorType.invalidInput);
            }
          },
          onError: (error) {
            ErrorService.instance.report(error: ErrorType.firestore);
          },
        );
    _subStatus = room$
        .map((r) => r.status)
        .distinct()
        .listen(
          status$.add,
          onError: (error) {
            // Handle errors from the room stream
            ErrorService.instance.report(error: ErrorType.firestore);
          },
        );
  }

  /// Attempts to join the initialized room via the server model.
  /// On success, starts listening for updates.
  ///
  /// Returns `true` if join succeeded.
  @override
  Future<bool> joinRoom() async {
    if (!_initialized) {
      debugPrint(
        'StartGameViewModelLogic not initialized. Call initialization() first.',
      );
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return false;
    }

    // Guard network errors and Firestore exceptions via safeCall.
    final Map<String, dynamic>? result = await safeCall<Map<String, dynamic>?>(
      () => StartGameModel.joinRoom(roomId: roomId, player: player),
      fallbackValue: null,
    );

    if (result == null || result['joined'] != true) {
      // Join failed either due to backend errors or explicit rejection.
      return false;
    }

    await _startListener();
    return true;
  }

  /// Generates a room ID, builds a `Room` model, and requests creation on the server.
  /// On success, initializes and starts listeners.
  ///
  /// Returns `true` if creation succeeded.
  @override
  Future<bool> createRoom({
    required Map<String, int> levels,
    required List<String> forbiddenWords,
    required bool isDrinkingMode,
    required String lang,
  }) async {
    if (levels.isEmpty) {
      // Creating an empty level sequence is not a valid room state.
      return false;
    }

    // Generate a unique room ID before creating any room documents.
    final String? newRoomId = await safeCall<String?>(
      () => StartGameModel.generateUniqueRoomId(),
      fallbackValue: null,
    );
    if (newRoomId == null) {
      // Abort early when ID generation fails.
      return false;
    }

    // Build the room payload that will be stored in Firestore.
    initialization(roomId: roomId = newRoomId);
    final room = Room(
      roomId: roomId,
      hostId: player.id,
      isDrinkingMode: isDrinkingMode,
      isForbiddenWordMode: forbiddenWords.isNotEmpty,
      forbiddenWords: forbiddenWords,
      status: RoomStatus.waiting,
      levels: levels.keys.toList(),
    );

    // Persist the room and level data.
    final String? createdId = await safeCall<String?>(
      () =>
          StartGameModel.createRoom(player: player, room: room, levels: levels),
      fallbackValue: null,
    );

    if (createdId == null) {
      // Backend room creation failed.
      return false;
    }

    // Start listeners after room creation succeeds.
    await _startListener();
    return true;
  }

  /// Cancels all subscriptions and closes subjects.
  @override
  void dispose() {
    if (!_initialized) return;
    _initialized = false;

    _subHost?.cancel();
    _subPlayers?.cancel();
    _subStatus?.cancel();

    hostId$.close();
    playerNames$.close();
    status$.close();

    _startedListener = false;
  }

  /// Checks forbidden‑words settings before allowing microphone access.
  ///
  /// Returns a tuple of (forbiddenWords, languageCode).
  @override
  Future<Tuple2<List<String>, String>> preJoiningMicPremission() async {
    // Provide a fallback tuple so callers always receive a usable value.
    final Tuple2<List<String>, String>? result =
        await safeCall<Tuple2<List<String>, String>?>(
          () => StartGameModel.forbiddenWordsCheck(roomId: roomId),
          fallbackValue: Tuple2([], 'en'),
        );

    return result!; // safeCall fallback ensures a non-null value here.
  }

  /// Transitions the room’s status to “playing” on the server.
  @override
  Future<void> start() async {
    if (!_initialized) {
      debugPrint(
        'StartGameViewModelLogic not initialized. Call initialization() first.',
      );
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }

    // Even a simple update can fail; wrap in safeCall (fallback = nothing)
    await safeCall<void>(
      () => FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'status': RoomStatus.playing.toServerString(),
      }),
      fallbackValue: null,
    );
  }

  /// Provides a stream of the host’s player ID, ensuring listeners are active.
  @override
  Stream<String> watchRoomHost() {
    if (!_initialized) {
      debugPrint(
        'StartGameViewModelLogic not initialized. Call initialization() first.',
      );
      ErrorService.instance.report(error: ErrorType.notInitialized);
    }
    _startListener();
    return hostId$.stream;
  }

  /// Provides a stream of the room’s status, ensuring listeners are active.
  @override
  Stream<RoomStatus> watchRoomStatus() {
    if (!_initialized) {
      debugPrint(
        'StartGameViewModelLogic not initialized. Call initialization() first.',
      );
      ErrorService.instance.report(error: ErrorType.notInitialized);
    }
    _startListener();
    return status$.stream;
  }

  /// Provides a stream of current player usernames, ensuring listeners are active.
  @override
  Stream<List<String>> watchPlayers() {
    if (!_initialized) {
      debugPrint(
        'StartGameViewModelLogic not initialized. Call initialization() first.',
      );
      ErrorService.instance.report(error: ErrorType.notInitialized);
    }
    _startListener();
    return playerNames$.stream;
  }
}
