// nexaburst/lib/screens/game_components/game_setting_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/menu/avatars/avatar_ui_helper.dart';
import 'package:nexaburst/Screens/menu/menu_screen.dart';
import 'package:nexaburst/Screens/main_components/app_button.dart';
import 'package:nexaburst/Screens/main_components/app_text.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/room/game/game_manager.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/structures/user_model.dart';

/// Screen allowing users to configure game settings and create a new room.
///
/// Presents tabs for general options (modes, forbidden words) and level settings,
/// then handles validation and room creation.

/// Creates a [SettingsScreen] for the specified [roomId].
class SettingsScreen extends StatefulWidget {
  final String roomId;

  /// Creates mutable state for [SettingsScreen].
  const SettingsScreen({super.key, required this.roomId});

  /// State implementation for [SettingsScreen].
  ///
  /// Manages user data, handles exit confirmation, and builds the settings UI.
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// Holds the current user’s profile data, loaded asynchronously.
class _SettingsScreenState extends State<SettingsScreen> {
  /// Loads the current user's data into [_user] and refreshes the UI.
  UserModel? _user;

  /// Initializes state by fetching user profile.
  Future<void> _loadUserData() async {
    final user = UserData.instance.user;
    setState(() {
      _user = user;
    });
  }

  /// Prompts the user to confirm exit and disconnects from the game.
  ///
  /// - Shows a confirmation dialog.
  /// - Attempts up to 10 times to disconnect via [MainGameManager].
  /// - Navigates back to the main menu on success.
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Builds the settings screen UI, including:
  /// 1. Back and exit buttons
  /// 2. User avatar and name
  /// 3. Toggles for music and sound effects
  ///
  /// Adjusts layout for narrow vs. wide screens.
  Future<void> _exitGame(BuildContext context) async {
    bool confirmExit =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              scrollable: true,
              title: Text(
                TranslationService.instance.t(
                  'screens.settings.logout_game_hint',
                ),
              ),
              content: Text(
                TranslationService.instance.t(
                  'screens.settings.logout_game_confirm',
                ),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    TranslationService.instance.t('screens.common.cancel'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    TranslationService.instance.t('screens.common.confirm'),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmExit) return;

    ErrorService.instance.dispose();

    MainGameManager manager = MainGameManager();
    int trying = 0;
    const int maxTrying = 10;
    while (!await manager.disconnect() && trying < maxTrying) {
      trying += 1;
      await Future.delayed(Duration(seconds: 1));
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Menu()),
      (_) => false,
    );
  }

  /// Builds a styled toggle row for a given [label].
  ///
  /// - [value]: Current switch state.
  /// - [onChanged]: Callback when switch toggles.
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    final minSize = min(screenWidth, size.height);

    final double iconSize = min(32, screenWidth / 2.7).toDouble();
    final double titleFontSize = min(24, minSize * 0.1);
    final double usernameFontSize = min(20, minSize * 0.05);

    final bool isNarrow = screenWidth < 400;

    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          color: const Color.fromARGB(255, 44, 165, 245),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),

                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          flex: 1,
                          child: AppButton.icon(
                            icon: Icons.arrow_back,
                            onPressed: () => Navigator.pop(context),
                            color: Colors.black,
                            size: iconSize,
                          ),
                        ),
                        Flexible(
                          flex: 1,
                          child: AppButton.icon(
                            icon: Icons.logout,
                            onPressed: () => _exitGame(context),
                            color: Colors.red,
                            size: iconSize,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      TranslationService.instance.t('screens.settings.title'),
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    (_user?.avatar ?? PicPaths.defaultAvatarPath).startsWith(
                          'http',
                        )
                        ? CircleAvatar(
                            radius: minSize * 0.12,
                            backgroundImage: NetworkImage(_user!.avatar),
                          )
                        : SpriteAvatar(
                            id: _user?.avatar ?? PicPaths.defaultAvatarPath,
                            radius: minSize * 0.12,
                          ),

                    const SizedBox(height: 12),

                    Text(
                      _user?.username ??
                          TranslationService.instance.t(
                            'screens.common.loading',
                          ),
                      style: TextStyle(
                        fontSize: usernameFontSize,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    if (isNarrow)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildSwitches(),
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildSwitches()
                            .map((w) => Expanded(child: w))
                            .toList(),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Constructs the list of mode toggles for music and sound.
  ///
  /// Returns two widgets: one for music, one for sound.
  Widget buildSwitchTile({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withOpacity(0.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 120) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.build(
                  label,
                  context: context,
                  type: TextType.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            );
          }

          return Row(
            children: [
              Flexible(
                child: AppText.build(
                  label,
                  context: context,
                  type: TextType.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildSwitches() {
    return [
      ValueListenableBuilder<bool>(
        valueListenable: UserData.instance.musicNotifier,
        builder: (_, isOn, __) => buildSwitchTile(
          label: TranslationService.instance.t('screens.settings.music_label'),
          value: isOn,
          onChanged: (_) async => await UserData.instance.setMusicEnabled(),
        ),
      ),
      ValueListenableBuilder<bool>(
        valueListenable: UserData.instance.soundNotifier,
        builder: (_, isOn, __) => buildSwitchTile(
          label: TranslationService.instance.t(
            'screens.settings.sound_effects_label',
          ),
          value: isOn,
          onChanged: (_) async => await UserData.instance.setSoundEnabled(),
        ),
      ),
    ];
  }
}
