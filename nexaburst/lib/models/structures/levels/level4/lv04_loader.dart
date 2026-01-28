// nexaburst/lib/models/structures/levels/level4/lv04_loader.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:nexaburst/constants.dart';

/// Loads and caches Level 4 social scenario data from JSON asset.
class Lv04Loader {
  static List<Map<String, dynamic>>? _cache;

  /// Reads the JSON at [TextPath.lv04] and caches it for future use.
  static Future<void> load() async {
    if (_cache != null) return;
    final jsonStr = await rootBundle.loadString(TextPaths.lv04);
    final List<dynamic> raw = jsonDecode(jsonStr);
    // Each entry is already a Map<String,dynamic>
    _cache = raw.cast<Map<String, dynamic>>();
  }

  /// Returns the cached social scenarios list, loading it if needed.
  static Future<List<Map<String, dynamic>>> get data async {
    if (_cache == null) {
      await load();
      debugPrint('lv04.load() not called yet');
    }
    return _cache!;
  }
}
