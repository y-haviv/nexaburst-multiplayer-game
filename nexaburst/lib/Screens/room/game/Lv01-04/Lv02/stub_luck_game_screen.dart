
// nexaburst/lib/screens/room/game/Lv01-04/Lv02/stub_luck_game_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luck Game Demo',
      theme: ThemeData(primarySwatch: Colors.brown),
      home: const GameWrapper(),
    );
  }
}

/// Wrapper showing a simple background and top bar
class GameWrapper extends StatelessWidget {
  const GameWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final topBarH = 50.0;//min(availableH * 0.25, 60.0);

              return Column(
                children: [
                  // Adaptive top bar:
                  SizedBox(
                    height: topBarH,
                    child: Container(
                      color: Colors.brown.shade700,
                      alignment: Alignment.center,
                      child: const Text(
                        'Luck Game Test',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),

                  Expanded(
                    child: LuckGame(
                      gold: 0,
                      black: 1,
                      onAnswered: (idx) {
                        debugPrint('User selected cup: $idx');
                      },
                      revealNotifier: RevealController().notifier,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Controller to trigger reveal
class RevealController {
  final ValueNotifier<bool> notifier = ValueNotifier(false);
  RevealController() {
    // Reveal automatically after 6 seconds
    Future.delayed(
      const Duration(seconds: 6),
    ).then((_) => notifier.value = true);
  }
}

/// Stub for timer manager
typedef SecondsStream = Stream<int>;

class TimerManager {
  TimerManager._();
  static final instance = TimerManager._();
  SecondsStream getTime() {
    // Countdown from 10 to 0
    return Stream.periodic(
      const Duration(seconds: 1),
      (count) => max(10 - count, 0),
    ).take(11);
  }
}

/// Stub for user data (no-op sounds)
class UserData {
  UserData._();
  static final instance = UserData._();
  Future<void> playSound(String _) async {}
  Future<void> playBackgroundMusic(String _) async {}
  Future<void> stopBackgroundMusic({bool clearFile = false}) async {}
}

/// Custom board painter
//typing CustomPainter as TableBoardPainter
class TableBoardPainter extends CustomPainter {
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

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// The LuckGame widget
class LuckGame extends StatefulWidget {
  final int gold;
  final int black;
  final Function(int) onAnswered;
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

class _LuckGameState extends State<LuckGame> with TickerProviderStateMixin {
  late AnimationController _coverCtrl;
  late Animation<double> _cupDrop;
  late Animation<double> _coinClip;
  final List<int> _cupOrder = [0, 1, 2];
  final List<String?> _randomContents = ['gold', null, 'black'];
  List<String?> _actualContents = [null, null, null];
  bool _revealed = false;
  late final StreamSubscription<int> _tapSub;

  bool _canTap = false;
  int? _selectedCup;
  final List<Alignment> _slots = [
    const Alignment(-1, 0),
    const Alignment(0, 0),
    const Alignment(1, 0),
  ];

  @override
  void initState() {
    super.initState();
    _initContents();

    _coverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _cupDrop = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(
        parent: _coverCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );
    _coinClip = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _coverCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    widget.revealNotifier.addListener(() {
      if (widget.revealNotifier.value) {
        _coverCtrl.reverse();
        setState(() => _revealed = true);
      }
    });

    Future.delayed(const Duration(seconds: 2))
        .then((_) => _coverCtrl.forward())
        .then((_) => _performShuffle())
        .then((_) => _startChoicePhase());
  }

  void _initContents() {
    _randomContents.shuffle();
    // actualContents seeded from input:
    _actualContents = [null, null, null];
    _actualContents[widget.gold] = 'gold';
    _actualContents[widget.black] = 'black';

    // Debug:
    debugPrint(
      "🔀 Random gold at ${_randomContents.indexOf('gold')}, black at ${_randomContents.indexOf('black')}",
    );
    debugPrint("📍 Server gold at ${widget.gold}, black at ${widget.black}");
  }

  Future<void> _performShuffle() async {
    await UserData.instance.playBackgroundMusic('shuffle.mp3');
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _cupOrder.shuffle();
      });
    }
    await UserData.instance.stopBackgroundMusic();
  }

  void _startChoicePhase() {
    setState(() {
      _canTap = true;
      _selectedCup = null;
    });
    _tapSub = TimerManager.instance.getTime().listen((remaining) {
      if (remaining == 5) _onChosen(-1);
    });
  }

  void _onChosen(int index) {
    if (!_canTap) return;
    setState(() {
      _canTap = false;
      _selectedCup = index;
    });
    widget.onAnswered(index);
  }

  @override
  void dispose() {
    _coverCtrl.dispose();
    _tapSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;

        return Container(
          padding: EdgeInsets.all(min(16, screenHeight)),
          decoration: BoxDecoration(
            color: Colors.brown.shade200,
            border: Border.all(color: Colors.brown, width: 4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(
            painter: TableBoardPainter(),
            child: AnimatedBuilder(
              animation: _coverCtrl,
              builder: (_, __) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Coins
                    ...List.generate(3, (i) {
                      final content = _revealed
                          ? _actualContents[i]
                          : _randomContents[i];
                      if (content == null) return const SizedBox.shrink();
                      return Align(
                        alignment: Alignment(_slots[i].x, 0.0),
                        heightFactor: _coinClip.value,
                        child: Container(
                          alignment: Alignment.center,
                          width: 80,
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              heightFactor: _coinClip.value,
                              child: Image.asset(
                                content == 'gold'
                                    ? 'assets/images/gold_coin.png'
                                    : 'assets/images/black_coin.png',
                                width: 40,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    // Cups
                    ...List.generate(3, (i) {
                      final isSel = _selectedCup == i;
                      return AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
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
                            child: Image.asset(
                              'assets/images/cup.png',
                              width: 80,
                              height: 90,
                            ),
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
      },
    );
  }
}
