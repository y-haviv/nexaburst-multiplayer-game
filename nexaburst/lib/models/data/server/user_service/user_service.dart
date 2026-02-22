// nexaburst/lib/models/server/user_service/user_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/models/data/server/safe_call.dart';
import 'package:nexaburst/models/data/server/user_service/user_repository.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:nexaburst/models/structures/user_model.dart';
import 'package:http_parser/http_parser.dart';

/// Concrete [UserRepository] that uses Firebase Auth, Firestore,
/// secure storage, and Cloudinary for full user data management.
class UserService implements UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final storage = FlutterSecureStorage();

  /// Cloudinary cloud name from environment variables.
  static final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;

  /// Cloudinary upload preset key from environment variables.
  static final String uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET']!;

  /// Private constructor for controlled async initialization.
  UserService._();

  /// Asynchronously creates and returns a new [UserService] instance.
  static Future<UserService> create() async {
    final instance = UserService._();
    return instance;
  }

  /// Retrieves the user from secure storage or Firestore fallback,
  /// then applies the user’s language to [TranslationService].
  ///
  /// Returns the [UserModel] or `null` if not found.
  @override
  Future<UserModel?> getUser() async {
    UserModel? user;

    // 1) Try local cache
    if (await storage.containsKey(key: 'id')) {
      final id = await storage.read(key: 'id');
      final username = await storage.read(key: 'username');
      final email = await storage.read(key: 'email');
      final language = await storage.read(key: 'language');
      final ageString = await storage.read(key: 'age');
      final avatar = await storage.read(key: 'avatar');
      final winsString = await storage.read(key: 'wins');

      final age = ageString == null ? 0 : int.parse(ageString);
      final wins = winsString == null ? 0 : int.parse(winsString);

      if (id != null && username != null && email != null && language != null) {
        user = UserModel(
          id: id,
          username: username,
          email: email,
          language: language,
          age: age,
          avatar: avatar ?? '',
          wins: wins,
        );
      }
    }

    // 2) Fallback to Firestore if we have an auth user but no prefs
    final fbUser = _auth.currentUser;
    if (user == null && fbUser != null) {
      safeCall(() async {
        final doc = await _firestore.collection('users').doc(fbUser.uid).get();
        if (doc.exists) {
          user = UserModel.fromMap(doc.data()!);
          await storage.write(key: 'id', value: user!.id);
          await storage.write(key: 'username', value: user!.username);
          await storage.write(key: 'email', value: user!.email);
          await storage.write(key: 'language', value: user!.language);
          await storage.write(key: 'age', value: user!.age.toString());
          await storage.write(key: 'avatar', value: user!.avatar);
          await storage.write(key: 'wins', value: user!.wins.toString());
        } else {
          ErrorService.instance.report(error: ErrorType.notFound);
        }
      });
    }

    // 3) Set the translation language right away
    if (user != null &&
        user?.language != TranslationService.instance.currentLanguage) {
      TranslationService.instance.setLanguage(user!.language);
    }

    return user;
  }

  /// Stores [user] fields to secure storage and updates translation language.
  @override
  Future<void> setUser(UserModel user) async {
    // Persist locally & remotely
    await storage.write(key: 'id', value: user.id);
    await storage.write(key: 'username', value: user.username);
    await storage.write(key: 'email', value: user.email);
    await storage.write(key: 'language', value: user.language);
    await storage.write(key: 'age', value: user.age.toString());
    await storage.write(key: 'avatar', value: user.avatar);
    await storage.write(key: 'wins', value: user.wins.toString());

    // Fire off translation change
    if (user.language != TranslationService.instance.currentLanguage) {
      TranslationService.instance.setLanguage(user.language);
    }
  }

  /// Updates [user] fields in secure storage and Firestore.
  /// Reports errors via [safeCall].
  @override
  Future<void> saveUser(UserModel user) async {
    // Persist locally & remotely
    await storage.write(key: 'id', value: user.id);
    await storage.write(key: 'username', value: user.username);
    await storage.write(key: 'email', value: user.email);
    await storage.write(key: 'language', value: user.language);
    await storage.write(key: 'age', value: user.age.toString());
    await storage.write(key: 'avatar', value: user.avatar);
    await storage.write(key: 'wins', value: user.wins.toString());

    safeCall(() async {
      final uid = _auth.currentUser?.uid ?? storage.read(key: 'id').toString();
      await _firestore.collection('users').doc(uid).update({
        'username': user.username,
        'language': user.language,
        'age': user.age,
        'avatar': user.avatar,
        'wins': user.wins,
      });
    }, fallbackValue: null);

    // Fire off translation change
    if (user.language != TranslationService.instance.currentLanguage) {
      TranslationService.instance.setLanguage(user.language);
    }
  }

  /// Clears all secure storage, signs out from Firebase Auth,
  /// and resets translation to default ('en').
  @override
  Future<void> logout() async {
    await storage.deleteAll(); // 🔥 clears user data
    await FirebaseAuth.instance.signOut(); // 🔥 revokes session
    // Optionally reset translation to default:
    TranslationService.instance.setLanguage('en');
  }

  /// Sends [data] to Cloudinary with [filename], updates Firestore
  /// and local avatar URL on success, returning the secure URL.
  @override
  Future<String?> uploadToCloudinary(
    /// Binary image data to upload.
    Uint8List data, {

    /// Desired public filename (including extension).
    required String filename,
  }) async {
    try {
      final uid = _auth.currentUser?.uid ?? storage.read(key: 'id').toString();
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['public_id'] = uid;

      // Fallback filename if none supplied
      final ext = filename.contains('.') ? filename.split('.').last : 'png';
      //file.name.isNotEmpty? file.name: '${uid}-avatar.${ext.toLowerCase()}';

      // Fallback mime type
      final mimeType = 'image/$ext';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          data,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        await storage.write(key: 'avatar', value: data['secure_url']);
        await _firestore.collection('users').doc(uid).update({
          'avatar': data['secure_url'],
        });
        return data['secure_url'] as String?;
      } else {
        debugPrint('Upload failed: ${response.statusCode} - $responseBody');
        debugPrint('File name: $filename');
        debugPrint('File mime: $mimeType');
        debugPrint('File length: ${data.length}');

        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }
}
