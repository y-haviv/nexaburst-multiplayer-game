// nexaburst/lib/screens/room/game/Lv01-04/round_summary.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:tuple/tuple.dart';

/// Shows a summary of points awarded this round.
///
/// Highlights the local player and displays only players who gained points.
class RoundSummaryScreen extends StatefulWidget {
  /// True if the local player answered correctly, false if wrong, or null.
  final bool? playerCorrect;

  /// Message to display when no player earned points.
  final String noPlayersGotPoints;

  /// Mapping from player ID to (username, pointsAdded) tuple.
  final Map<String, Tuple2<String, int>> playersAndAddedPoints;

  /// The current user’s ID for highlighting their row.
  final String currentPlayerId = UserData.instance.user!.id;

  /// Creates a [RoundSummaryScreen] with results and the local player’s correctness.
  RoundSummaryScreen({
    super.key,
    required this.playersAndAddedPoints,
    required this.playerCorrect,
    required this.noPlayersGotPoints,
  });

  /// Creates mutable state for [RoundSummaryScreen].
  @override
  _RoundSummaryScreenState createState() => _RoundSummaryScreenState();
}

/// State class for [RoundSummaryScreen], plays appropriate sound on init.
class _RoundSummaryScreenState extends State<RoundSummaryScreen> {
  @override
  void initState() {
    super.initState();
    _startSound();
  }

  /// Plays a random correct or wrong sound based on [playerCorrect].
  Future<void> _startSound() async {
    if (widget.playerCorrect != null) {
      final random = Random();

      final soundList = widget.playerCorrect!
          ? AudioPaths.correctSounds
          : AudioPaths.wrongSounds;
      final filePath = soundList[random.nextInt(soundList.length)];

      await UserData.instance.playSound(filePath);
    }
  }

  /// Builds the result table or a fallback message if no points were awarded.
  ///
  /// - Highlights the current user’s row.
  /// - Uses [DataTable] if entries exist, otherwise shows [noPlayersGotPoints].
  @override
  Widget build(BuildContext context) {
    // Background based on correctness
    Color backgroundColor = const Color.fromARGB(0, 253, 255, 250);
    if (widget.playerCorrect != null) {
      backgroundColor = widget.playerCorrect!
          ? const Color.fromARGB(118, 139, 195, 74)
          : const Color.fromARGB(129, 255, 82, 82);
    }

    // Filter entries with addedPoints > 0
    final entries =
        widget.playersAndAddedPoints.entries
            .where((e) => e.value.item2 > 0)
            .toList()
          ..sort((a, b) => b.value.item2.compareTo(a.value.item2));

    final hasRows = entries.isNotEmpty;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
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
              child: hasRows
                  ? DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey.shade200,
                      ),
                      columns: [
                        DataColumn(
                          label: Text(
                            TranslationService.instance.t(
                              'screens.settings.current_user_name',
                            ),
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            TranslationService.instance.t(
                              'game.common.added_points',
                            ),
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                      rows: entries.map((entry) {
                        final playerId = entry.key;
                        final playerName = entry.value.item1;
                        final addedPoints = entry.value.item2;
                        final isCurrent = playerId == widget.currentPlayerId;
                        return DataRow(
                          color: isCurrent
                              ? WidgetStateProperty.all(Colors.yellow.shade200)
                              : null,
                          cells: [
                            DataCell(
                              Text(
                                playerName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                addedPoints.toString(),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    )
                  : Center(
                      child: Text(
                        widget.noPlayersGotPoints,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
