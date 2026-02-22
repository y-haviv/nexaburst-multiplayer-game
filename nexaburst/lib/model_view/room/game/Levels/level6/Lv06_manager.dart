// nexaburst/lib/model_view/room/game/levels/level6/Lv06_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/Levels/levels_interface.dart';
import 'package:nexaburst/model_view/room/sync_manager.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/models/data/server/levels/level6/Lv06.dart';
import 'package:nexaburst/models/data/server/safe_call.dart';
import 'package:nexaburst/models/data/service/loading_controller.dart';
import 'package:nexaburst/model_view/room/game/modes/drinking/drinking_manager.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:tuple/tuple.dart';

/// UI states for the Trust stage:
/// - `preChoice`: initial countdown before choice
/// - `choice`: player makes a steal/leave and optional guess
/// - `result`: show round summary
/// - `loading`: waiting for other players
/// - `drinkingMode`: handle drinking penalties
enum Lv06TrustState {
  preChoice,

  choice,

  /// Display the private results for the stage.
  result,

  loading,

  drinkingMode,
}

/// Carries a state transition and optional data for the Trust stage UI.
///
/// [state]: target `Lv06TrustState`.<br>
/// [payload]: additional parameters (e.g., streams, guess results).
class Lv06TrustStageCommand {
  final Lv06TrustState state;
  final dynamic payload;
  Lv06TrustStageCommand({required this.state, this.payload});
}

/// Manages the Trust game logic:
/// handles player choices, guesses, scoring, synchronization,
/// and drinking mode flows over multiple rounds.
class Lv06TrustStageManager extends LevelLogic {
  /// Backend model implementing the Trust stage rules.
  final Lv06 lv06trust;

  /// Firestore game room identifier.
  final String roomId; // Unique identifier of the room (as a string)
  /// Current player’s identifier.
  final String playerId = UserData
      .instance
      .user!
      .id; // Unique identifier of the current player (as a string)
  /// Whether drinking penalties apply this round.
  final bool isDrinkingMode; // Whether the game is in drinking mode or not.
  /// Translation key for this level’s name.
  static final String levelName = TranslationService.instance.levelKeys[5];

  /// Localized message shown when prompting to drink.
  final String drinking;

  /// Prevents multiple invocations of `runLevel()`.
  bool _isStarted =
      false; // Added flag to check if the loop has already started.

  /// Emits `Lv06TrustStageCommand` events for UI updates.
  final StreamController<Lv06TrustStageCommand> _commandController =
      StreamController<Lv06TrustStageCommand>.broadcast();
  Stream<Lv06TrustStageCommand> get commandStream => _commandController.stream;

  /// Completes when the drinking UI task finishes.
  Completer<void>? _overDrink;

  /// Number of rounds to execute.
  final int rounds;

  /// Initializes the manager, sets up the Trust model, and configures round count.
  Lv06TrustStageManager({
    required this.isDrinkingMode,
    required this.roomId,
    required this.lv06trust,
    this.rounds = LevelsRounds.defaultlevelRounds,
  }) : drinking = TranslationService.instance.t(
         'game.levels.$levelName.drink_penalty',
       ) {
    lv06trust.initialization(roomId: roomId, isDrinkingMode: isDrinkingMode);
    debugPrint("Lv06 manager created [hashCode: $hashCode].");
  }

  /// Returns the instruction text from the Trust model.
  @override
  String getInstruction() {
    return lv06trust.getInstruction();
  }

