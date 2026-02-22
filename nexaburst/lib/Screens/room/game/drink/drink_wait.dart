// nexaburst/lib/screens/room/game/drink/drink_wait.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// A screen that shows which players need to perform the drinking action.
///
/// Displays a scrollable list of player names from a provided stream.
class WaitingForPlayersScreen extends StatefulWidget {
  /// Stream emitting lists of player names who must drink.
  final Stream<List<String>> playersToDrink;

  /// Creates a [WaitingForPlayersScreen] bound to the given stream of player names.
  const WaitingForPlayersScreen({super.key, required this.playersToDrink});

  /// Creates mutable state for [WaitingForPlayersScreen].
  @override
  State<WaitingForPlayersScreen> createState() =>
      _WaitingForPlayersScreenState();
}

/// State class for [WaitingForPlayersScreen], manages scroll controller.
class _WaitingForPlayersScreenState extends State<WaitingForPlayersScreen> {
  late final ScrollController _listController;

  /// Initializes the scroll controller for the player list.
  @override
  void initState() {
    super.initState();
    _listController = ScrollController();
  }

  /// Disposes the scroll controller when the widget is removed.
  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  /// Builds the UI that listens to [playersToDrink] and shows each name in a styled list.
  ///
  /// Shows a loading placeholder when the list is empty.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return StreamBuilder<List<String>>(
          stream: widget.playersToDrink,
          builder: (context, snapshot) {
            // Diagnostics: print connection state / error / raw data
            debugPrint(
              'WaitingForPlayersScreen snapshot: '
              'connection=${snapshot.connectionState}, '
              'hasData=${snapshot.hasData}, '
              'hasError=${snapshot.hasError}, '
              'error=${snapshot.error}, '
              'data=${snapshot.data}',
            );

            // 1) If we are still waiting for the first event, show a spinner
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: SizedBox(
                  height: 120,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Loading players...'),
                    ],
                  ),
                ),
              );
            }

            // 2) If error -> show message
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading players: ${snapshot.error}'),
              );
            }

            // 3) Normal case: we have active stream (maybe empty)
            final names = snapshot.data ?? <String>[];

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.08,
                vertical: h * 0.04,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ... your header texts remain unchanged ...
                    const SizedBox(height: 12),

                    Center(
                      child: Container(
                        height: h * 0.6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(166, 255, 255, 255),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white30),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: names.isEmpty
                            // Stream active but no players to drink -> show explicit message
                            ? Center(
                                child: Text(
                                  TranslationService.instance.t(
                                    'game.modes.drinking_mode.no_players_to_drink', // fallback to 'None right now'
                                  ),
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: w * 0.05,
                                  ),
                                ),
                              )
                            : Scrollbar(
                                controller: _listController,
                                thumbVisibility: true,
                                child: ListView.separated(
                                  controller: _listController,
                                  padding: EdgeInsets.symmetric(
                                    vertical: h * 0.02,
                                    horizontal: w * 0.04,
                                  ),
                                  itemCount: names.length,
                                  separatorBuilder: (ctx, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (ctx, i) {
                                    final playerName = names[i];
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: h * 0.015,
                                        horizontal: w * 0.03,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          60,
                                          0,
                                          0,
                                          0,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white38,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        playerName,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: const Color.fromARGB(
                                            255,
                                            0,
                                            0,
                                            0,
                                          ),
                                          fontSize: w * 0.06,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  },
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
      },
    );
  }
}
