// nexaburst/lib/model_view/room/game/levels/level2/Lv02_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/Levels/levels_interface.dart';
import 'package:nexaburst/model_view/room/sync_manager.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/models/data/server/levels/level2/Lv02.dart';
import 'package:nexaburst/models/data/server/levels/level2/lv02_model_manager.dart';
import 'package:nexaburst/models/data/server/safe_call.dart';
import 'package:nexaburst/models/data/service/loading_controller.dart';
import 'package:nexaburst/model_view/room/game/modes/drinking/drinking_manager.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:tuple/tuple.dart';

/// UI states for Level 2 “Luck” stage:
/// - `game_cup`: cup guessing
/// - `game_weel`: spin‑the‑wheel
/// - `result_weel`: show wheel results
/// - `result_cup`: show cup results
/// - `drinkingMode`: handle drinking penalties
enum Lv02LuckState {
  game_cup,

  game_weel,

  result_weel,

  /// Display the private results for the stage.
  result_cup,

  drinkingMode,
}

/// Carries a `Lv02LuckState` transition to the Level 2 UI.
class Lv02LuckStageCommand {
  final Lv02LuckState state;
  final dynamic payload;
  Lv02LuckStageCommand({required this.state, this.payload});
}

/// Manages the two sub‑phases (“cup” and “wheel”) of Level 2,
/// handling data fetch/update, UI commands, synchronization, and drinking mode.
class Lv02LuckStageManager extends LevelLogic {
  /// Model interface for the cup‑guessing sub‑stage.
  final Lv02Luck lv02Luck = Lv02ModelManager.instanceLuck();

  /// Model interface for the spin‑the‑wheel sub‑stage.
  final Lv02Weel lv02luckWeel = Lv02ModelManager.instanceWeel();

  /// Firestore room document ID.
  final String roomId; // Unique identifier of the room (as a string)
  /// Current player’s unique identifier.
  final String playerId = UserData
      .instance
      .user!
      .id; // Unique identifier of the current player (as a string)
  /// Whether drinking penalties are enabled.
  final bool isDrinkingMode; // Whether the game is in drinking mode or not.
  /// Translation key for this level’s name.
  static final String levelName = TranslationService.instance.levelKeys[1];

  /// Localized prompt for the drinking screen.
  final String drinkMessage;

  /// Guard to prevent multiple `runLevel()` loops.
  bool _isStarted =
      false; // Added flag to check if the loop has already started.
  /// Flags set by the wheel sub‑stage to modify the next cup round.
  bool skipPlayerNextRound = false;
  bool doublePlayerPointsNextRound = false;

  /// Emits `Lv02LuckStageCommand` events for UI state transitions.
  final StreamController<Lv02LuckStageCommand> _commandController =
      StreamController<Lv02LuckStageCommand>.broadcast();
  Stream<Lv02LuckStageCommand> get commandStream => _commandController.stream;

  /// Emits countdown values for time‑limited screens.
  final _timerController = StreamController<int>.broadcast();
  Stream<int> get timerStream => _timerController.stream;

  /// Completer for completing the drinking UI phase.
  Completer<void>? _overDrink;

  /// Number of rounds in this level.
  final int rounds;

  /// Constructs the manager with [isDrinkingMode], [roomId], and optional [rounds].
  Lv02LuckStageManager({
    required this.isDrinkingMode,
    required this.roomId,
    this.rounds = LevelsRounds.defaultlevelRounds,
  }) : drinkMessage = TranslationService.instance
           .t(
             'game.levels.$levelName.drink_penalty',
           ) // Message to show on the drinking screen.
           {
    debugPrint("Lv02 manager created [hashCode: $hashCode].");
  }

  /// Combines instructions from both cup and wheel models.
  @override
  String getInstruction() {
    return lv02Luck.getInstruction() + lv02luckWeel.getInstruction();
  }

