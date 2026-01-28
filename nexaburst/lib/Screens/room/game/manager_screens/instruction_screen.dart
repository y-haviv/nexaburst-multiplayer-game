// nexaburst/lib/screens/room/game/manager_screens/instruction_screen.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// Displays a full-screen, scrollable instructions text for a game stage.
class InstructionsScreen extends StatefulWidget {
  /// The instruction text to display to the user.
  final String instructions;

  /// Creates an [InstructionsScreen] with the given instructions.
  const InstructionsScreen({super.key, required this.instructions});

  /// Creates mutable state for the instructions screen.
  @override
  _InstructionsScreenState createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  /// Builds a layout that adapts to screen size, showing a title and
  /// a scrollable container with the instruction text.
  @override
  Widget build(BuildContext context) {
    // LayoutBuilder to adapt to any size.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final double boxHeight = height * 0.8;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.1,
            vertical: height * 0.05,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationService.instance.t(
                      'screens.game.instructions_title',
                    ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: height * 0.05),

                  SizedBox(
                    height: boxHeight,
                    width: double.infinity,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.instructions,
                          style: TextStyle(
                            fontSize: width * 0.045,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.05),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
