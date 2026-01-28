// nexaburst/lib/model_view/room/game/levels/level3/Lv03_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/Levels/levels_interface.dart';
import 'package:nexaburst/model_view/room/sync_manager.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/models/data/server/levels/level3/Lv03.dart';
import 'package:nexaburst/models/data/server/safe_call.dart';
import 'package:nexaburst/models/data/service/loading_controller.dart';
import 'package:nexaburst/model_view/room/game/modes/drinking/drinking_manager.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:tuple/tuple.dart';

/// UI states for the Intelligence (Level 3) stage:
/// - `question`: show question & answer UI
/// - `result`: show round summary
/// - `loading`: loading/synchronization screen
/// - `drinkingMode`: handle drinking penalties
enum Lv03IntelligenceState {
  /// Display the question and answer UI.
  question,

  /// Display the private results for the stage.
  result,

  loading,

  drinkingMode,
}

/// Carries a state transition command for Level 3 UI.
///
/// [state]: the target `Lv03IntelligenceState`.<br>
/// [payload]: optional data (e.g., question text, callbacks).
class Lv03IntelligenceStageCommand {
  final Lv03IntelligenceState state;
  final dynamic payload;
  Lv03IntelligenceStageCommand({required this.state, this.payload});
}

/// Manages the “Intelligence” trivia stage:
/// fetches questions, collects answers, processes scores,
/// synchronizes players, and handles drinking mode.
class Lv03IntelligenceStageManager extends LevelLogic {
  /// Backend model for fetching questions and submitting answers.
  final Lv03 lv03intelligence;

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
  static final String levelName = TranslationService.instance.levelKeys[2];

  /// Localized prompt shown when asking the player to drink.
  final String drinking;

  /// Prevents multiple invocations of `runLevel()`.
  bool _isStarted =
      false; // Added flag to check if the loop has already started.
  /// Number of trivia rounds to execute.
  final int rounds;

  /// Emits `Lv03IntelligenceStageCommand` events for UI updates.
  final StreamController<Lv03IntelligenceStageCommand> _commandController =
      StreamController<Lv03IntelligenceStageCommand>.broadcast();
  Stream<Lv03IntelligenceStageCommand> get commandStream =>
      _commandController.stream;

  /// Completer to signal completion of the drinking screen.
  Completer<void>? _OverDrink;

  /// Creates manager with [isDrinkingMode], [roomId], [lv03intelligence], and optional [rounds].
  Lv03IntelligenceStageManager({
    required this.isDrinkingMode,
    required this.roomId,
    required this.lv03intelligence,
    this.rounds = LevelsRounds.defaultlevelRounds,
  }) : drinking = TranslationService.instance.t(
         'game.levels.$levelName.drink_penalty',
       ) {
    debugPrint("Lv03 manager created [hashCode: $hashCode].");
  }

  /// Returns the localized instruction from the model.
  @override
  String getInstruction() {
    return lv03intelligence.getInstruction();
  }

  /// Executes the stage loop:
  /// for each round: fetch question, show UI, collect answer,
  /// sync players, display results, and handle drinking.
  @override
  Future<void> runLevel() async {
    if (_isStarted) {
      debugPrint("startGameLoop() already called, ignoring duplicate call.");
      return;
    }
    _isStarted = true;
    debugPrint("Lv03 manager Starting level loop [hashCode: $hashCode]...");
    // Loop through the rounds
    for (int round = 0; round < rounds; round++) {
      LoadingService().show(
        "${TranslationService.instance.t('game.levels.$levelName.loading_messages.loading1')}: ${round + 1}/$rounds",
      );
      // Fetch next round data from server and update local variables.
      Map<String, dynamic> roundData;
      roundData = await safeCall(
        () => lv03intelligence.fetchNextRoundDataAndUpdate(),
        fallbackValue: {"done": true},
      );
      // Check if there are no more questions.
      if (roundData["done"] == true) break;

      // Create a completer so we can wait for the UI response.
      Completer<double> completer = Completer<double>();

      // Extract question details.
      String questionText = roundData["question"] ?? "No question provided";
      Map<String, dynamic> answers = roundData["answers"] ?? {};
      String correctAnswer = roundData["correct_answer"] ?? "";
      int questionId = roundData["questionId"] ?? -1;

      debugPrint(
        "Question ID: $questionId, Question: $questionText, Answers: $answers, Correct Answer: $correctAnswer",
      );

      // Build the payload from the current data.
      final questionPayload = {
        'questionText': questionText,
        'answers': answers,
        'correctAnswer': correctAnswer,
        'questionId': questionId,
        // Callback to be invoked by the UI when the answer is submitted.
        'onQuestionAnswered': (double result) {
          if (!completer.isCompleted) completer.complete(result);
        },
      };
      TimerManager.instance.start(ScreenDurations.generalGameTime);
      // Start by showing the question screen.
      await _updateState(Lv03IntelligenceState.question, questionPayload);
      LoadingService().show(
        TranslationService.instance.t(
          'game.levels.$levelName.loading_messages.loading2',
        ),
      );
      // Wait until the UI returns a result (time it took to player ans and if ans not correct it will be -1).
      double result = await completer.future;
      TimerManager.instance.stop();
      // logging the result.
      debugPrint("Player answered with result time: $result");

      // Update the answer in the server/model.
      await lv03intelligence.updatePlayerAnswer(result);
      debugPrint("Player answer updated successfully.");

      await _updateState(Lv03IntelligenceState.loading);
      await safeCall(() => lv03intelligence.loading());

      debugPrint("done waiting for other players to answer.");

      Map<String, Tuple2<String, int>> resultData;
      LoadingService().show(
        TranslationService.instance.t(
          'game.levels.$levelName.loading_messages.loading3',
        ),
      );
      resultData = await safeCall(
        () => lv03intelligence.processQuestionResults(),
        fallbackValue: {},
      );

      debugPrint("level 03: processing question results complete.");

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
        Lv03IntelligenceState.result,
        scorePayload,
      );

      await SyncManager.instance.synchronizePlayers();
      (lv03intelligence.resetRound, roomId);

      // 8. Handle drinking/waiting screens.
      await drinkHandel();

      debugPrint("End of round $round");
    }
  }

  /// Syncs players (unless loading), emits a UI command,
  /// and returns whether the UI was updated.
  Future<bool> _updateState(
    Lv03IntelligenceState state, [
    dynamic payload,
  ]) async {
    if (state != Lv03IntelligenceState.loading) {
      if (!await SyncManager.instance.synchronizePlayers()) return false;
    }
    if (_commandController.isClosed) return false;
    _commandController.add(
      Lv03IntelligenceStageCommand(state: state, payload: payload),
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
      _OverDrink = Completer<void>();
      if (await _updateState(Lv03IntelligenceState.drinkingMode, {
        'onDrinkComplete': () async {
          if (_OverDrink != null && !_OverDrink!.isCompleted) {
            _OverDrink!.complete();
          }
        },
      })) {
        await Future.any([_OverDrink!.future]);
      }
      _OverDrink = null;
    }
  }

  /// Starts a timer for [time] seconds, sends a UI state command,
  /// and awaits the timer’s completion.
  Future<void> timerManage(
    int time,
    Lv03IntelligenceState state, [
    dynamic payload,
  ]) async {
    final done = TimerManager.instance.start(time);
    if (!await _updateState(state, payload)) return;
    await done;
  }

  /// Closes the UI command stream and disposes the model.
  void dispose() {
    _commandController.close();
    lv03intelligence.dispose();
  }
}
