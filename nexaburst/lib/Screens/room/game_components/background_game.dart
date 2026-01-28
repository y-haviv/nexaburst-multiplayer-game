// nexaburst/lib/screens/game_components/background_game.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/room/game_components/parmanent_button_overplay.dart';
import 'package:nexaburst/constants.dart';

/// A background wrapper widget for game screens.
///
/// Provides a common background gradient and background image.
/// Includes a top bar with persistent controls and renders the provided
/// child widget below it.
///
/// Typically used to wrap game-related screens consistently.
class gameBackground extends StatelessWidget {
  /// The main content widget to be displayed in the game area.
  final Widget child;

  /// The unique room ID associated with the current game session.
  final String roomId;

  /// Constructs a [gameBackground] widget.
  ///
  /// Requires a [child] widget and a [roomId] for identifying the game room.
  const gameBackground({super.key, required this.child, required this.roomId});

  /// Builds the game background with a top bar and gradient + image overlay.
  ///
  /// Returns a [Scaffold] with a [Stack] containing:
  /// - A background image with gradient.
  /// - A column with a constrained top overlay (e.g., buttons) and the main content.
  @override
  Widget build(BuildContext context) {
    final totalHeight = MediaQuery.of(context).size.height;

    final paddingTop = MediaQuery.of(context).padding.top;
    final paddingBot = MediaQuery.of(context).padding.bottom;

    final availableHeight = totalHeight - paddingTop - paddingBot;

    final maxTopBarHeight = availableHeight * 0.25;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(PicPaths.mainBackground, fit: BoxFit.cover),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxTopBarHeight,
                      minHeight: 0,
                    ),
                    child: PermanentButtonsOverlay(roomId: roomId),
                  ),

                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
