// nexaburst/lib/Screens/authorization/signup/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/main_components/background_enter.dart';
import 'components/signup_form.dart';

/// A stateless widget representing the user registration screen.
///
/// Displays a scrollable sign-up form over a designed background.
/// This screen is typically used to register a new user.
class SignUpScreen extends StatelessWidget {
  /// Creates a new [SignUpScreen] instance.
  ///
  /// This constructor is constant and takes an optional key.
  const SignUpScreen({super.key});

  /// Builds the widget tree for the sign-up screen.
  ///
  /// Returns a [Background] widget containing a padded, scrollable [SignUpForm].
  ///
  /// Parameters:
  /// - [context]: The build context.
  ///
  /// Returns:
  /// - A [Widget] displaying the registration UI.
  @override
  Widget build(BuildContext context) {
    return const Background(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: SignUpForm(),
      ),
    );
  }
}
