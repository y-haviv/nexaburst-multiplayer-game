// nexaburst/lib/screens/menu/home_setting_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/menu/avatars/avatar_ui_helper.dart';
import 'package:nexaburst/Screens/menu/avatars/avater_pic_screen.dart';
import 'package:nexaburst/Screens/main_components/app_button.dart';
import 'package:nexaburst/Screens/main_components/app_text.dart';
import 'package:nexaburst/Screens/main_components/background_enter.dart';
import 'package:nexaburst/Screens/main_components/lunguage_field.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/structures/user_model.dart';

/// A screen that allows users to manage their privacy and profile settings,
/// including username, language, avatar, music/sound preferences, and logout.
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

/// The state class for [PrivacySettingsScreen], responsible for managing UI
/// state, user data loading, profile updates, and UI interactions.
class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  /// Controls the text input for the username field.
  final TextEditingController _nameController = TextEditingController();

  /// Stores the currently selected language code for the user.
  String? _selectedLanguage;

  /// Holds the current user's data model.
  UserModel? _user;

  /// Indicates whether the screen is currently loading user data.
  bool _loading = true;

  /// Initializes the screen state and triggers user data loading.
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Loads the current user's data and populates the UI fields accordingly.
  ///
  /// Updates [_nameController], [_selectedLanguage], and [_user].
  Future<void> _loadUserData() async {
    final user = UserData.instance.user;
    setState(() {
      _user = user;
      _nameController.text = user?.username ?? '';
      _selectedLanguage =
          user?.language ?? TranslationService.instance.currentLanguage;
      _loading = false;
    });
  }

  /// Logs the user out and navigates back to the welcome screen.
  ///
  /// Clears user data and removes the navigation stack.
  Future<void> _handleLogout() async {
    await UserData.instance.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (r) => false);
  }

  /// Validates and saves the updated user profile data (username and language).
  ///
  /// Shows a success or error message and navigates back on success.
  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.instance.t('errors.user_data.user_not_found'),
          ),
        ),
      );
      return;
    }

    await UserData.instance.updateProfile(
      username: name,
      language: _selectedLanguage,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          TranslationService.instance.t(
            'screens.settings.update_success_message',
          ),
        ),
      ),
    );
    Navigator.pop(context);
  }

  /// Builds the UI section displaying the user's avatar and basic profile info.
  ///
  /// Includes a tappable avatar that navigates to the avatar selection screen.
  ///
  /// [size] defines the radius of the avatar widget.
  Widget _buildAvatarSection(double size) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AvatarScreen()),
            );
            setState(() => _loading = true);
            await _loadUserData();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              SpriteAvatar(
                id: _user?.avatar ?? PicPaths.defaultAvatarPath,
                radius: size,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: size / 4,
                  backgroundColor: const Color.fromARGB(108, 255, 255, 255),
                  child: Icon(
                    Icons.edit,
                    size: size / 5,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        AppText.build(
          _user?.username ??
              TranslationService.instance.t('screens.common.loading'),
          context: context,
          type: TextType.subtitle,
          backgroundColor: Colors.black.withOpacity(0.4),
        ),
        SizedBox(height: 4),
        AppText.build(
          '${TranslationService.instance.t('screens.settings.age_label')}: ${_user?.age ?? '-'}, '
          '${TranslationService.instance.t('screens.settings.current_language_label')}: ${_user?.language ?? '-'}, '
          '${TranslationService.instance.t('screens.settings.wins_label')}: ${_user?.wins ?? '-'}',
          context: context,
          type: TextType.caption,
          backgroundColor: Colors.black.withOpacity(0.4),
        ),
      ],
    );
  }

  /// Builds a styled switch tile widget for toggling settings.
  ///
  /// Displays a label and a [Switch] widget, adapting layout based on width.
  ///
  /// - [label]: Text displayed next to the switch
  /// - [value]: Current value of the switch
  /// - [onChanged]: Callback triggered when the value changes
  Widget buildSwitchTile({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                SizedBox(height: 4),
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
              SizedBox(width: 8),
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

  /// Builds the main controls section for user settings, including:
  /// - Username input
  /// - Music and sound effect toggles
  /// - Language selector
  /// - Save button
  ///
  /// [constraints] provide layout sizing information.
  Widget _buildControlsSection(BoxConstraints constraints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: TranslationService.instance.t(
              'screens.settings.current_user_name',
            ),
            labelStyle: TextStyle(
              color: AppColors.warning,
              backgroundColor: const Color.fromARGB(
                237,
                0,
                0,
                0,
              ).withOpacity(0.4),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        SizedBox(height: 16),
        ValueListenableBuilder<bool>(
          valueListenable: UserData.instance.musicNotifier,
          builder: (_, isOn, __) => buildSwitchTile(
            label: TranslationService.instance.t(
              'screens.settings.music_label',
            ),
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
        SizedBox(height: 16),
        LanguageField(onSaved: (code) => _selectedLanguage = code),

        SizedBox(height: 24),
        AppButton.primary(
          context: context,
          label: TranslationService.instance.t('screens.settings.done_button'),
          onPressed: _handleSave,
        ),
      ],
    );
  }

  /// Builds the full UI layout of the privacy settings screen.
  ///
  /// Shows a loading indicator until user data is ready. Displays a
  /// responsive layout with avatar and control sections based on orientation.
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Background(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final topBar = Row(
            children: [
              Flexible(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AppButton.icon(
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                      color: Colors.black,
                      size: min(32, (constraints.maxWidth * 0.9) / 4),
                    ),
                  ),
                ),
              ),
              Spacer(),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AppButton.icon(
                      icon: Icons.logout,
                      onPressed: _handleLogout,
                      color: Colors.red,
                      size: min(32, (constraints.maxWidth * 0.9) / 4),
                    ),
                  ),
                ),
              ),
            ],
          );

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.1,
                vertical: constraints.maxHeight * 0.05,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight * 0.8,
                ),
                child: OrientationBuilder(
                  builder: (context, orientation) {
                    if (orientation == Orientation.landscape) {
                      return Column(
                        children: [
                          topBar,
                          SizedBox(height: 16),
                          Flexible(
                            child: Row(
                              children: [
                                Flexible(
                                  flex: 1,
                                  child: _buildAvatarSection(
                                    min(
                                          constraints.maxWidth,
                                          constraints.maxHeight,
                                        ) *
                                        0.3,
                                  ),
                                ),
                                SizedBox(width: 24),
                                Flexible(
                                  flex: 2,
                                  child: _buildControlsSection(constraints),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          topBar,
                          SizedBox(height: 24),
                          _buildAvatarSection(
                            min(constraints.maxWidth, constraints.maxHeight) *
                                0.3,
                          ),
                          SizedBox(height: 32),
                          _buildControlsSection(constraints),
                        ],
                      );
                    }
                  },
                ),
                //),
              ),
            ),
          );
        },
      ),
    );
  }
}
