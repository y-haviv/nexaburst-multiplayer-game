// nexaburst/lib/screens/room/game/waiting_room_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/menu/menu_screen.dart';
import 'package:nexaburst/Screens/room/game/game_manager_screen.dart';
import 'package:nexaburst/Screens/main_components/app_button.dart';
import 'package:nexaburst/Screens/main_components/app_text.dart';
import 'package:nexaburst/Screens/main_components/background_enter.dart';
import 'package:nexaburst/Screens/room/game_components/game_setting_screen.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/room/game/game_manager.dart';
import 'package:nexaburst/model_view/room/waiting_room/start_game_interface.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:nexaburst/models/structures/room_model.dart';

/// A screen that displays the waiting room for players before a game starts.
///
/// Shows the list of connected players, allows the host to start the game,
/// and listens for room status changes and game errors to navigate accordingly.
class WaitingRoomScreen extends StatefulWidget {
  /// Service responsible for controlling room status, players, and starting the game.
  final IStartGameService manager;

  const WaitingRoomScreen({super.key, required this.manager});

  @override
  _WaitingRoomScreenState createState() => _WaitingRoomScreenState();
}

/// State class for [WaitingRoomScreen], handling UI logic, subscriptions, and navigation
/// based on the game status and player roles.
class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  /// Manages the core game logic and handles initialization and cleanup for the game session.
  MainGameManager mainGameManager = MainGameManager();

  /// Indicates whether the screen has already navigated to the game to prevent duplicate actions.
  bool _hasNavigated = false;

  /// Subscription to room host changes, used to determine if the user is the host.
  late StreamSubscription<String> _hostSub;

  /// Whether the current user is the host of the room.
  bool _isHost = false;

  /// Subscription to room status changes (e.g., waiting, playing, over).
  late StreamSubscription<RoomStatus> _statusSub;

  /// Current status of the game room.
  RoomStatus _status = RoomStatus.waiting;

  /// Subscription to game-related errors emitted by the [ErrorService].
  late StreamSubscription<ErrorType> _errorSub;

  /// Ensures that the error service is only initialized once during the lifecycle.
  bool _initializedErrorService = false;

  /// Initializes state, subscribes to room events, error handling, and sets up audio.
  @override
  void initState() {
    super.initState();
    debugPrint("WaitingRoomScreen initState called");
    _setupAudio();

    // 1) Start listening to hostId$:
    _hostSub = widget.manager.watchRoomHost().listen((hostId) {
      final me = UserData.instance.user!.id;
      final amIHost = hostId == me;

      if (amIHost) {
        setState(() {
          _isHost = amIHost;
        });
      }
    });

    _statusSub = widget.manager.watchRoomStatus().listen((status) {
      if (status != _status) {
        setState(() {
          _status = status;
        });
      }
    });

    if (!_initializedErrorService) {
      _initializedErrorService = true;
      // 2) Initialize the ErrorService only once
      ErrorService.instance.init();
    }

    _errorSub = ErrorService.instance.errors().listen((newStatus) async {
      _handleNavigationOrDialog(() async {
        if (_hasNavigated) return;
        // 1) Show a SnackBar so the user sees “Game Over”
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            scrollable: true,
            title: Text(
              TranslationService.instance.t('errors.game.game_error_title'),
            ),
            content: Text(newStatus.toString()),
            insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  TranslationService.instance.t('screens.common.confirm'),
                ),
              ),
            ],
          ),
        ).then((_) {
          if (!mounted) return;
          // 3) Finally navigate back to menu, clearing the stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => Menu()),
            (route) => false,
          );
        });
      });
    });
  }

  void _handleNavigationOrDialog(Function action) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action();
    });
  }

  /// Plays the background music specific to the waiting room screen.
  Future<void> _setupAudio() async {
    await UserData.instance.playBackgroundMusic(AudioPaths.waiting_room);
  }

  /// Navigates to the settings screen for the current room.
  ///
  /// Parameters:
  /// - [context]: Build context used to push the route.
  void _goToSettingsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(roomId: widget.manager.getRoomId()),
      ),
    );
  }

  /// Cancels all subscriptions, stops background music, and disposes managers as needed.
  @override
  void dispose() {
    _statusSub.cancel();
    _hostSub.cancel(); // stop listening
    _errorSub.cancel(); // stop listening to errors
    UserData.instance.stopBackgroundMusic(clearFile: true);
    if (!_hasNavigated) {
      mainGameManager.dispose();
      ErrorService.instance.dispose();
    }
    widget.manager.dispose();
    debugPrint("WaitingRoomScreen disposed");
    super.dispose();
  }

  /// Builds the UI for the waiting room screen, including player list, status display,
  /// settings button, and navigation logic to the game or back to menu.
  @override
  Widget build(BuildContext context) {
    // auto‐navigate to game
    if (_status == RoomStatus.playing && !_hasNavigated) {
      _hasNavigated = true;
      _handleNavigationOrDialog(() async {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await mainGameManager.initialize(roomId: widget.manager.getRoomId());
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GameScreen(gameManager: mainGameManager),
            ),
          );
        });
      });
    } else if (_status == RoomStatus.over) {
      _handleNavigationOrDialog(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => Menu()),
          (route) => false,
        );
      });
    }
    return Background(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double playersBoxHeight = constraints.maxHeight * 0.5;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.1,
                  vertical: constraints.maxHeight * 0.05,
                ),
                child: SizedBox(
                  width: constraints.maxWidth * 0.8,

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: AppButton.icon(
                          icon: Icons.settings,
                          onPressed: () => _goToSettingsScreen(context),
                          tooltip: TranslationService.instance.t(
                            'screens.setting.title',
                          ),
                          color: Colors.black,
                          size: min(32, constraints.maxWidth * 0.8).toDouble(),
                        ),
                      ),

                      SizedBox(height: constraints.maxHeight * 0.02),
                      AppText.build(
                        TranslationService.instance.t(
                          'screens.waiting_room.title',
                        ),
                        context: context,
                        type: TextType.subtitle,
                        backgroundColor: Colors.black.withAlpha(
                          (0.4 * 255).toInt(),
                        ),
                      ),

                      Text(
                        "${TranslationService.instance.t('screens.waiting_room.room_number_label')}: ${widget.manager.getRoomId()}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent1,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // The white box of players:
                      Container(
                        height: playersBoxHeight,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(197, 255, 255, 255),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: StreamBuilder<List<String>>(
                          stream: widget.manager.watchPlayers(),
                          builder: (ctx, snap) {
                            final names = snap.data ?? [];
                            if (names.isEmpty) {
                              return Center(
                                child: Text(
                                  TranslationService.instance.t(
                                    'errors.common.error_loading_data',
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              scrollDirection: Axis.vertical,
                              itemCount: names.length,
                              separatorBuilder: (_, __) => Divider(),
                              itemBuilder: (_, i) => Text(
                                names[i],
                                textAlign: TextAlign.center,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Start button only for host
                      if (_isHost)
                        StreamBuilder<List<String>>(
                          stream: widget.manager.watchPlayers(),
                          builder: (ctx, snap) {
                            final count = snap.data?.length ?? 0;
                            return ElevatedButton(
                              onPressed: count >= 2
                                  ? () => widget.manager.start()
                                  : null,
                              child: Text(
                                TranslationService.instance.t(
                                  'screens.game.start_game_button',
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
