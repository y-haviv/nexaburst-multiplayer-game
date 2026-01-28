// nexaburst/lib/Screens/authorization/signup/singup_from.dart
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/authorization/Login/login_screen.dart';
import 'package:nexaburst/Screens/authorization/components/already_have_an_account_acheck.dart';
import 'package:nexaburst/Screens/main_components/app_text.dart';
import 'package:nexaburst/Screens/main_components/lunguage_field.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/authorization/auth_manager_interface.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:provider/provider.dart';

/// A stateful widget that presents the user registration form.
///
/// Collects user details—email, username, password, language, and age—
/// validates input, and triggers the sign‑up process via [AuthManagerInterface].
class SignUpForm extends StatefulWidget {
  /// Creates a [SignUpForm].
  ///
  /// This constructor is constant and accepts an optional [key].
  const SignUpForm({super.key});

  /// Creates the mutable state for this widget.
  @override
  _SignUpFormState createState() => _SignUpFormState();
}

/// Holds form state and user input for the sign‑up flow.
///
/// Manages validation, error messages, and submission logic.
class _SignUpFormState extends State<SignUpForm> {
  /// Key to access and validate the sign‑up [Form].
  final _formKey = GlobalKey<FormState>();

  /// Stores user‑entered values:
  /// - [email]: user’s email address
  /// - [username]: chosen display name
  /// - [password]: chosen password
  /// - [confirmPassword]: password confirmation
  /// - [language]: selected language code
  String? email, username, password, confirmPassword, language;
  int? age;

  /// Stores the user’s selected age.
  String errorMessage = "";

  /// Initializes state for the sign‑up form.
  ///
  /// Currently only calls [super.initState].
  @override
  void initState() {
    super.initState();
  }

  /// Builds the sign‑up form UI, including all input fields and buttons.
  ///
  /// Adapts spacing based on screen height and constrains form width.
  @override
  Widget build(BuildContext context) {
    /// Retrieves the total height of the screen for responsive spacing.
    final screenHeight = MediaQuery.of(context).size.height;

    /// Defines vertical spacing values proportional to screen height:
    /// - [bigSpace] for larger gaps
    /// - [smallSpace] for tighter gaps
    final bigSpace = screenHeight * 0.04;
    final smallSpace = screenHeight * 0.02;

    /// Maximum width for the form to maintain readability on large screens.
    const maxFormWidth = 500.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxFormWidth),

