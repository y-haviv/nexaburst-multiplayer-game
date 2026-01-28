// nexaburst/lib/screens/room/game/Lv01-04/Lv04/social_guess_question_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// A screen for Stage 4 (Social) shown to non‑target players.
///
/// Prompts players to guess what the target player would choose,
/// displays shuffled options, and runs a countdown timer.
/// Calls [onAnswerSubmitted] with the chosen key or "-1" on timeout.
class SocialGuessQuestionScreen extends StatefulWidget {
  /// The name of the target player being guessed.
  final String
  targetPlayerName; // The target player's name as given by the server.
  /// The scenario text describing the social question.
  final String scenarioText;

  /// Map of option keys to display text for the guess options.
  final Map<String, dynamic> options;

  /// Callback invoked with the selected option key, or "-1" if time runs out.
  final Function(String) onAnswerSubmitted;

  /// Creates a [SocialGuessQuestionScreen] for guessing the target’s choice.
  const SocialGuessQuestionScreen({
    super.key,
    required this.targetPlayerName,
    required this.scenarioText,
    required this.options,
    required this.onAnswerSubmitted,
  });

  /// Creates mutable state for [SocialGuessQuestionScreen].
  @override
  _SocialGuessQuestionScreenState createState() =>
      _SocialGuessQuestionScreenState();
}

/// State class that manages timer, shuffles options, and handles user input.
class _SocialGuessQuestionScreenState extends State<SocialGuessQuestionScreen> {
  late List<String> _optionKeys;
  bool _answered = false;
  late final StreamSubscription<int> _tapSub;

  /// Starts the countdown timer and auto‑submits "-1" if time expires without an answer.
  @override
  void initState() {
    super.initState();
    _tapSub = TimerManager.instance.getTime().listen((remaining) {
      if (remaining <= 0 && !_answered) {
        widget.onAnswerSubmitted("-1");
      }
    });

    // Shuffle option keys.
    _optionKeys = widget.options.keys.toList();
    _optionKeys.shuffle();
  }

  /// Cancels the timer subscription when disposing.
  @override
  void dispose() {
    _tapSub.cancel();
    super.dispose();
  }

  /// Handles the user’s answer selection, ensuring only one submission.
  void _handleAnswer(String chosenKey) {
    if (_answered) return;
    _answered = true;
    widget.onAnswerSubmitted(chosenKey);
  }

  /// Builds the UI with:
  /// - A title incorporating [targetPlayerName]
  /// - The [scenarioText]
  /// - A column of shuffled answer buttons
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title incorporating the target player's name.
                Text(
                  "${TranslationService.instance.t('game.levels.${TranslationService.instance.levelKeys[3]}.what_would')} ${widget.targetPlayerName} ${TranslationService.instance.t('game.levels.${TranslationService.instance.levelKeys[3]}.choose')}?",
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                // Scenario text.
                Text(
                  widget.scenarioText,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    backgroundColor: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                // Answer buttons.
                for (String key in _optionKeys)
                  _buildAnswerButton(key, width * 0.6),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds an individual answer button for [optionKey] at given width.
  Widget _buildAnswerButton(String optionKey, double width) {
    String answerText = widget.options[optionKey] ?? 'N/A';
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: () => _handleAnswer(optionKey),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrangeAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          answerText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Colors.white),
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
      ),
    );
  }
}
