// nexaburst/lib/model_view/room/game/game_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/Levels/level_factory/game_levels_factory_manager.dart';
import 'package:nexaburst/model_view/room/game/Levels/levels_interface.dart';
import 'package:nexaburst/model_view/room/game/presence_view_model.dart';
import 'package:nexaburst/model_view/room/sync_manager.dart';
import 'package:nexaburst/debug/fake_models/fake_main_manager.dart';
import 'package:nexaburst/models/data/server/game_manager_models/game_manager_interface.dart';
import 'package:nexaburst/models/data/server/game_manager_models/game_manager_model.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/models/data/service/loading_controller.dart';
import 'package:nexaburst/model_view/room/game/modes/drinking/drinking_manager.dart';
import 'package:nexaburst/model_view/room/game/modes/forbiden_words/forbiden_words_manager.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/structures/room_model.dart';

/// Represents the various UI screens/states during gameplay.
enum GameScreenState {
  instructions,
  stage,
  finalSummary,
  gameOver,
  drinkingMode,
}

/// Encapsulates a state transition command for the main game loop.
///
/// [state]: target UI state.<br>
/// [payload]: optional data for that state.
class MainGameManagerCommand {
  final GameScreenState state;
  final dynamic payload;
  MainGameManagerCommand({required this.state, this.payload});
}

/// Orchestrates the overall game flow:
/// initialization, synchronization, level looping, and UI commands.
class MainGameManager {
  /// Singleton instance for centralized game management.
  static final MainGameManager _instance = MainGameManager._internal();
  factory MainGameManager() => _instance;

  /// Private constructor for the singleton pattern.
  MainGameManager._internal();

  /// Durations (in seconds) for drinking, instruction, and result screens.
  final int remainingDrinkingTime =
      ScreenDurations.drinkScreenTime; // Remaining time for the drink screen.
  final int instructionsTime = ScreenDurations.instructionsTime;
  final int resultTime = ScreenDurations.finalResultTime;

  /// Flags tracking whether initialization and main loop have started.
  bool _initialized = false;
  bool _isStarted =
      false; // Added flag to check if the loop has already started.

  /// Index of the current level within the room's level list.
  int _currentLevelIndex = 0;

  /// Identifier of the active game room.
  late String roomId;

  /// Cached room data loaded from the model.
  Room? room;

  /// Underlying model interface and optional forbidden‑words manager.
  late GameManagerInterface _model;
  late ForbiddenWordsModManager forbiddenWordsModManager;

  /// Controller and stream for sending UI navigation commands.
  late StreamController<MainGameManagerCommand> _commandController;
  Stream<MainGameManagerCommand> get commandStream => _commandController.stream;

  /// Controller and stream for broadcasting room status updates.
  late StreamController<RoomStatus> _statusController;
  Stream<RoomStatus> get statusStream => _statusController.stream;

  /// Subscription to the model’s status stream.
  late StreamSubscription<RoomStatus> _modelSub;

  Completer<void>? _over;
  Completer<void>? _overDrink;

  /// Sets up sync and presence, loads room data, and begins live status listening.
  ///
  /// [roomId]: the ID of the room to manage.
  Future<void> initialize({required String roomId}) async {
    if (_initialized || _isStarted) return;
    _initialized = true;
    _isStarted = false;

    this.roomId = roomId;
    _commandController = StreamController<MainGameManagerCommand>.broadcast();
    _statusController = StreamController<RoomStatus>.broadcast();

    SyncManager.instance.init(roomId: roomId);
    await PresenceManager.init(roomId: roomId);

    final bool dm = debug;
    if (dm) {
      //bool.fromEnvironment('DEBUG_MODE', defaultValue: false)) {
      _model = FakeMainManager();
    } else {
      _model = MainGameModel();
    }

    room = await _model.initialize(roomId: roomId);
    _model.startListener();
    if (room == null) {
      debugPrint("Main game manager: game room is NULL...");
    } else {
      if (room!.isForbiddenWordMode) {
        forbiddenWordsModManager = ForbiddenWordsModManager();
        forbiddenWordsModManager.initialize(room: room!);
        debugPrint("Main game manager: initialized forbidden words mode.");
      }
    }

    // --- Start live listening for status changes ---
    // CORRECT: always compare to the previous status, not the controller itself
    RoomStatus? lastStatus;

    // Forward every status update from the model into our own controller.
    _modelSub = _model.statusStream.listen(
      (status) async {
        if (status != lastStatus) {
          lastStatus = status;
          _statusController.add(status);

          // if room just ended, wait & clean up
          if (status == RoomStatus.over) {
            await Future.delayed(const Duration(seconds: 3));
            await SyncManager.instance.synchronizePlayers(_deleteRoomIfHost);
          }
        }
      },
      onError: (e) {
        _statusController.addError(e);
        debugPrint("Error in model status stream: $e");
      },
    );
  }

