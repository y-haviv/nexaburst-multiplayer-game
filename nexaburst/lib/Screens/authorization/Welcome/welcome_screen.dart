// lib/Screens/authorization/welcome/welcom_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/authorization/login/login_screen.dart';
import 'package:nexaburst/Screens/authorization/signup/signup_screen.dart';
import 'package:nexaburst/Screens/main_components/background_enter.dart';
import 'package:nexaburst/constants.dart';

/// The main welcome screen displayed to users who are not logged in.
///
/// This screen presents a central image and two primary buttons:
/// one to navigate to the login screen and one to the signup screen.
/// It adapts its layout based on screen dimensions for responsiveness.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  /// Builds the responsive layout for the welcome screen.
  ///
  /// If the screen is wider than it is tall, content is arranged in a row.
  /// Otherwise, a vertically scrollable column layout is used.
  @override
  Widget build(BuildContext context) {
    return Background(
      child: LayoutBuilder(
        builder: (context, constraints) {
          /// Determines screen width and height for responsive layout logic.
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final isWider = width > height;

          /// Calculates the image size as 60% of the smaller screen dimension.
          final picSize = min(width, height) * 0.6;

          /// Chooses layout style based on screen orientation:
          /// horizontal row for wide screens, vertical column for narrow ones.
          return isWider
              ? SizedBox(
                  height: height * 0.95,
                  width: width * 0.95,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      SizedBox(
                        width: picSize,
                        height: picSize,
                        child: Image.asset(
                          PicPaths.enterPic,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const Spacer(),
                      SizedBox(
                        width: width * 0.3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              /// Navigates to the login screen and replaces the current route.
                              ///
                              /// Triggered when the user taps the "Login" button.
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text("Login"),
                              ),
                            ),
                            SizedBox(height: height * 0.02),
                            Flexible(
                              /// Navigates to the signup screen and replaces the current route.
                              ///
                              /// Triggered when the user taps the "Sign Up" button.
                              /// Styled with a light background to differentiate from the login button.
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignUpScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.kPrimaryLightColor,
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: height * 0.1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: picSize,
                            height: picSize,
                            child: Image.asset(
                              PicPaths.enterPic,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: height * 0.05),
                          SizedBox(
                            width: picSize,
                            child: Column(
                              children: [
                                /// "Login" button for narrow screen layout.
                                ///
                                /// Navigates to the login screen and replaces the current route.
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(
                                      picSize,
                                      min(height * 0.06, 56),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  ),
                                  child: Text("Login"),
                                ),
                                SizedBox(height: height * 0.01),

                                /// "Sign Up" button for narrow screen layout.
                                ///
                                /// Navigates to the signup screen and replaces the current route.
                                /// Uses a light background for visual distinction.
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.kPrimaryLightColor,
                                    elevation: 0,
                                    minimumSize: Size(
                                      picSize,
                                      min(height * 0.06, 56),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignUpScreen(),
                                    ),
                                  ),
                                  child: const Text(
                                    "Sign Up",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
        },
      ),
    );
  }
}
