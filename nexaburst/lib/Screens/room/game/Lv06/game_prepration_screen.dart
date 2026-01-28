// nexaburst/lib/screens/room/game/Lv06/game_prepration_screen.dart

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// A countdown preparation screen showing an animated hourglass and remaining seconds.
class GamePreparationScreen extends StatefulWidget {
  const GamePreparationScreen({super.key});

  /// Creates state for [GamePreparationScreen].
  @override
  _GamePreparationScreenState createState() => _GamePreparationScreenState();
}

/// State for [GamePreparationScreen], controlling animation and timer subscription.
class _GamePreparationScreenState extends State<GamePreparationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _progressAnim;
  late final StreamSubscription<int> _timerSub;
  late int _remainingTime;
  final int totalTime = ScreenDurations.generalGameTime;

  /// Starts the countdown animation, ticking sound, and listens for timer updates.
  @override
  void initState() {
    super.initState();
    _startMusic();

    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalTime),
    );
    _progressAnim =
        Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _animController, curve: Curves.linear),
        )..addListener(() {
          setState(() {});
        });
    _animController.repeat();

    _remainingTime = totalTime;
    _timerSub = TimerManager.instance.getTime().listen(
      (seconds) {
        if (!mounted) return;
        setState(() {
          _remainingTime = seconds.clamp(0, totalTime);
        });
      },
      onDone: () {
        if (!mounted) return;
        _animController.stop();
        UserData.instance.stopBackgroundMusic(clearFile: true);
      },
    );
  }

  /// Plays the ticking background music until preparation completes.
  Future<void> _startMusic() async {
    await UserData.instance.playBackgroundMusic(AudioPaths.tikTak);
  }

  /// Stops music, cancels timer, and disposes animation controller.
  @override
  void dispose() {
    UserData.instance.stopBackgroundMusic(clearFile: true);
    _timerSub.cancel();
    _animController.dispose();
    super.dispose();
  }

  /// Builds the layout: title text, animated hourglass, and remaining time label.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final canvasSize =
            min(width, height) * 0.6; // 60% of the smaller dimension

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: height * 0.02),
                    child: Text(
                      TranslationService.instance.t('game.levels.${TranslationService.instance.levelKeys[5]}.pre_game'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  SizedBox(
                    width: canvasSize,
                    height: canvasSize,
                    child: CustomPaint(
                      painter: _SmoothHourglassPainter(
                        progress: _progressAnim.value,
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                  Text(
                    '$_remainingTime s',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: width * 0.04,
                      color: _remainingTime > 7
                          ? Colors.blue
                          : (_remainingTime > 4 ? Colors.yellow : Colors.red),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A painter that draws a smooth hourglass with flowing sand based on [progress].
class _SmoothHourglassPainter extends CustomPainter {
  final double progress;
  final Paint _framePaint;
  final Paint _sandPaint;
  final Path _topTriangle;
  final Path _bottomTriangle;

  _SmoothHourglassPainter({required this.progress})
    : _framePaint = Paint()
        ..color = Colors.brown.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0,
      _sandPaint = Paint()..color = Colors.amberAccent,
      _topTriangle = Path(),
      _bottomTriangle = Path() {
    // Top (inverted) triangle path in normalized coordinates (0..1)
    _topTriangle
      ..moveTo(0, 0)
      ..lineTo(1, 0)
      ..lineTo(0.5, 0.5)
      ..close();

    // Bottom triangle path in normalized coordinates (0..1)
    _bottomTriangle
      ..moveTo(0, 1)
      ..lineTo(1, 1)
      ..lineTo(0.5, 0.5)
      ..close();
  }

  /// Paints the hourglass frame, the top and bottom sand fill according to [progress],
  /// and animates individual falling grains.
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midX = w / 2;
    final midY = h / 2;

    // 1) Draw frame (an “X”-shaped outline connecting the four corners).
    canvas.drawLine(Offset(0, 0), Offset(w, 0), _framePaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), _framePaint);
    canvas.drawLine(Offset(0, h), Offset(w, h), _framePaint);
    canvas.drawLine(Offset(w, h), Offset(0, 0), _framePaint);

    // 2) Draw Top Sand (inverted triangle):
    canvas.save();
    canvas.scale(w, h);
    canvas.clipPath(_topTriangle);
    canvas.drawRect(
      Rect.fromLTWH(0, 0.5 - 0.5 * (1 - progress), 1, 0.5 * (1 - progress)),
      _sandPaint,
    );
    canvas.restore();

    // 3) Draw Bottom Sand (regular triangle, filling upward from y = 1 → y = 0.5):
    canvas.save();
    canvas.scale(w, h);
    canvas.clipPath(_bottomTriangle);
    canvas.drawRect(
      Rect.fromLTWH(0, 1 - 0.5 * progress, 1, 0.5 * progress),
      _sandPaint,
    );
    canvas.restore();

    // 4) Draw “falling sand” particles from the neck (y=0.5*h) down to bottom (y=h),
    //    but force their first dx to be exactly midX so they appear to originate at the center.

    final dropPaint = Paint()..color = Colors.orangeAccent;
    final bottomSandTopY =
        (1 - 0.5 * progress) * h; // y at which bottom sand begins
    final topSandBottomY = 0.5 * h; // neck y

    const dropCount = 5;
    for (int i = 0; i < dropCount; i++) {
      // dp = “local time” for grain i, looped around via %1
      final dp = (progress + i / dropCount) % 1;

      // Compute its y-position: from midY → h
      final dy = lerpDouble(topSandBottomY, h, dp)!;

      // If the grain has not yet reached the top of the bottom sand, draw it:
      if (dy < bottomSandTopY) {
        // If dp is very near 0, treat this as “first appearance” and put dx exactly at midX
        final isStarting = dy >= topSandBottomY;

        // Otherwise offset by a small horizontal spread
        final spreadX = (i - dropCount / 2) * w * 0.02;

        final dx = isStarting ? midX : (midX + spreadX);
        canvas.drawCircle(Offset(dx, dy), w * 0.01, dropPaint);
      }
    }
  }

  /// Returns true when [progress] has changed, triggering a repaint.
  @override
  bool shouldRepaint(covariant _SmoothHourglassPainter old) {
    return old.progress != progress;
  }
}




/*
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui';

void main() => runApp(const HourglassApp());

class HourglassApp extends StatelessWidget {
  const HourglassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hourglass Animation with Timer',
      home: Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: HourglassAnimation(
            totalRunDuration: Duration(seconds: 20), // ← run for 20 seconds total
          ),
        ),
      ),
    );
  }
}

class HourglassAnimation extends StatefulWidget {
  /// The total amount of time for which the sand‐fall animation should repeat.
  /// Once this duration elapses, the animation stops.
  final Duration totalRunDuration;

  const HourglassAnimation({
    super.key,
    required this.totalRunDuration,
  });

  @override
  State<HourglassAnimation> createState() => _HourglassAnimationState();
}


class _HourglassAnimationState extends State<HourglassAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _sandAnimation;
  Timer? _stopTimer;

  @override
  void initState() {
    super.initState();

    // 1) Create the AnimationController that drives one "sand‐fall" cycle of 5 seconds.
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    // 2) Wrap it in a linear Tween from 0.0 → 1.0.
    _sandAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.linear),
    )..addListener(() {
        setState(() {
          // Rebuild so that CustomPaint sees updated progress.
        });
      });

    // 3) Start repeating indefinitely.
    _animController.repeat();

    // 4) Kick off a one‐shot Timer that will fire after widget.totalRunDuration.
    //    When it fires, we stop the animation controller so nothing more animates.
    _stopTimer = Timer(widget.totalRunDuration, () {
      _animController.stop();
      // Optionally, you could also call setState() here if you want to draw
      // something “final” or show some “finished” UI. For now, we simply stop.
    });
  }

  @override
  void dispose() {
    // Cancel the timer if still active:
    _stopTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final canvasSize = min(width, height) * 0.6; // 60% of the smaller dimension
        return Center(
          child: SizedBox(
            width: canvasSize,
            height: canvasSize,
            child: CustomPaint(
              painter: _SmoothHourglassPainter(progress: _sandAnimation.value),
            ),
          ),
        );
      },
    );
  }
}

class _SmoothHourglassPainter extends CustomPainter {
  final double progress;
  final Paint _framePaint;
  final Paint _sandPaint;
  final Path _topTriangle;
  final Path _bottomTriangle;

  _SmoothHourglassPainter({required this.progress})
      : _framePaint = Paint()
          ..color = Colors.brown.shade700
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0,
        _sandPaint = Paint()..color = Colors.amberAccent,
        _topTriangle = Path(),
        _bottomTriangle = Path() {
    // Top (inverted) triangle path in normalized coordinates (0..1)
    _topTriangle
      ..moveTo(0, 0)
      ..lineTo(1, 0)
      ..lineTo(0.5, 0.5)
      ..close();

    // Bottom triangle path in normalized coordinates (0..1)
    _bottomTriangle
      ..moveTo(0, 1)
      ..lineTo(1, 1)
      ..lineTo(0.5, 0.5)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midX = w / 2;
    final midY = h / 2;

    // 1) Draw frame (an “X”-shaped outline connecting the four corners).
    canvas.drawLine(Offset(0, 0), Offset(w, 0), _framePaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), _framePaint);
    canvas.drawLine(Offset(0, h), Offset(w, h), _framePaint);
    canvas.drawLine(Offset(w, h), Offset(0, 0), _framePaint);

    // 2) Draw Top Sand (inverted triangle):
    canvas.save();
    canvas.scale(w, h);
    canvas.clipPath(_topTriangle);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0.5 - 0.5 * (1 - progress),
        1,
        0.5 * (1 - progress),
      ),
      _sandPaint,
    );
    canvas.restore();

    // 3) Draw Bottom Sand (regular triangle, filling upward from y = 1 → y = 0.5):
    canvas.save();
    canvas.scale(w, h);
    canvas.clipPath(_bottomTriangle);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        1 - 0.5 * progress,
        1,
        0.5 * progress,
      ),
      _sandPaint,
    );
    canvas.restore();

    // 4) Draw “falling sand” particles from the neck (y=0.5*h) down to bottom (y=h),
    //    but force their first dx to be exactly midX so they appear to originate at the center.

    final dropPaint = Paint()..color = Colors.orangeAccent;
    final bottomSandTopY = (1 - 0.5 * progress) * h; // y at which bottom sand begins
    final topSandBottomY = 0.5 * h;                  // neck y

    const dropCount = 5;
    for (int i = 0; i < dropCount; i++) {
      // dp = “local time” for grain i, looped around via %1
      final dp = (progress + i / dropCount) % 1;

      // Compute its y-position: from midY → h
      final dy = lerpDouble(topSandBottomY, h, dp)!;

      // If the grain has not yet reached the top of the bottom sand, draw it:
      if (dy < bottomSandTopY) {
        // If dp is very near 0, treat this as “first appearance” and put dx exactly at midX
        final isStarting = dy>=topSandBottomY;

        // Otherwise offset by a small horizontal spread
        final spreadX = (i - dropCount / 2) * w * 0.02;

        final dx = isStarting ? midX : (midX + spreadX);
        canvas.drawCircle(Offset(dx, dy), w * 0.01, dropPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SmoothHourglassPainter old) {
    return old.progress != progress;
  }
}

*/