  /// Disconnects presence and returns success status.
  Future<bool> disconnect() async {
    if (!_initialized) return true;
    await PresenceManager.instance.disconnect();
    debugPrint("Presence disconnected.");
    return true;
  }

  /// Starts listening for forbidden‑words events if enabled.
  Future<void> _streamForbiddenWords() async {
    try {
      // Start detection and listening.
      forbiddenWordsModManager.startForbidenWordsListener();
    } catch (e) {
      debugPrint("Error stream forbiden words: $e");
    }
  }

  /// Signals that the UI is ready, then starts the main game loop.
  Future<void> setUIReady() async {
    if (!_isStarted && _initialized) {
      PresenceManager.instance.start();
      if (room!.isForbiddenWordMode) _streamForbiddenWords();
      if (room!.isDrinkingMode) {
        DrinkingStageManager().init(
          roomId: roomId,
          isDrinkingMode: room!.isDrinkingMode,
        );
      }
      debugPrint("UI is ready. Starting game loop...");
      _startGameLoop();
    } else {
      debugPrint("startGameLoop() already called, ignoring duplicate call.");
      return;
    }
  }

  /// Core loop that runs each level in sequence, handling instructions,
  /// gameplay, results, and final summary.
  Future<void> _startGameLoop() async {
    if (_isStarted) return;
    _isStarted = true;
    debugPrint("Starting game loop [hashCode: $hashCode]...");
    _currentLevelIndex = 0;

    // The players list is now retrieved from the /players subcollection.
    Map<String, dynamic>? players = {};

    try {
      await SyncManager.instance.synchronizePlayers();
      debugPrint("Synchronization complete; proceeding with round.");
    } catch (e) {
      debugPrint("Synchronization failed: $e");
      // Handle error (retry, timeout, or abort game)
    }

    while (_currentLevelIndex < room!.levels.length) {
      LoadingService().show(
        TranslationService.instance.t(
          'game.load_messages.loading_instructions',
        ),
      );
      String currentLevel = room!.levels[_currentLevelIndex];
      LevelLogic stageLogic;
      debugPrint(
        "\nGame Manager - Creating logic object for stage: $currentLevel\n",
      );
      // 1. Create and run the stage using the factory.
      stageLogic = await GameLevelsFactoryManager.instance.create(
        levelName: currentLevel,
        roomId: roomId,
        isDrinkingMode: room!.isDrinkingMode,
      );

      debugPrint(
        "\nGame Manager - Show instructions for the stage (screen time: $instructionsTime seconds)",
      );
      debugPrint("Instructions: ${stageLogic.getInstruction()}\n");
      // 2. Create and store a completer so that the UI can signal completion.
      // instraction for the level - instraction screen
      final instructionsPayload = {'instructions': stageLogic.getInstruction()};
      debugPrint("Waiting for instructions screen to finish...");
      await timerManage(
        instructionsTime,
        GameScreenState.instructions,
        instructionsPayload,
      );
      debugPrint("Instructions screen finished.");

      // 3.
      // in case needed - drink mode - if one of the pleyer or more need to drink -
      // so the pleyer thet need to drink go to drink screen
      // and player that dont need to drink but detect other players that need to drink go to wait screen
      await drinkHandel();
      LoadingService().show(
        TranslationService.instance.t('game.load_messages.loading_level'),
      );
      debugPrint("\nGame Manager - Starting level: $currentLevel\n");
      // 4. After the stage completes, show the stage UI.
      // go to each of the level and let there manager take controll on the logic and ui(screens).
      final levelPayload = {
        'stageName': currentLevel,
        'Level': stageLogic,
        'onLevelComplete': () async {
          if (_over != null && !_over!.isCompleted) {
            _over!.complete();
          }
        },
      };
      if (await _updateState(GameScreenState.stage, levelPayload)) {
        _over = Completer<void>();
        await Future.any([_over!.future]);
        _over = null;
      }

      // 5. again just in case thet need to handel drink logic and screens...
      await drinkHandel();

      // 6. Retrieve players from the players subcollection.
      debugPrint(
        "\nGame Manager - Level complete: $currentLevel. Now showing result screen (duration: $resultTime seconds)\n",
      );

      // Build a map where the key is playerId and the value is the document data.
      players = await _model.getPlayers();

      if (_currentLevelIndex < room!.levels.length - 1 && players != null) {
        final finalSummaryPayload = {'players': players};
        await timerManage(
          resultTime,
          GameScreenState.finalSummary,
          finalSummaryPayload,
        );
      } else {
        break;
      }

      _currentLevelIndex++;
    }

    debugPrint(
      "\nGame Manager - All levels complete. Showing game over screen (duration: $resultTime seconds)\n",
    );
    if (players!.isNotEmpty) {
      // finaly show the final screen (winner of the game)
      // and then end the game...
      // Determine the winner by comparing players' total_score from their individual documents.
      final winnerEntry = players.entries.reduce((a, b) {
        return (a.value['total_score'] as int) > (b.value['total_score'] as int)
            ? a
            : b;
      });
      final finalPayload = {
        'players': players,
        'winner': [winnerEntry.key],
      };
      if (winnerEntry.key == UserData.instance.user!.id) {
        await upadteWinner();
      }
      await timerManage(resultTime, GameScreenState.gameOver, finalPayload);
    }

    await SyncManager.instance.synchronizePlayers(
      () => endGame(RoomStatus.over),
    );
    debugPrint("Game over. Ending game...");
  }

