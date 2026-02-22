// nexaburst/lib/screens/room/game/levels_managers/Lv04_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/room/game/Lv01-04/Lv04/social_guess_question_screen.dart';
import 'package:nexaburst/Screens/room/game/Lv01-04/Lv04/social_target_question_screen.dart';
import 'package:nexaburst/Screens/room/game/Lv01-04/round_summary.dart';
import 'package:nexaburst/Screens/room/game/drink/drink_manager_screen.dart';
import 'package:nexaburst/Screens/room/game/manager_screens/loading_screen.dart';
import 'package:nexaburst/model_view/room/game/Levels/level4/Lv04_manager.dart';

/// A widget that orchestrates the Social stage (Level 4) of the game.
///
/// Listens to the [Lv04SocialStageManager] command stream and
/// renders the appropriate sub-screen based on the current state:
/// - Target question for the chosen player
/// - Guess question for others
/// - Loading, result summary, or drinking sub‑stages
class SocialStageScreen extends StatefulWidget {
  /// Callback invoked when the entire social stage completes, including any drinking sub‑stage.
  final VoidCallback onStageComplete;

  /// Manager responsible for controlling the flow and commands of the Social stage.
  final Lv04SocialStageManager stageManager;

  /// Creates a [SocialStageScreen] with the given [stageManager] and [onStageComplete] callback.
  const SocialStageScreen({
    super.key,
    required this.onStageComplete,
    required this.stageManager,
  });

  /// Creates mutable state for [SocialStageScreen].
  @override
  _SocialStageScreenState createState() => _SocialStageScreenState();
}

/// State class that starts the social stage, disposes resources, and
/// builds sub‑screens based on [Lv04SocialStageCommand] updates.
class _SocialStageScreenState extends State<SocialStageScreen> {
  /// State class that starts the social stage, disposes resources, and
  /// builds sub‑screens based on [Lv04SocialStageCommand] updates.
  @override
  void initState() {
    super.initState();

    // Start the stage flow.
    widget.stageManager.runLevel().then((_) {
      widget.onStageComplete();
    });
  }

  /// Disposes the [stageManager] when this widget is removed from the tree.
  @override
  void dispose() {
    widget.stageManager.dispose();
    super.dispose();
  }

  /// Builds the UI by listening to [stageManager.commandStream] and selecting
  /// the correct sub‑screen for each [Lv04SocialState].
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Lv04SocialStageCommand>(
      stream: widget.stageManager.commandStream,
      builder: (context, snapshot) {
        Widget subScreen;
        if (!snapshot.hasData) {
          subScreen = LoadingScreen();
        } else {
          final command = snapshot.data!;

          switch (command.state) {
            case Lv04SocialState.targetQuestion:
              subScreen = SocialTargetQuestionScreen(
                scenarioText: command.payload['scenario'],
                options: command.payload['options'] ?? {},
                onAnswerSubmitted: command.payload['onQuestionAnswered'],
              );
              break;
            case Lv04SocialState.guessQuestion:
              subScreen = SocialGuessQuestionScreen(
                targetPlayerName: command.payload['targetPlayerName'],
                scenarioText: command.payload['scenario'],
                options: command.payload['options'] ?? {},
                onAnswerSubmitted: command.payload['onQuestionAnswered'],
              );
              break;
            case Lv04SocialState.loading:
              subScreen = LoadingScreen();
              break;
            case Lv04SocialState.result:
              subScreen = RoundSummaryScreen(
                playersAndAddedPoints: command.payload['resultData'] ?? {},
                playerCorrect: command.payload['playerCorrect'],
                noPlayersGotPoints: command.payload['noPlayersGotPoints'],
              );
              break;
            case Lv04SocialState.drinkingMode:
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
