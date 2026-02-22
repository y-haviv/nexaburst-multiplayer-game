// nexaburst/lib/screens/room/game/Lv06/round_result_screen.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:tuple/tuple.dart';

/// A stateless widget that displays the outcome of a round:
/// shows points earned, bonus-guess feedback, and a table of all
/// players’ choices and guesses.
class RoundResultsScreen extends StatelessWidget {
  /// The number of points added to the player’s total this round.
  final int added;

  /// True if the player’s bonus guess matched the actual number of
  /// stealers; false otherwise.
  final bool bonusGuessCorrect;

  /// Maps each player’s name to a tuple of (`choiceLabel`, `guessLabel`)
  /// for display in the results table.
  final Map<String, Tuple2<String, String>> playersInfo;

  /// Constructs a [RoundResultsScreen] with the round’s score,
  /// bonus-guess result, and per-player info.
  const RoundResultsScreen({
    super.key,
    required this.added,
    required this.bonusGuessCorrect,
    required this.playersInfo,
  });

  /// Builds the results layout: a header text, summary line with points
  /// and bonus feedback, and a scrollable [DataTable] of all players.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final spaceSizeH = height * 0.02;
        final tableSize = Size(width * 0.7, height * 0.8);

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // header
                  Text(
                    TranslationService.instance.t(
                      'screens.game.round_summary_title',
                    ),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: spaceSizeH * 1.5),

                  // Summary section
                  Text(
                    '| ${TranslationService.instance.t('game.common.added_points')}: $added | ${bonusGuessCorrect ? TranslationService.instance.t('game.levels.${TranslationService.instance.levelKeys[5]}.guessed_right') : TranslationService.instance.t('game.levels.${TranslationService.instance.levelKeys[5]}.guessed_wrong')}. |',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),

                  SizedBox(height: spaceSizeH),

                  // Table of players
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      width: tableSize.width,
                      height: tableSize.height,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            Colors.grey.shade200,
                          ),
                          columns: [
                            DataColumn(
                              label: Text(
                                TranslationService.instance.t(
                                  'screens.settings.player',
                                ),
                                style: TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                TranslationService.instance.t(
                                  'game.levels.${TranslationService.instance.levelKeys[5]}.choice',
                                ),
                                style: TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                TranslationService.instance.t(
                                  'game.levels.${TranslationService.instance.levelKeys[5]}.guess',
                                ),
                                style: TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                          rows: playersInfo.entries.map((entry) {
                            final player = entry.key;
                            final info = entry.value;
                            final choice = info.item1;
                            final guess = info.item2;
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    player,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    choice,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    guess,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: spaceSizeH),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
