// nexaburst/lib/screens/room/room_setting/level_setting.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/main_components/app_button.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// A widget that displays selectable game levels in a grid.
///
/// Allows toggling each level on or off and adjusting the number of
/// rounds per level. Supports an optional “drinking mode”
/// to show extra instructions.
class LevelSetting extends StatefulWidget {
  /// If true, shows additional drinking-mode instructions
  /// in the level info dialogs.
  final bool drinkingMode;

  /// The full list of available level identifiers.
  final List<String> allLevels;

  /// A parallel list to [allLevels] indicating the current
  /// number of rounds configured for each level.
  final List<int> allRoundPerLevel;

  /// The list of level identifiers that are currently selected.
  final List<String> selectedLevels;

  /// Callback invoked when the number of rounds for a level changes.
  ///
  /// Provides the level ID and the new round count.
  final void Function(String, int) onRoundsLevelChange;

  /// Callback invoked when a level is toggled selected/deselected.
  ///
  /// Provides the level ID.
  final void Function(String) onLevelSelceted;

  /// Creates a [LevelSetting] widget.
  ///
  /// - [drinkingMode]: Whether to include drinking-mode instructions.
  /// - [allLevels]: All level IDs available for selection.
  /// - [allRoundPerLevel]: Initial round counts per level.
  /// - [selectedLevels]: Levels that start selected.
  /// - [onLevelSelceted]: Called when a level is toggled.
  /// - [onRoundsLevelChange]: Called when rounds count is adjusted.
  const LevelSetting({
    super.key,
    required this.drinkingMode,
    required this.allLevels,
    required this.allRoundPerLevel,
    required this.selectedLevels,
    required this.onLevelSelceted,
    required this.onRoundsLevelChange,
  });

  @override
  State<LevelSetting> createState() => _LevelSetting();
}

/// State management for [LevelSetting], including UI updates
/// when levels are toggled or round counts change.
class _LevelSetting extends State<LevelSetting> {
  /// Local copy of all level IDs for building the grid.
  late List<String> allLevels;

  /// Local copy of round counts for each level tile.
  late List<int> allRoundPerLevel;

  /// Local copy of currently selected level IDs.
  late List<String> selectedLevels;

  /// The minimum allowed number of rounds per level.
  late final int minRounds;

  /// The maximum allowed number of rounds per level.
  late final int maxRounds;

  /// Initializes local state from widget properties and
  /// retrieves min/max round constraints.
  @override
  void initState() {
    super.initState();
    allLevels = widget.allLevels;
    allRoundPerLevel = widget.allRoundPerLevel;
    selectedLevels = widget.selectedLevels;

    minRounds = LevelsRounds.minLevelRound();
    maxRounds = LevelsRounds.maxLevelRound();
  }

  /// Updates the round count for level at [index] to [rounds],
  /// clamped between [minRounds] and [maxRounds].
  ///
  /// Also notifies via [widget.onRoundsLevelChange].
  void _changeRounds(int index, int rounds) {
    if (rounds > maxRounds || rounds < minRounds) return;
    setState(() {
      allRoundPerLevel[index] = rounds;
      widget.onRoundsLevelChange(allLevels[index], rounds);
    });
  }

