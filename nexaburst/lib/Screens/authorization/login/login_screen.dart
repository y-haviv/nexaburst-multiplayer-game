// nexaburst/lib/Screens/authorization/login/login_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/authorization/signup/signup_screen.dart';
import 'package:nexaburst/Screens/authorization/components/already_have_an_account_acheck.dart';
import 'package:nexaburst/Screens/authorization/components/reset_password_screen.dart';
import 'package:nexaburst/Screens/main_components/background_enter.dart';
import 'package:nexaburst/Screens/menu/menu_screen.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/authorization/auth_manager_interface.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:provider/provider.dart';

/// A screen for users to log into the app.
///
/// Displays a designed background and a login form,
/// along with navigation to signup and password reset.
/// Translated text and responsive layout are supported.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  /// Builds the login screen wrapped in the designed background.
  ///
  /// Returns a [LoginForm] widget as the main content.
  @override
  Widget build(BuildContext context) {
    return Background(child: LoginForm());
  }
}

/// A stateful widget that handles the login form UI and logic.
///
/// Collects email and password input, validates credentials,
/// handles login requests, and displays error messages or redirects
/// based on the result.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

/// The state class for [LoginForm], managing form behavior and layout.
///
/// Controls user input, handles form submission, and displays errors
/// or success feedback.
class _LoginFormState extends State<LoginForm> {
  /// A global key used to validate and save the login form.
  final _formKey = GlobalKey<FormState>();

  /// Stores the user's email after input.
  String? email;

  /// Stores the user's password after input.
  String? password;

  /// Displays login error or success messages to the user.
  String errorMessage = "";

  /// Builds the visual login form, including email and password fields,
  /// a login button, error message, and navigation to signup/reset.
  ///
  /// Parameters:
  /// - `heightSpace`: vertical spacing used for consistent layout.
  ///
  /// Returns a [Form] widget wrapped in a background image.
  Widget logForm(double heightSpace) {
    return Form(
      key: _formKey,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Opacity(
                opacity: 0.8,
                child: Image.asset(PicPaths.inputBackground, fit: BoxFit.cover),
              ),
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Email input field.
              ///
              /// Saves the input to `email` and uses translated placeholder text.
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                cursorColor: AppColors.kPrimaryColor,
                onSaved: (value) => email = value,
                decoration: InputDecoration(
                  hintText: TranslationService.instance.t(
                    'screens.registration_and_login.email',
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.person),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),

                /// Password input field.
                ///
                /// Saves the input to `password`, hides characters, and uses
                /// translated placeholder text.
                child: TextFormField(
                  textInputAction: TextInputAction.done,
                  obscureText: true,
                  cursorColor: AppColors.kPrimaryColor,
                  onSaved: (value) => password = value,
                  decoration: InputDecoration(
                    hintText: TranslationService.instance.t(
                      'screens.registration_and_login.password',
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.lock),
                    ),
                  ),
                ),
              ),
              SizedBox(height: heightSpace),

              /// Submits the login form and attempts to authenticate the user.
              ///
              /// If successful, navigates to the menu screen.
              /// Otherwise, displays an error message.
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    final authManager = context.read<AuthManagerInterface>();
                    String? result = await authManager.login(email!, password!);
                    if (result == null) {
                      setState(() {
                        errorMessage = TranslationService.instance.t(
                          'screens.registration_and_login.login_success',
                        );
                      });
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Menu()),
                      );
                    } else {
                      setState(() {
                        errorMessage = result;
                      });
                    }
                  }
                },
                child: Text(
                  TranslationService.instance.t(
                    'screens.registration_and_login.login',
                  ),
                ),
              ),

              /// Displays error or success feedback after login attempt.
              ///
              /// Shows the translated result in red text.
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              SizedBox(height: heightSpace),

              /// Navigates to the reset password screen.
              ///
              /// Triggered when the user clicks "Forgot Password".
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ResetPasswordScreen(),
                    ),
                  );
                },
                child: Text(
                  TranslationService.instance.t(
                    'screens.registration_and_login.forgot_password',
                  ),
                  style: TextStyle(
                    color: Color.fromARGB(255, 248, 170, 0),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              SizedBox(height: heightSpace),

              /// Provides a link to the signup screen for users without an account.
              ///
              /// Uses a pre-built widget to handle layout and navigation.
              AlreadyHaveAnAccountCheck(
                press: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the responsive layout for the login form,
  /// arranging widgets based on screen orientation.
  ///
  /// Returns a scrollable view containing an image and the login form.
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Calculates screen dimensions and spacing for responsive layout.
    final isWider = screenWidth > screenHeight;
    final picSize = min(screenWidth, screenHeight) * 0.6;
    final heightSpace = isWider
        ? screenHeight * 0.05
        : (screenHeight * 0.3) * 0.02;

    /// Chooses between horizontal or vertical layout for the screen
    /// depending on screen orientation.
    Widget content = isWider
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              SizedBox(
                width: picSize,
                height: picSize,
                child: Image.asset(PicPaths.enterPic, fit: BoxFit.cover),
              ),

              const Spacer(),
              SizedBox(width: screenWidth * 0.3, child: logForm(heightSpace)),
              const Spacer(),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: picSize,
                height: picSize,
                child: Image.asset(PicPaths.enterPic, fit: BoxFit.cover),
              ),
              SizedBox(height: heightSpace * 2),
              SizedBox(width: picSize, child: logForm(heightSpace)),
            ],
          );

    /// Wraps the entire content in a scrollable container with constraints
    /// to ensure consistent sizing across devices.
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: screenHeight * 0.95),
        child: content,
      ),
    );
  }
}
