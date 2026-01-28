// nexaburst/lib/screens/room/game/levels_managers/Lv03_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/room/game/Lv01-04/Lv03/intelligence_question_screen.dart';
import 'package:nexaburst/Screens/room/game/Lv01-04/round_summary.dart';
import 'package:nexaburst/Screens/room/game/drink/drink_manager_screen.dart';
import 'package:nexaburst/Screens/room/game/manager_screens/loading_screen.dart';
import 'package:nexaburst/model_view/room/game/Levels/level3/Lv03_manager.dart';

/// A screen that orchestrates the Intelligence stage (Level 3) of the game.
///
/// Listens to the [Lv03IntelligenceStageManager] command stream and
/// renders the appropriate sub-screen based on the current stage state.
class intelligenceStageScreen extends StatefulWidget {
  /// Callback invoked when the entire intelligence stage (including any drinking sub‑stage) completes.
  final VoidCallback onStageComplete;

  /// Manager responsible for running the intelligence questions and state commands.
  final Lv03IntelligenceStageManager stageManager;

  /// Creates an [intelligenceStageScreen] with the given stage manager and completion callback.
  const intelligenceStageScreen({
    super.key,
    required this.onStageComplete,
    required this.stageManager,
  });

  /// Creates mutable state for the intelligence stage screen.
  @override
  _intelligenceStageScreen createState() => _intelligenceStageScreen();
}

/// State class for [intelligenceStageScreen], which starts the level flow,
/// disposes the manager, and builds sub‑screens based on incoming commands.
class _intelligenceStageScreen extends State<intelligenceStageScreen> {
  /// Starts the intelligence level and calls [onStageComplete] when done.
  @override
  void initState() {
    super.initState();

    // Start the stage flow.
    widget.stageManager.runLevel().then((_) {
      widget.onStageComplete();
    });
  }

  /// Disposes the stage manager when this widget is removed from the tree.
  @override
  void dispose() {
    widget.stageManager.dispose();
    super.dispose();
  }

  /// Builds the UI by listening to [stageManager.commandStream] and rendering
  /// either [LoadingScreen], [Lv03QuestionScreen], [RoundSummaryScreen], or
  /// [DrinkStageScreen], based on the current [Lv03IntelligenceState].
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Lv03IntelligenceStageCommand>(
      stream: widget.stageManager.commandStream,
      builder: (context, snapshot) {
        Widget subScreen;
        if (!snapshot.hasData) {
          subScreen = LoadingScreen();
        } else {
          final command = snapshot.data!;

          switch (command.state) {
            case Lv03IntelligenceState.question:
              subScreen = Lv03QuestionScreen(
                questionText: command.payload['questionText'],
                answers:
                    command.payload['answers'] as Map<String, dynamic>? ?? {},
                onQuestionAnswered: command.payload['onQuestionAnswered'],
                currentAnswer: command.payload['correctAnswer'] ?? "",
              );
              break;
            case Lv03IntelligenceState.loading:
              subScreen = LoadingScreen();
              break;
            case Lv03IntelligenceState.result:
              subScreen = RoundSummaryScreen(
                playersAndAddedPoints: command.payload['resultData'] ?? {},
                playerCorrect: command.payload['playerCorrect'],
                noPlayersGotPoints: command.payload['noPlayersGotPoints'],
              );
              break;
            case Lv03IntelligenceState.drinkingMode:
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
