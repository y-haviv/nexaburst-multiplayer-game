// nexaburst/lib/screens/room/game/drink/drink_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/room/game/manager_screens/loading_screen.dart';
import 'package:nexaburst/Screens/room/game/drink/drink_instraction.dart';
import 'package:nexaburst/Screens/room/game/drink/drink_wait.dart';
import 'package:nexaburst/model_view/room/game/modes/drinking/drinking_manager.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// A screen that manages the drinking stage of the game.
///
/// Listens to commands from [DrinkingStageManager] and displays
/// instruction, waiting, or loading sub‑screens accordingly.
class DrinkStageScreen extends StatefulWidget {
  /// Callback invoked when the drinking stage is complete.
  final VoidCallback onStageComplete;

  /// Manages the drinking stage logic and command stream.
  final stageManager = DrinkingStageManager();

  /// Creates a [DrinkStageScreen] with a completion callback.
  DrinkStageScreen({super.key, required this.onStageComplete});

  /// Creates mutable state for [DrinkStageScreen].
  @override
  _DrinkStageScreenState createState() => _DrinkStageScreenState();
}

/// State class for [DrinkStageScreen], starts and listens to stage commands.
class _DrinkStageScreenState extends State<DrinkStageScreen> {
  /// Initializes the drinking stage and invokes [onStageComplete] when done.
  @override
  void initState() {
    super.initState();

    // Start the stage flow.
    widget.stageManager.runDrinking().then((_) {
      widget.stageManager.dispose();
      widget.onStageComplete();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Builds the UI by reacting to the stage manager’s command stream.
  ///
  /// Displays [LoadingScreen] until a command arrives, then switches
  /// between instruction and waiting sub‑screens.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DrinkStageCommand>(
      stream: widget.stageManager.commandStream,
      builder: (context, snapshot) {
        Widget subScreen;
        if (!snapshot.hasData) {
          subScreen = LoadingScreen();
        } else {
          final command = snapshot.data!;

          switch (command.state) {
            case DrinkState.drinking:
              subScreen = DrinkInstructionScreen(
                message:
                    command.payload['message'] ??
                    TranslationService.instance.t(
                      'game.modes.drinking_mode.drink_action_prompt',
                    ),
                onDrinkingComplete: command.payload['onDrinkingComplete'],
              );
              break;
            case DrinkState.waitDrinking:
              subScreen = WaitingForPlayersScreen(
                playersToDrink:
                    command.payload['drinkStream'] ?? Stream.empty(),
              );
              break;
            case DrinkState.loading:
              subScreen = LoadingScreen();
              break;
          }
        }
        return subScreen;
      },
    );
  }
}
