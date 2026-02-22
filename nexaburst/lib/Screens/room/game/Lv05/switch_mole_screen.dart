// nexaburst/lib/screens/room/game/Lv05/switch_mole_screen.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// A transitional screen shown when passing the mole role.
///
/// Displays a message and the user’s current score.
class SwitchMoleScreen extends StatefulWidget {
  /// The player’s cumulative score to display.
  final int score;

  /// Creates a [SwitchMoleScreen] showing the given [score].
  const SwitchMoleScreen({super.key, required this.score});

  /// Creates mutable state for [SwitchMoleScreen].
  @override
  _SwitchMoleScreenState createState() => _SwitchMoleScreenState();
}

/// State class that renders the switch‑mole message and score.
class _SwitchMoleScreenState extends State<SwitchMoleScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Builds UI with:
  /// 1. A localized “switch mole” title
  /// 2. The player’s [score]
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        // Force whole‐pixel font sizes:
        final titleFont = 22.0;
        final scoreFont = 18.0;

        return SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TranslationService.instance.t(
                      'game.levels.${TranslationService.instance.levelKeys[4]}.switch_mole',
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: titleFont,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: h * 0.02),
                  Text(
                    '${TranslationService.instance.t('game.common.your_points')}: ${widget.score}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: scoreFont,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // ),
        );
      },
    );
  }
}
