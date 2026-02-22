// nexaburst/lib/screens/room/game/levels_managers/LV05_managr_screen.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/room/game/Lv05/game_screen.dart';
import 'package:nexaburst/Screens/room/game/Lv05/over_play_screen.dart';
import 'package:nexaburst/Screens/room/game/Lv05/switch_mole_screen.dart';
import 'package:nexaburst/Screens/room/game/drink/drink_manager_screen.dart';
import 'package:nexaburst/Screens/room/game/manager_screens/loading_screen.dart';
import 'package:nexaburst/model_view/room/game/Levels/level5/Lv05_manager.dart';
import 'package:nexaburst/models/data/server/levels/level5/lv05.dart';

/// Manages the Whack‑A‑Mole stage (Level 5) flow by listening to [Lv05ReflexStageManager].
/// Renders game, switch‑mole, or drinking sub‑screens as commanded.
class Lv05ManagerScreenState extends StatefulWidget {
  /// Callback invoked when the entire Whack‑A‑Mole stage completes.
  final VoidCallback onStageComplete;

  /// Controller that coordinates stage commands and data.
  final Lv05ReflexStageManager stageManager;

  /// Creates a new [Lv05ManagerScreenState] using the given [stageManager]
  /// and [onStageComplete] callback.
  const Lv05ManagerScreenState({
    super.key,
    required this.onStageComplete,
    required this.stageManager,
  });

  /// Creates mutable state for the Whack‑A‑Mole manager screen.
  @override
  _Lv05ManagerScreenState createState() => _Lv05ManagerScreenState();
}

/// State class that initializes the level, listens to commands,
/// and wraps the appropriate sub‑screen in [Lv05WhackAMoleScreenWrapper].
class _Lv05ManagerScreenState extends State<Lv05ManagerScreenState> {
  late Lv05 _controller;

  /// Grabs the internal controller and starts the Whack‑A‑Mole stage.
  /// When [stageManager.runLevel] completes, invokes [onStageComplete].
  @override
  void initState() {
    super.initState();
    _controller = widget.stageManager.controller;

    // Begin the stage, and notify when done.
    widget.stageManager.runLevel().then((_) => widget.onStageComplete());
  }

  /// Disposes the [stageManager] when leaving the stage.
  @override
  void dispose() {
    widget.stageManager.dispose();
    super.dispose();
  }

  /// Builds UI by subscribing to [stageManager.commandStream] and
  /// selecting the correct sub‑screen for each [Lv05WhackAMoleState].
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Lv05WhackAMoleStageCommand>(
      stream: widget.stageManager.commandStream,
      builder: (context, snapshot) {
        final cmd = snapshot.data;
        Widget content;

        if (cmd == null) {
          content = LoadingScreen();
        } else {
          switch (cmd.state) {
            case Lv05WhackAMoleState.game:
              content = GameScreen(
                controller: _controller,
                isMolePlayer: cmd.payload['isMole'] as bool,
              );
              break;

            case Lv05WhackAMoleState.switchMole:
              content = SwitchMoleScreen(
                score: cmd.payload['scoreIncrement'] as int,
              );
              break;

            case Lv05WhackAMoleState.drinkingMode:
              content = DrinkStageScreen(
                onStageComplete: cmd.payload['onDrinkComplete'] as VoidCallback,
              );
              break;
          }
        }

        // Wrap in the common screen wrapper
        return Lv05WhackAMoleScreenWrapper(
          controller: _controller,
          screen: content,
        );
      },
    );
  }
}
