// nexaburst/lib/models/structures/levels/level3/lv03_loader.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:nexaburst/constants.dart';

/// Loads and caches Level 3 question data from JSON asset.
class Lv03Loader {
  static List<Map<String, dynamic>>? _cache;

  /// Reads the JSON at [TextPath.lv03] and caches it for future use.
  static Future<void> load() async {
    if (_cache != null) return;
    final jsonStr = await rootBundle.loadString(TextPaths.lv03);
    final List<dynamic> raw = jsonDecode(jsonStr);
    // Each entry is already a Map<String,dynamic>
    _cache = raw.cast<Map<String, dynamic>>();
  }

  /// Returns the cached scenario data, loading it if necessary.
  static Future<List<Map<String, dynamic>>> get data async {
    if (_cache == null) {
      await load();
      debugPrint('lv03.load() not called yet');
    }
    return _cache!;
  }
}
