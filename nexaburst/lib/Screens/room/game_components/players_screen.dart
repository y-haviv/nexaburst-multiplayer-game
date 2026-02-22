// nexaburst/lib/screens/game_components/players_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/menu/avatars/avatar_ui_helper.dart';
import 'package:nexaburst/Screens/main_components/app_button.dart';
import 'package:nexaburst/model_view/room/players_view_model/players_interface.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/structures/player_model.dart';
import 'package:provider/provider.dart';

/// Screen that displays the list of players in the current room.
///
/// Shows avatar, username, wins, and score for each participant,
/// highlighting the local user.

/// Creates a [PlayersScreen] bound to the specified [roomId].
class PlayersScreen extends StatefulWidget {
  final String roomId;

  /// Creates mutable state for [PlayersScreen].
  const PlayersScreen({super.key, required this.roomId});

  /// State implementation for [PlayersScreen].
  ///
  /// Initializes the players view model, subscribes to the player stream,
  /// and builds the UI list.
  @override
  _PlayersScreenState createState() => _PlayersScreenState();
}

/// The view model providing player data.
class _PlayersScreenState extends State<PlayersScreen> {
  /// Indicates whether initialization is complete.
  Players? viewModel;

  /// Stream of current players in the room.
  bool initialized = false;

  /// Starts view model initialization after first frame.
  Stream<List<Player>>? playerStream;

  /// Performs asynchronous initialization:
  /// - Reads the [Players] viewModel from Provider.
  /// - Calls `initialization(roomId)`.
  /// - Subscribes to the `players()` stream.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initialize());
  }

  /// Disposes the view model when this widget is removed.
  void initialize() async {
    viewModel = context.read<Players>();
    await viewModel?.initialization(roomId: widget.roomId);
    if (mounted) {
      setState(() {
        initialized = true;
      });
    }
    playerStream = initialized
        ? (await viewModel?.players()) ?? Stream.empty()
        : Stream.empty();
  }

  /// Builds the players list UI.
  ///
  /// - Shows a loading indicator until data arrives.
  /// - Displays a header row and a scrollable list of players.
  /// - Highlights the local user’s row.
  @override
  void dispose() {
    viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 44, 165, 245),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(167, 104, 72, 248),
        elevation: 0,
        leading: AppButton.icon(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
          color: Colors.black,
          size: min(32, MediaQuery.of(context).size.width * 0.08),
        ),
        title: Text(
          TranslationService.instance.t('game.common.players'),
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: playerStream == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Player>>(
              stream: playerStream,
              initialData: const <Player>[],
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.isEmpty) {
                  return Center(
                    child: Text(
                      TranslationService.instance.t('screens.common.loading'),
                    ),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      TranslationService.instance.t(
                        'errors.common.error_loading_data',
                      ),
                    ),
                  );
                }

                final players = snap.data!;
                if (players.isEmpty) {
                  return Center(
                    child: Text(
                      TranslationService.instance.t('screens.common.loading'),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final tableWidth = constraints.maxWidth > 600
                        ? 600.0
                        : constraints.maxWidth * 0.95;

                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: tableWidth),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              color: Colors.white.withOpacity(0.7),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: min(60, tableWidth * 0.15),
                                    child: const Text(''),
                                  ),

                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      TranslationService.instance.t(
                                        'screens.settings.current_user_name',
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      TranslationService.instance.t(
                                        'screens.settings.wins_label',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      TranslationService.instance.t(
                                        'screens.settings.score_label',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Divider(height: 10, color: Colors.grey),

                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 20),
                                itemCount: players.length,
                                itemBuilder: (context, i) {
                                  final p = players[i];
                                  final isMe =
                                      p.id == UserData.instance.user!.id;
                                  final bg = isMe
                                      ? const Color.fromARGB(120, 255, 235, 59)
                                      : Colors.transparent;

                                  return Container(
                                    color: bg,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: min(60, tableWidth * 0.15),
                                          child: SpriteAvatar(
                                            id: p.avatar,
                                            radius: 24,
                                          ),
                                        ),

                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            p.username,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),

                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            p.wins.toString(),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            p.totalScore.toString(),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
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
              },
            ),
    );
  }
}
