// nexaburst/lib/screens/room/game/manager_screens/game_over_screen.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// Displays the game over results, indicating winners and final scores.
///
/// Highlights winning players and the local player with distinct background colors.
class GameOverScreen extends StatefulWidget {
  /// Mapping from player ID to player data (includes 'username' and 'total_score').
  final Map<String, dynamic> players;

  /// List of player IDs who won the game.
  final List<String> winner;

  /// The current user’s ID, used to indicate their entry in the list.
  final String currentPlayerId;

  /// Creates a [GameOverScreen] with players, winners, and the local player ID.
  const GameOverScreen({
    super.key,
    required this.players,
    required this.winner,
    required this.currentPlayerId,
  });

  /// Creates mutable state for the game over screen.
  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Builds the UI, sorting players, styling winners and current user, and displaying
  /// each entry with name and score.
  @override
  Widget build(BuildContext context) {
    final sortedPlayers = widget.players.entries.toList()
      ..sort(
        (a, b) => (b.value['total_score'] as int).compareTo(
          a.value['total_score'] as int,
        ),
      );

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final spaceSize = h * 0.02;
        final fontSize = w < 600 ? 16.0 : 20.0;
        final maxListSize = (h - spaceSize * 4) * 0.8;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Center(
            child: Column(
              children: [
                SizedBox(height: spaceSize),
                Center(
                  child: Text(
                    TranslationService.instance.t(
                      'screens.game.game_over_title',
                    ),
                    style: TextStyle(
                      fontSize: fontSize * 1.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(height: spaceSize * 2),
                SizedBox(
                  width: double.infinity,
                  height: maxListSize,
                  child: ListView.builder(
                    itemCount: sortedPlayers.length,
                    itemBuilder: (context, index) {
                      final playerId = sortedPlayers[index].key;
                      final player = sortedPlayers[index].value;
                      final isWinner = widget.winner.contains(playerId);
                      final isCurrentPlayer =
                          playerId == widget.currentPlayerId;

                      Color bgColor;
                      if (isWinner) {
                        bgColor = Colors.green.shade300.withOpacity(0.6);
                      } else if (isCurrentPlayer) {
                        bgColor = Colors.yellow.shade700.withOpacity(0.6);
                      } else {
                        bgColor = Colors.black.withOpacity(0.4);
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 16,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            isWinner
                                ? '${TranslationService.instance.t('screens.game.winner')}: ${player['username']} - ${player['total_score']}'
                                : '${player['username']} - ${player['total_score']}',
                            style: TextStyle(
                              fontSize: isWinner ? fontSize * 1.1 : fontSize,
                              fontWeight: isWinner
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
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
