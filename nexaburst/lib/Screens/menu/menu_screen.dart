// nexaburst/lib/Screens/menu/menu_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexaburst/Screens/room/room_setting/room_setting_screen.dart';
import 'package:nexaburst/Screens/main_components/app_button.dart';
import 'package:nexaburst/Screens/main_components/background_enter.dart';
import 'package:nexaburst/Screens/menu/home_settings_screen.dart';
import 'package:nexaburst/Screens/room/game/waiting_room_screen.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/modes/forbiden_words/forbiden_words_manager.dart';
import 'package:nexaburst/model_view/room/waiting_room/start_game_interface.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/structures/user_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

/// A stateless widget that displays the background and main menu screen.
///
/// Wraps the [MenuScreen] with a consistent background design.
class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    return Background(child: MenuScreen());
  }
}

/// The main interactive screen for the game menu.
///
/// Displays buttons for creating or joining a game and manages UI
/// logic depending on the user’s choice.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

/// State logic and UI builder for [MenuScreen].
///
/// Manages user input for joining a game, handles navigation,
/// permission checks, and conditional UI rendering.
class _MenuScreenState extends State<MenuScreen> {
  /// Indicates whether the user is currently trying to join a game.
  ///
  /// Controls the visibility of the room code input field and enter button.
  bool isJoiningRoom = false;

  /// Controller for the room code input field used when joining a game.
  final TextEditingController roomCodeController = TextEditingController();