  /// Helper to synchronize players and emit a UI command.
  ///
  /// Returns false if sync failed or stream is closed.
  Future<bool> _updateState(GameScreenState state, [dynamic payload]) async {
    if (!await SyncManager.instance.synchronizePlayers()) return false;
    if (_commandController.isClosed) return false;
    _commandController.add(
      MainGameManagerCommand(state: state, payload: payload),
    );
    return true;
  }

  /// Returns the current number of players in the room.
  Future<int> getPlayers() async {
    int ans = 0;
    if (!_initialized) return ans;
    ans = (await _model.getPlayers())?.length ?? ans;
    return ans;
  }

  /// Increments the win count of the current user.
  Future<void> upadteWinner() async {
    await UserData.instance.incrementWins();
  }

  /// Signals the model to end the game with the given [status].
  Future<void> endGame(RoomStatus? status) async {
    // Update the room status to 'over'.
    await _model.endGame(status ?? RoomStatus.over);
  }

  /// Deletes the room document if this player is the host.
  Future<void> _deleteRoomIfHost() async {
    await _model.deleteRoomIfHost();
  }

  /// Cancels subscriptions, stops managers, and resets internal flags.
  void dispose() async {
    if (!_initialized) return;
    _modelSub.cancel();
    _model.clean();
    if (room!.isForbiddenWordMode) forbiddenWordsModManager.stopForbidenWords();
    await PresenceManager.instance.dispose();
    if (room!.isDrinkingMode) DrinkingStageManager().finalDispose();
    SyncManager.instance.synchronizePlayers(_deleteRoomIfHost).then((_) {
      SyncManager.instance.clear();
    });
    _commandController.close();
    _statusController.close();
    _initialized = false;
    _isStarted = false;
  }

  /// Displays a timed screen for [time] seconds at [state], with optional [payload].
  Future<void> timerManage(
    int time,
    GameScreenState state, [
    dynamic payload,
  ]) async {
    final done = TimerManager.instance.start(time);
    if (!await _updateState(state, payload)) return;
    await done;
  }

  /// Handles drinking‑mode screens, waiting for completion callback.
  Future<void> drinkHandel() async {
    debugPrint(
      "start drink function in case handeling drink stats is nessery...",
    );
    if (room!.isDrinkingMode) {
      await _updateState(GameScreenState.drinkingMode, {
        'onDrinkComplete': () async {
          if (_overDrink != null && !_overDrink!.isCompleted) {
            _overDrink!.complete();
          }
        },
      });
      _overDrink = Completer<void>();
      await Future.any([_overDrink!.future]);
      _overDrink = null;
    }
  }
}
