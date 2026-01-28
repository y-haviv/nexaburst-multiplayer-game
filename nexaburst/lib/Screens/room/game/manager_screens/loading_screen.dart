// nexaburst/lib/screens/room/game/manager_screens/loading_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/models/data/service/loading_controller.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// A simple loading indicator screen with dynamic status messages.
class LoadingScreen extends StatelessWidget {
  /// Default message shown when no custom message is provided.
  final String defaultMessage = TranslationService.instance.t(
    'screens.common.loading',
  );

  /// Creates a [LoadingScreen], optionally displaying custom loading messages.
  LoadingScreen({super.key});

  /// Builds a centered spinner and status text.
  ///
  /// Listens to the [LoadingService] for status updates and displays them,
  /// falling back to [defaultMessage] if none are available.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // sizes relative to available space:
        final spinnerSize = min(w, h) * 0.15;
        final gapHeight = min(20.0, h * 0.04);
        final fontSize = min(18.0, w * 0.05);

        return Center(
          child: StreamBuilder<String?>(
            stream: LoadingService().messageStream,
            initialData: defaultMessage,
            builder: (context, snapshot) {
              final text = snapshot.data ?? defaultMessage;
              return Column(
                mainAxisSize: MainAxisSize.min, // shrinkwrap
                children: [
                  SizedBox(
                    width: spinnerSize,
                    height: spinnerSize,
                    child: const CircularProgressIndicator(strokeWidth: 4),
                  ),
                  SizedBox(height: gapHeight),
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
