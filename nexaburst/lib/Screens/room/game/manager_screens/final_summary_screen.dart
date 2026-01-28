// nexaburst/lib/screens/room/game/manager_screens/final_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// Displays the final ranking of players after a game round.
///
/// Shows a scrollable list sorted by total score, highlighting the local player.
class FinalSummaryScreen extends StatefulWidget {
  /// Mapping from player ID to a map containing 'username' and 'total_score'.
  final Map<String, dynamic> players;

  /// The current user’s ID, used to highlight their entry.
  final String currentPlayerId;

  /// Creates a [FinalSummaryScreen] with player data and the local player ID.
  const FinalSummaryScreen({
    super.key,
    required this.players,
    required this.currentPlayerId,
  });

  /// Creates mutable state for the final summary screen.
  @override
  _FinalSummaryScreen createState() => _FinalSummaryScreen();
}

class _FinalSummaryScreen extends State<FinalSummaryScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Builds the UI, sorting players by score and rendering a styled list.
  @override
  Widget build(BuildContext context) {
    // Sort players by score descending
    final entries = widget.players.entries.toList()
      ..sort((a, b) {
        final sa = (a.value['total_score'] as num).toInt();
        final sb = (b.value['total_score'] as num).toInt();
        return sb.compareTo(sa);
      });

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final listSize = Size(w * 0.7, h * 0.8);

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.1,
              vertical: h * 0.05,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: timer on left, title centered
                Text(
                  TranslationService.instance.t(
                    'screens.game.final_summary_title',
                  ),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: w * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: h * 0.05),

                // The table of results
                Container(
                  width: listSize.width,
                  height: listSize.height,
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final id = entries[i].key;
                      final data = entries[i].value as Map<String, dynamic>;
                      final name = data['username'] as String;
                      final score = (data['total_score'] as num).toInt();
                      final isMe = id == widget.currentPlayerId;

                      return Container(
                        color: isMe ? Colors.yellow[200] : Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          vertical: h * 0.015,
                          horizontal: w * 0.04,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: w * 0.045,
                                  fontWeight: isMe
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                score.toString(),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: w * 0.045,
                                  fontWeight: isMe
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: h * 0.05),
              ],
            ),
          ),
        );
      },
    );
  }
}
