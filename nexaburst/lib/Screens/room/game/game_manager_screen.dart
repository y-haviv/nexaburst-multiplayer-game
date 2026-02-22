// nexaburst/lib/screens/room/game/game_manager_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/room/game_components/background_game.dart';
import 'package:nexaburst/Screens/menu/menu_screen.dart';
import 'package:nexaburst/Screens/room/game/drink/drink_manager_screen.dart';
import 'package:nexaburst/Screens/room/game/levels_managers/Lv01_manager_screen.dart';
import 'package:nexaburst/Screens/room/game/levels_managers/Lv02_manager_screen.dart';
import 'package:nexaburst/Screens/room/game/levels_managers/Lv03_manager_screen.dart';
import 'package:nexaburst/Screens/room/game/levels_managers/Lv04_manager_screen.dart';
import 'package:nexaburst/Screens/room/game/levels_managers/Lv05_manager_screen.dart';
import 'package:nexaburst/Screens/room/game/levels_managers/Lv06_manager_screen.dart';
import 'package:nexaburst/Screens/room/game/manager_screens/final_summary_screen.dart';
import 'package:nexaburst/Screens/room/game/manager_screens/game_over_screen.dart';
import 'package:nexaburst/Screens/room/game/manager_screens/instruction_screen.dart';
import 'package:nexaburst/Screens/room/game/manager_screens/loading_screen.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/room/game/game_manager.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:nexaburst/models/structures/room_model.dart';

/// The main screen that manages the flow of game stages.
///
/// Listens to updates from [MainGameManager] and displays the appropriate UI
/// based on the current [GameScreenState], such as instruction screens, level stages,
/// final summary, and game over screens.
class GameScreen extends StatefulWidget {
  /// The main game manager responsible for controlling game logic and broadcasting UI commands.
  final MainGameManager gameManager;

  const GameScreen({super.key, required this.gameManager});

  /// Creates the mutable state for this widget.
  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// Handles the UI logic and state transitions for the game screen.
///
/// Subscribes to game status and error streams, displays the appropriate stage or
/// game-related screen, and ensures cleanup on dispose.
class _GameScreenState extends State<GameScreen> {
  /// A local reference to the passed [MainGameManager] for easier access.
  late final MainGameManager _gameManager = widget.gameManager;

  /// Subscription to listen for room status updates (e.g., game over).
  late StreamSubscription<RoomStatus> _statusSub;

  /// Subscription to listen for critical game errors and display dialogs accordingly.
  late StreamSubscription<ErrorType> _errorSub;

  /// (Unused) Placeholder for a list of all level keys if needed in future logic.
  late List<String> allLevels;

  bool _blockedMultypleNavigations = false;

  /// Initializes the game screen, sets the UI as ready, and starts listening
  /// to status and error updates from the game manager and error service.
  @override
  void initState() {
    super.initState();

    // Wait until the first frame is drawn, then signal the game manager.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gameManager.setUIReady();
    });

