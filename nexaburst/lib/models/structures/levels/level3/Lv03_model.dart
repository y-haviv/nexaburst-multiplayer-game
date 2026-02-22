// nexaburst/lib/models/structures/levels/level3/Lv03_model.dart

import 'dart:math';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/models/structures/levels/level3/lv03_loader.dart';
import 'package:nexaburst/models/structures/levels/levels_factory.dart';

/// Game model for Level 3: selects random questions,
/// tracks answers and progress across [rounds].
class Lv03Model implements GameModels {
  /// IDs of questions chosen for this session.
  late List<int> questions;

  /// Collected answer data from players.
  final List<Map<String, dynamic>> answers;

  /// Index of the next question to present.
  late int currentQuestionIndex;

  /// Tracks which players answered before a drink penalty.
  Map<String, String> player_before_drink = {};

  /// Number of questions to ask this session.
  final int rounds;

  /// Constructs a Level 3 model with optional initial state
  /// and required [rounds].
  Lv03Model({
    this.currentQuestionIndex = 0,
    this.questions = const [],
    this.answers = const [{}],
    this.player_before_drink = const {},
    required this.rounds,
  });

  /// Loads all questions via [Lv03Loader], shuffles them,
  /// and selects [rounds] of them.
  @override
  Future<void> initialization() async {
    await Lv03Loader.load();

    final allEntries = await Lv03Loader.data;
    final allIds = allEntries.map((q) => q['ID'] as int).toList();

    allIds.shuffle(Random());
    questions = allIds.take(rounds).toList();
    currentQuestionIndex = 0;
  }

  /// Serializes current questions, answers, and progress
  /// into a JSON map.
  @override
  Map<String, dynamic> toJson() {
    return {
      'questions': questions,
      'answers': answers.isEmpty ? [] : answers,
      'player_before_drink': player_before_drink.isEmpty
          ? {}
          : player_before_drink,
      'currentQuestionIndex': currentQuestionIndex,
      'rounds': rounds,
    };
  }

  /// Reconstructs a [Lv03Model] from JSON, parsing:
  /// - `questions`, `answers` (list or map form)
  /// - `player_before_drink`, `currentQuestionIndex`, `rounds`
  factory Lv03Model.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    final questions = <int>[];
    if (rawQuestions is Iterable) {
      questions.addAll(rawQuestions.map((e) => e as int));
    }

    final rawAnswers = json['answers'];
    final answers = <Map<String, dynamic>>[];
    if (rawAnswers is Iterable) {
      // e.g. [{"text":"foo","id":0},…]
      answers.addAll(
        rawAnswers.map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } else if (rawAnswers is Map<String, dynamic>) {
      // e.g. {"player1":3.2,"player2":-1,…}
      // convert each entry into a small map
      rawAnswers.forEach((key, value) {
        answers.add({'playerId': key, 'time': (value as num).toDouble()});
      });
    }

    final rounds = json['rounds'] as int? ?? LevelsRounds.defaultLevelRound();

    return Lv03Model(
      questions: questions,
      answers: answers,
      player_before_drink: Map<String, String>.from(
        json['player_before_drink'] ?? {},
      ),
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      rounds: rounds,
    );
  }
}
