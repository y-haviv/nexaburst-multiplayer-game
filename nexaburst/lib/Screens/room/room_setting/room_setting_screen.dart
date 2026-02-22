// nexaburst/lib/screens/room/room_setting/room_setting_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/room/game/waiting_room_screen.dart';
import 'package:nexaburst/Screens/room/room_setting/general_setting.dart';
import 'package:nexaburst/Screens/room/room_setting/level_setting.dart';
import 'package:nexaburst/Screens/main_components/app_button.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/modes/forbiden_words/forbiden_words_manager.dart';
import 'package:nexaburst/model_view/room/waiting_room/start_game_interface.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/user_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

/// Screen for configuring and creating a new game room.
///
/// Allows the user to select game modes, forbidden words, levels with
/// rounds per level, and then initiate room creation.
class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  /// Creates the mutable state for this widget.
  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

/// State implementation for [GameSetupScreen].
///
/// Manages UI state for mode toggles, word inputs, level selection,
/// and handles validation and room creation logic.
class _GameSetupScreenState extends State<GameSetupScreen> {
  /// Whether drinking mode is currently enabled.
  bool drinkingMode = false;

  /// Whether forbidden-words mode is currently enabled.
  bool forbiddenWordsMode = false;

  /// Indicates that room creation is in progress to prevent duplicate submissions.
  bool _started = false;

  /// Two-element list storing the forbidden words input by the user.
  List<String> forbiddenWords = ["", ""];

  /// Number of rounds configured for each available level.
  late List<int> levelRounds;

  /// List of level identifiers that the user has selected.
  List<String> selectedLevels = [];

  /// Regular expression to validate forbidden words (at least 3 letters).
  final RegExp _validWordRegex = RegExp(r'^[\p{L}]{3,}$', unicode: true);

  /// Initializes default rounds per level and logs available level keys.
  @override
  void initState() {
    super.initState();
    levelRounds = List<int>.generate(
      TranslationService.instance.levelKeys.length,
      (_) => LevelsRounds.defaultLevelRound(),
    );
    debugPrint('SLOT NAMES: ${TranslationService.instance.levelKeys}');
  }

  /// Validates the two forbidden words for non‑empty, format, and server-side rules.
  ///
  /// Returns an empty string if valid, or an error message otherwise.
  Future<String> _validateForbiddenWords() async {
    final word1 = forbiddenWords.isNotEmpty ? forbiddenWords[0] : "";
    final word2 = forbiddenWords.length > 1 ? forbiddenWords[1] : "";

    if (word1.isEmpty || word2.isEmpty) return "must enter words";
    if (!_validWordRegex.hasMatch(word1) || !_validWordRegex.hasMatch(word2)) {
      return "problem with input words";
    }
    String ans = await ForbiddenWordsModManager.validate([word1, word2]);
    return ans;
  }

  /// Ensures microphone permission is granted, requesting if necessary.
  ///
  /// Returns `true` if permission is granted, `false` otherwise.
  Future<bool> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Builds the UI for game setup, including tabs for General and Level settings,
  /// and a Create Room button that validates inputs and calls the backend service.
  ///
  /// Handles permission requests, input validation, and navigation to the waiting room.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final barHeight = min((height * 0.2), 60).toDouble();
        final colHeight = (height - barHeight) * 0.9;
        final colWidth = width * 0.9;
        final spaceHeight = colHeight * 0.07;
        final buttonHeight = min(
          ((colHeight - (spaceHeight * 3)) * 0.2),
          50,
        ).toDouble();
        final buttonWidth = colWidth * 0.6;

        // Tab sizes
        final tabHeight = (colHeight - buttonHeight - (spaceHeight * 3)) * 0.95;
        final tabWidth = colWidth * 0.8;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: barHeight,
              backgroundColor: AppColors.accent1,

