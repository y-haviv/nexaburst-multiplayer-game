// nexaburst/lib/models/service/translation_controllers.dart

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nexaburst/constants.dart';

/// Singleton for loading and serving localized strings.
///
/// Manages current language, notifies listeners on changes.
class TranslationService extends ChangeNotifier {
  /// Private constructor for singleton instantiation.
  TranslationService._internal();

  /// Shared global instance.
  static final TranslationService instance = TranslationService._internal();

  /// Ordered list of level identifiers from the 'en' translations.
  late final List<String> levelKeys;

  /// Nested map containing all translation data keyed by language code.
  late final Map<String, dynamic> _translations;

  /// Currently selected language code.
  String _currentLang = 'en';

  /// Locale objects for each supported language.
  List<Locale> get supportedLocales =>
      _translations.keys.map((lang) => Locale(lang)).toList();

  /// Returns the active language code.
  String get currentLanguage => _currentLang;

  /// Loads translation JSON from assets and initializes [_translations] and [levelKeys].
  Future<void> loadTranslations() async {
    final data = await rootBundle.loadString(TextPaths.texts);
    _translations = jsonDecode(data) as Map<String, dynamic>;
    levelKeys = (_translations['en']['game']['levels'] as Map<String, dynamic>)
        .keys
        .toList();
  }

  /// Sets the current language to [langCode] if available, then notifies listeners.
  void setLanguage(String langCode) {
    if (_translations.containsKey(langCode)) {
      _currentLang = langCode;
      notifyListeners();
    }
  }

  /// Retrieves the localized string for [key] in the current language.
  ///
  /// Falls back to English if missing.
  /// Supports parameter substitution via `{param}` in the string.
  ///
  /// Returns the translated text or `key` if not found.
  String t(String key, {Map<String, String>? params}) {
    dynamic value = _lookup(_currentLang, key) ?? _lookup('en', key);
    if (value == null || value is! String) return key;

    if (params != null) {
      params.forEach((k, v) {
        value = value.replaceAll('{$k}', v);
      });
    }

    return value;
  }

  /// Internal helper to navigate the nested [_translations] map
  /// for [lang] and dot‑separated [key].
  dynamic _lookup(String lang, String key) {
    final parts = key.split('.');
    dynamic node = _translations[lang];
    for (final p in parts) {
      if (node is! Map<String, dynamic> || !node.containsKey(p)) return null;
      node = node[p];
    }
    return node;
  }
}
