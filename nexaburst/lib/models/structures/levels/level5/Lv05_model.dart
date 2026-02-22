// nexaburst/lib/models/structures/levels/level5/Lv05_model.dart

import 'package:nexaburst/constants.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/levels/levels_factory.dart';

/// Represents a single hole in the whack-a-mole game.
/// Each hole can be empty or occupied, and tracks interaction state.
class HoleModel {
  /// Unique identifier for the hole.
  final int id;

  /// Current state of the hole, such as `'empty'` or `'occupied'`.
  String state; // "empty" or "occupied"
  /// Indicates whether the hole is currently being whacked.
  bool whacking; // true while being whacked
  /// Whether the mole in this hole was successfully hit.
  final bool gotHit; // true if this hole was successfully hit
  /// Number of players who are currently synchronized with this hole's state.
  final int syncPlayers; // number of players synced on this hole

  HoleModel(this.id, this.state, this.whacking, this.gotHit, this.syncPlayers);

  /// Factory constructor that creates an empty hole with default values.
  ///
  /// [id] - The unique identifier of the hole.
  factory HoleModel.create(int id) {
    return HoleModel(id, 'empty', false, false, 0);
  }

  /// Converts the hole's state to a JSON map suitable for Firestore.
  ///
  /// Returns a `Map<String, dynamic>` representing the hole.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'state': state,
      'whacking': whacking,
      'gotHit': gotHit,
      'syncPlayers': syncPlayers,
    };
  }

  /// Creates a `HoleModel` from a Firestore document map.
  ///
  /// [docId] - The document ID representing the hole ID.
  /// [map] - The data map from Firestore.
  ///
  /// Returns a new `HoleModel` instance.
  factory HoleModel.fromMap(String docId, Map<String, dynamic> map) {
    return HoleModel(
      int.parse(docId),
      map['state'] as String? ?? 'empty',
      map['whacking'] as bool? ?? false,
      map['gotHit'] as bool? ?? false,
      map['syncPlayers'] as int? ?? 0,
    );
  }
}

/// Model representing the "Whack-a-Mole" game level (Level 5).
/// Manages the game logic, player data, and hole states.
class Lv05WhackMoleModel implements GameModels {
  /// Latest action message to display during live gameplay.
  String liveStreaming;

  /// List of player IDs currently acting as the mole.
  List<String> playersMoleIds;

  /// Corresponding player names for mole roles.
  List<String> playersMoleNames;

  /// Index of the current mole player in the list.
  int molePlayerIndex;

  /// Total number of holes currently occupied by a mole.
  int sumOccupiedHoles;

  /// Total number of holes currently occupied by a mole.
  List<HoleModel> holes;

  /// Indicates whether the level has finished.
  bool endLevel;

  /// Map of player IDs to their current scores.
  Map<String, int> playerScores;

  /// Points awarded when the mole successfully hides.
  static final int scoreIncrementMole = 2;

  /// Points awarded to a player who successfully hits the mole.
  static final int scoreIncrementHit = 1;

  /// Time limit (in seconds) for each mole appearance round.
  static final int timePerMole = 10;

  /// Message displayed when the mole successfully survives.
  static final String moleSecsess =
      "${TranslationService.instance.t('game.levels.level5.mole_live')}: $scoreIncrementMole";

  /// Message displayed when a player successfully hits the mole.
  static final String hitSecsess =
      "${TranslationService.instance.t('game.levels.level5.player_live')}: $scoreIncrementHit";

  /// Total number of rounds in this level.
  final int rounds;

  /// Number of holes to generate at the start of the game.
  final int numberOfHoles;

  /// Constructs a `Lv05WhackMoleModel` with optional custom values and default fallbacks.
  ///
  /// [rounds] must be provided to indicate the total number of rounds.
  Lv05WhackMoleModel({
    this.liveStreaming = '',
    this.playersMoleIds = const [],
    this.playersMoleNames = const [],
    this.molePlayerIndex = 0,
    this.sumOccupiedHoles = 0,
    List<HoleModel>? holes,
    this.numberOfHoles = 10,
    this.endLevel = false,
    this.playerScores = const {},
    required this.rounds,
  }) : holes = holes ?? [];

  /// Initializes the game state by creating a list of empty holes and resetting round data.
  @override
  Future<void> initialization() async {
    holes = List.generate(numberOfHoles, (i) => HoleModel.create(i));
    sumOccupiedHoles = 0;
    molePlayerIndex = 0;
    liveStreaming = '';
  }

  /// Converts the current game state into a JSON map for storage.
  ///
  /// Returns a `Map<String, dynamic>` containing the top-level level data.
  @override
  Map<String, dynamic> toJson() {
    return {
      'playersMoleIds': playersMoleIds,
      'playersMoleNames': playersMoleNames,
      'molePlayerIndex': molePlayerIndex,
      'sumOccupiedHoles': sumOccupiedHoles,
      'liveStreaming': liveStreaming,
      'endLevel': endLevel,
      'rounds': rounds,
    };
  }

  /// Constructs a `Lv05WhackMoleModel` from a JSON map (e.g., from Firestore).
  ///
  /// [json] - The source map containing level state.
  ///
  /// Returns a new instance of the model.
  factory Lv05WhackMoleModel.fromJson(Map<String, dynamic> json) {
    return Lv05WhackMoleModel(
      liveStreaming: json['liveStreaming'] as String? ?? '',
      playersMoleIds: (json['playersMoleIds'] as List).cast<String>(),
      playersMoleNames: (json['playersMoleNames'] as List).cast<String>(),
      playerScores: Map<String, int>.from(json['playerScores'] as Map? ?? {}),
      molePlayerIndex: json['molePlayerIndex'] as int? ?? 0,
      sumOccupiedHoles: json['sumOccupiedHoles'] as int? ?? 0,
      endLevel: json['endLevel'] as bool? ?? false,
      rounds: json['rounds'] as int? ?? LevelsRounds.defaultLevelRound(),
    );
  }

  /// Generates a live gameplay message string based on the player's action.
  ///
  /// [isMole] - Whether the player is currently the mole.
  /// [playerName] - The name of the player involved.
  ///
  /// Returns a localized message for display.
  static String updateLive(bool isMole, String playerName) {
    return "${TranslationService.instance.t('game.common.player')}: $playerName ${(isMole ? moleSecsess : hitSecsess)}";
  }
}
