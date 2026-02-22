// nexaburst/lib/screens/room/game/Lv01-04/Lv02/luck_game_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';

/// Custom painter for drawing the table board used in the LuckGame screen.
///
/// It paints a 3x2 grid with brown strokes to simulate a physical game table.
class _TableBoardPainter extends CustomPainter {
  /// Draws vertical and horizontal lines to create the game board grid.
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.shade800
      ..strokeWidth = 2;

    final margin = 16.0;
    final w = size.width - margin * 2;
    final h = size.height - margin * 2;
    final colW = w / 3;
    final rowH = h / 2;

    // Vertical lines
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(margin + colW * i, margin),
        Offset(margin + colW * i, margin + h),
        paint,
      );
    }
    // Horizontal line
    canvas.drawLine(
      Offset(margin, margin + rowH),
      Offset(margin + w, margin + rowH),
      paint,
    );
  }

  /// Indicates that the board doesn't need to repaint since it is static.
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// A game widget for the "cup and coin" luck mini-game stage.
///
/// Displays three cups that may hide gold or black coins. The player selects a cup,
/// and the outcome is revealed with animations.
class LuckGame extends StatefulWidget {
  /// The index of the cup that hides the gold coin, as determined by the server.
  final int gold;

  /// The index of the cup that hides the black coin, as determined by the server.
  final int black;

  /// Callback triggered with the selected cup index (-1 if timeout occurs).
  final Function(int) onAnswered;

  /// Notifier used to trigger the reveal of coin contents beneath the cups.
  final ValueNotifier<bool> revealNotifier;

  const LuckGame({
    super.key,
    required this.gold,
    required this.black,
    required this.onAnswered,
    required this.revealNotifier,
  });

  @override
  _LuckGameState createState() => _LuckGameState();
}

/// State class for the [LuckGame] widget that handles animations, logic, and UI rendering.
class _LuckGameState extends State<LuckGame> with TickerProviderStateMixin {
  late AnimationController _coverCtrl;
  late Animation<double> _cupDrop;
  late Animation<double> _coinClip;
  final List<int> _cupOrder = [0, 1, 2];
  List<String?> _randomContents = [null, null, null];
  List<String?> _actualContents = [null, null, null];
  bool _revealed = false;
  late final StreamSubscription<int> _tapSub;

  bool _canTap = false;
  int? _selectedCup;
  final List<Alignment> _slots = [
    Alignment(-1, 0),
    Alignment(0, 0),
    Alignment(1, 0),
  ];

  @override
  void initState() {
    super.initState();

    // initialize coin positions randomly
    _initContents();

    _coverCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    // synchronized intervals
    _cupDrop = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(
        parent: _coverCtrl,
        curve: Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );
    _coinClip = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _coverCtrl,
        curve: Interval(0.3, 1.0, curve: Curves.easeIn), // Curves.easeIn
      ),
    );

    widget.revealNotifier.addListener(() {
      if (widget.revealNotifier.value) {
        _soundReveal();
        _coverCtrl.reverse().then((_) async {});
        setState(() => _revealed = true);
      }
    });

    Future.delayed(Duration(seconds: 2))
        .then((_) => _coverCtrl.forward())
        .then((_) => _performShuffle())
        .then((_) => _startChoicePhase());
  }

  /// Initializes the positions of coins randomly for display purposes,
  /// and sets the actual coin positions based on server values.
  void _initContents() {
    final positions = [0, 1, 2]..shuffle();
    _randomContents = [null, null, null];
    _randomContents[positions[0]] = 'gold';
    _randomContents[positions[1]] = 'black';

    // actualContents seeded from input:
    _actualContents = [null, null, null];
    _actualContents[widget.gold] = 'gold';
    _actualContents[widget.black] = 'black';

    // Debug:
    debugPrint("🔀 Random gold at ${positions[0]}, black at ${positions[1]}");
    debugPrint("📍 Server gold at ${widget.gold}, black at ${widget.black}");
  }

  /// Plays the coin reveal sound effect.
  Future<void> _soundReveal() async {
    UserData.instance.playSound(AudioPaths.revealCups);
  }

  /// Performs a shuffle animation of the cups while playing background music.
  Future<void> _performShuffle() async {
    await UserData.instance.playBackgroundMusic(AudioPaths.shuffleCups);

    for (int i = 0; i < 3; i++) {
      await Future.delayed(Duration(milliseconds: 300));
      setState(() {
        _cupOrder.shuffle();
      });
    }
    await UserData.instance.stopBackgroundMusic(clearFile: true);
  }

  /// Starts the phase where the user can select a cup. A timer listens for the remaining time and triggers auto-selection if needed.
  void _startChoicePhase() {
    setState(() {
      _canTap = true;
      _selectedCup = null;
    });
    _tapSub = TimerManager.instance.getTime().listen((remaining) {
      if (remaining == 5) {
        _onChosen(-1);
      }
    });
  }

  /// Handles the logic when the user selects a cup.
  ///
  /// If the user doesn't select a cup in time, index -1 is used.
  void _onChosen(int index) {
    if (!_canTap) return;
    setState(() {
      _canTap = false;
      _selectedCup = index;
    });
    debugPrint('Answer chosen: $index');
    widget.onAnswered(index);
  }

  /// Cleans up animation controllers and stream subscriptions.
  @override
  void dispose() {
    UserData.instance.stopBackgroundMusic(clearFile: true);
    _coverCtrl.dispose();
    _tapSub.cancel();
    super.dispose();
  }

  /// Builds the UI layout of the game, showing coins and cups with animations.
  @override
  Widget build(BuildContext context) {
    for (int displayIndex = 0; displayIndex < 3; displayIndex++) {
      final content = _revealed
          ? _actualContents[displayIndex]
          : _randomContents[displayIndex];
      debugPrint("🏷️ disp=$displayIndex content=$content");
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown.shade200,
        border: Border.all(color: Colors.brown, width: 4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: _TableBoardPainter(),
        child: AnimatedBuilder(
          animation: _coverCtrl,
          builder: (_, __) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Coins layer under cups
                ...List.generate(3, (i) {
                  final content = _revealed
                      ? _actualContents[i]
                      : _randomContents[i];
                  if (content == null) return const SizedBox.shrink();
                  return Align(
                    // use the same slot that the cup in position [cupIndex] is using
                    alignment: Alignment(_slots[i].x, 0.0),
                    heightFactor: _coinClip.value,
                    child: Container(
                      alignment: Alignment.center,
                      width: 80,
                      child: ClipRect(
                        child: Align(
                          // use the same slot that the cup in position [cupIndex] is using
                          alignment: Alignment.bottomCenter,
                          heightFactor: _coinClip.value,
                          child: Image.asset(
                            content == 'gold'
                                ? PicPaths.goldCoin
                                : PicPaths.blackCoin,
                            width: 40,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // Cups layer
                ...List.generate(3, (i) {
                  final isSel = (_selectedCup == i);
                  return AnimatedAlign(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: Alignment(
                      _slots[_cupOrder[i]].x,
                      _cupDrop.value,
                    ),
                    child: GestureDetector(
                      onTap: () => _canTap ? _onChosen(i) : null,
                      child: Container(
                        decoration: isSel
                            ? BoxDecoration(
                                border: Border.all(
                                  color: Colors.green,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              )
                            : null,
                        child: Image.asset(PicPaths.cup, width: 80, height: 90),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
