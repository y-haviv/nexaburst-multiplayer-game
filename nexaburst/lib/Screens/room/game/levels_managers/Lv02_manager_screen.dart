// nexaburst/lib/screens/room/game/levels_managers/Lv02_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/room/game/Lv01-04/Lv02/luck_weel_result.dart';
import 'package:nexaburst/Screens/room/game/Lv01-04/Lv02/luck_weel_screen.dart';
import 'package:nexaburst/Screens/room/game/Lv01-04/round_summary.dart';
import 'package:nexaburst/Screens/room/game/drink/drink_manager_screen.dart';
import 'package:nexaburst/Screens/room/game/manager_screens/loading_screen.dart';
import 'package:nexaburst/Screens/room/game/Lv01-04/Lv02/luck_game_screen.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/Levels/level2/Lv02_manager.dart';

/// A widget that manages and displays the full flow of the "Luck" stage in the game.
///
/// It listens to the [Lv02LuckStageManager]'s command stream and renders the
/// corresponding sub-screen based on the current state of the stage.
class LuckStageScreen extends StatefulWidget {
  /// Callback that is triggered once the stage is completed.
  final VoidCallback onStageComplete;

  /// Controller responsible for managing the logic and state transitions of the Luck stage.
  final Lv02LuckStageManager stageManager;

  const LuckStageScreen({
    super.key,
    required this.onStageComplete,
    required this.stageManager,
  });

  @override
  _LuckStageScreen createState() => _LuckStageScreen();
}

class _LuckStageScreen extends State<LuckStageScreen> {
  /// Initializes the screen, precaches background assets, and starts the stage flow.
  @override
  void initState() {
    super.initState();
    // 1) Precache your background
    //precacheImage(const AssetImage(PicPaths.weelBackground), context);
    // Start the level flow using the new runLevel method.
    widget.stageManager.runLevel().then((_) {
      widget.onStageComplete();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(PicPaths.weelBackground), context);
  }

  /// Disposes the stage manager and related resources.
  @override
  void dispose() {
    widget.stageManager.dispose();
    super.dispose();
  }

  /// Builds the UI by rendering the appropriate sub-screen based on the current command state.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Lv02LuckStageCommand>(
      stream: widget.stageManager.commandStream,
      builder: (context, snapshot) {
        Widget subScreen;
        if (!snapshot.hasData) {
          subScreen = LoadingScreen();
        } else {
          final command = snapshot.data!;

          switch (command.state) {
            case Lv02LuckState.game_cup:
              subScreen = LuckGame(
                black: command.payload['black'] ?? 1,
                gold: command.payload['gold'] ?? 0,
                onAnswered: command.payload['onAnswered'],
                revealNotifier:
                    command.payload['revealNotifier'] as ValueNotifier<bool>? ??
                    ValueNotifier(false),
              );
              break;
            case Lv02LuckState.result_cup:
              subScreen = RoundSummaryScreen(
                playersAndAddedPoints: command.payload['resultData'] ?? {},
                playerCorrect: command.payload['playerCorrect'],
                noPlayersGotPoints: command.payload['noPlayersGotPoints'],
              );
              break;
            case Lv02LuckState.game_weel:
              subScreen = LuckWheelScreen(
                wheelData: command.payload['weelData'] ?? [],
                onAnswered: command.payload['onAnswered'],
                roomId: command.payload['roomId'],
              );

              break;
            case Lv02LuckState.result_weel:
              subScreen = LuckWheelResultsScreen(
                resultData: command.payload['resultData'] ?? [],
              );

              break;
            case Lv02LuckState.drinkingMode:
              subScreen = DrinkStageScreen(
                onStageComplete: command.payload['onDrinkComplete'],
              );
              break;
          }
        }
        return subScreen;
      },
    );
  }
}
