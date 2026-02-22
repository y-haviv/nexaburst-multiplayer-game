// nexaburst/lib/model_view/authorization/auth_manager_interface.dart

/// Defines the contract for authentication managers handling signup and login.
abstract class AuthManagerInterface {
  /// Predefined list of valid ages (1–130) for user registration.
  static final List<int> ages = List.generate(130, (index) => index + 1);

  /// Attempts to register a new user with the given credentials.
  ///
  /// Returns an error message on failure, or null on success.
  Future<String?> signUp(
    String email,
    String username,
    String password,
    String confirmPassword,
    String language,
    int age,
  );

  /// Attempts to log in with [email] and [password].
  ///
  /// Returns an error message on failure, or null on success.
  Future<String?> login(String email, String password);
}
