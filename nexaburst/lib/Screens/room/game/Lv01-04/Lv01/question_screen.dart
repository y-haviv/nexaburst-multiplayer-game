// nexaburst/lib/screens/room/game/Lv01-04/Lv01/question_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';

/// Displays a quiz question with optional image, multiple-choice answers,
/// and a countdown timer.
///
/// Returns the time taken if answered correctly, or -1 on timeout/incorrect.
class QuestionScreen extends StatefulWidget {
  /// The question text to display.
  final String questionText;

  /// The key corresponding to the correct answer in [answers].
  final String currentAnswer;

  /// Map of answer keys to answer text. May include an 'image' entry.
  final Map<String, dynamic> answers;

  /// Callback receiving the time taken (in seconds) or -1 on fail/timeout.
  final Function(double) onQuestionAnswered;

  /// Creates a [QuestionScreen] with question, possible answers, and answer callback.
  const QuestionScreen({
    super.key,
    required this.questionText,
    required this.answers,
    required this.onQuestionAnswered,
    required this.currentAnswer,
  });

  /// Creates mutable state for [QuestionScreen].
  @override
  _QuestionScreenState createState() => _QuestionScreenState();
}

/// State class for [QuestionScreen], managing timer, answer shuffling,
/// and user interactions.
class _QuestionScreenState extends State<QuestionScreen> {
  late List<String>
  _answerKeys; // Shuffled list of answer keys (e.g. ['a','b','c','d'])
  String? _imagePath; // Optional path to an image (if provided in answers)
  bool _answered = false;
  late int _remainingTime;
  final int totalTime = ScreenDurations.generalGameTime;
  StreamSubscription<int>? _timerSubscription;

  /// Initializes background music, shuffles answers, extracts optional image,
  /// and starts the countdown timer.
  @override
  void initState() {
    super.initState();
    UserData.instance.playBackgroundMusic(AudioPaths.tikTak);

    // Shuffle the answer keys to randomize the button order.
    _answerKeys = widget.answers.keys.toList();
    _answerKeys.shuffle();

    // If there's an 'image' key in the answers map, store it for later display.
    // Or you might pass the image path separately from the question data.
    if (widget.answers.containsKey('image')) {
      _imagePath = widget.answers['image'];
      // Remove 'image' from the main answer keys if it exists there.
      _answerKeys.remove('image');
    }

    _timerSubscription = TimerManager.instance.getTime().listen((remaining) {
      _remainingTime = remaining;
      if (remaining <= 0) {
        done(-1);
      }
    });
  }

  /// Handles the user's answer choice, calculates time or failure,
  /// stops music, and invokes [onQuestionAnswered].
  ///
  /// - [timeTaken]: Seconds elapsed (or -1.0 for incorrect/timeout).
  void done(double timeTaken) {
    UserData.instance.stopBackgroundMusic(clearFile: true);
    widget.onQuestionAnswered(timeTaken);
  }

  /// Cancels the timer subscription and stops any playing music.
  @override
  void dispose() {
    // Stop the timer when leaving the screen to avoid memory leaks.
    _timerSubscription?.cancel();
    UserData.instance.stopBackgroundMusic(clearFile: true);
    super.dispose();
  }

  /// Called when the user taps an answer. Prevents multiple taps,
  /// compares with [currentAnswer], and calls [done].
  void _handleAnswer(String chosenKey) {
    if (_answered) return;
    _answered = true;

    if (chosenKey == widget.currentAnswer) {
      double timeTaken = totalTime.toDouble() - _remainingTime;
      done(timeTaken);
    } else {
      done(-1.0);
    }
  }

  /// Builds the question UI with:
  /// - Centered question text
  /// - Optional image display
  /// - A column of answer buttons in random order
  /// - A countdown-based auto-completion
  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to adapt to any size.
    return LayoutBuilder(
      builder: (context, constraints) {
        debugPrint(
          'InstructionsScreen: hight- <max>=${constraints.maxHeight}, <min>=${constraints.minHeight}',
        );
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final spaceH = height * 0.04;
        debugPrint('InstructionsScreen: width=$width, height=$height');

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Question text
                Text(
                  widget.questionText,
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 5,
                ),

                SizedBox(height: spaceH),

                // Optional image
                if (_imagePath != null)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.25,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: AssetImage(_imagePath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                SizedBox(height: spaceH),

                // Answer buttons
                for (String key in _answerKeys)
                  _buildAnswerButton(key, width * 0.7),

                SizedBox(height: spaceH),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds an individual answer button for [answerKey],
  /// sizing to [width], and invoking [_handleAnswer] on tap.
  Widget _buildAnswerButton(String answerKey, double width) {
    String answerText = widget.answers[answerKey] ?? 'N/A';

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: () => _handleAnswer(answerKey),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.deepPurpleAccent, // Text color
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          answerText,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
    );
  }
}
