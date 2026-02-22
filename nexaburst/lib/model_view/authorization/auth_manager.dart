// nexaburst/lib/model_view/authorization/auth_manager.dart

import 'package:nexaburst/model_view/authorization/auth_manager_interface.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/authorization/signup_login_model.dart';

/// Concrete implementation of `AuthManagerInterface` using `SignupLoginModel`.
/// Validates inputs and delegates actual auth calls.
class AuthManager extends AuthManagerInterface {
  /// Model handling the low‑level signup and login HTTP requests.
  final SignupLoginModel _SignupLogin = SignupLoginModel();

  /// Checks for non‑empty and well‑formed email address.
  /// Returns an error message or null if valid.
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return TranslationService.instance.t(
        'errors.registration_and_login.field_empty',
      );
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return TranslationService.instance.t(
        'errors.registration_and_login.invalid_email',
      );
    }
    return null;
  }

  /// Ensures username is alphanumeric and at least 2 characters.
  /// Returns an error message or null if valid.
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return TranslationService.instance.t(
        'errors.registration_and_login.field_empty',
      );
    }
    if (!RegExp(r'^[a-zA-Z0-9]{2,}$').hasMatch(value)) {
      return TranslationService.instance.t(
        'errors.registration_and_login.invalid_user_name',
      );
    }
    return null;
  }

  /// Enforces password length (5–16) and inclusion of a number.
  /// Returns an error message or null if valid.
  String? _validatePassword(String? value) {
    if (value == null || value.length < 5) {
      return TranslationService.instance.t(
        'errors.registration_and_login.password_too_short',
      );
    }
    if (value.length > 16) {
      return TranslationService.instance.t(
        'errors.registration_and_login.password_too_long',
      );
    }

    // fix to check: "password_requires": "Password must include a number and must include a special character."
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{5,}$').hasMatch(value)) {
      return TranslationService.instance.t(
        'errors.registration_and_login.password_requires',
      );
    }
    //

    return null;
  }

  /// Verifies that [confirmPassword] matches [password].
  /// Returns an error message or null if they match.
  String? _validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword != password) {
      return TranslationService.instance.t(
        'errors.registration_and_login.passwords_match',
      );
    }
    return null;
  }

  /// Validates inputs in sequence and invokes `_SignupLogin.signUp`.
  /// Returns the first validation error or a default message on failure.
  @override
  Future<String?> signUp(
    String email,
    String username,
    String password,
    String confirmPassword,
    String language,
    int age,
  ) async {
    String? ans;

    ans = _validateConfirmPassword(password, confirmPassword);
    if (ans != null) return ans;

    ans = _validateEmail(email);
    if (ans != null) return ans;

    ans = _validatePassword(password);
    if (ans != null) return ans;

    ans = _validateUsername(username);
    if (ans != null) return ans;

    bool success = await _SignupLogin.signUp(
      email,
      username,
      password,
      language,
      age,
    );

    return success
        ? null
        : TranslationService.instance.t(
            'errors.registration_and_login.default_signup_error',
          );
  }

  /// Validates email/password and invokes `_SignupLogin.login`.
  /// Returns the first validation error or a default message on failure.
  @override
  Future<String?> login(String email, String password) async {
    String? ans;

    ans = _validateEmail(email);
    if (ans != null) return ans;

    ans = _validatePassword(password);
    if (ans != null) return ans;

    bool success = await _SignupLogin.login(email, password);

    return success
        ? null
        : TranslationService.instance.t(
            'errors.registration_and_login.default_login_error',
          );
  }
}
