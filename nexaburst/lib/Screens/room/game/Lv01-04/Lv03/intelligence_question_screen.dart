// nexaburst/lib/screens/room/game/Lv01-04/Lv03/intelligence_question_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';

/// A questionnaire screen for the Intelligence stage (Level 3).
///
/// Displays the question, optional image, four shuffled answer buttons,
/// and a countdown timer. Returns the time taken if correct, or -1 otherwise.
class Lv03QuestionScreen extends StatefulWidget {
  /// The question text to present to the player.
  final String questionText;

  /// The correct answer key used to validate the player’s selection.
  final String currentAnswer;

  /// Map of answer keys to their display text. May include an 'image' entry.
  final Map<String, dynamic> answers;

  /// Callback receiving the time taken (in seconds) for correct answers, or -1 for incorrect/timeout.
  final Function(double) onQuestionAnswered;

  /// Creates an [Lv03QuestionScreen] with the given question, answers, and callback.
  const Lv03QuestionScreen({
    super.key,
    required this.questionText,
    required this.answers,
    required this.onQuestionAnswered,
    required this.currentAnswer,
  });

  /// Creates mutable state for [Lv03QuestionScreen].
  @override
  _Lv03QuestionScreenState createState() => _Lv03QuestionScreenState();
}

/// State class for [Lv03QuestionScreen], managing timer, music, and user interactions.
class _Lv03QuestionScreenState extends State<Lv03QuestionScreen> {
  late final StreamSubscription<int> _tapSub;

  late List<String> _answerKeys; // Shuffled answer keys.
  String? _imagePath; // Optional image if provided.
  bool _answered = false;

  late int _remainingTime;
  final int totalTime = ScreenDurations.generalGameTime;

  /// Begins background music playback and starts the countdown timer.
  /// Shuffles answer keys and extracts an optional image path.
  @override
  void initState() {
    super.initState();
    _startMusic();
    _startTimer();
    _answerKeys = widget.answers.keys.toList();
    _answerKeys.shuffle();

    // If there's an image defined in the answers map, use it and remove its key.
    if (widget.answers.containsKey('image')) {
      _imagePath = widget.answers['image'];
      _answerKeys.remove('image');
    }
  }

  /// Plays the ticking background music for the question timer.
  Future<void> _startMusic() async {
    await UserData.instance.playBackgroundMusic(AudioPaths.tikTak);
  }

  /// Starts the countdown timer using [TimerManager], and if time expires
  /// without an answer, invokes [onQuestionAnswered] with -1.
  void _startTimer() {
    _tapSub = TimerManager.instance.getTime().listen((remaining) {
      _remainingTime = remaining;
      if (remaining <= 0) {
        if (!_answered) widget.onQuestionAnswered(-1);
      }
    });
  }

  /// Handles cleanup by stopping music and cancelling the timer subscription.
  @override
  void dispose() {
    UserData.instance.stopBackgroundMusic(clearFile: true);
    _tapSub.cancel();
    super.dispose();
  }

  /// Processes the player’s chosen answer. If correct, calculates time taken;
  /// otherwise returns -1. Ensures only a single response is processed.
  void _handleAnswer(String chosenKey) {
    if (_answered) return;
    _answered = true;

    if (chosenKey == widget.currentAnswer) {
      double timeTaken = totalTime.toDouble() - _remainingTime;
      widget.onQuestionAnswered(timeTaken);
    } else {
      widget.onQuestionAnswered(-1.0);
    }
  }

  /// Builds the question UI, including:
  ///  - Centered question text with styled font
  ///  - Optional image display if provided
  ///  - A column of styled answer buttons in randomized order
  @override
  Widget build(BuildContext context) {
    // Using padding and a scrollable column to support various screen sizes.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Question text with modified font and spacing.
                Text(
                  widget.questionText,
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 5,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 25),

                // Display an optional image if provided.
                if (_imagePath != null)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 15),
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.30,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: AssetImage(_imagePath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Answer buttons.
                for (String key in _answerKeys)
                  _buildAnswerButton(key, width * 0.6),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a single answer button for [answerKey] at the given width,
  /// invoking `_handleAnswer` on tap.
  Widget _buildAnswerButton(String answerKey, double w) {
    String answerText = widget.answers[answerKey] ?? 'N/A';

    return Container(
      width: w,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: () => _handleAnswer(answerKey),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          answerText,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, color: Colors.white),
          maxLines: 3,
        ),
      ),
    );
  }
}
