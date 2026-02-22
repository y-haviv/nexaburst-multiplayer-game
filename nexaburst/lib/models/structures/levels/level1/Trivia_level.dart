// nexaburst/lib/models/structures/levels/level1/Trivia_level.dart

import 'dart:math';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/models/structures/levels/level1/lv01_questions_loader.dart';
import 'package:nexaburst/models/structures/levels/levels_factory.dart';

/// Implements the trivia‐question level:
/// selects random question IDs, records answers, and tracks progress.
class TriviaLevel implements GameModels {
  /// IDs of the questions selected for the current session.
  late List<int> questions;

  /// Player answer data: either question payloads or map of player times.
  final List<Map<String, dynamic>> answers;

  /// Zero‑based index of the next question to present.
  late int currentQuestionIndex;

  /// Tracks which player submitted each answer before a drink penalty.
  Map<String, String> player_before_drink;

  /// Total number of questions to ask this session.
  final int rounds;

  /// Constructs an instance with optional prefilled state
  /// and the required number of [rounds].
  TriviaLevel({
    this.currentQuestionIndex = 0,
    this.questions = const [],
    this.answers = const [{}],
    this.player_before_drink = const {},
    required this.rounds,
  });

  /// Loads all questions via [Lv01QuestionsLoader],
  /// shuffles their IDs, and picks [rounds] of them.
  @override
  Future<void> initialization() async {
    await Lv01QuestionsLoader.load();

    // 1) make sure our JSON is loaded
    final allEntries = await Lv01QuestionsLoader.questions;
    final allIds = allEntries.map((q) => q['ID'] as int).toList();

    // 2) shuffle & select `rounds` of them
    allIds.shuffle(Random());
    questions = allIds.take(rounds).toList();
    currentQuestionIndex = 0;
  }

  /// Serializes the current state—questions, answers, index, and rounds—
  /// into a JSON map for persistence.
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

  /// Reconstructs a [TriviaLevel] from JSON, parsing:
  /// - `questions`: list of IDs
  /// - `answers`: either a list of maps or a map of player times
  /// - `player_before_drink`, `currentQuestionIndex`, and `rounds`
  factory TriviaLevel.fromJson(Map<String, dynamic> json) {
    // QUESTIONS: might be a JSArray or Dart List
    final rawQuestions = json['questions'];
    final questions = <int>[];
    if (rawQuestions is Iterable) {
      questions.addAll(rawQuestions.map((e) => e as int));
    }

    // ANSWERS: could be a List<Map> (your asset JSON) or a Map (Firestore answers)
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

    return TriviaLevel(
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
