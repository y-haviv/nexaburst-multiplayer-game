// nexaburst/lib/model_view/room/game/drinking/drinking_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/server/modes/drinking/drink_manager.dart';
import 'package:nexaburst/models/data/server/modes/drinking/drinking_game.dart';
import 'package:nexaburst/models/data/server/safe_call.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:rxdart/rxdart.dart';

/// Represents the UI state during the drinking phase:
/// - `drinking`: show the drinking screen to players who must drink
/// - `waitDrinking`: show a waiting screen to others
/// - `loading`: transition state before starting or after finishing
enum DrinkState {
  /// Display the drinking screen to player that need to drink (only if drinking mode is enabled).
  drinking,

  /// Display the waiting screen to player that need to wait for other players to drink (only if drinking mode is enabled).
  waitDrinking,

  loading,
}

/// Encapsulates a command to update the drinking‑phase UI.
///
/// [state]: the target `DrinkState`.<br>
/// [payload]: optional data for that state (e.g., messages, callbacks).
class DrinkStageCommand {
  final DrinkState state;
  final dynamic payload;
  DrinkStageCommand({required this.state, this.payload});
}

/// Singleton controller for the drinking game phase.
/// Manages initialization, state transitions, and UI command stream.
class DrinkingStageManager {
  /// Private constructor for singleton pattern.
  DrinkingStageManager._internal();
  static final DrinkingStageManager _instance =
      DrinkingStageManager._internal();

  /// Returns the singleton instance of `DrinkingStageManager`.
  factory DrinkingStageManager() => _instance;

  /// ID of the current game room.
  String? roomId; // Unique identifier of the room (as a string)
  /// Flag indicating whether drinking penalties are enabled.
  bool? isDrinkingMode;

  /// Fallback message shown on the drinking screen.
  final String defaultDrinkingMessage = TranslationService.instance.t(
    'game.modes.drinking_mode.drink_action_prompt',
  ); // Message to show on the drinking screen.
  /// Customizable prompt message and aggregated forbidden‑words feedback.
  String? drinkMessage;
  String? drinkWords;

  /// Reference to the shared timer service for countdowns.
  final timerService = TimerManager.instance;

  /// Controller and broadcast stream sending `DrinkStageCommand` to the UI.
  late StreamController<DrinkStageCommand> _commandController;
  Stream<DrinkStageCommand> get commandStream => _commandController.stream;

  /// Completer used to await the UI’s “done drinking” callback.
  Completer<void>? _drinkingCompleter;

  /// Fallback timeout duration for the drinking phase.
  final Duration fallBackTime = Duration(seconds: 30);

  /// Underlying data model handling who must drink.
  DrinkingGame drinkingModel = DrinkManager.instance;

  /// Emits the list of player names currently required to drink.
  late BehaviorSubject<List<String>> _valueController;
  Stream<List<String>> get valuesStream => _valueController.stream;

  /// Subscriptions for player list and timer updates.
  late StreamSubscription<Map<String, String>> _subPlayers;
  late StreamSubscription<int> _subTime;

  /// Internal flags tracking initialization and running state.
  bool _started = false;
  bool _initialized = false;

  /// Prepares the manager with [roomId] and [isDrinkingMode].
  /// Must be called before `runDrinking()`.
  void init({required String roomId, required bool isDrinkingMode}) {
    if (_initialized) {
      debugPrint("[Drinking] Already initialized.");
      return;
    }
    _initialized = true;
    this.roomId = roomId;
    this.isDrinkingMode = isDrinkingMode;
    drinkMessage = defaultDrinkingMessage;
    drinkWords = "";
    _commandController = StreamController<DrinkStageCommand>.broadcast();
    _started = false;
  }

  /// Overrides the drink prompt before phase starts.
  void setDrinkMessage(String message) {
    if (!_initialized || _started) return;
    drinkMessage = message;
  }

  /// Records a forbidden‑word event to append to the drink prompt.
  Future<void> saidForbidden(String message) async {
    if (!_initialized) return;
    if (_started) {
      await Future.any([
        () async {
          while (_started) {
            await Future.delayed(Duration(milliseconds: 700));
          }
        }(),
        Future.delayed(Duration(seconds: ScreenDurations.drinkScreenTime)),
      ]);
    }
    drinkWords = (drinkWords == null || drinkWords!.isEmpty)
        ? '${TranslationService.instance.t('game.modes.forbidden_words_mode.drink_instruction')}: $message'
        : '${drinkWords!}, $message';
  }

