// nexaburst/lib/models/structures/levels/level6/Lv06_trust_model.dart

import 'package:nexaburst/constants.dart';
import 'package:nexaburst/models/structures/levels/levels_factory.dart';

/// Model for the "Trust Round" game level (Level 6).
/// Players make strategic decisions to steal or stay and try to guess others' choices.
class Lv06TrustModel implements GameModels {
  /// Maps each player ID to their choice (true = stole, false = kept).
  late Map<String, bool> playerChoices; // playerId -> stole or not
  /// Maps each player ID to their guess of how many players will steal.
  late Map<String, int> playerGuesses; // playerId -> guess (optional)

  /// Tracks how many times each player correctly guessed the number of thieves.
  Map<String, int> correctGuessCount =
      {}; // playerId -> number of correct guesses
  /// Total points accumulated during rounds where all players chose to stay.
  int accumulatedPoints =
      0; // total points collected from 'everyone left' rounds

  /// The current round number (starting at 0).
  late int currentRound;

  /// Total number of rounds in the level.
  final int rounds; // Total number of rounds

  /// Constructs a new `Lv06TrustModel` with optional initial state values.
  ///
  /// [rounds] must be provided to indicate the number of rounds.
  Lv06TrustModel({
    this.currentRound = 0,
    this.playerChoices = const {},
    this.playerGuesses = const {},
    this.correctGuessCount = const {},
    required this.rounds,
  });

  /// Resets level-specific values, such as the accumulated points.
  @override
  Future<void> initialization() async {
    accumulatedPoints = 0;
  }

  /// Converts the current state of the level into a JSON map.
  ///
  /// Returns a `Map<String, dynamic>` representing the trust round state.
  @override
  Map<String, dynamic> toJson() => {
    'correctGuessCount': correctGuessCount,
    'accumulatedPoints': accumulatedPoints,
    'playerChoices': playerChoices,
    'playerGuesses': playerGuesses,
    'currentRound': currentRound,
    'rounds': rounds,
  };

  /// Constructs a `Lv06TrustModel` from a JSON map (e.g., Firestore).
  ///
  /// [json] - The source map containing the saved game state.
  ///
  /// Returns a new instance of the model.
  factory Lv06TrustModel.fromJson(Map<String, dynamic> json) {
    final model = Lv06TrustModel(
      rounds: json['rounds'] as int? ?? LevelsRounds.defaultLevelRound(),
    );
    model.correctGuessCount = Map<String, int>.from(
      json['correctGuessCount'] ?? {},
    );
    model.accumulatedPoints = json['accumulatedPoints'] ?? 0;
    model.playerChoices = Map<String, bool>.from(json['playerChoices'] ?? {});
    model.playerGuesses = Map<String, int>.from(json['playerGuesses'] ?? {});
    model.currentRound = json['currentRound'] ?? 0;
    return model;
  }
}
