// nexaburst/lib/model_view/room/game/levels/level1/Lv01_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/Levels/levels_interface.dart';
import 'package:nexaburst/model_view/room/sync_manager.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/models/data/server/levels/level1/Lvo1.dart';
import 'package:nexaburst/models/data/server/safe_call.dart';
import 'package:nexaburst/models/data/service/loading_controller.dart';
import 'package:nexaburst/model_view/room/game/modes/drinking/drinking_manager.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:tuple/tuple.dart';

/// The UI states for the Knowledge (Level 1) stage:
/// - `question`: show question & answers
/// - `result`: show round summary
/// - `loading`: transition/loading screen
/// - `drinkingMode`: handle drinking penalties
enum Lv01KnowledgeState {
  /// Display the question and answer UI.
  question,

  /// Display the private results for the stage.
  result,

  loading,

  drinkingMode,
}

/// Carries a state transition for the Level 1 UI.
///
/// [state]: target `Lv01KnowledgeState`.<br>
/// [payload]: optional data for that state (e.g., question text, callbacks).
class Lv01KnowledgeStageCommand {
  final Lv01KnowledgeState state;
  final dynamic payload;
  Lv01KnowledgeStageCommand({required this.state, this.payload});
}

//// Orchestrates the trivia rounds for Level 1:
/// fetches questions, collects answers, processes scores, and manages drinking mode.
class Lv01knowledgeStageManager extends LevelLogic {
  /// Underlying data/model interface for fetching and updating questions.
  final Lvo1 lv01Knowledge;

  /// Firestore room document ID.
  final String roomId; // Unique identifier of the room (as a string)
  /// Current player’s unique identifier.
  final String playerId = UserData
      .instance
      .user!
      .id; // Unique identifier of the current player (as a string)
  /// Whether drinking penalties are active for this stage.
  final bool isDrinkingMode; // Whether the game is in drinking mode or not.
  /// Guard to prevent multiple `runLevel()` loops.
  bool _isStarted =
      false; // Added flag to check if the loop has already started.
  /// Number of trivia rounds to execute.
  final int rounds;

  /// Emits `Lv01KnowledgeStageCommand` events for the UI to render appropriate screens.
  final StreamController<Lv01KnowledgeStageCommand> _commandController =
      StreamController<Lv01KnowledgeStageCommand>.broadcast();
  Stream<Lv01KnowledgeStageCommand> get commandStream =>
      _commandController.stream;

  /// Completer signaled when the drinking screen completes.
  Completer<void>? _overDrink;

  /// Localized prompt shown on the drinking screen.
  String drinkMessage = TranslationService.instance.t(
    'game.levels.${Lvo1.levelName}.drink_penalty',
  );

  /// Creates the stage manager with configuration:
  /// [isDrinkingMode], [roomId], [lv01Knowledge], and optional [rounds].
  Lv01knowledgeStageManager({
    required this.isDrinkingMode,
    required this.roomId,
    required this.lv01Knowledge,
    this.rounds = LevelsRounds.defaultlevelRounds,
  }) {
    {
      debugPrint("Lv01 manager created [hashCode: $hashCode].");
    }
  }

  /// Delegates to `lv01Knowledge.getInstruction()`.
  @override
  String getInstruction() {
    return lv01Knowledge.getInstruction();
  }