              leading: Builder(
                builder: (context) {
                  final backSize = width * 0.1;
                  final iconSize = backSize.clamp(24.0, 32.0);
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, size: iconSize),
                      onPressed: () => Navigator.pop(context),
                    ),
                  );
                },
              ),

              title: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  TranslationService.instance.t('screens.room_settings.title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              centerTitle: true,

              bottom: TabBar(
                tabs: [
                  Tab(
                    text: TranslationService.instance.t(
                      'screens.room_settings.tab_general',
                    ),
                  ),
                  Tab(
                    text: TranslationService.instance.t(
                      'screens.room_settings.tab_levels',
                    ),
                  ),
                ],
              ),
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(PicPaths.mainBackground, fit: BoxFit.cover),
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: (width - colWidth) / 2,
                      vertical: (height - colHeight) / 2,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: colWidth),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: tabHeight,
                            width: tabWidth,
                            child: TabBarView(
                              children: [
                                GeneralSetting(
                                  drinkingMode: drinkingMode,
                                  forbiddenWordsMode: forbiddenWordsMode,
                                  forbiddenWords: forbiddenWords,
                                  onDrinkingModeChanged: (bool value) {
                                    setState(() {
                                      drinkingMode = value;
                                    });
                                  },
                                  onForbiddenModeChanged: (bool value) {
                                    setState(() {
                                      forbiddenWordsMode = value;
                                    });
                                  },
                                  onForbiddenWordsChanged:
                                      (int id, String word) {
                                        if (id < forbiddenWords.length) {
                                          setState(() {
                                            forbiddenWords[id] = word;
                                          });
                                        } else {
                                          debugPrint("Error id forbiden word");
                                        }
                                      },
                                ),
                                LevelSetting(
                                  drinkingMode: drinkingMode,
                                  allLevels:
                                      TranslationService.instance.levelKeys,
                                  allRoundPerLevel: levelRounds,
                                  selectedLevels: selectedLevels,
                                  onLevelSelceted: (slot) {
                                    setState(() {
                                      if (selectedLevels.contains(slot)) {
                                        selectedLevels.remove(slot);
                                      } else {
                                        selectedLevels.add(slot);
                                      }
                                    });
                                  },
                                  onRoundsLevelChange: (slot, rounds) {
                                    setState(() {
                                      final index = TranslationService
                                          .instance
                                          .levelKeys
                                          .indexOf(slot);
                                      if (index >= 0 &&
                                          levelRounds.length > index) {
                                        levelRounds[index] = rounds;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: spaceHeight),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: AppButton.primary(
                              height: buttonHeight,
                              width: buttonWidth,
                              context: context,
                              label: TranslationService.instance.t(
                                'screens.room_settings.create_room_button',
                              ),
                              onPressed: () async {
                                try {
                                  if (selectedLevels.isEmpty || _started) {
                                    return;
                                  }
                                  setState(() {
                                    _started = true;
                                  });

                                  if (forbiddenWordsMode) {
                                    bool micGranted =
                                        await _checkMicrophonePermission();
                                    if (!micGranted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            TranslationService.instance.t(
                                              'errors.common.permission_denied',
                                            ),
                                          ),
                                        ),
                                      );
                                      if (!mounted) return;
                                      setState(() {
                                        forbiddenWordsMode = false;
                                      });

                                      _started = false;
                                      return;
                                    }
                                    String checkWords =
                                        await _validateForbiddenWords();
                                    if (checkWords.isNotEmpty) {
                                      debugPrint(checkWords);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            TranslationService.instance.t(
                                              'errors.game.invalid_forbidden_word',
                                            ),
                                          ),
                                        ),
                                      );
                                      _started = false;
                                      return;
                                    }
                                  }

                                  final UserModel? user =
                                      UserData.instance.user;
                                  if (user == null) {
                                    debugPrint("User not found");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          TranslationService.instance.t(
                                            'errors.game.room_create',
                                          ),
                                        ),
                                      ),
                                    );
                                    _started = false;
                                    return;
                                  }

                                  IStartGameService manager = context
                                      .read<IStartGameService>();

                                  Map<String, int> finalLevels = {};
                                  for (final level in selectedLevels) {
                                    final index = TranslationService
                                        .instance
                                        .levelKeys
                                        .indexOf(level);
                                    finalLevels[level] =
                                        (index >= 0 &&
                                            index < levelRounds.length)
                                        ? levelRounds[index]
                                        : LevelsRounds.minLevelRound();
                                  }

                                  final created = await manager.createRoom(
                                    levels: finalLevels,
                                    forbiddenWords: forbiddenWordsMode
                                        ? forbiddenWords
                                        : [],
                                    isDrinkingMode: drinkingMode,
                                    lang: user.language,
                                  );
                                  if (!created) {
                                    debugPrint("Room creation failed");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          TranslationService.instance.t(
                                            'errors.game.room_create',
                                          ),
                                        ),
                                      ),
                                    );
                                    _started = false;
                                    return;
                                  }

                                  // Navigate to waiting room
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          WaitingRoomScreen(manager: manager),
                                    ),
                                  );
                                } catch (e) {
                                  _started = false;
                                  debugPrint("Error creating room: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        TranslationService.instance.t(
                                          'errors.game.room_create',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
