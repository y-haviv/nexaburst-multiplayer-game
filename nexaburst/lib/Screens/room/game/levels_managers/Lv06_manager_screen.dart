// nexaburst/lib/screens/room/game/levels_managers/LV06_managr_screen.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/room/game/Lv06/game_prepration_screen.dart';
import 'package:nexaburst/Screens/room/game/Lv06/game_screen.dart';
import 'package:nexaburst/Screens/room/game/Lv06/round_result_screen.dart';
import 'package:nexaburst/Screens/room/game/drink/drink_manager_screen.dart';
import 'package:nexaburst/Screens/room/game/manager_screens/loading_screen.dart';
import 'package:nexaburst/model_view/room/game/Levels/level6/Lv06_manager.dart';

/// A Trust stage screen that drives the UI flow via [Lv06TrustStageManager].
/// Listens to manager commands and renders preparation, choice, result, or drink sub‑screens.
class TrustStageScreen extends StatefulWidget {
  /// Callback invoked when this Trust stage completes.
  final VoidCallback onStageComplete;

  /// The logic manager that sequences preparation, choice, result, and drinking steps.
  final Lv06TrustStageManager stageManager;

  /// Creates a TrustStageScreen bound to [stageManager] and notifying via [onStageComplete].
  const TrustStageScreen({
    super.key,
    required this.onStageComplete,
    required this.stageManager,
  });

  @override
  _TrustStageScreen createState() => _TrustStageScreen();
}

class _TrustStageScreen extends State<TrustStageScreen> {
  @override
  void initState() {
    super.initState();
    // Begin the stage, and notify when done.
    widget.stageManager.runLevel().then((_) => widget.onStageComplete());
  }

  /// Disposes the [stageManager] subscription when this widget is removed.
  @override
  void dispose() {
    widget.stageManager.dispose();
    super.dispose();
  }

  /// Begins listening to [stageManager.commandStream] and builds the appropriate sub‑screen.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Lv06TrustStageCommand>(
      stream: widget.stageManager.commandStream,
      builder: (context, snapshot) {
        final cmd = snapshot.data;
        Widget content;

        if (cmd == null) {
          content = LoadingScreen();
        } else {
          switch (cmd.state) {
            case Lv06TrustState.preChoice:
              content = GamePreparationScreen();
              break;

            case Lv06TrustState.choice:
              content = GameScreen(
                playerCountStream:
                    cmd.payload['playerCountStream'] ?? Stream.value(0),
                onSubmitted: cmd.payload['onplayerAnswer'],
              );
              break;
            case Lv06TrustState.loading:
              content = LoadingScreen();
              break;
            case Lv06TrustState.result:
              content = RoundResultsScreen(
                added: cmd.payload['add_to_score'],
                bonusGuessCorrect: cmd.payload['bonusGuessCorrect'],
                playersInfo: cmd.payload['playersInfo'],
              );
              break;
            case Lv06TrustState.drinkingMode:
              content = DrinkStageScreen(
                onStageComplete: cmd.payload['onDrinkComplete'],
              );
              break;
          }
        }

        return content;
      },
    );
  }
}
