// nexaburst/lib/screens/room/game/Lv01-04/Lv02/luck_weel_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:nexaburst/Screens/room/game/manager_screens/loading_screen.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/players_view_model/players_interface.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/player_model.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

/// A screen that presents a "Wheel of Fortune" style spinner for the Luck stage.
///
/// - [wheelData]: list of tuples containing (optionId, label, requiresOtherPlayer).
/// - [onAnswered]: callback invoked with the chosen option and (if required) other player ID.
/// - [roomId]: current game room identifier for fetching player lists.
class LuckWheelScreen extends StatefulWidget {
  /// The data used to populate the wheel segments.
  ///
  /// Each tuple contains:
  /// - item1: segment identifier (int)
  /// - item2: display text (String)
  /// - item3: whether selecting this segment requires choosing another player (bool)
  final List<Tuple3<int, String, bool>> wheelData;

  /// Callback invoked when the wheel spin completes.
  ///
  /// Parameters:
  /// - selectedId: the `item1` of the selected segment, or -1 if timed out.
  /// - otherPlayerId: ID of another player if `requiresOtherPlayer` is true, otherwise empty.
  final void Function(int, String) onAnswered;

  /// The current room ID, used to load player lists when needed.
  final String roomId;

  /// Creates a [LuckWheelScreen] with the given [wheelData], [onAnswered] callback, and [roomId].
  const LuckWheelScreen({
    super.key,
    required this.wheelData,
    required this.onAnswered,
    required this.roomId,
  });

  /// Creates mutable state for the wheel screen.
  @override
  _LuckWheelScreenState createState() => _LuckWheelScreenState();
}

/// State class for [LuckWheelScreen], managing the spin logic, timer,
/// player selection dialog, and wheel animations.
class _LuckWheelScreenState extends State<LuckWheelScreen> {
  /// Static background decoration image for the wheel screen.
  static const _bg = DecorationImage(
    image: AssetImage(PicPaths.weelBackground),
    fit: BoxFit.cover,
  );
  bool _spinning = false;
  final StreamController<int> _selected = StreamController<int>();
  StreamSubscription<int>? _tapSub;
  late int _selectedIndex;
  Players? viewModel;
  Stream<List<Player>>? playerStream;

  /// Initializes the countdown timer for auto-spin on timeout.
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  /// Asynchronously loads the list of players from the provider for effectOther segments.
  Future<Stream<List<Player>>> _loadPlayers() async {
    final viewModel = context.read<Players>();
    await viewModel.initialization(roomId: widget.roomId);
    return await viewModel.players();
  }

  /// Plays the spinning sound effect when the wheel starts.
  Future<void> _startMusic() async {
    await UserData.instance.playSound(AudioPaths.wheelSpin);
  }

  /// Listens to the timer and triggers auto-selection if time runs out.
  void _startTimer() {
    _tapSub = TimerManager.instance.getTime().listen((remaining) {
      if (remaining <= 0) {
        if (!_spinning) {
          widget.onAnswered(-1, "");
        }
      }
    });
  }

  /// Spins the wheel, handles special segment behavior, and invokes [onAnswered].
  Future<void> _spinWheel() async {
    if (_spinning) return;

    setState(() => _spinning = true);
    _tapSub?.cancel();
    TimerManager.instance.stop();
    await _startMusic();

    // Choose random segment
    _selectedIndex = Random().nextInt(widget.wheelData.length);
    _selected.add(_selectedIndex);

    // Wait for animation (~5s) + display (~2s)
    await Future.delayed(const Duration(seconds: 9));

    final choice = widget.wheelData[_selectedIndex];
    final id = choice.item1;
    final effectOther = choice.item3;

    if (id == 4) {
      // Special behavior for id == 4
      TimerManager.instance.reStart();
      await Future.delayed(const Duration(milliseconds: 500));
      _startTimer();
      setState(() {
        _spinning = false;
      });
      return;
    }

    if (!effectOther) {
      widget.onAnswered(id, "");
    } else {
      TimerManager.instance.reStart();
      await Future.delayed(const Duration(milliseconds: 500));
      _startTimer();
      setState(() {
        _spinning = false;
      });
      // Select another player
      final otherId = await _showPlayerSelectionDialog();

      if (otherId != null) {
        widget.onAnswered(id, otherId);
      } else {
        widget.onAnswered(-1, "");
      }
    }
  }

  /// Shows a modal dialog for selecting another player when required.
  ///
  /// Returns the chosen player’s ID, or null if dismissed.
  Future<String?> _showPlayerSelectionDialog() async {
    final maxHeight = MediaQuery.of(context).size.height * 0.5;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            scrollable: true,
            title: Text(widget.wheelData[_selectedIndex].item2),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: maxHeight,
              child: FutureBuilder<Stream<List<Player>>>(
                future: _loadPlayers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text(
                      TranslationService.instance.t('errors.game.wheel_error'),
                    );
                  }

                  final stream = snapshot.data!;
                  return StreamBuilder<List<Player>>(
                    stream: stream,
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data!.isEmpty) {
                        return Center(
                          child: Text(
                            TranslationService.instance.t(
                              'screen.common.loading',
                            ),
                          ),
                        );
                      }

                      final players = snap.data!;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: players.length,
                        itemBuilder: (context, i) {
                          final data = players[i];
                          return ListTile(
                            title: Text(data.username),
                            subtitle: Text(
                              '${TranslationService.instance.t('game.common.points')}: ${data.totalScore}',
                            ),
                            onTap: () {
                              Navigator.of(context).pop(data.id);
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the main wheel UI with a FortuneWheel, spin button, and title.
  ///
  /// Shows a loading screen if [wheelData] is empty.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // If no wheel data, show a loading screen:
        if (widget.wheelData.isEmpty) {
          return LoadingScreen();
        }

        return SizedBox.expand(
          child: Container(
            decoration: BoxDecoration(image: _bg),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 600),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          TranslationService.instance.t(
                            'game.levels.${TranslationService.instance.levelKeys[1]}.wheel_title',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.04),

                        SizedBox(
                          width: double.infinity,
                          height: screenHeight * 0.6,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              FortuneWheel(
                                selected: _selected.stream,
                                items: widget.wheelData.map((t) {
                                  return FortuneItem(
                                    child: Text(
                                      t.item2,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onAnimationEnd: () {},
                                animateFirst: false,
                                duration: const Duration(seconds: 9),
                              ),
                              const Positioned(
                                top: 0,
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.red,
                                  size: 48,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.04),

                        SizedBox(
                          width: (screenWidth.clamp(0, 600)) * 0.6,
                          child: _spinning
                              ? const SizedBox.shrink()
                              : ElevatedButton(
                                  onPressed: _spinWheel,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: Text(
                                    TranslationService.instance.t(
                                      'game.levels.${TranslationService.instance.levelKeys[1]}.spin',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                        ),

                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Cancels subscriptions and closes streams when disposing.
  @override
  void dispose() {
    viewModel?.dispose();
    _tapSub?.cancel();
    _selected.close();
    super.dispose();
  }
}