          /// Wraps all input fields and buttons in a Flutter [Form].
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: bigSpace),
                AppText.build(
                  TranslationService.instance.t(
                    'screens.registration_and_login.sign_up_title',
                  ),
                  context: context,
                  type: TextType.subtitle,
                  backgroundColor: Colors.black.withOpacity(0.4),
                ),
                SizedBox(height: bigSpace),

                Stack(
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Opacity(
                          opacity: 0.6,
                          child: Image.asset(
                            PicPaths.inputBackground,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// Email input field.
                        ///
                        /// - `keyboardType`: email address input
                        /// - `onSaved`: stores value in [email]
                        /// - `validator`: ensures non‑empty and shows localized error
                        TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          cursorColor: AppColors.kPrimaryColor,
                          decoration: InputDecoration(
                            hintText: TranslationService.instance.t(
                              'screens.registration_and_login.email',
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.email),
                            ),
                            errorStyle: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onSaved: (value) => email = value,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return TranslationService.instance.t(
                                'screens.registration_and_login.email_request',
                              );
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: smallSpace),

                        /// Username input field.
                        ///
                        /// - `onSaved`: stores value in [username]
                        /// - `validator`: ensures non‑empty and shows localized error
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          cursorColor: AppColors.kPrimaryColor,
                          decoration: InputDecoration(
                            hintText: TranslationService.instance.t(
                              'screens.registration_and_login.user_name',
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.person),
                            ),
                            errorStyle: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onSaved: (value) => username = value,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return TranslationService.instance.t(
                                'screens.registration_and_login.user_name_request',
                              );
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: smallSpace),

                        /// A dropdown to select user language.
                        ///
                        /// Saves selected language code to [language].
                        LanguageField(onSaved: (code) => language = code),

                        SizedBox(height: smallSpace),

                        /// Age selection dropdown.
                        ///
                        /// - Items generated from [AuthManagerInterface.ages].
                        /// - `onChanged`: updates [age].
                        /// - `validator`: ensures a selection is made.
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final avail = constraints.maxWidth;
                            final fieldWidth = avail < 120.0 ? 120.0 : avail;

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: fieldWidth,
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  items: AuthManagerInterface.ages.map((
                                    ageValue,
                                  ) {
                                    return DropdownMenuItem(
                                      value: ageValue,
                                      child: Text(
                                        ageValue.toString(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 12,
                                    ),
                                    hintText: TranslationService.instance.t(
                                      'screens.registration_and_login.select_age',
                                    ),
                                    hintMaxLines: 1,
                                    hintStyle: const TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Icon(Icons.cake, size: 20),
                                    ),
                                    errorStyle: const TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onChanged: (value) =>
                                      setState(() => age = value),
                                  validator: (value) {
                                    if (value == null) {
                                      return TranslationService.instance.t(
                                        'screens.registration_and_login.select_age_request',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: smallSpace),

                        /// Password input field.
                        ///
                        /// - `obscureText`: hides input.
                        /// - `onSaved`: stores value in [password].
                        /// - `validator`: ensures non‑empty and shows localized error.
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          obscureText: true,
                          cursorColor: AppColors.kPrimaryColor,
                          decoration: InputDecoration(
                            hintText: TranslationService.instance.t(
                              'screens.registration_and_login.password',
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.lock),
                            ),
                            errorStyle: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onSaved: (value) => password = value,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return TranslationService.instance.t(
                                'screens.registration_and_login.password_request',
                              );
                            }

                            return null;
                          },
                        ),

                        SizedBox(height: smallSpace),

                        /// Password confirmation field.
                        ///
                        /// - `onSaved`: stores value in [confirmPassword].
                        /// - `validator`: checks non‑empty and matches [password],
                        ///   showing localized mismatch error if needed.
                        TextFormField(
                          textInputAction: TextInputAction.done,
                          obscureText: true,
                          cursorColor: AppColors.kPrimaryColor,
                          decoration: InputDecoration(
                            hintText: TranslationService.instance.t(
                              'screens.registration_and_login.confirm_password',
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.lock),
                            ),
                            errorStyle: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onSaved: (value) => confirmPassword = value,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return TranslationService.instance.t(
                                'screens.registration_and_login.confirm_password_request',
                              );
                            }
                            if (password != null && password != value) {
                              return TranslationService.instance.t(
                                'screens.errors.passwords_match',
                              );
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: bigSpace),

                /// Submits the sign‑up form.
                ///
                /// - Validates all fields via [_formKey].
                /// - On success, calls [AuthManagerInterface.signUp] with collected inputs.
                /// - Shows a success dialog and navigates to login on success.
                /// - Updates [errorMessage] on failure.
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      // Ensure no field is null
                      if (email == null ||
                          username == null ||
                          password == null ||
                          confirmPassword == null ||
                          language == null ||
                          age == null) {
                        setState(() {
                          errorMessage = TranslationService.instance.t(
                            'screens.errors.field_empty',
                          );
                        });
                        return;
                      }
                      // Call the sign-up method
                      final authManager = context.read<AuthManagerInterface>();
                      String? result = await authManager.signUp(
                        email!,
                        username!,
                        password!,
                        confirmPassword!,
                        language!,
                        age!,
                      );
                      if (result == null) {
                        // Show a dialog to notify the user and navigate to login screen
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              TranslationService.instance.t(
                                'screens.registration_and_login.signup_success_title',
                              ),
                            ),
                            content: Text(
                              TranslationService.instance.t(
                                'screens.registration_and_login.signup_success',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  TranslationService.instance.t(
                                    'screens.common.confirm',
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                      'screens.registration_and_login.sign_up',
                    ),
                  ),
                ),
                SizedBox(height: bigSpace),

                /// Displays a prompt to navigate back to the login screen.
                ///
                /// Uses [AlreadyHaveAnAccountCheck] with `login: false`.
                AlreadyHaveAnAccountCheck(
                  login: false,
                  press: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const LoginScreen();
                        },
                      ),
                    );
                  },
                ),

                /// Shows any error or confirmation messages below the sign‑up button.
                ///
                /// Styled with an error background if present.
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        color: AppColors.error,
                        backgroundColor: Color.fromARGB(255, 111, 53, 165),
                      ),
                    ),
                  ),
                SizedBox(height: bigSpace),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