  /// Checks and requests microphone permission from the user.
  ///
  /// Returns `true` if the permission is granted, `false` otherwise.
  ///
  /// This is required for modes that involve voice features.
  Future<bool> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Builds the column layout for the main menu buttons and room input field.
  ///
  /// Dynamically adapts layout and button sizes based on screen size.
  /// Displays the input field when `isJoiningRoom` is `true`.
  Widget menu() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final heightSpace = min(height * 0.1, 16).toDouble();
        final buttonHeight = min(
          (isJoiningRoom
              ? (height - (heightSpace * 2) - (heightSpace / 2)) / 4
              : (height - heightSpace) * 0.4),
          60,
        ).toDouble();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppButton.primary(
              key: 'createGameBtn',
              context: context,
              height: buttonHeight,
              label: TranslationService.instance.t(
                'screens.menu.host_game_button',
              ),
              onPressed: () {
                setState(() {
                  isJoiningRoom = false;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GameSetupScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: heightSpace),
            AppButton.primary(
              key: 'joinGameBtn',
              context: context,
              height: buttonHeight,
              label: TranslationService.instance.t(
                'screens.menu.join_game_button',
              ),
              onPressed: () {
                setState(() {
                  isJoiningRoom = !isJoiningRoom;
                });
              },
            ),
            if (isJoiningRoom) ...[
              SizedBox(height: heightSpace),
              SizedBox(
                width: width * 0.7,
                child: TextField(
                  key: const ValueKey('roomCodeField'),
                  controller: roomCodeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    hintText: TranslationService.instance.t(
                      'screens.menu.room_number_placeholder',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: min(heightSpace / 2, 14).toDouble()),
              AppButton.secondary(
                key: 'enterRoomBtn',
                context: context,
                height: buttonHeight,
                label: TranslationService.instance.t(
                  'screens.menu.enter_game_button',
                ),

                /// Handles the process of joining a game room.
                ///
                /// This includes:
                /// - Validating the current user
                /// - Parsing and validating the room code
                /// - Checking microphone permission if needed
                /// - Validating forbidden words if applicable
                /// - Attempting to join the room via the manager
                /// - Navigating to the [WaitingRoomScreen] on success
                ///
                /// If any step fails, appropriate feedback is shown using [SnackBar].
                onPressed: () async {
                  try {
                    final UserModel? user = UserData.instance.user;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            TranslationService.instance.t(
                              'errors.user_data.default_error',
                            ),
                          ),
                        ),
                      );
                      return;
                    }
                    final raw = roomCodeController.text.trim();
                    if (raw.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            (TranslationService.instance.t(
                              'errors.game.room_number_request',
                            )),
                          ),
                        ),
                      );
                      return;
                    }
                    if (raw.length != 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            TranslationService.instance.t(
                              'errors.game.invalid_room_number',
                            ),
                          ),
                        ),
                      );
                      return;
                    }
                    int roomNumber;
                    try {
                      roomNumber = int.parse(raw);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            TranslationService.instance.t(
                              'errors.game.invalid_room_number',
                            ),
                          ),
                        ),
                      );
                      return;
                    }

                    IStartGameService manager = context
                        .read<IStartGameService>();
                    manager.initialization(roomId: roomNumber.toString());

                    Tuple2<List<String>, String> checkMode = await manager
                        .preJoiningMicPremission();
                    if (checkMode.item1.isNotEmpty) {
                      bool micGranted = await _checkMicrophonePermission();
                      if (!micGranted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              TranslationService.instance.t(
                                'errors.common.permission_denied',
                              ),
                            ),
                          ),
                        );

                        return;
                      }

                      String checkWords =
                          await ForbiddenWordsModManager.validate(
                            checkMode.item1,
                          );
                      if (checkWords.isNotEmpty) {
                        debugPrint("Invalid forbidden words: $checkWords");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              TranslationService.instance.t(
                                'errors.game.error_room_join',
                              ),
                            ),
                          ),
                        );
                        return;
                      }
                    }

                    final created = await manager.joinRoom();
                    if (!created) {
                      debugPrint("Room join failed");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            TranslationService.instance.t(
                              'errors.game.error_room_join',
                            ),
                          ),
                        ),
                      );
                      return;
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              WaitingRoomScreen(manager: manager),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint("Error creating room: $e");
                    debugPrint("Room join failed");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          TranslationService.instance.t(
                            'errors.game.error_room_join',
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        );
      },
    );
  }

  /// Builds the full layout of the menu screen, including background,
  /// app title image, settings button, and responsive UI for various screen sizes.
  ///
  /// Also includes logic to dismiss the keyboard when tapping outside input fields.
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width * 0.97;
    final screenHeight = MediaQuery.of(context).size.height * 0.97;

    final isWider = screenWidth > screenHeight;
    final iconSize = min(screenHeight * 0.2, 32);
    final spaceHeight_1 = screenHeight * 0.03;
    final leftOverHeight = (screenHeight - iconSize - spaceHeight_1) * 0.95;
    final picSize = ((isWider ? leftOverHeight : screenWidth) * 0.45);

    final wideScreenSpacer =
        ((screenWidth - picSize - (screenWidth * 0.3)) * 0.9) / 3;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topLeft,

                  /// Settings button that navigates to the [PrivacySettingsScreen].
                  ///
                  /// Resets `isJoiningRoom` state to false on press.
                  child: AppButton.icon(
                    icon: Icons.settings,
                    onPressed: () {
                      setState(() {
                        isJoiningRoom = false;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacySettingsScreen(),
                        ),
                      );
                    },
                    color: Colors.black,
                    size: iconSize.toDouble(),
                    tooltip: TranslationService.instance.t(
                      'screens.settings.title',
                    ),
                  ),
                ),
                SizedBox(height: spaceHeight_1),
                isWider
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: wideScreenSpacer),

                          SizedBox(
                            width: picSize,
                            height: picSize,
                            child: Image.asset(
                              PicPaths.titlePath,
                              fit: BoxFit.cover,
                            ),
                          ),

                          SizedBox(width: wideScreenSpacer),
                          SizedBox(width: screenWidth * 0.3, child: menu()),

                          SizedBox(width: wideScreenSpacer),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: picSize,
                            height: picSize,
                            child: Image.asset(
                              PicPaths.titlePath,
                              fit: BoxFit.cover,
                            ),
                          ),

                          SizedBox(width: picSize, child: menu()),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
