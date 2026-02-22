// nexaburst/lib/models/server/user_service/user_repository.dart

import 'dart:typed_data';
import 'package:nexaburst/models/structures/user_model.dart';

/// Contract for user data persistence, including local storage,
/// remote updates, and logout functionality.
abstract class UserRepository {
  /// Retrieves the current user from cache or remote source.
  ///
  /// Returns a [UserModel] if found, or `null` otherwise.
  Future<UserModel?> getUser();

  /// Persists [user] to the local cache (e.g., secure storage).
  Future<void> setUser(UserModel user);

  /// Persists [user] both locally and remotely (e.g., Firestore).
  Future<void> saveUser(UserModel user);

  /// Clears user data and terminates authentication session.
  Future<void> logout();

  /// Uploads raw [data] to Cloudinary under [filename], returning
  /// the secure URL or `null` on failure.
  Future<String?> uploadToCloudinary(
    Uint8List data, {
    required String filename,
  });
}
