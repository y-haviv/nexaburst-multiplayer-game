// nexaburst/lib/screens/room/room_setting/general_setting.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/main_components/app_button.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// A stateful widget that allows configuring general game settings,
/// including toggling drinking mode and forbidden words mode, and editing forbidden words.
///
/// Provides callbacks to notify parent widgets of changes.
class GeneralSetting extends StatefulWidget {
  final bool drinkingMode;
  final bool forbiddenWordsMode;
  final List<String> forbiddenWords;

  final void Function(bool) onDrinkingModeChanged;
  final void Function(bool) onForbiddenModeChanged;
  final void Function(int, String) onForbiddenWordsChanged;

  /// Creates a GeneralSetting widget.
  ///
  /// Parameters:
  /// - [drinkingMode]: Whether drinking mode is enabled initially.
  /// - [forbiddenWordsMode]: Whether forbidden words mode is enabled initially.
  /// - [forbiddenWords]: List of forbidden words (expected up to 2).
  /// - [onDrinkingModeChanged]: Callback when drinking mode toggled.
  /// - [onForbiddenModeChanged]: Callback when forbidden words mode toggled.
  /// - [onForbiddenWordsChanged]: Callback when forbidden words are changed,
  ///    with index and new word string.
  const GeneralSetting({
    super.key,
    required this.drinkingMode,
    required this.forbiddenWordsMode,
    required this.forbiddenWords,
    required this.onDrinkingModeChanged,
    required this.onForbiddenModeChanged,
    required this.onForbiddenWordsChanged,
  });

  @override
  State<GeneralSetting> createState() => _GeneralSetting();
}

/// State implementation for [GeneralSetting].
/// Manages toggles and text controllers for forbidden words inputs.
class _GeneralSetting extends State<GeneralSetting> {
  late bool drinkingMode;
  late bool forbiddenWordsMode;
  final TextEditingController _forbiddenWord1Controller =
      TextEditingController();
  final TextEditingController _forbiddenWord2Controller =
      TextEditingController();

  /// Initializes state variables from widget properties.
  /// Sets initial text values for forbidden word input controllers.
  @override
  void initState() {
    super.initState();
    drinkingMode = widget.drinkingMode;
    forbiddenWordsMode = widget.forbiddenWordsMode;

    _forbiddenWord1Controller.text = widget.forbiddenWords.isNotEmpty
        ? widget.forbiddenWords[0]
        : '';
    _forbiddenWord2Controller.text = widget.forbiddenWords.length > 1
        ? widget.forbiddenWords[1]
        : '';
  }

  /// Disposes the text editing controllers to free resources.
  @override
  void dispose() {
    _forbiddenWord1Controller.dispose();
    _forbiddenWord2Controller.dispose();
    super.dispose();
  }

  /// Builds a responsive UI widget combining a title, help icon, and toggle control.
  ///
  /// The toggle is a Checkbox or Switch depending on available width.
  /// Tapping the help icon shows an informational dialog with [title] and [description].
  ///
  /// Parameters:
  /// - [title]: The title text to display.
  /// - [description]: The help description shown in the dialog.
  /// - [onChanged]: Callback when the toggle value changes.
  /// - [value]: Current toggle state.
  Widget _buildModeToggle({
    required String title,
    required String description,
    required Function(bool) onChanged,
    required bool value,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        double iconSize = min(20, width * 0.1);
        double textSize = width < 150 ? 12 : 16;

        Widget icon = AppButton.icon(
          icon: Icons.help_outline,
          onPressed: () {
            showDialog(
              context: context,
              builder: (dialogContext) {
                final screenH = MediaQuery.of(dialogContext).size.height;

                return AlertDialog(
                  scrollable: true,
                  title: Text(title),
                  content: Text(description),
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  actions: screenH < 300
                      ? []
                      : [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              TranslationService.instance.t(
                                'screens.common.close',
                              ),
                            ),
                          ),
                        ],
                );
              },
            );
          },
          color: AppColors.accent2,
          size: iconSize,
        );

        Widget toggleWidget;
        if (width < 200) {
          toggleWidget = Checkbox(
            value: value,
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );
        } else {
          toggleWidget = Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        }

        if (width < 180) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                icon,
                const SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w900,
                    color: AppColors.chacking,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                const SizedBox(height: 4),
                toggleWidget,
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w900,
                    color: AppColors.chacking,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              toggleWidget,
            ],
          ),
        );
      },
    );
  }

  /// Builds the main UI for the settings panel.
  ///
  /// Contains toggles for drinking mode and forbidden words mode,
  /// and text fields for forbidden words if the mode is enabled.
  ///
  /// Uses responsive layout and scrollable container.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final scrollPaddingHeight = height * 0.01;
        final scrollPaddingWidth = width * 0.02;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: scrollPaddingWidth,
            vertical: scrollPaddingHeight,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(scrollPaddingWidth),
              color: const Color.fromARGB(137, 241, 230, 255),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildModeToggle(
                  title: TranslationService.instance.t(
                    'game.modes.drinking_mode.title',
                  ),
                  description: TranslationService.instance.t(
                    'game.modes.drinking_mode.instructions',
                  ),
                  value: drinkingMode,
                  onChanged: (bool value) {
                    setState(() {
                      drinkingMode = value;
                    });
                    widget.onDrinkingModeChanged(value);
                  },
                ),
                _buildModeToggle(
                  title: TranslationService.instance.t(
                    'game.modes.forbidden_words_mode.title',
                  ),
                  description: TranslationService.instance.t(
                    'game.modes.forbidden_words_mode.instructions',
                  ),
                  value: forbiddenWordsMode,
                  onChanged: (bool value) {
                    setState(() {
                      forbiddenWordsMode = value;
                    });
                    widget.onForbiddenModeChanged(value);
                  },
                ),

                if (forbiddenWordsMode) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextField(
                      controller: _forbiddenWord1Controller,
                      onChanged: (text) {
                        widget.onForbiddenWordsChanged(0, text);
                      },
                      decoration: InputDecoration(
                        hintText: TranslationService.instance.t(
                          'screens.room_settings.forbidden_word_1_placeholder',
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextField(
                      controller: _forbiddenWord2Controller,
                      onChanged: (text) {
                        widget.onForbiddenWordsChanged(1, text);
                      },
                      decoration: InputDecoration(
                        hintText: TranslationService.instance.t(
                          'screens.room_settings.forbidden_word_2_placeholder',
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
