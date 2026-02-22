// nexaburst/lib/models/structures/levels/level2/lv02_loader.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:nexaburst/constants.dart';

/// Loads and caches Level 2 wheel configuration from JSON asset.
class Lv02Loader {
  static List<Map<String, dynamic>>? _cache;

  /// Reads the JSON at [TextPath.lv02] and caches it for future use.
  static Future<void> load() async {
    if (_cache != null) return;
    final jsonStr = await rootBundle.loadString(TextPaths.lv02);
    final List<dynamic> raw = jsonDecode(jsonStr);
    // Each entry is already a Map<String,dynamic>
    _cache = raw.cast<Map<String, dynamic>>();
  }

  /// Returns the cached wheel data, loading it if not already done.
  static Future<List<Map<String, dynamic>>> get data async {
    if (_cache == null) {
      await load();
      debugPrint('lv02.load() not called yet');
    }
    return _cache!;
  }
}
