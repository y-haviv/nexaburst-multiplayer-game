// responsive.dart

import 'package:flutter/material.dart';

/// Simple responsive switch widget used by older experimental layouts.
class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  /// Returns true when the viewport width maps to mobile breakpoints.
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 576;

  /// Returns true when the viewport width maps to tablet breakpoints.
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 576 &&
      MediaQuery.of(context).size.width <= 992;

  /// Returns true when the viewport width maps to desktop breakpoints.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 992;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (size.width > 992) {
      return desktop;
    } else if (size.width >= 576 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}