    /// Subscribes to status changes and navigates back to the menu if the game is over.
    _statusSub = widget.gameManager.statusStream.listen((newStatus) async {
      if (newStatus == RoomStatus.over && !_blockedMultypleNavigations) {
        _blockedMultypleNavigations = true;
        // 3) Finally navigate back to menu, clearing the stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => Menu()),
          (route) => false,
        );
      }
    });

    /// Subscribes to error events and displays a modal dialog before navigating to the menu.
    _errorSub = ErrorService.instance.errors().listen((newStatus) async {
      if (_blockedMultypleNavigations) return;
      _blockedMultypleNavigations = true;

      _handleNavigationOrDialog(() async {
        // 1) Show a SnackBar so the user sees “Game Over”
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            scrollable: true,
            title: Text(
              TranslationService.instance.t('errors.game.game_error_title'),
            ),
            content: Text(newStatus.toString()),
            insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  TranslationService.instance.t('screens.common.confirm'),
                ),
              ),
            ],
          ),
        ).then((_) {
          if (!mounted) return;
          // 3) Finally navigate back to menu, clearing the stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => Menu()),
            (route) => false,
          );
        });
      });
    });
  }

  void _handleNavigationOrDialog(Function action) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action();
    });
  }

  /// Cleans up subscriptions and disposes resources when the widget is removed from the tree.
  @override
  void dispose() {
    debugPrint("Disposing game manager and presence manager...");
    _statusSub.cancel();
    _errorSub.cancel();
    _gameManager.dispose();
    ErrorService.instance.dispose();
    super.dispose();
  }

  /// Builds the appropriate screen based on the current [MainGameManagerCommand].
  ///
  /// Handles transitions between instruction, game stage, summary, and game over screens.
  @override
  Widget build(BuildContext context) {
    /// Listens to game commands and renders the corresponding game screen.
    return StreamBuilder<MainGameManagerCommand>(
      stream: _gameManager.commandStream,
      builder: (context, snapshot) {
        Widget screen;
        String levelName = "";

        /// Shows a loading screen while waiting for the first game command.
        if (!snapshot.hasData) {
          debugPrint("No data in the snapshot");
          screen = LoadingScreen();
        } else {
          final command = snapshot.data!;
          debugPrint("Command: $command");

          /// Displays the corresponding screen based on the current game state.
          switch (command.state) {
            /// Displays the instruction screen with text payload from the game manager.
            case GameScreenState.instructions:
              screen = InstructionsScreen(
                instructions: command.payload['instructions'] as String,
              );
              break;
            case GameScreenState.stage:
              levelName = command.payload['stageName'];
              final level = command.payload['Level'];
              final onComplete =
                  command.payload['onLevelComplete'] as VoidCallback;

              /// Loads and displays the game stage screen corresponding to the current level name.
              ///
              /// Dynamically selects the stage widget based on the level index.
              int levelId = 0;
              for (
                int i = 0;
                i < TranslationService.instance.levelKeys.length;
                i++
              ) {
                if (TranslationService.instance.levelKeys[i] == levelName) {
                  levelId = i;
                }
              }

              switch (levelId) {
                case 0:
                  screen = KnowledgeStageScreen(
                    onStageComplete: onComplete,
                    stageManager: level,
                  );
                  break;
                case 1:
                  screen = LuckStageScreen(
                    onStageComplete: onComplete,
                    stageManager: level,
                  );
                  break;
                case 2:
                  screen = intelligenceStageScreen(
                    onStageComplete: onComplete,
                    stageManager: level,
                  );
                  break;
                case 3:
                  screen = SocialStageScreen(
                    onStageComplete: onComplete,
                    stageManager: level,
                  );
                  break;
                case 4:
                  screen = Lv05ManagerScreenState(
                    onStageComplete: onComplete,
                    stageManager: level,
                  );
                  break;
                case 5:
                  screen = TrustStageScreen(
                    onStageComplete: onComplete,
                    stageManager: level,
                  );
                  break;
                default:
                  screen = Center(
                    child: Text(
                      TranslationService.instance.t('errors.game.unknow_level'),
                    ),
                  );
                  break;
              }
              break;

            /// Shows the final game summary with player rankings and scores.
            case GameScreenState.finalSummary:
              screen = FinalSummaryScreen(
                players: command.payload['players'] as Map<String, dynamic>,
                currentPlayerId: UserData.instance.user!.id,
              );
              break;

            /// Shows the game over screen with the winner and player results.
            case GameScreenState.gameOver:
              screen = GameOverScreen(
                players: command.payload['players'],
                winner: command.payload['winner'],
                currentPlayerId: UserData.instance.user!.id,
              );
              break;

            /// Shows the drinking mode screen for special intermission gameplay.
            case GameScreenState.drinkingMode:
              screen = DrinkStageScreen(
                onStageComplete: command.payload['onDrinkComplete'],
              );
              break;
          }
        }

        /// Wraps the selected screen with a background and overlays any global elements.
        return gameBackground(roomId: widget.gameManager.roomId, child: screen);
      },
    );
  }
}
