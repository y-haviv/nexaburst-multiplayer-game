// nexaburst/lib/screens/room/game/Lv01-04/Lv04/social_target_question_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// A screen for Stage 4 (Social) shown to the target player.
///
/// Presents the social scenario question and options,
/// runs a countdown timer, and calls [onAnswerSubmitted]
/// with the chosen key or "-1" if time runs out.
class SocialTargetQuestionScreen extends StatefulWidget {
  /// The scenario text that the target player must answer.
  final String scenarioText; // The social scenario question text.
  /// Map of answer options for the target’s question.
  final Map<String, dynamic>
  options; // Answer options (ex: { 'a': 'Option A', 'b': 'Option B', ... })
  /// Callback invoked with the selected option key, or "-1" on timeout.
  final Function(String) onAnswerSubmitted; // Callback with the answer key.

  /// Creates a [SocialTargetQuestionScreen] prompting the target player.
  const SocialTargetQuestionScreen({
    super.key,
    required this.scenarioText,
    required this.options,
    required this.onAnswerSubmitted,
  });

  /// Creates mutable state for [SocialTargetQuestionScreen].
  @override
  _SocialTargetQuestionScreenState createState() =>
      _SocialTargetQuestionScreenState();
}

/// State class that starts the timer, shuffles options, and handles input.
class _SocialTargetQuestionScreenState
    extends State<SocialTargetQuestionScreen> {
  late final StreamSubscription<int> _tapSub;
  late List<String> _optionKeys;
  bool _answered = false;

  /// Starts the countdown timer and auto‑submits "-1" if time expires.
  @override
  void initState() {
    super.initState();
    // Initialize timer countdown.
    _tapSub = TimerManager.instance.getTime().listen((remaining) {
      if (remaining <= 0 && !_answered) {
        widget.onAnswerSubmitted("-1");
      }
    });

    // Shuffle options keys for random order.
    _optionKeys = widget.options.keys.toList();
    _optionKeys.shuffle();
  }

  /// Cancels the timer subscription when disposing.
  @override
  void dispose() {
    _tapSub.cancel();
    super.dispose();
  }

  /// Handles the target player’s option selection.
  void _handleAnswer(String chosenKey) {
    if (_answered) return;
    _answered = true;
    widget.onAnswerSubmitted(chosenKey);
  }

  /// Builds the UI with:
  /// - Title indicating the target question
  /// - The [scenarioText]
  /// - A column of shuffled answer buttons
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        debugPrint('InstructionsScreen: width=$width, height=$height');

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title for target player.
                Text(
                  "${TranslationService.instance.t('game.levels.${TranslationService.instance.levelKeys[3]}.friends_know')}:",
                  style: TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Scenario text.
                Text(
                  widget.scenarioText,
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                // Answer options as buttons.
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
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: () => _handleAnswer(optionKey),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
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
