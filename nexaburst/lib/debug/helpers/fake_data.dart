// lib/debug/fake_room_data.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/structures/levels/levels_factory.dart';
import 'package:nexaburst/models/structures/player_model.dart';
import 'package:nexaburst/models/structures/room_model.dart';
import 'package:nexaburst/models/structures/user_model.dart';
import 'package:nexaburst/models/structures/word_event.dart';

class FakeRoomData {
  static UserModel currentUserDefault = UserModel(
    id: 'me',
    username: 'Dev',
    email: '',
    language: 'en',
    avatar: PicPaths.defaultAvatarPath,
    age: 25,
    wins: 5,
  );

  static Player currentPlayerDefault = Player(
    id: UserData.instance.user!.id,
    username: UserData.instance.user!.username,
    avatar: UserData.instance.user!.avatar,
    wins: UserData.instance.user!.wins,
    totalScore: 0,
  );

  static List<Player> otherPlayers = [
    currentPlayerDefault,
    Player(
      id: 'p1',
      username: 'Alice',
      wins: 2,
      totalScore: 15,
      avatar: "male_1",
    ),
    Player(
      id: 'p2',
      username: 'Bob',
      wins: 1,
      totalScore: 8,
      avatar: "female_2",
    ),
  ];

  // starts off as “waiting”
  static Room room = Room(
    roomId: 'DEBUG-123',
    hostId: 'me',
    levels: [],
    forbiddenWords: [],
    isDrinkingMode: false,
    isForbiddenWordMode: false,
    playersToDrink: {},
    lang: 'en',
    status: RoomStatus.waiting,
  );

  static Map<String, GameModels> levelsData = {};
  static List<WordEvent> wor = [];

  static Future<void> levelsInitialization(
    Map<String, int> l,
    List<String> forbidden,
    bool isDrinkingMode,
  ) async {
    currentPlayerDefault = Player(
      id: UserData.instance.user!.id,
      username: UserData.instance.user!.username,
      avatar: UserData.instance.user!.avatar,
      wins: UserData.instance.user!.wins,
      totalScore: 0,
    );

    otherPlayers = [
      currentPlayerDefault,
      Player(
        id: 'p1',
        username: 'Alice',
        wins: 2,
        totalScore: 15,
        avatar: "male_1",
      ),
      Player(
        id: 'p2',
        username: 'Bob',
        wins: 1,
        totalScore: 8,
        avatar: "female_2",
      ),
    ];
    room = room.copyWith(
      roomId: 'DEBUG-123',
      hostId: 'me',
      levels: l.keys.toList(),
      forbiddenWords: forbidden,
      isDrinkingMode: isDrinkingMode,
      isForbiddenWordMode: forbidden.isNotEmpty,
      playersToDrink: {},
      lang: 'en',
      status: RoomStatus.waiting,
    );
    for (final levelName in l.keys) {
      debugPrint('Creating level document for: $levelName');
      final lv = GameLevelsInitializationFactory.createLevel(
        levelName,
        isDrinkingMode: room.isDrinkingMode,
        levelRound: l[levelName] ?? 0,
      );
      await lv.initialization();
      levelsData[levelName] = lv;
    }

    if (forbidden.isNotEmpty) {
      for (final word in forbidden) {
        final lowerCasedWord = word.toLowerCase();
        WordEvent w = WordEvent(word: word);
        debugPrint('Initializing forbidden word document for: $lowerCasedWord');
        // Each forbidden word gets its own document under the 'forbidden_events' subcollection.
        // The document is initialized with an empty 'events' map.
        wor.add(w);
      }
    }
  }

  static void changeRoomSetting({
    String? roomId,
    String? hostId,
    bool? isDrinkingMode,
    RoomStatus? status,
    Map<String, String>? playersToDrink,
    List<String>? levels,
    bool? isForbiddenWordMode,
    List<String>? forbiddenWords,
    String? lang,
  }) {
    room = room.copyWith(
      roomId: roomId,
      hostId: hostId,
      status: status,
      playersToDrink: playersToDrink,
      levels: levels,
      forbiddenWords: forbiddenWords,
      isForbiddenWordMode: isForbiddenWordMode,
      isDrinkingMode: isDrinkingMode,
      lang: lang,
    );
  }

  static void changeCurrentPlayer({
    String? username,
    String? avatar,
    int? wins,
    int? totalScore,
  }) {
    currentPlayerDefault = currentPlayerDefault.copyWith(
      username: username,
      avatar: avatar,
      wins: wins,
      totalScore: totalScore,
    );
  }

  static void changePlayerData({
    required String id,
    String? username,
    String? avatar,
    int? wins,
    int? totalScore,
  }) {
    otherPlayers = otherPlayers.map((p) {
      if (p.id != id) return p;
      return p.copyWith(
        username: username ?? p.username,
        avatar: avatar ?? p.avatar,
        wins: wins ?? p.wins,
        totalScore: totalScore ?? p.totalScore,
      );
    }).toList();
  }
}

extension on Room {
  Room copyWith({
    String? roomId,
    String? hostId,
    bool? isDrinkingMode,
    RoomStatus? status,
    Map<String, String>? playersToDrink,
    List<String>? levels,
    bool? isForbiddenWordMode,
    List<String>? forbiddenWords,
    String? lang,
  }) {
    return Room(
      roomId: roomId ?? this.roomId,
      hostId: hostId ?? this.hostId,
      isDrinkingMode: isDrinkingMode ?? this.isDrinkingMode,
      status: status ?? this.status,
      playersToDrink: playersToDrink ?? this.playersToDrink,
      levels: levels ?? this.levels,
      isForbiddenWordMode: isForbiddenWordMode ?? this.isForbiddenWordMode,
      forbiddenWords: forbiddenWords ?? this.forbiddenWords,
      lang: lang ?? this.lang,
    );
  }
}

extension on Player {
  Player copyWith({
    String? username,
    String? avatar,
    int? wins,
    int? totalScore,
  }) {
    return Player(
      id: id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      wins: wins ?? this.wins,
      totalScore: totalScore ?? this.totalScore,
    );
  }
}
