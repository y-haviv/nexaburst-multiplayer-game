// nexaburst/lib/screens/room/game/Lv06/game_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// A stateful widget that presents the decision interface for a single round:
/// the player selects “Remain” or “Steal” and optionally guesses how many
/// players will steal. Automatically submits when time expires or when the
/// user taps “Done,” via [onSubmitted].
class GameScreen extends StatefulWidget {
  /// A stream providing the current count of players in the room,
  /// used to build the guess dropdown options.
  final Stream<int> playerCountStream;

  /// Callback invoked when the player’s choice and guess are finalized.
  /// Provides `(didSteal, guessCount)`, where `didSteal` is true if the player
  /// chose “Steal,” and `guessCount` is the selected guess or –1 if none.
  final void Function(bool result, int guess) onSubmitted;

  /// Constructs a [GameScreen] with the given player-count stream and
  /// submission callback.
  const GameScreen({
    super.key,
    required this.onSubmitted,
    required this.playerCountStream,
  });

  /// Creates the mutable state for this widget.
  @override
  _GameScreenState createState() => _GameScreenState();
}

/// State class for [GameScreen], responsible for tracking the player’s
/// selection, managing the countdown timer, and handling submission logic.
class _GameScreenState extends State<GameScreen> {
  /// Whether the player has chosen to steal (`true`) or remain (`false`),
  /// or `null` if no choice yet.
  bool? _choseSteal;

  /// The player’s selected guess for how many will steal, or `null` if none.
  int? _guessSelected;

  /// Prevents duplicate submissions by tracking if “Done” has already fired.
  bool _submitted = false;

  /// Subscription to the global timer stream; auto‑submits when time reaches zero.
  StreamSubscription<int>? _timerSubscription;

  /// Subscribes to the countdown from [TimerManager] and triggers
  /// `_submit()` when remaining time ≤ 0.
  @override
  void initState() {
    super.initState();

    _timerSubscription = TimerManager.instance.getTime().listen((remaining) {
      if (remaining <= 0) {
        if (!_submitted) _submit();
      }
    });
  }

  /// Cancels the timer subscription and disposes resources when the widget
  /// is removed from the tree.
  @override
  void dispose() {
    // Ensure timer is stopped when leaving screen
    _timerSubscription?.cancel();
    super.dispose();
  }

  /// Gathers the current choice and guess (or defaults) and invokes
  /// `widget.onSubmitted`, ensuring it only runs once.
  void _submit() {
    if (_submitted) return;
    _submitted = true;
    final result = _choseSteal ?? false;
    final guess = _guessSelected ?? -1;
    widget.onSubmitted(result, guess);
  }

  /// Builds the responsive UI: two choice cards, a guess dropdown based
  /// on `playerCountStream`, and a “Done” button styled with [AppColors].
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isWide = width > 600;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Choice row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ChoiceCard(
                        label: TranslationService.instance.t(
                          'game.levels.${TranslationService.instance.levelKeys[5]}.choice_remain',
                        ),
                        selected: _choseSteal == false,
                        onTap: () => setState(() => _choseSteal = false),
                      ),
                      SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
                      _ChoiceCard(
                        label: TranslationService.instance.t(
                          'game.levels.${TranslationService.instance.levelKeys[5]}.choice_stolen',
                        ),
                        selected: _choseSteal == true,
                        onTap: () => setState(() => _choseSteal = true),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    '${TranslationService.instance.t('game.levels.${TranslationService.instance.levelKeys[5]}.how_many_steal')}?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<int>(
                    stream: widget.playerCountStream,
                    builder: (ctx, snap) {
                      final playerCount = snap.data ?? 1;
                      if (_guessSelected != null &&
                          _guessSelected! > playerCount) {
                        _guessSelected = null;
                      }

                      final items = <DropdownMenuItem<int>>[
                        DropdownMenuItem(
                          value: -1,
                          child: Text(
                            TranslationService.instance.t(
                              'game.levels.${TranslationService.instance.levelKeys[5]}.default_not_select',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        for (int i = 0; i <= playerCount; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(
                              i.toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ];

                      final dropdown = Container(
                        width: width >= 100 ? width * 0.5 : double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: (width >= 100 ? 12 : 6),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(
                            width >= 100 ? 24 : 12,
                          ),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            hint: Text(
                              TranslationService.instance.t(
                                'game.levels.${TranslationService.instance.levelKeys[5]}.default_not_select',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            value: _guessSelected == -1 ? null : _guessSelected,
                            items: items,
                            onChanged: (val) {
                              setState(() {
                                _guessSelected = (val != null && val >= 0)
                                    ? val
                                    : null;
                              });
                            },
                            dropdownColor: Colors.white,
                            elevation: 4,
                            itemHeight: null,
                            menuMaxHeight: 200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );

                      return width >= 70 ? dropdown : const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: width * 0.5,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent4,
                      ),
                      onPressed: _choseSteal != null ? _submit : null,
                      child: Text(
                        TranslationService.instance.t(
                          'screens.settings.done_button',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A card widget for Remain/Stolen choice.
/// A reusable card widget for displaying a single choice option
/// with visual feedback when selected.
class _ChoiceCard extends StatelessWidget {
  /// The text to display inside the choice card.
  final String label;

  /// Whether this card is currently selected, affecting its border
  /// color, shadow, and background.
  final bool selected;

  /// Callback invoked when the user taps this card.
  final VoidCallback onTap;

  /// Creates a [_ChoiceCard] with the given [label], selection state,
  /// and tap handler.
  const _ChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Builds the card’s container, text, and applies styling changes
  /// when [selected] is true.
  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey;

    return Flexible(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: selected
                ? AppColors
                      .accent3 // Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : AppColors.accent4, //Colors.transparent,
            border: Border.all(color: borderColor, width: selected ? 3 : 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: borderColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
