// skillrush/lib/model_view/authorization/auth_manager.dart

import 'package:nexaburst/model_view/authorization/auth_manager_interface.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// Debug auth manager that performs validation without remote auth calls.
class FakeAuthManager extends AuthManagerInterface {
  /// Validates email structure and returns localized error text when invalid.
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty)
      return TranslationService.instance.t(
        'errors.registration_and_login.field_empty',
      );
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
      return TranslationService.instance.t(
        'errors.registration_and_login.invalid_email',
      );
    return null;
  }

  /// Validates username policy and returns localized error text when invalid.
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty)
      return TranslationService.instance.t(
        'errors.registration_and_login.field_empty',
      );
    if (!RegExp(r'^[a-zA-Z0-9]{2,}$').hasMatch(value)) {
      return TranslationService.instance.t(
        'errors.registration_and_login.invalid_user_name',
      );
    }
    return null;
  }

  /// Validates password policy and returns localized error text when invalid.
  String? _validatePassword(String? value) {
    if (value == null || value.length < 5)
      return TranslationService.instance.t(
        'errors.registration_and_login.password_too_short',
      );
    if (value.length > 16)
      return TranslationService.instance.t(
        'errors.registration_and_login.password_too_long',
      );

    // Keep validation aligned with current regex policy used by the app.
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{5,}$').hasMatch(value)) {
      return TranslationService.instance.t(
        'errors.registration_and_login.password_requires',
      );
    }

    return null;
  }

  /// Validates password confirmation and returns localized mismatch text.
  String? _validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword != password)
      return TranslationService.instance.t(
        'errors.registration_and_login.passwords_match',
      );
    return null;
  }

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

    return null;
  }

  @override
  Future<String?> login(String email, String password) async {
    return null;
  }
}