  /// Main loop: for each round, show pre‑choice countdown,
  /// collect choice and guess, sync, display results, and handle drinking screens.
  @override
  Future<void> runLevel() async {
    if (_isStarted) {
      debugPrint("startGameLoop() already called, ignoring duplicate call.");
      return;
    }
    _isStarted = true;
    debugPrint("Lv06 manager Starting level loop [hashCode: $hashCode]...");
    // Loop through the rounds
    for (int round = 0; round < rounds; round++) {
      debugPrint("Starting round $round...");

      //
      LoadingService().show(
        TranslationService.instance.t('game.levels.$levelName.loading1'),
      );
      final prePayload = {};
      await timerManage(
        ScreenDurations.level06PreGameTime,
        Lv06TrustState.preChoice,
        prePayload,
      );

      // Create a completer for the UI response.
      Completer<Map<String, dynamic>> completer =
          Completer<Map<String, dynamic>>();

      // Build the payload from the current data.
      final gamePayload = {
        "playerCountStream": lv06trust.playerCountStream,
        // Callback to be invoked by the UI when the answer is submitted.
        'onplayerAnswer': (bool result, int guess) {
          if (!completer.isCompleted) {
            completer.complete({'result': result, 'guess': guess});
          }
        },
      };
      LoadingService().show(
        TranslationService.instance.t('game.levels.$levelName.loading2'),
      );
      debugPrint("starting game screen...");
      // Start by showing the question screen.
      timerManage(
        ScreenDurations.generalGameTime,
        Lv06TrustState.choice,
        gamePayload,
      );

      // Wait until the UI returns a result.
      final response = await completer.future;
      bool result = response['result'];
      int guess = response['guess'];

      // Logging the result.
      debugPrint("Player choice was: $result");
      debugPrint("Player guess was: $guess");

      // Update the time in the server/model.
      await safeCall(() => lv06trust.updatePlayerAnswer(result, guess));
      debugPrint("Player answer updated successfully.");

      await _updateState(Lv06TrustState.loading);
      await safeCall(() => lv06trust.loading());

      Map<String, dynamic> resultData;
      resultData = await safeCall(
        () => lv06trust.processResults(),
        fallbackValue: {},
      );
      if (resultData.isEmpty) {
        debugPrint("No results data received, skipping to next round.");
        continue;
      }

      int addScore = resultData["add_to_score"] ?? 0;
      bool bonusGuessCorrect = resultData["bonusGuessCorrect"] ?? false;
      Map<String, Tuple2<String, String>> playersInfo =
          resultData["playersInfo"] ?? {};

      debugPrint(
        "Total score: $addScore, Correct guess bonus: $bonusGuessCorrect, Players info: $playersInfo",
      );

      // 7. Show the results screen (a temporary round summary).

      final scorePayload = {
        'add_to_score': addScore,
        'bonusGuessCorrect': bonusGuessCorrect,
        'playersInfo': playersInfo,
      };
      await timerManage(
        ScreenDurations.resultTime,
        Lv06TrustState.result,
        scorePayload,
      );

      await SyncManager.instance.synchronizePlayers(lv06trust.resetRound);

      // 8. Handle drinking/waiting screens.
      await drinkHandel();

      debugPrint("End of round $round");
    }
  }

  /// Synchronizes players, emits a UI state command, and returns whether UI was updated.
  Future<bool> _updateState(Lv06TrustState state, [dynamic payload]) async {
    if (state != Lv06TrustState.loading) {
      if (!await SyncManager.instance.synchronizePlayers()) return false;
    }
    if (_commandController.isClosed) return false;
    _commandController.add(
      Lv06TrustStageCommand(state: state, payload: payload),
    );
    return true;
  }

  /// If drinking mode is enabled, displays drinking or waiting UI
  /// until all required players have completed.
  Future<void> drinkHandel() async {
    debugPrint(
      "start drink function in case handeling drink stats is nessery...",
    );
    if (isDrinkingMode) {
      DrinkingStageManager().setDrinkMessage(drinking);
      _overDrink = Completer<void>();
      if (await _updateState(Lv06TrustState.drinkingMode, {
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

  /// Starts a countdown for [time] seconds, emits the specified UI state,
  /// and waits for the timer to complete.
  Future<void> timerManage(
    int time,
    Lv06TrustState state, [
    dynamic payload,
  ]) async {
    final done = TimerManager.instance.start(time);
    if (!await _updateState(state, payload)) return;
    await done;
  }

  /// Closes the command stream and cleans up manager resources.
  void dispose() {
    _commandController.close();
  }
}
