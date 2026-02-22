// nexaburst/lib/screens/main_components/background_enter.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';

/// A reusable widget that displays a full-screen background image
/// behind a given child widget.
///
/// Typically used to wrap entire screens with a consistent background.
class Background extends StatelessWidget {
  /// The widget to display on top of the background image.
  final Widget child;

  /// Creates a [Background] widget with the specified [child] displayed
  /// over a full-screen background image.
  const Background({super.key, required this.child});

  /// Builds the widget tree with a full-screen background image and
  /// overlays the provided [child] on top.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(PicPaths.mainBackground, fit: BoxFit.cover),
          child,
        ],
      ),
    );
  }
}
