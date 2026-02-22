// nexaburst/lib/Screens/authorization/component/already_have_an_account_check.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// A widget that provides a toggle link between login and sign-up screens.
///
/// Displays a message like "Don't have an account? Sign Up" or
/// "Already have an account? Sign In", depending on [login].
///
/// Includes a tappable text that triggers the [press] callback.
class AlreadyHaveAnAccountCheck extends StatelessWidget {
  /// Determines which message and action to show.
  ///
  /// If `true`, displays the prompt to sign up.
  /// If `false`, displays the prompt to sign in.
  final bool login;

  /// Callback executed when the user taps the action link.
  ///
  /// Typically used to navigate to either the sign-in or sign-up screen.
  final Function? press;

  /// Creates an [AlreadyHaveAnAccountCheck] widget.
  ///
  /// Parameters:
  /// - [login]: controls the type of prompt shown (default is `true`)
  /// - [press]: required callback triggered when link is tapped
  const AlreadyHaveAnAccountCheck({
    super.key,
    this.login = true,
    required this.press,
  });

  /// Builds the responsive account check widget.
  ///
  /// Uses screen dimensions to size the layout, and displays
  /// a localized message with an interactive link.
  @override
  Widget build(BuildContext context) {
    /// Calculates screen dimensions and sets a maximum width
    /// for the widget layout to keep it compact and centered.
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final maxWidth = min(screenWidth, screenHeight) * 0.6;

    /// Returns the main UI containing a localized message and
    /// a tappable link to switch between login/signup.
    ///
    /// Texts and colors are styled for clarity and visibility.
    return SizedBox(
      width: maxWidth,
      child: Wrap(
        alignment: WrapAlignment.center,
        children: <Widget>[
          Text(
            TranslationService.instance.t(
              'screens.registration_and_login.${login ? 'not_already_have_account' : 'already_have_account'}',
            ),
            style: const TextStyle(
              color: Colors.black,
              backgroundColor: Color.fromARGB(188, 111, 53, 165),
            ),
          ),
          GestureDetector(
            onTap: press as void Function()?,
            child: Text(
              TranslationService.instance.t(
                'screens.registration_and_login.${login ? 'sign_up' : 'sign_in'}',
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 248, 170, 0),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
