// nexaburst/lib/model_view/user_data_view_model.dart

import 'package:flutter/foundation.dart';
import 'package:nexaburst/debug/fake_view_model/fake_user_service.dart';
import 'package:nexaburst/models/data/server/user_service/audio_service.dart';
import 'package:nexaburst/models/data/server/user_service/user_repository.dart';
import 'package:nexaburst/models/data/server/user_service/user_service.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import '../models/structures/user_model.dart';

/// Singleton view‑model that holds and manages the current user state.
/// Provides authentication data, preferences, and audio controls.
class UserData extends ChangeNotifier {
  /// Private constructor for the singleton instance.
  UserData._internal();

  /// The singleton instance for accessing user data throughout the app.
  static final UserData instance = UserData._internal();

  /// When true, uses fake repositories for testing instead of real services.
  bool debugMode = false;

  /// Underlying data source for user persistence and retrieval.
  late UserRepository _repository;

  /// The currently authenticated user, or null if not logged in.
  UserModel? _user;
  UserModel? get user => _user;

  /// Indicates whether `init()` has been called and completed.
  bool get isInitialized => _intialized;
  bool _intialized = false;

  /// Controls background music and sound effects settings.
  final AudioService audio = AudioService();

  /// Emits updates when background music is enabled or disabled.
  final ValueNotifier<bool> musicNotifier = ValueNotifier(true);

  /// Emits updates when sound effects are enabled or disabled.
  final ValueNotifier<bool> soundNotifier = ValueNotifier(true);

  /// Performs one‑time setup:
  /// - Chooses repository (fake or real)
  /// - Loads the current user
  /// - Loads translations
  /// - Initializes audio settings
  /// - Notifies listeners
  ///
  /// Parameters:
  /// - `debugMode`: if true, uses `FakeUserRepository`.
  Future<void> init({required bool debugMode}) async {
    if (_intialized) return;

    this.debugMode = debugMode;

    _repository = this.debugMode
        ? FakeUserRepository()
        : await UserService.create();

    await TranslationService.instance.loadTranslations();

    _user = await _repository.getUser();

    musicNotifier.value = audio.isMusicEnabled;
    soundNotifier.value = audio.isSoundEnabled;
    _intialized = true;

    notifyListeners();
  }

  /// Replaces the current user with [fresh], persists it, and notifies listeners.
  Future<void> setUser(UserModel fresh) async {
    _user = fresh;

    await _repository.setUser(fresh);

    notifyListeners();
  }

  /// Updates user fields (username, language, age, avatar) if provided,
  /// persists changes, and notifies listeners.
  Future<void> updateProfile({
    String? username,
    String? language,
    int? age,
    String? avatar,
  }) async {
    if (_user == null || !_intialized) return;

    final updated = _user!.copyWith(
      username: username ?? _user!.username,
      language: language ?? _user!.language,
      age: age ?? _user!.age,
      avatar: avatar ?? _user!.avatar,
    );
    _user = updated;

    // Persist locally & remotely
    await _repository.saveUser(updated);

    notifyListeners();
  }

  /// Increments the user's win count both locally and remotely, then notifies.
  Future<void> incrementWins() async {
    if (_user == null || !_intialized) return;

    final newWins = _user!.wins + 1;
    _user = _user!.copyWith(wins: newWins);

    // Persist locally & remotely
    await _repository.saveUser(_user!);

    notifyListeners();
  }

  /// Logs out the user by clearing local and remote data,
  /// resets user model in non‑debug mode, clears audio, and notifies.
  Future<void> logout() async {
    // Persist locally & remotely
    await _repository.logout();
    if (!debugMode) _user = null;
    await audio.clear();
    notifyListeners();
  }

  /// Starts playing the background music file at [filePath].
  Future<void> playBackgroundMusic(String filePath) async {
    await audio.playBackgroundMusic(filePath);
  }

  /// Stops background music playback, optionally clearing the file reference.
  Future<void> stopBackgroundMusic({bool clearFile = false}) async {
    await audio.stopBackgroundMusic();
  }

  /// Plays the sound effect file at [filePath].
  Future<void> playSound(String filePath) async {
    await audio.playSound(filePath);
  }

  /// Toggles music on/off in the audio service and updates `musicNotifier`.
  Future<void> setMusicEnabled() async {
    await audio.setMusicEnabled();
    musicNotifier.value = !musicNotifier.value;
  }

  /// Toggles sound effects on/off in the audio service and updates `soundNotifier`.
  Future<void> setSoundEnabled() async {
    await audio.setSoundEnabled();
    soundNotifier.value = !soundNotifier.value;
  }

  /// Uploads [data] to Cloudinary under [filename], updates user's avatar URL,
  /// and notifies listeners.
  Future<void> uploadImage(Uint8List data, {required String filename}) async {
    if (_user == null || !_intialized) return;

    String? url = await _repository.uploadToCloudinary(
      data,
      filename: filename,
    );
    final updated = _user!.copyWith(avatar: url ?? _user!.avatar);
    _user = updated;
    notifyListeners();
  }
}

/// Provides a convenient `copyWith` method for updating user model fields.
extension on UserModel {
  /// Returns a new `UserModel` with specified fields overridden.
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? language,
    int? age,
    String? avatar,
    int? wins,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      language: language ?? this.language,
      age: age ?? this.age,
      avatar: avatar ?? this.avatar,
      wins: wins ?? this.wins,
    );
  }
}
