// nexaburst/lib/model_view/room/game/levels/level4/Lv04_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/Levels/levels_interface.dart';
import 'package:nexaburst/model_view/room/sync_manager.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/models/data/server/levels/level4/lv04.dart';
import 'package:nexaburst/models/data/server/safe_call.dart';
import 'package:nexaburst/models/data/service/loading_controller.dart';
import 'package:nexaburst/model_view/room/game/modes/drinking/drinking_manager.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:tuple/tuple.dart';

/// UI states for the Social (Level 4) stage:
/// - `targetQuestion`: target answers a prompt
/// - `guessQuestion`: others guess the target’s answer
/// - `result`: show round summary
/// - `loading`: loading/synchronization screen
/// - `drinkingMode`: handle drinking penalties
enum Lv04SocialState {
  /// Display the question and answer UI.
  targetQuestion,

  guessQuestion,

  /// Display the private results for the stage.
  result,

  loading,

  drinkingMode,
}

/// Carries a state transition command for Level 4 UI.
///
/// [state]: the target `Lv04SocialState`.<br>
/// [payload]: optional data (e.g., scenario text, callbacks).
class Lv04SocialStageCommand {
  final Lv04SocialState state;
  final dynamic payload;
  Lv04SocialStageCommand({required this.state, this.payload});
}

/// Manages the “Social” stage:
/// selects a target, collects guesses, processes scores,
/// synchronizes players, and handles drinking mode.
class Lv04SocialStageManager extends LevelLogic {
  /// Backend model for scenario loading and answer submission.
  late Lv04 lv04social;

  /// Firestore game room document ID.
  final String roomId; // Unique identifier of the room (as a string)
  /// Current player’s unique identifier.
  final String playerId = UserData
      .instance
      .user!
      .id; // Unique identifier of the current player (as a string)
  /// Indicates whether drinking penalties are active.
  final bool isDrinkingMode; // Whether the game is in drinking mode or not.
  /// Translation key for this level’s name.
  static final String levelName = TranslationService.instance.levelKeys[3];

  /// Localized prompt shown when asking the player to drink.
  final String drinking;

  /// Prevents multiple invocations of `runLevel()`.
  bool _isStarted =
      false; // Added flag to check if the loop has already started.
  /// Number of social rounds to execute.
  final int rounds;

  /// Emits `Lv04SocialStageCommand` events for UI updates.
  final StreamController<Lv04SocialStageCommand> _commandController =
      StreamController<Lv04SocialStageCommand>.broadcast();
  Stream<Lv04SocialStageCommand> get commandStream => _commandController.stream;

  /// Completer to signal completion of the drinking screen.
  Completer<void>? _overDrink;

  /// Creates manager with [isDrinkingMode], [roomId], [lv04social], and optional [rounds].
  Lv04SocialStageManager({
    required this.isDrinkingMode,
    required this.roomId,
    required this.lv04social,
    this.rounds = LevelsRounds.defaultlevelRounds,
  }) : drinking = TranslationService.instance.t(
         'game.levels.$levelName.drink_penalty',
       ) {
    debugPrint("Lv04 manager created [hashCode: $hashCode].");
  }

  /// Returns the localized instruction from the model.
  @override
  String getInstruction() {
    return lv04social.getInstruction();
  }