  /// Executes the drinking loop:
  /// 1. Initializes model
  /// 2. Streams live updates
  /// 3. Manages drinking or waiting states
  /// 4. Transitions via `_updateState`.
  Future<void> runDrinking() async {
    debugPrint(
      "[Drinking] Starting drinking phase (roomId: $roomId, isDrinkingMode: $isDrinkingMode)",
    );

    if (isDrinkingMode == null || roomId == null) {
      debugPrint(
        "[Drinking] End of drinking phase - Error init state.",
      ); // problem
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }
    if (_started || !isDrinkingMode! || !_initialized) {
      debugPrint("[Drinking] End of drinking phase - not starting."); // change
      return;
    }
    _started = true;

    _valueController = BehaviorSubject<List<String>>();

    // 1.
    drinkingModel.initialization(roomId: roomId!);
    await safeCall(
      () => drinkingModel.waitUntilInitialized(),
      fallbackValue: null,
    );

    bool isFinish = drinkingModel.stream.value.isEmpty;
    bool playerNeedToDrink = drinkingModel.stream.value.containsKey(
      UserData.instance.user!.id,
    );

    // 2. Live updates
    _subPlayers = drinkingModel.stream.listen(
      (map) {
        if (map.isEmpty) {
          isFinish = true;
        } else if (map.containsKey(UserData.instance.user!.id)) {
          playerNeedToDrink = true;
        } else {
          playerNeedToDrink = false;
        }
        debugPrint("[Drinking] map: ${map.values.toList()}");
        _valueController.add(map.values.toList());
      },
      onError: (error, stack) {
        debugPrint("[Drinking] Stream error: $error\n$stack");
        ErrorService.instance.report(error: ErrorType.unknown);
        isFinish = true;
      },
    );

    // 2.timer for UI and fallback
    final done = timerService.start(ScreenDurations.drinkScreenTime);
    _subTime = timerService.getTime().listen(
      (secs) {
        if (secs <= 0) {
          debugPrint("[Drinking] seconds elapsed - finishing.");
          isFinish = true;
        }
      },
      onError: (error, stack) {
        debugPrint("[Drinking] Stream error: $error\n$stack");
        ErrorService.instance.report(error: ErrorType.unknown);
        isFinish = true;
      },
    );

    // 3. drinking loop
    debugPrint("[Drinking] Entering drinking loop isFinish: $isFinish");
    while (!isFinish) {
      // 4. if player need to drink
      if (playerNeedToDrink) {
        // Create and store a completer so that the UI can signal completion.
        _drinkingCompleter = Completer<void>();
        final drinkingPayload = {
          'message':
              (drinkMessage ?? defaultDrinkingMessage) + (drinkWords ?? ""),
          'onDrinkingComplete': () async {
            // Once done, complete the completer to signal the UI.
            if (_drinkingCompleter != null &&
                !_drinkingCompleter!.isCompleted) {
              _drinkingCompleter!.complete();
            }
          },
        };

        if (!await _updateState(DrinkState.drinking, drinkingPayload)) return;

        await Future.any([
          () async {
            await _drinkingCompleter!.future;
            debugPrint("[Drinking] Player signaled done drinking.");
          }(),
          () async {
            await done;
            debugPrint("[Drinking] Fallback timer elapsed - finishing.");
          }(),
        ]);

        // Clean up the completer.
        _drinkingCompleter = null;
        await safeCall(() async {
          await drinkingModel.removeFromPlayersToDrink();
        });
        playerNeedToDrink = false;
      } else {
        // doesnt need to drink need to wait for rest of players
        await _updateState(DrinkState.waitDrinking, {
          'drinkStream': _valueController.stream,
        });

        await Future.any([
          () async {
            while (!isFinish) {
              await Future.delayed(Duration(milliseconds: 200));
            }
            debugPrint("[Drinking] All players done drinking.");
          }(),
          Future.delayed(
            Duration(seconds: ScreenDurations.drinkScreenTime * 2),
          ),
        ]);
      }
    }
    await _updateState(DrinkState.loading, {});

    debugPrint("[Drinking] End of drinking phase.");
  }

  /// Cancels subscriptions, closes streams, and stops timers.
  void dispose() {
    if (!_started || !_initialized) return;
    _started = false;
    drinkMessage = null;
    drinkWords = null;
    _subPlayers.cancel();
    _subTime.cancel();
    _valueController.close();
    drinkingModel.dispose();
    timerService.stop();
  }

  /// Resets all state and closes the UI command stream.
  void finalDispose() {
    if (!_initialized) return;
    _initialized = false;
    dispose();
    _commandController.close();
    roomId = null;
    isDrinkingMode = null;
  }

  /// Helper to emit a `DrinkStageCommand` to the UI.
  ///
  /// Returns `false` if the stream is closed.
  Future<bool> _updateState(DrinkState state, [dynamic payload]) async {
    if (_commandController.isClosed) return false;
    _commandController.add(DrinkStageCommand(state: state, payload: payload));
    return true;
  }
}
