// nexaburst/lib/screens/room/game/drink/drink_instraction.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// A screen that shows a drink instruction and countdown timer.
///
/// Plays sounds and allows the user to confirm or fail the drinking action.
class DrinkInstructionScreen extends StatefulWidget {
  /// The instruction message to display to the user.
  final String message;

  /// Callback invoked when the drinking action completes (success or fail).
  final VoidCallback onDrinkingComplete;

  /// Creates a [DrinkInstructionScreen] with a message and completion callback.
  const DrinkInstructionScreen({
    super.key,
    required this.message,
    required this.onDrinkingComplete,
  });

  /// Creates mutable state for [DrinkInstructionScreen].
  @override
  _DrinkInstructionScreenState createState() => _DrinkInstructionScreenState();
}

/// State class for [DrinkInstructionScreen], manages timer, sounds, and UI.
class _DrinkInstructionScreenState extends State<DrinkInstructionScreen> {
  int _remaining = ScreenDurations.drinkScreenTime;
  late final StreamSubscription<int> _sub;
  bool cheering = false;

  /// Plays the start sound, listens to the countdown stream, and
  /// auto‑completes when time runs out.
  @override
  void initState() {
    super.initState();
    UserData.instance.playSound(AudioPaths.drink_sound);
    _sub = TimerManager.instance.getTime().listen((secs) {
      if (!mounted) return;
      setState(() => _remaining = secs);
      if (_remaining <= 0) {
        _completeDrink(success: false);
      }
    });
  }

  /// Toggles background cheering music on or off.
  Future<void> _toggleCheering() async {
    setState(() => cheering = !cheering);
    if (cheering) {
      await UserData.instance.playBackgroundMusic(AudioPaths.drink_music);
    } else {
      await UserData.instance.stopBackgroundMusic(clearFile: true);
    }
  }

  /// Completes the drinking stage, plays success/fail sound, waits, then invokes callback.
  ///
  /// - [success]: true for successful drink, false for timeout/fail.
  Future<void> _completeDrink({required bool success}) async {
    await UserData.instance.stopBackgroundMusic(clearFile: true);
    await UserData.instance.playSound(
      success ? AudioPaths.drink_success : AudioPaths.drink_fail,
    );
    await Future.delayed(const Duration(seconds: 2));
    widget.onDrinkingComplete();
  }

  /// Cleans up timer subscription and stops music when disposed.
  @override
  void dispose() {
    _sub.cancel();
    UserData.instance.stopBackgroundMusic(clearFile: true);
    super.dispose();
  }

  /// Builds the instruction UI with message, confirm button, and cheer toggle.
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          final messageFont = w * 0.09;
          final buttonFont = w * 0.05;
          final spaceSize = h * 0.04;

          return Container(
            width: double.infinity,
            height: h,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                // כאן אנחנו אומרים: השטח המינימלי שה־Column יתפוס = h
                constraints: BoxConstraints(minHeight: h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: spaceSize * 2),

                    // Message Box עם רקע שקוף
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: messageFont,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    SizedBox(height: spaceSize * 1.2),

                    // Main Confirm Button
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: w * 0.7,
                        minWidth: w * 0.3,
                      ),
                      child: ElevatedButton(
                        onPressed: () => _completeDrink(success: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent3,
                          padding: EdgeInsets.symmetric(vertical: h * 0.01),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: Text(
                          '${TranslationService.instance.t('game.modes.drinking_mode.confirm_drink_button')}!',
                          style: TextStyle(
                            fontSize: buttonFont,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),

                    // Cheer Toggle Button (Text Button)
                    Container(
                      alignment: Alignment.centerRight,
                      margin: const EdgeInsets.only(top: 8),
                      child: TextButton(
                        onPressed: _toggleCheering,
                        style: TextButton.styleFrom(
                          backgroundColor: cheering
                              ? const Color.fromARGB(144, 70, 137, 214)
                              : const Color.fromARGB(90, 0, 0, 0),
                          foregroundColor: const Color.fromARGB(
                            211,
                            165,
                            173,
                            49,
                          ),
                          textStyle: TextStyle(
                            fontSize: buttonFont * 0.8,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        child: Text(
                          cheering
                              ? TranslationService.instance.t(
                                  'game.modes.drinking_mode.stop_cheer_button',
                                )
                              : TranslationService.instance.t(
                                  'game.modes.drinking_mode.start_cheer_button',
                                ),
                        ),
                      ),
                    ),

                    SizedBox(height: spaceSize * 2),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