  /// Builds a responsive grid of level tiles, each showing:
  /// - A help icon to view level instructions
  /// - A settings icon to adjust round count
  /// - The level’s title
  ///
  /// Handles taps to toggle selection and dialogs for details.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final sizeBox = min(220, width * 0.99).toDouble();
        final ratioBox = 1.6;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: sizeBox,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: ratioBox,
          ),
          itemCount: allLevels.length,
          itemBuilder: (context, index) {
            final slot = allLevels[index];

            /// Toggles selection of this level [slot], updates local state,
            /// and calls [widget.onLevelSelceted].
            return GestureDetector(
              onTap: () {
                setState(() {
                  final updatedLevels = [...selectedLevels];
                  if (updatedLevels.contains(slot)) {
                    updatedLevels.remove(slot);
                  } else {
                    updatedLevels.add(slot);
                  }
                  selectedLevels = updatedLevels;
                  widget.onLevelSelceted(slot);
                });
              },
              child: LayoutBuilder(
                builder: (ctx, itemConstraints) {
                  final w = itemConstraints.maxWidth;
                  final iconSize = w * 0.13;

                  final h =
                      (itemConstraints.maxHeight - iconSize - w * 0.08) * 0.9;
                  final titleFont = min(w * 0.11, h * 0.48);
                  final roundsFont = min(w * 0.1, h * 0.45);

                  return Container(
                    padding: EdgeInsets.all(w * 0.05),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(w * 0.08),
                      color: selectedLevels.contains(slot)
                          ? AppColors.kPrimaryColor.withOpacity(0.7)
                          : AppColors.kPrimaryLightColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          flex: 1,
                          fit: FlexFit.loose,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: AppButton.icon(
                                  icon: Icons.help_outline,
                                  onPressed: () {
                                    Widget contectText = !widget.drinkingMode
                                        ? Text(
                                            TranslationService.instance.t(
                                              'game.levels.$slot.instructions',
                                            ),
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                TranslationService.instance.t(
                                                  'game.levels.$slot.instructions',
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "${TranslationService.instance.t('game.modes.drinking_mode.instructions_title')}:",
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                TranslationService.instance.t(
                                                  'game.levels.$slot.drinking_instructions',
                                                ),
                                              ),
                                            ],
                                          );
                                    showDialog(
                                      context: context,
                                      builder: (dialogContext) {
                                        final screenH = MediaQuery.of(
                                          dialogContext,
                                        ).size.height;

                                        return AlertDialog(
                                          scrollable: true,
                                          title: Text(
                                            TranslationService.instance.t(
                                              'game.levels.$slot.title',
                                            ),
                                          ),
                                          content: contectText,
                                          insetPadding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          actions: screenH < 300
                                              ? []
                                              : [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          dialogContext,
                                                        ),
                                                    child: Text(
                                                      TranslationService
                                                          .instance
                                                          .t(
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
                                ),
                              ),
                              Flexible(
                                child: AppButton.icon(
                                  icon: Icons.settings,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (dialogContext) {
                                        final screenH = MediaQuery.of(
                                          dialogContext,
                                        ).size.height;

                                        final screenW = MediaQuery.of(
                                          dialogContext,
                                        ).size.width;

                                        int dialogRounds =
                                            allRoundPerLevel[index];

                                        return StatefulBuilder(
                                          builder: (dialogContext, setDialogState) {
                                            /// Dialog for adjusting the number of rounds for the current level.
                                            ///
                                            /// Uses [allRoundPerLevel[index]] as the initial value,
                                            /// provides increment/decrement controls within allowed range.
                                            return AlertDialog(
                                              scrollable: true,
                                              title: Text(
                                                TranslationService.instance.t(
                                                  'screens.settings.title',
                                                ),
                                              ),
                                              content: screenW < 400
                                                  ? Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          "${TranslationService.instance.t('screens.room_settings.round_count_label')}:",
                                                          style: TextStyle(
                                                            fontSize:
                                                                roundsFont,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        screenW < 200
                                                            ? Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  IconButton(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .remove_circle_outline,
                                                                      size:
                                                                          roundsFont *
                                                                          1.2,
                                                                    ),
                                                                    onPressed: () {
                                                                      setDialogState(() {
                                                                        dialogRounds = max(
                                                                          minRounds,
                                                                          dialogRounds -
                                                                              1,
                                                                        );
                                                                      });
                                                                      _changeRounds(
                                                                        index,
                                                                        dialogRounds,
                                                                      );
                                                                    },
                                                                    color:
                                                                        dialogRounds >
                                                                            minRounds
                                                                        ? null
                                                                        : Colors
                                                                              .grey,
                                                                  ),
                                                                  Text(
                                                                    '$dialogRounds',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          roundsFont,
                                                                    ),
                                                                  ),
                                                                  IconButton(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .add_circle_outline,
                                                                      size:
                                                                          roundsFont *
                                                                          1.2,
                                                                    ),
                                                                    onPressed: () {
                                                                      setDialogState(() {
                                                                        dialogRounds = min(
                                                                          maxRounds,
                                                                          dialogRounds +
                                                                              1,
                                                                        );
                                                                      });
                                                                      _changeRounds(
                                                                        index,
                                                                        dialogRounds,
                                                                      );
                                                                    },
                                                                    color:
                                                                        dialogRounds <
                                                                            maxRounds
                                                                        ? null
                                                                        : Colors
                                                                              .grey,
                                                                  ),
                                                                ],
                                                              )
                                                            : Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  IconButton(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .remove_circle_outline,
                                                                      size:
                                                                          roundsFont *
                                                                          1.2,
                                                                    ),
                                                                    onPressed: () {
                                                                      setDialogState(() {
                                                                        dialogRounds = max(
                                                                          minRounds,
                                                                          dialogRounds -
                                                                              1,
                                                                        );
                                                                      });
                                                                      _changeRounds(
                                                                        index,
                                                                        dialogRounds,
                                                                      );
                                                                    },
                                                                    color:
                                                                        dialogRounds >
                                                                            minRounds
                                                                        ? null
                                                                        : Colors
                                                                              .grey,
                                                                  ),
                                                                  Text(
                                                                    '$dialogRounds',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          roundsFont,
                                                                    ),
                                                                  ),
                                                                  IconButton(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .add_circle_outline,
                                                                      size:
                                                                          roundsFont *
                                                                          1.2,
                                                                    ),
                                                                    onPressed: () {
                                                                      setDialogState(() {
                                                                        dialogRounds = min(
                                                                          maxRounds,
                                                                          dialogRounds +
                                                                              1,
                                                                        );
                                                                      });
                                                                      _changeRounds(
                                                                        index,
                                                                        dialogRounds,
                                                                      );
                                                                    },
                                                                    color:
                                                                        dialogRounds <
                                                                            maxRounds
                                                                        ? null
                                                                        : Colors
                                                                              .grey,
                                                                  ),
                                                                ],
                                                              ),
                                                      ],
                                                    )
                                                  : Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          "${TranslationService.instance.t('screens.room_settings.round_count_label')}:",
                                                          style: TextStyle(
                                                            fontSize:
                                                                roundsFont,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons
                                                                .remove_circle_outline,
                                                            size:
                                                                roundsFont *
                                                                1.2,
                                                          ),
                                                          onPressed: () {
                                                            setDialogState(() {
                                                              dialogRounds = max(
                                                                minRounds,
                                                                dialogRounds -
                                                                    1,
                                                              );
                                                            });
                                                            _changeRounds(
                                                              index,
                                                              dialogRounds,
                                                            );
                                                          },
                                                          color:
                                                              dialogRounds >
                                                                  minRounds
                                                              ? null
                                                              : Colors.grey,
                                                        ),
                                                        Text(
                                                          '$dialogRounds',
                                                          style: TextStyle(
                                                            fontSize:
                                                                roundsFont,
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons
                                                                .add_circle_outline,
                                                            size:
                                                                roundsFont *
                                                                1.2,
                                                          ),
                                                          onPressed: () {
                                                            setDialogState(() {
                                                              dialogRounds = min(
                                                                maxRounds,
                                                                dialogRounds +
                                                                    1,
                                                              );
                                                            });
                                                            _changeRounds(
                                                              index,
                                                              dialogRounds,
                                                            );
                                                          },
                                                          color:
                                                              dialogRounds <
                                                                  maxRounds
                                                              ? null
                                                              : Colors.grey,
                                                        ),
                                                      ],
                                                    ),
                                              insetPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              actions: screenH < 300
                                                  ? []
                                                  : [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              dialogContext,
                                                            ),
                                                        child: Text(
                                                          TranslationService
                                                              .instance
                                                              .t(
                                                                'screens.common.close',
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                  color: AppColors.accent2,
                                  size: iconSize,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          flex: 1,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              TranslationService.instance.t(
                                'game.levels.$slot.title',
                              ),
                              style: TextStyle(
                                fontSize: titleFont,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
