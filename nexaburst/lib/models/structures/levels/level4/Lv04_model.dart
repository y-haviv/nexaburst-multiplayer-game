// nexaburst/lib/models/structures/levels/level4/lv04_model.dart

import 'dart:math';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/models/structures/levels/level4/lv04_loader.dart';
import 'package:nexaburst/models/structures/levels/levels_factory.dart';

/// Model for the “Stage 4 – Social” round.
/// In this stage one player (the target) answers a social scenario question,
/// and the other players guess which option the target picked.
/// There is no predetermined “correct” answer; the target’s choice is used to compare against the guesses.
class Lv04SocialModel implements GameModels {
  /// Selected scenario IDs for this session.
  late List<int> scenarios;

  /// Index of the current scenario in [scenarios].
  late int currentScenarioIndex;

  /// The choice made by the target player for the current scenario.
  String? targetAnswer;

  /// Maps each guessing player's ID to their selected option.
  Map<String, String> playersGuesses = {};

  /// Number of social scenarios to present.
  final int rounds;

  /// Constructs a social round model with initial index and [rounds].
  Lv04SocialModel({
    this.currentScenarioIndex = 0,
    this.scenarios = const [],
    required this.rounds,
  });

  /// Loads scenarios via [Lv04Loader], shuffles them,
  /// and resets selection state for a new session.
  @override
  Future<void> initialization() async {
    await Lv04Loader.load();
    // 1) make sure our JSON is loaded
    final allEntries = await Lv04Loader.data;
    final allIds = allEntries.map((q) => q['ID'] as int).toList();

    // Shuffle the list for randomness.
    allIds.shuffle(Random());
    // Take the required number of rounds.
    scenarios = allIds.take(rounds).toList();
    currentScenarioIndex = 0;
    targetAnswer = null;
    playersGuesses.clear();
  }

  /// Serializes scenarios, guesses, and target answer
  /// into a JSON map for persistence.
  @override
  Map<String, dynamic> toJson() {
    return {
      'scenarios': scenarios,
      'currentScenarioIndex': currentScenarioIndex,
      'playersGuesses': playersGuesses,
      'targetAnswer': targetAnswer ?? "",
      'rounds': rounds,
    };
  }

  /// Create an instance of [Lv04SocialModel] from JSON.
  factory Lv04SocialModel.fromJson(Map<String, dynamic> json) {
    final model = Lv04SocialModel(
      currentScenarioIndex: json['currentScenarioIndex'] as int? ?? 0,
      rounds: json['rounds'] as int? ?? LevelsRounds.defaultLevelRound(),
    );
    model.scenarios = (json['scenarios'] as List<dynamic>)
        .map((e) => e as int)
        .toList();
    model.playersGuesses = Map<String, String>.from(
      json['playersGuesses'] ?? {},
    );
    model.targetAnswer = json['targetAnswer'] as String?;
    return model;
  }
}
