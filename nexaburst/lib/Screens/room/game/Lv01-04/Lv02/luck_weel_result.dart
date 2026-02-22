// nexaburst/lib/screens/room/game/Lv01-04/Lv02/luck_weel_result.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// A screen that displays the results of the Luck Wheel stage.
///
/// Shows a list of outcomes in order, or an error message if no data is available.
class LuckWheelResultsScreen extends StatefulWidget {
  /// List of result strings to display (e.g., player names or outcomes).
  final List<String> resultData;

  /// Creates a [LuckWheelResultsScreen] with the provided [resultData].
  const LuckWheelResultsScreen({super.key, required this.resultData});

  @override
  _LuckWheelResultsScreenState createState() => _LuckWheelResultsScreenState();
}

class _LuckWheelResultsScreenState extends State<LuckWheelResultsScreen> {
  /// Builds the UI, showing a title and either an error message or a
  /// scrollable numbered list of results.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final resultFontSize = max(16.0, screenWidth / 20);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 600),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      '${TranslationService.instance.t('game.levels.${TranslationService.instance.levelKeys[1]}.wheel_results')}:',
                      style: TextStyle(
                        fontSize: resultFontSize * 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (widget.resultData.isEmpty)
                    Center(
                      child: Text(
                        TranslationService.instance.t(
                          'errors.game.wheel_result_error',
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: screenHeight * 0.6,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: widget.resultData.length,
                        itemBuilder: (context, index) {
                          final text = widget.resultData[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Center(
                              child: Text(
                                '${index + 1}. $text',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: resultFontSize,
                                  fontWeight: FontWeight.w500,
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
          ),
        );
      },
    );
  }
}
