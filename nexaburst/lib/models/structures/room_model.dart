// nexaburst/lib/models/structures/room_model.dart

/// Possible lifecycle states of a multiplayer room, with server‐side
/// string representations.
enum RoomStatus {
  waiting('WATING'),
  playing('PlAYING'),
  over('OVER'),
  unknown('UNKNOWN');

  final String rawValue;

  /// Associates each enum value with its server‐expected string.
  const RoomStatus(this.rawValue);

  /// Parses a raw status string (case‐insensitive) into a [RoomStatus],
  /// defaulting to [RoomStatus.unknown] on no match.
  factory RoomStatus.fromString(String value) {
    return RoomStatus.values.firstWhere(
      (e) => e.rawValue.toLowerCase() == value.toLowerCase(),
      orElse: () => RoomStatus.unknown,
    );
  }

  /// Returns the string value to send to the backend.
  String toServerString() => rawValue;
}

/// Model for a game room’s settings, participants, and state.
class Room {
  /// Unique identifier of this room.
  final String roomId;

  /// Player ID of the room’s host.
  final String hostId;

  /// True if the “drinking” variant of the game is enabled.
  final bool isDrinkingMode;

  /// True if the forbidden‐word challenge mode is active.
  final bool isForbiddenWordMode;

  /// List of words disallowed in forbidden‐word mode.
  final List<String> forbiddenWords; // List of forbidden words
  /// Current lifecycle status of the room.
  final RoomStatus status;

  /// Map of player IDs to usernames who must take a drink.
  final Map<String, String> playersToDrink; // { playerId: username }
  /// Ordered list of level identifiers for this room’s game sequence.
  final List<String> levels;

  /// Language code used for room‐specific translations.
  final String lang;

  /// Constructs a [Room] with required identifiers, modes, levels,
  /// and optional defaults.
  Room({
    required this.roomId,
    required this.hostId,
    required this.isDrinkingMode,
    this.status = RoomStatus.waiting,
    this.playersToDrink = const {},
    this.isForbiddenWordMode = false,
    this.forbiddenWords = const [],
    required this.levels,
    this.lang = 'en',
  });

  /// Serializes this room for storing in Firestore, converting enum
  /// values and applying defaults.
  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'hostId': hostId,
      'isDrinkingMode': isDrinkingMode,
      'status': status.toServerString(),
      'isForbiddenWordMode': isForbiddenWordMode,
      'forbiddenWords': forbiddenWords,
      'players_to_drink': playersToDrink.isEmpty ? {} : playersToDrink,
      'Levels': levels,
      'lang': lang,
    };
  }

  /// Deserializes a Firestore map into a [Room], parsing status and
  /// ensuring correct collection types.
  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomId: json['roomId'] as String,
      hostId: json['hostId'] as String,
      isDrinkingMode: json['isDrinkingMode'] as bool,
      status: RoomStatus.fromString(json['status'] as String? ?? ''),
      playersToDrink: Map<String, String>.from(json['players_to_drink'] ?? {}),
      levels: List<String>.from(json['Levels']),
      isForbiddenWordMode: json['isForbiddenWordMode'] as bool? ?? false,
      forbiddenWords: List<String>.from(json['forbiddenWords'] ?? []),
      lang: json['lang'],
    );
  }
}
