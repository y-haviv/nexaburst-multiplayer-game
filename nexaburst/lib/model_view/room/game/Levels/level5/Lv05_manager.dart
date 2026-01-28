// nexaburst/lib/model_view/room/game/levels/level5/Lv05_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/Levels/levels_interface.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/room/sync_manager.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/models/data/server/levels/level5/lv05.dart';
import 'package:nexaburst/models/data/server/safe_call.dart';
import 'package:nexaburst/models/data/service/loading_controller.dart';
import 'package:nexaburst/model_view/room/game/modes/drinking/drinking_manager.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';

/// UI states for the Whack‑a‑Mole stage:
/// - `game`: show mole or whacking prompt
/// - `switchMole`: display score and next mole turn
/// - `drinkingMode`: handle drinking penalties
enum Lv05WhackAMoleState { game, switchMole, drinkingMode }

/// Carries a state transition and optional data for the Stage UI.
///
/// [state]: target `Lv05WhackAMoleState`.<br>
/// [payload]: additional parameters (e.g., isMole flag, score).
class Lv05WhackAMoleStageCommand {
  final Lv05WhackAMoleState state;
  final dynamic payload;
  Lv05WhackAMoleStageCommand({required this.state, this.payload});
}

/// Coordinates the Whack‑a‑Mole game logic:
/// initializes the model, runs rounds, handles scoring,
/// synchronization, and drinking mode.
class Lv05ReflexStageManager extends LevelLogic {
  /// Backend controller for hole states and player actions.
  final Lv05 controller;

  /// Firestore game room identifier.
  final String roomId; // Unique identifier of the room (as a string)
  /// ID of the current player.
  final String playerId = UserData
      .instance
      .user!
      .id; // Unique identifier of the current player (as a string)
  /// Whether drinking penalties are enabled for this stage.
  final bool isDrinkingMode; // Whether the game is in drinking mode or not.
  /// Translation key for this level’s name.
  static final String levelName = TranslationService.instance.levelKeys[4];

  /// Localized prompt for the drinking screen.
  final String drinking;

  /// Prevents multiple invocations of `runLevel()`.
  bool _isStarted =
      false; // Added flag to check if the loop has already started.
  /// Number of player turns (rounds) to execute.
  final int rounds;

  /// Emits `Lv05WhackAMoleStageCommand` events for UI state changes.
  final StreamController<Lv05WhackAMoleStageCommand> _commandController =
      StreamController<Lv05WhackAMoleStageCommand>.broadcast();
  Stream<Lv05WhackAMoleStageCommand> get commandStream =>
      _commandController.stream;

  /// Completes when the player finishes the drinking screen.
  Completer<void>? _overDrink;

  /// Constructs manager with room config, controller instance, and optional round count.
  Lv05ReflexStageManager({
    required this.isDrinkingMode,
    required this.roomId,
    required this.controller,
    this.rounds = LevelsRounds.defaultlevelRounds,
  }) : drinking = TranslationService.instance.t(
         'game.levels.$levelName.drink_penalty',
       ) {
    debugPrint("Lv05 manager created [hashCode: $hashCode].");
  }

  /// Returns the instruction text provided by the controller.
  @override
  String getInstruction() {
    return controller.getInstruction();
  }

  /// Main loop: for each round, show game or whack UI, switch mole, display score,
  /// sync with server, and handle drinking screens.
  @override
  Future<void> runLevel() async {
    if (_isStarted) {
      debugPrint("startGameLoop() already called, ignoring duplicate call.");
      return;
    }
    _isStarted = true;
    LoadingService().show(
      TranslationService.instance.t(
        'game.levels.$levelName.loading_messages.loading1',
      ),
    );
    await SyncManager.instance.synchronizePlayers(controller.initializeGame);
    LoadingService().show(
      TranslationService.instance.t(
        'game.levels.$levelName.loading_messages.loading2',
      ),
    );

    debugPrint("Lv05 manager Starting level loop [hashCode: $hashCode]...");

    // Loop through the rounds
    // while stream end != true (using lv05whackamole)
    for (int round = 0; round < rounds; round++) {
      // 1) Game phase: show question
      while (true) {
        debugPrint("Starting round $round");
        LoadingService().show(
          TranslationService.instance.t(
            'game.levels.$levelName.loading_messages.loading3',
          ),
        );
        bool isMole = false;
        try {
          isMole = await controller.playerMole.first;
        } catch (e) {
          debugPrint("Error getting player mole status: $e");
          ErrorService.instance.report(error: ErrorType.firestore);
          break; // Exit the loop if there's an error
        }

        final gamePayload = {'isMole': isMole};
        // Wait until the UI done
        await timerManage(
          ScreenDurations.level05PerPlayerTime,
          Lv05WhackAMoleState.game,
          gamePayload,
        );

        debugPrint("switch mole...");
        LoadingService().show(
          TranslationService.instance.t(
            'game.levels.$levelName.loading_messages.loading4',
          ),
        );

        // Reset the round data in the model.
        await SyncManager.instance.synchronizePlayers(controller.resetRound);

        // 2) SwitchMole phase: show score
        int score = await safeCall(
          () => controller.getPlayerScore(),
          fallbackValue: 0,
        );
        final scorePayload = {'scoreIncrement': score};
        await timerManage(
          ScreenDurations.resultTime,
          Lv05WhackAMoleState.switchMole,
          scorePayload,
        );
        LoadingService().show(
          TranslationService.instance.t(
            'game.levels.$levelName.loading_messages.loading2',
          ),
        );

        debugPrint("End of round $round");

        round += 1;
        // Check end flag
        final ended = controller.checkEndLevel();
        if (ended) break;
        await SyncManager.instance.synchronizePlayers();
      }

      // 8. Handle drinking/waiting screens.
      await drinkHandel();
    }
  }

  /// Synchronizes players, emits a UI state command, and returns success.
  Future<bool> _updateState(
    Lv05WhackAMoleState state, [
    dynamic payload,
  ]) async {
    if (!await SyncManager.instance.synchronizePlayers()) return false;
    if (_commandController.isClosed) return false;
    _commandController.add(
      Lv05WhackAMoleStageCommand(state: state, payload: payload),
    );
    return true;
  }

  /// If drinking mode is active, displays drinking or waiting UI
  /// until all required players have completed.
  Future<void> drinkHandel() async {
    debugPrint(
      "start drink function in case handeling drink stats is nessery...",
    );
    if (isDrinkingMode) {
      DrinkingStageManager().setDrinkMessage(drinking);
      _overDrink = Completer<void>();
      if (await _updateState(Lv05WhackAMoleState.drinkingMode, {
        'onDrinkComplete': () async {
          if (_overDrink != null && !_overDrink!.isCompleted) {
            _overDrink!.complete();
          }
        },
      })) {
        await Future.any([_overDrink!.future]);
      }
      _overDrink = null;
    }
  }

  /// Starts a countdown of [time] seconds, emits a UI state, and awaits completion.
  Future<void> timerManage(
    int time,
    Lv05WhackAMoleState state, [
    dynamic payload,
  ]) async {
    final done = TimerManager.instance.start(time);
    if (!await _updateState(state, payload)) return;
    await done;
  }

  /// Cleans up controller subscriptions and closes the command stream.
  void dispose() {
    controller.dispose();
    _commandController.close();
  }
}