  /// Executes the stage loop:
  /// for each round: start sync, choose target, fetch scenario,
  /// show UI for target/guessers, collect answer, sync, show results, and handle drinking.
  @override
  Future<void> runLevel() async {
    if (_isStarted) {
      debugPrint("startGameLoop() already called, ignoring duplicate call.");
      return;
    }
    _isStarted = true;
    debugPrint("Lv04 manager Starting level loop [hashCode: $hashCode]...");
    // Loop through the rounds
    for (int round = 0; round < rounds; round++) {
      debugPrint("Starting round $round...");
      LoadingService().show(
        TranslationService.instance.t(
          'game.levels.$levelName.loading_messages.loading1',
        ),
      );
      await safeCall(() => lv04social.allPlayersStartLoop());

      // 1. Reset the round data in the model.
      await SyncManager.instance.synchronizePlayers(
        lv04social.chooseRandomPlayer,
      );
      debugPrint("choosed Random target Player.");

      // Fetch next round data from server and update local variables.
      Map<String, dynamic> roundData;
      LoadingService().show(
        "${TranslationService.instance.t('game.levels.$levelName.loading_messages.loading2')}: ${round + 1}/$rounds",
      );
      roundData = await safeCall(
        () => lv04social.fetchNextRoundDataAndUpdate(),
        fallbackValue: {"done": true},
      );

      // Check if there are no more questions.
      if (roundData["done"] == true) break;

      // Create a completer so we can wait for the UI response.
      Completer<String> completer = Completer<String>();

      // Extract question details.
      String targetPlayerID = roundData["targetPlayer"] ?? "No target Player";
      String targetPlayerName =
          roundData["targetPlayerName"] ?? "No target Player Name";
      String scenario = roundData["scenario"] ?? "No scenario";
      Map<String, dynamic> options = roundData["options"] ?? {};
      int scenarioId = roundData["scenarioId"] ?? -1;
      LoadingService().show(
        TranslationService.instance.t(
          'game.levels.$levelName.loading_messages.loading3',
        ),
      );

      debugPrint(
        "scenario ID: $scenarioId. scenario: $scenario, options: $options, target Playe rName: $targetPlayerName",
      );

      bool isTargetPlayer = (targetPlayerID == playerId);
      debugPrint("Player is target player: $isTargetPlayer");

      // Build the payload from the current data.
      final scenarioPayload = isTargetPlayer
          ? {
              'scenario': scenario,
              'options': options,
              'scenarioId': scenarioId,
              // Callback to be invoked by the UI when the answer is submitted.
              'onQuestionAnswered': (String result) {
                if (!completer.isCompleted) completer.complete(result);
              },
            }
          : {
              'targetPlayerName': targetPlayerName,
              'scenario': scenario,
              'options': options,
              'scenarioId': scenarioId,
              'onQuestionAnswered': (String result) {
                if (!completer.isCompleted) completer.complete(result);
              },
            };

      Lv04SocialState questionState = isTargetPlayer
          ? Lv04SocialState.targetQuestion
          : Lv04SocialState.guessQuestion;
      TimerManager.instance.start(ScreenDurations.generalGameTime);
      // Start by showing the question screen.
      await _updateState(questionState, scenarioPayload);
      // Wait until the UI returns a result
      String result = await completer.future;
      TimerManager.instance.stop();

      // logging the result.
      debugPrint("Player answered was: $result");

      // Update the answer in the server/model.
      await safeCall(() => lv04social.updatePlayerAnswer(result));
      debugPrint("Player answer updated successfully.");

      await _updateState(Lv04SocialState.loading);
      await safeCall(() => lv04social.loading());
      debugPrint("done waiting for other players to answer.");

      Map<String, Tuple2<String, int>> resultData;
      resultData = await safeCall(
        () => lv04social.processQuestionResults(),
        fallbackValue: {},
      );

      debugPrint("level 04: processing question results complete.");

      // 7. Show the results screen (a temporary round summary).

      final scorePayload = {
        'resultData': resultData,
        'playerCorrect': resultData.keys.contains(playerId),
        'noPlayersGotPoints': TranslationService.instance.t(
          'game.common.no_player_got_points',
        ),
      };
      await timerManage(
        ScreenDurations.resultTime,
        Lv04SocialState.result,
        scorePayload,
      );

      // 8. Handle drinking/waiting screens.
      await drinkHandel();

      debugPrint("End of round $round");
    }
  }

  /// Syncs players (unless loading), emits a UI command,
  /// and returns whether the UI was updated.
  Future<bool> _updateState(Lv04SocialState state, [dynamic payload]) async {
    if (state != Lv04SocialState.loading) {
      if (!await SyncManager.instance.synchronizePlayers()) return false;
    }
    if (_commandController.isClosed) return false;
    _commandController.add(
      Lv04SocialStageCommand(state: state, payload: payload),
    );
    return true;
  }

  /// If drinking mode is enabled, shows drinking or waiting screens
  /// until all required players have completed.
  Future<void> drinkHandel() async {
    debugPrint(
      "start drink function in case handeling drink stats is nessery...",
    );
    if (isDrinkingMode) {
      DrinkingStageManager().setDrinkMessage(drinking);
      _overDrink = Completer<void>();
      if (await _updateState(Lv04SocialState.drinkingMode, {
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

  /// Starts a timer for [time] seconds, sends a UI state command,
  /// and awaits the timer’s completion.
  Future<void> timerManage(
    int time,
    Lv04SocialState state, [
    dynamic payload,
  ]) async {
    final done = TimerManager.instance.start(time);
    if (!await _updateState(state, payload)) return;
    await done;
  }

  /// Closes the UI command stream.
  void dispose() {
    _commandController.close();
  }
}