  /// Main loop: for each round, fetch question data, dispatch UI commands,
  /// await answer, sync with other players, display results, and handle drinking.
  @override
  Future<void> runLevel() async {
    if (_isStarted) {
      debugPrint("startGameLoop() already called, ignoring duplicate call.");
      return;
    }
    _isStarted = true;
    debugPrint("Lv01 manager Starting level loop [hashCode: $hashCode]...");
    // Loop through the rounds
    for (int round = 0; round < rounds; round++) {
      // Fetch next round data from server and update local variables.
      Map<String, dynamic> roundData;
      roundData = await safeCall(
        () => lv01Knowledge.fetchNextRoundDataAndUpdate(),
        fallbackValue: {
          "done": true,
          "question": "No question available",
          "answers": {},
          "correct_answer": "",
          "questionId": -1,
        },
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
        "Question ID: $questionId, Question: $questionText, Answers: $answers ,Correct Answer: $correctAnswer",
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

      LoadingService().show(
        TranslationService.instance.t(
          'game.levels.${Lvo1.levelName}.loading_messages.loading2',
        ),
      );
      TimerManager.instance.start(ScreenDurations.generalGameTime);
      // Start by showing the question screen.
      if (!await _updateState(Lv01KnowledgeState.question, questionPayload)) {
        debugPrint("should skip...");
      }
      // Wait until the UI returns a result (time it took to player ans and if ans not correct it will be -1).
      double result = await completer.future;
      TimerManager.instance.stop();

      // logging the result.
      debugPrint("Player answered with result time: $result");

      // Update the answer in the server/model.
      safeCall(() => lv01Knowledge.updatePlayerAnswer(result));
      debugPrint("Player answer updated successfully.");

      if (!await _updateState(Lv01KnowledgeState.loading, {})) {
        debugPrint("should skip..");
      }
      safeCall(() => lv01Knowledge.loading());
      debugPrint("done waiting for other players to answer.");

      Map<String, Tuple2<String, int>> resultData;
      LoadingService().show(
        TranslationService.instance.t(
          'game.levels.${Lvo1.levelName}.loading_messages.loading3',
        ),
      );
      resultData = await safeCall(
        () => lv01Knowledge.processQuestionResults(),
        fallbackValue: {},
      );
      debugPrint("level 01: result after process - $resultData");

      final scorePayload = {
        'resultData': resultData,
        'playerCorrect': resultData.keys.contains(playerId),
        'noPlayersGotPoints': TranslationService.instance.t(
          'game.common.no_player_got_points',
        ),
      };
      await _timerManage(
        ScreenDurations.resultTime,
        Lv01KnowledgeState.result,
        scorePayload,
      );
      if (!await SyncManager.instance.synchronizePlayers(
        lv01Knowledge.resetRound,
      )) {
        debugPrint(
          "should skip... also if i am the host resent has not been DONE",
        );
      }
      // 8. Handle drinking/waiting screens.
      await _drinkHandel();

      debugPrint("End of round $round");
      if (round + 1 < rounds)
        LoadingService().show(
          "${TranslationService.instance.t('game.levels.${Lvo1.levelName}.loading_messages.loading1')}: ${round + 2}/$rounds",
        );
    }
  }

  /// Internal helper to sync players (unless loading),
  /// emit a `Lv01KnowledgeStageCommand`, and return success.
  Future<bool> _updateState(Lv01KnowledgeState state, [dynamic payload]) async {
    if (state != Lv01KnowledgeState.loading) {
      if (!await SyncManager.instance.synchronizePlayers()) return false;
    }
    if (_commandController.isClosed) return false;
    _commandController.add(
      Lv01KnowledgeStageCommand(state: state, payload: payload),
    );
    return true;
  }

  /// If drinking mode is on, shows drinking or waiting screens and
  /// completes when all required players finish.
  Future<void> _drinkHandel() async {
    debugPrint(
      "start drink function in case handeling drink stats is nessery...",
    );
    if (isDrinkingMode) {
      DrinkingStageManager().setDrinkMessage(drinkMessage);
      _overDrink = Completer<void>();
      if (await _updateState(Lv01KnowledgeState.drinkingMode, {
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

  /// Starts a timer for [time] seconds, emits a state, and awaits completion.
  Future<void> _timerManage(
    int time,
    Lv01KnowledgeState state, [
    dynamic payload,
  ]) async {
    final done = TimerManager.instance.start(time);
    if (await _updateState(state, payload)) {
      await done;
    }
  }

  /// Closes the UI command stream.
  /// Clean-up.
  void dispose() {
    _commandController.close();
  }
}
