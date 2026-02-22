// nexaburst/lib/screens/room/game/levels_managers/Lv01_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/room/game/Lv01-04/round_summary.dart';
import 'package:nexaburst/Screens/room/game/drink/drink_manager_screen.dart';
import 'package:nexaburst/Screens/room/game/manager_screens/loading_screen.dart';
import 'package:nexaburst/model_view/room/game/Levels/level1/Lv01_manager.dart';
import 'package:nexaburst/Screens/room/game/Lv01-04/Lv01/question_screen.dart';

/// A screen driving the Knowledge (Level 1) stage of the game.
///
/// Listens to commands from [Lv01knowledgeStageManager] and switches
/// between question, loading, result summary, and drinking sub‑screens.
class KnowledgeStageScreen extends StatefulWidget {
  /// Callback invoked when the stage completes (including any drinking sub‑stage).
  final VoidCallback onStageComplete;

  /// Manager providing the command stream and stage logic for Level 1.
  final Lv01knowledgeStageManager stageManager;

  /// Creates a [KnowledgeStageScreen] with the given stage manager and completion callback.
  const KnowledgeStageScreen({
    super.key,
    required this.onStageComplete,
    required this.stageManager,
  });

  /// Creates mutable state for [KnowledgeStageScreen].
  @override
  _KnowledgeStageScreenState createState() => _KnowledgeStageScreenState();
}

/// State class for [KnowledgeStageScreen].
///
/// Starts the level flow, disposes the manager, and builds sub‑screens
/// based on incoming commands.
class _KnowledgeStageScreenState extends State<KnowledgeStageScreen> {
  /// Starts the level and invokes [onStageComplete] when done.
  @override
  void initState() {
    super.initState();

    // Start the stage flow.
    widget.stageManager.runLevel().then((_) {
      widget.onStageComplete();
    });
  }

  /// Disposes the stage manager when this widget is removed.
  @override
  void dispose() {
    widget.stageManager.dispose();
    super.dispose();
  }

  /// Builds the UI by listening to the level manager’s commandStream.
  ///
  /// Shows [LoadingScreen] until a command arrives, then switches on
  /// [Lv01KnowledgeState] to render the appropriate sub‑screen.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Lv01KnowledgeStageCommand>(
      stream: widget.stageManager.commandStream,
      builder: (context, snapshot) {
        Widget subScreen;
        if (!snapshot.hasData) {
          subScreen = LoadingScreen();
        } else {
          final command = snapshot.data!;

          switch (command.state) {
            case Lv01KnowledgeState.question:
              subScreen = QuestionScreen(
                questionText: command.payload['questionText'],
                answers:
                    command.payload['answers'] as Map<String, dynamic>? ?? {},
                onQuestionAnswered: command.payload['onQuestionAnswered'],
                currentAnswer: command.payload['correctAnswer'] ?? "",
              );
              break;
            case Lv01KnowledgeState.loading:
              subScreen = LoadingScreen();
              break;
            case Lv01KnowledgeState.result:
              subScreen = RoundSummaryScreen(
                playersAndAddedPoints: command.payload['resultData'] ?? {},
                playerCorrect: command.payload['playerCorrect'],
                noPlayersGotPoints: command.payload['noPlayersGotPoints'],
              );
              break;
            case Lv01KnowledgeState.drinkingMode:
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
