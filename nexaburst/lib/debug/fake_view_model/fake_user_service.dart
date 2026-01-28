

import 'dart:typed_data';

import 'package:nexaburst/constants.dart';
import 'package:nexaburst/models/data/server/user_service/user_repository.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/user_model.dart';

class FakeUserRepository implements UserRepository {
  UserModel _fakeUser = UserModel(
    id: 'debug123',
    username: 'DebugUser',
    email: 'debug@example.com',
    language: 'en',
    age: 10,
    avatar: PicPaths.defaultAvatarPath,
    wins: 0,
  );

  @override
  Future<void> setUser(UserModel user) async {
    _fakeUser = user;
    // Fire off translation change
    TranslationService.instance.setLanguage(user.language);
  }

  @override
  Future<UserModel> getUser() async => _fakeUser;

  @override
  Future<void> saveUser(UserModel user) async {
    _fakeUser = user;
    // Fire off translation change
    TranslationService.instance.setLanguage(user.language);
  }

  @override
  Future<void> logout() async {
    // כלום – debug mode
  }

  @override
  Future<String?> uploadToCloudinary(Uint8List data, {required String filename}) async {return null;}

}