  /// Executes the spin‑the‑wheel sub‑phase:
  /// fetches options, waits for UI, updates server, and shows results.
  Future<void> runWeel() async {
    LoadingService().show(
      TranslationService.instance.t(
        'game.levels.$levelName.loading_messages.loading1',
      ),
    );
    List<Tuple3<int, String, bool>> weelData =
        []; // should look like [("id":<int>, "option":<String>, "effectOther":<bool>), (...), (...)]
    debugPrint("Fetching round data for weel...");
    weelData = await safeCall(
      () => lv02luckWeel.fetchWeelData(),
      fallbackValue: [],
    );
    if (weelData.isEmpty) return;

    debugPrint("weel data: $weelData");
    // Create a completer so we can wait for the UI response.
    Completer<Tuple2<int, String>> completer =
        Completer<
          Tuple2<int, String>
        >(); // to get from UI back when end weel screen the (option_id<int>), (player_id<String>-the player who is effected)

    TimerManager.instance.start(ScreenDurations.generalGameTime);
    // Build the payload from the current data.
    final gameWeelPayload = {
      'weelData': weelData,
      'roomId': roomId,
      // Callback to be invoked by the UI when the choise is submitted.
      'onAnswered': (int result1, String result2) {
        if (!completer.isCompleted) {
          completer.complete(Tuple2(result1, result2));
        }
      },
    };
    if (!await _updateState(Lv02LuckState.game_weel, gameWeelPayload)) {
      debugPrint("Level 02 problem update wheel game screen...");
      return;
    }
    // Wait until the UI returns a result (place player choosed).
    Tuple2<int, String> result = await completer.future;
    TimerManager.instance.stop();

    // proform and Update in the server/model.
    Tuple2<bool, bool> temp = await safeCall(
      () => lv02luckWeel.updateForPlayer(result),
      fallbackValue: Tuple2(false, false),
    );
    skipPlayerNextRound = temp.item1;
    doublePlayerPointsNextRound = temp.item2;

    LoadingService().show(
      TranslationService.instance.t(
        'game.levels.$levelName.loading_messages.loading2',
      ),
    );
    await lv02luckWeel.loading();

    LoadingService().show(
      TranslationService.instance.t(
        'game.levels.$levelName.loading_messages.loading3',
      ),
    );

    List<String>
    resultData; // should look like this - each String is summary of player in the and what happan to him in luck weel and we show to evrey player all of the string in the list
    resultData = await safeCall(
      () => lv02luckWeel.processResults(),
      fallbackValue: [
        TranslationService.instance.t('errors.game.wheel_result_error'),
      ],
    );

    // 7. Show the results screen (a temporary round summary).
    final scorePayload = {'resultData': resultData};
    await timerManage(
      ScreenDurations.resultTime,
      Lv02LuckState.result_weel,
      scorePayload,
    );
    LoadingService().show(
      "${TranslationService.instance.t('game.levels.$levelName.loading_messages.loading4')}...",
    );
    await SyncManager.instance.synchronizePlayers(lv02luckWeel.resetRound);

    // 8. Handle drinking/waiting screens.
    await drinkHandel();

    debugPrint("End of round 0");
  }

