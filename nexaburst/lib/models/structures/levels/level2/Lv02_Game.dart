// nexaburst/lib/models/structures/levels/level2/Lv02_Game.dart

import 'dart:math';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/levels/level2/lv02_loader.dart';
import 'package:nexaburst/models/structures/levels/levels_factory.dart';
import 'package:tuple/tuple.dart';

/// Game model for Level 2 (“Wheel”):
/// generates random wheel positions, loads wheel options,
/// and tracks player choices and answers.
class Lv02Model implements GameModels {
  /// Number of slots on the wheel.
  final int numberOfWeel = 6;

  /// Maximum index for wheel slot generation.
  final int max = 3;

  /// Stores string results from each wheel spin.
  List<String> weel_result;

  /// Number of spins (rounds) in this session.
  final int rounds;

  /// IDs of spins that award double points.
  final List<String> doublePoints;

  /// Whether drinking‑mode rules apply (filters options).
  late bool isDrinking;

  /// Randomly selected wheel option IDs for this session.
  late List<int> options;

  /// Maps round index to generated {gold, black} slot positions.
  late Map<String, dynamic> positions;

  /// Current spin index (zero‑based).
  late int currentIndex;

  /// Player answer data collected per spin.
  final List<Map<String, dynamic>> answers;

  /// Creates a Level 2 model with optional prefilled state:
  /// - [isDrinking]: filter out “drinking” options
  /// - [rounds]: number of spins to prepare
  /// Other fields default to empty collections.
  Lv02Model({
    this.isDrinking = false,
    this.currentIndex = 0,
    Map<String, dynamic>? positions,
    this.answers = const [{}],
    this.options = const [],
    this.weel_result = const [],
    required this.rounds,
    this.doublePoints = const [],
  }) {
    this.positions = positions ?? {};
  }

  /// Asynchronously prepares:
  /// 1. Random gold/black positions for each round
  /// 2. Loads wheel data via [Lv02Loader]
  /// 3. Filters and shuffles IDs into [options].
  @override
  Future<void> initialization() async {
    currentIndex = 0;
    final random = Random();
    positions = {};

    for (int i = 0; i < rounds; i++) {
      int gold, black;

      do {
        gold = random.nextInt(max);
        black = random.nextInt(max);
      } while (gold == black);

      positions[i.toString()] = {"gold": gold, "black": black};
    }

    await Lv02Loader.load();
    final allEntries = await Lv02Loader.data;
    final allIds = allEntries
        .where((q) => isDrinking || !q['drinking'])
        .map((q) => q['ID'] as int)
        .toList();

    allIds.shuffle(random);
    options = allIds.take(numberOfWeel).toList();
  }

  /// Returns a localized result message for [optionId].
  /// - [currentPlayerName]: name to prefix
  /// - [otherPlayerName]: optional second player involved
  /// Falls back to an error translation if missing.
  static Future<String> getResultStringById(
    int optionId,
    String currentPlayerName, [
    String otherPlayerName = "",
  ]) async {
    final wheel = await Lv02Loader.data;
    final Map<String, dynamic> option = wheel.firstWhere(
      (item) => item["ID"] == optionId,
      orElse: () => {},
    );

    final lang = TranslationService.instance.currentLanguage;
    final localized =
        option[lang] as Map<String, dynamic>? ??
        option['en'] as Map<String, dynamic>;

    if (localized == {} || !localized.containsKey("resultText")) {
      return "$currentPlayerName ${TranslationService.instance.t('errors.game.lv02_unexpected')}";
    }

    final String resultText = localized["resultText"];

    if (otherPlayerName.isNotEmpty) {
      return "$currentPlayerName ${TranslationService.instance.t('game.levels.${TranslationService.instance.levelKeys[1]}.chosed')} $otherPlayerName $resultText.";
    }

    return "$currentPlayerName $resultText.";
  }

  /// Builds a list of tuples `(id, optionText, effectOtherFlag)`
  /// by looking up each [id] in the loaded wheel data.
  static Future<List<Tuple3<int, String, bool>>> getOptionsMapByIds(
    List<int> ids,
  ) async {
    final List<Tuple3<int, String, bool>> result = [];
    final wheel = await Lv02Loader.data;
    for (var id in ids) {
      final option = wheel.firstWhere(
        (element) => element["ID"] == id,
        orElse: () => {},
      );

      if (option.isEmpty) continue;

      final lang = TranslationService.instance.currentLanguage;
      final localized =
          option[lang] as Map<String, dynamic>? ??
          option['en'] as Map<String, dynamic>;

      final bool? effectOtherFlag = option["effectOther"] as bool?;

      if (localized.isEmpty || effectOtherFlag == null) continue;

      result.add(Tuple3(id, localized["option"] as String, effectOtherFlag));
    }
    return result;
  }

  /// Builds a list of tuples `(id, optionText, effectOtherFlag)`
  /// by looking up each [id] in the loaded wheel data.
  @override
  Map<String, dynamic> toJson() {
    return {
      'positions': positions,
      'currentIndex': currentIndex,
      'answers': answers.isEmpty ? [{}] : answers,
      'options': options,
      'weel_result': weel_result,
      'rounds': rounds,
      'doublePoints': doublePoints,
    };
  }

  /// Recreates a [Lv02Model] from JSON, applying defaults
  /// for any missing fields.
  factory Lv02Model.fromJson(Map<String, dynamic> json) {
    return Lv02Model(
      positions: Map<String, dynamic>.from(json['positions'] ?? {}),
      currentIndex: json['currentIndex'] ?? 0,
      answers: List<Map<String, dynamic>>.from(json['answers'] ?? [{}]),
      options: json['options'],
      weel_result: json['weel_result'],
      rounds: json['rounds'] ?? LevelsRounds.defaultlevelRounds,
      doublePoints: List<String>.from(json['doublePoints'] ?? []),
    );
  }
}
