// nexaburst/lib/screens/game_components/parmanent_button_overplay.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/room/game_components/players_screen.dart';
import 'package:nexaburst/Screens/main_components/app_button.dart';
import 'package:nexaburst/Screens/room/game_components/game_setting_screen.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/room/game/modes/forbiden_words/forbiden_words_manager.dart';

/// A widget that displays permanent buttons and game status at the top of the screen.
///
/// Includes:
/// - Players button
/// - Countdown timer
/// - Forbidden word warning messages
/// - Settings button
///
/// Subscribes to timer and forbidden word events to update UI in real-time.
class PermanentButtonsOverlay extends StatefulWidget {
  /// The ID of the current game room, used for routing and data binding.
  final String roomId;

  /// Constructs the permanent button overlay for a game session.
  ///
  /// Takes a [roomId] to provide context to the screen (e.g., navigation).
  const PermanentButtonsOverlay({super.key, required this.roomId});

  @override
  State<PermanentButtonsOverlay> createState() =>
      _PermanentButtonsOverlayState();
}

/// The state class for [PermanentButtonsOverlay].
///
/// Handles subscriptions to game timer and forbidden word events,
/// and manages layout calculations and rendering of buttons/messages.
class _PermanentButtonsOverlayState extends State<PermanentButtonsOverlay> {
  /// The remaining time in seconds, used for the countdown display.
  ///
  /// Null when no timer is active.
  int? _remaining;

  /// Subscription to the game's timer stream.
  ///
  /// Updates [_remaining] based on emitted time values.
  late final StreamSubscription<int> _subTimer;

  /// The latest forbidden word warning message to display.
  ///
  /// Null if no message is currently shown.
  String? _message;

  /// Subscription to forbidden word events for real-time UI feedback.
  StreamSubscription<Map<String, dynamic>>? _subMessage;

  /// Initializes timer and forbidden word event listeners.
  ///
  /// Updates UI when time changes or a forbidden word is detected.
  @override
  void initState() {
    super.initState();

    /// Subscribes to the timer and updates the countdown display.
    ///
    /// Sets [_remaining] to null when time reaches zero.
    _subTimer = TimerManager.instance.getTime().listen((secs) {
      if (!mounted) return;
      if (secs <= 0) {
        setState(() => _remaining = null);
      } else {
        setState(() => _remaining = secs);
      }
    });
    debugPrint('▶ ModNotificationOverlay: initState, subscribing…');

    /// Listens for forbidden word events and shows a temporary penalty message.
    ///
    /// Also plays a sound effect when a penalty occurs.
    _subMessage = ForbiddenWordsModManager().forbiddenEventStream?.listen(
      (event) async {
        debugPrint('▶ ModNotificationOverlay: got event → $event');
        if (!ForbiddenWordsModManager().isInitialized) return;

        final player = event['playerName'] as String?;
        final word = event['word'] as String?;
        final penalty = event['penalty']?.toString() ?? '1';
        debugPrint(
          '   parsed player="$player", word="$word", penalty=$penalty',
        );

        if (player != null && word != null) {
          setState(() {
            _message =
                "$player ${TranslationService.instance.t('game.modes.forbidden_words_mode.message1')} '$word' (-$penalty ${TranslationService.instance.t('game.common.points')})";
            debugPrint('   setState: _message="$_message"');
          });

          await UserData.instance.playSound(
            'assets/audio/wah_wah_trombone.mp3',
          );
          // clear after 3s
          Future.delayed(const Duration(seconds: 5), () {
            if (!mounted) return;
            debugPrint('   clearing message');
            setState(() => _message = null);
          });
        }
      },
      onError: (e, st) {
        debugPrint('❌ ModNotificationOverlay stream error: $e\n$st');
      },
    );
  }

  /// Cancels all active stream subscriptions when the widget is disposed.
  @override
  void dispose() {
    _subTimer.cancel();
    _subMessage?.cancel();
    super.dispose();
  }

  /// Navigates to the settings screen for the current room.
  void _goToSettingsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SettingsScreen(roomId: widget.roomId)),
    );
  }

  /// Navigates to the player list screen for the current room.
  void _goToPlayersScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlayersScreen(roomId: widget.roomId)),
    );
  }

  /// Builds the permanent control overlay with player/settings buttons,
  /// countdown timer, and forbidden word banner.
  ///
  /// Dynamically adjusts layout based on available space.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final iconBase = w * 0.07;
        final iconSize = iconBase.clamp(16, 28).toDouble();
        final isVeryNarrow = w < 150;
        final isVeryLow = constraints.maxHeight < 40;
        final fontBaseByWidth = w * 0.04;
        final fontBaseByHeight = constraints.maxHeight * 0.3;
        final fontSize = min(
          18,
          max(12, min(fontBaseByWidth, fontBaseByHeight)),
        ).toDouble();

        final timerWidget = (_remaining != null && _remaining! > 0)
            ? Text(
                '${TranslationService.instance.t('screens.game.time_label')}: $_remaining',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: _remaining! <= 4 ? Colors.red : Colors.white,
                ),
              )
            : const SizedBox.shrink();

        final forbiddenBanner = (_message != null)
            ? ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.8,
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    fontSize: min(24, fontSize),
                    color: AppColors.accent1,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              )
            : const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: constraints.maxHeight < 60 ? 4 : 10,
          ),
          child: Wrap(
            direction: (isVeryNarrow || isVeryLow)
                ? Axis.vertical
                : Axis.horizontal,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.icon(
                icon: Icons.people,
                onPressed: () => _goToPlayersScreen(context),
                color: Colors.black,
                size: iconSize,
                tooltip: TranslationService.instance.t('game.common.players'),
              ),

              timerWidget,
              forbiddenBanner,

              AppButton.icon(
                icon: Icons.settings,
                onPressed: () => _goToSettingsScreen(context),
                color: Colors.black,
                size: iconSize,
                tooltip: TranslationService.instance.t(
                  'screens.settings.title',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