  /// Main loop: first runs one wheel round, then iterates cup rounds:
  /// handles UI commands, server sync, scoring adjustments, and drinking mode.
  @override
  Future<void> runLevel() async {
    if (_isStarted) {
      debugPrint("startGameLoop() already called, ignoring duplicate call.");
      return;
    }
    _isStarted = true;
    debugPrint("Lv02 manager Starting level loop [hashCode: $hashCode]...");

    // Loop through the rounds
    for (int round = 0; round < rounds; round++) {
      if (round == 0) {
        await runWeel();
        round += 1;
      } else {
        await SyncManager.instance.synchronizePlayers();
      }

      LoadingService().show(
        "${TranslationService.instance.t('game.levels.$levelName.loading_messages.loading5')}...",
      );

      // Fetch next round data from server and update local variables.
      Map<String, dynamic> roundData;
      debugPrint("Fetching round data for round $round...");
      roundData = await safeCall(
        () => lv02Luck.fetchNextRoundDataAndUpdate(),
        fallbackValue: {"done": true},
      );

      // Check if there are no more questions.
      if (roundData["done"] == true) {
        debugPrint("No more questions available. Ending game loop.");
        break;
      }

      // Create a completer so we can wait for the UI response.
      Completer<int> completer = Completer<int>();
      final revealNotifier = ValueNotifier<bool>(false);

      // Extract game details.
      int goldPlace = roundData["gold"] ?? -1;
      int blackPlace = roundData["black"] ?? -1;

      debugPrint("Gold place: $goldPlace, Black place: $blackPlace");
      // Build the payload from the current data.
      final gameCupPayload = {
        'gold': goldPlace,
        'black': blackPlace,
        // Callback to be invoked by the UI when the choise is submitted.
        'onAnswered': (int result) {
          if (!completer.isCompleted) completer.complete(result);
        },
        'revealNotifier': revealNotifier,
      };
      int result = -1; // Default value in case of an error.

      if (skipPlayerNextRound) {
        LoadingService().show(
          TranslationService.instance.t(
            'game.levels.$levelName.skip_player_message',
          ),
        );
      } else {
        TimerManager.instance.start(ScreenDurations.generalGameTime);
        if (!await _updateState(Lv02LuckState.game_cup, gameCupPayload)) {
          debugPrint("Level 02 problem update cup game screen...");
        } else {
          LoadingService().show(
            TranslationService.instance.t(
              'game.levels.$levelName.loading_messages.loading6',
            ),
          );
        }
        // Wait until the UI returns a result (place player choosed).
        result = await completer.future;
        TimerManager.instance.stop();
        // logging the result.
        debugPrint("Player answered with result time: $result");
      }

      // Update the choise in the server/model.
      await safeCall(() => lv02Luck.updatePlayerAnswer(result));

      await lv02Luck.loading();
      revealNotifier.value = true;
      await Future.delayed(Duration(seconds: 3));

      Map<String, Tuple2<String, int>> resultData;
      resultData = await safeCall(
        () => lv02Luck.processResults(
          blackPlace,
          goldPlace,
          skip: skipPlayerNextRound,
        ),
        fallbackValue: {},
      );
      if (doublePlayerPointsNextRound) {
        doublePlayerPointsNextRound = false;
      }
      if (skipPlayerNextRound) {
        skipPlayerNextRound = false;
      }

      debugPrint("Result data: $resultData");

      // 7. Show the results screen (a temporary round summary).
      final scorePayload = {
        'resultData': resultData,
        'playerCorrect': (resultData.keys.contains(playerId)
            ? resultData[playerId]!.item2 > 0
            : null),
        'noPlayersGotPoints': TranslationService.instance.t(
          'game.common.no_player_got_points',
        ),
      };
      await timerManage(
        ScreenDurations.resultTime,
        Lv02LuckState.result_cup,
        scorePayload,
      );

      await SyncManager.instance.synchronizePlayers(lv02Luck.resetRound);

      // 8. Handle drinking/waiting screens.
      await drinkHandel();

      if (round + 1 < rounds) {
        LoadingService().show(
          "${TranslationService.instance.t('game.levels.$levelName.loading_messages.loading4')}...",
        );
      }

      debugPrint("End of round $round");
    }
  }

  /// Syncs players, emits a `Lv02LuckStageCommand`, and returns whether UI was updated.
  Future<bool> _updateState(Lv02LuckState state, [dynamic payload]) async {
    if (!await SyncManager.instance.synchronizePlayers()) return false;
    if (_commandController.isClosed) return false;
    _commandController.add(
      Lv02LuckStageCommand(state: state, payload: payload),
    );
    return true;
  }

  /// Manages drinking/waiting screens if drinking mode is active.
  Future<void> drinkHandel() async {
    debugPrint(
      "start drink function in case handeling drink stats is nessery...",
    );
    if (isDrinkingMode) {
      DrinkingStageManager().setDrinkMessage(drinkMessage);
      _overDrink = Completer<void>();
      if (await _updateState(Lv02LuckState.drinkingMode, {
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

  /// Starts a timer, emits a state command, and awaits timer completion.
  Future<void> timerManage(
    int time,
    Lv02LuckState state, [
    dynamic payload,
  ]) async {
    final done = TimerManager.instance.start(time);
    if (!await _updateState(state, payload)) return;
    await done;
  }

  /// Closes command stream and resets Level 2 model manager.
  void dispose() {
    _commandController.close();
    Lv02ModelManager.reset();
  }
}
