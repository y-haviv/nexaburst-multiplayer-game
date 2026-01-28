// nexaburst/lib/models/structures/levels/level1/lv01_questions_loader.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:nexaburst/constants.dart';

/// Utility for loading and caching level‑1 trivia questions
/// from a JSON asset.
class Lv01QuestionsLoader {
  /// Reads 'assets/texts/lv01_questions.json', decodes it,
  /// and caches the list of question maps.
  static List<Map<String, dynamic>>? _cache;

  /// Reads 'assets/texts/lv01_questions.json', decodes it,
  /// and caches the list of question maps.
  static Future<void> load() async {
    if (_cache != null) return;
    final jsonStr = await rootBundle.loadString(TextPaths.lv01);
    final List<dynamic> raw = jsonDecode(jsonStr);
    // Each entry is already a Map<String,dynamic>
    _cache = raw.cast<Map<String, dynamic>>();
  }

  /// Returns the cached questions list, loading it if necessary.
  /// Emits a debugWarning if `load()` was not called first.
  static Future<List<Map<String, dynamic>>> get questions async {
    if (_cache == null) {
      await load();
      debugPrint('Lv01QuestionsLoader.load() not called yet');
    }
    return _cache!;
  }
}
