// nexaburst/lib/model_view/room/game/forbiden_words/forbiden_words.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/debug/fake_models/fake_forbidden_words_detector.dart';
import 'package:nexaburst/models/data/server/modes/forbidden_words/forbidden_words_detector.dart';
import 'package:nexaburst/models/data/server/modes/forbidden_words/forbidden_words_detector_interface.dart';
import 'package:nexaburst/models/data/server/safe_call.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:nexaburst/models/structures/room_model.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:language_detector/language_detector.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
// Conditional import
import 'package:nexaburst/web/web_utils_stub.dart'
    if (dart.library.html) 'package:nexaburst/web/web_utils_web.dart'
    as html;

/// Singleton manager for forbidden‑words mode.
/// Orchestrates speech detection, server event listening, and UI event stream.
class ForbiddenWordsModManager {
  /// Private constructor for singleton pattern.
  ForbiddenWordsModManager._internal();

  /// Singleton instance reference.
  static final ForbiddenWordsModManager _instance =
      ForbiddenWordsModManager._internal();

  /// Returns the singleton `ForbiddenWordsModManager`.
  factory ForbiddenWordsModManager() => _instance;

  /// Tracks initialization state and holds the current room data.
  bool isInitialized = false;
  Room? room;

  /// Speech‑to‑text detector implementation (real or fake).
  IForbiddenWordsDetector? _detector;

  /// Controller and stream for server‑reported forbidden‑word events.
  StreamController<Map<String, dynamic>>? _forbiddenEventController;
  Stream<Map<String, dynamic>>? get forbiddenEventStream =>
      _forbiddenEventController?.stream;

  /// Subscription to local forbidden‑word detections.
  StreamSubscription<Map<String, dynamic>>? _detectorSub;

  /// Sets up the manager with [room] parameters.
  /// Must be called once before starting detection.
  void initialize({required Room room}) {
    if (isInitialized) return;
    // Initialize the ForbiddenWordsModManager with the provided parameters.
    debugPrint(
      'ForbiddenWordsModManager initialized with roomId: ${room.roomId}, playerId: ${UserData.instance.user!.id}, playerName: ${UserData.instance.user!.username}',
    );
    this.room = room;
    _forbiddenEventController =
        StreamController<Map<String, dynamic>>.broadcast();
    isInitialized = true;
  }

  /// Begins local speech detection and subscribes to server events.
  /// Requires `room.isForbiddenWordMode` and non‑empty forbidden list.
  Future<void> startForbidenWordsListener() async {
    if (!isInitialized ||
        room == null ||
        !room!.isForbiddenWordMode ||
        room!.forbiddenWords.isEmpty) {
      debugPrint('ForbiddenWordsModManager is not initialized.');
      ErrorService.instance.report(error: ErrorType.notInitialized);
      return;
    }

    // 1) Setup detector
    _detector = debug
        ? FakeForbiddenWordsDetector(room!)
        : ForbiddenWordsDetector(room: room!);

    if (kIsWeb && !debug) {
      final ok = await ensureMicPermissionWeb();
      if (!ok) {
        debugPrint(
          'Cannot start STT: microphone access denied or unavailable.',
        );
        return;
      }
    }

    final ok = await safeCall(
      () => _detector!.initialize(),
      fallbackValue: false,
    );
    if (!ok) {
      debugPrint('ForbiddenWordsModManager model problem initialized.');
      return;
    }
    _detector?.startDetection();

    _detector?.startListeningToForbiddenEvents();
    // Begin listening to the server for forbidden events.
    _startListeningToForbiddenEvents();
  }

  /// Internal method to pipe detector’s events into `_forbiddenEventController`.
  void _startListeningToForbiddenEvents() {
    if (!isInitialized || _detector == null) return;
    debugPrint(
      'ForbiddenWordsModManager starting to listen to forbidden events.',
    );
    // 2) Listen to server‐side forbidden events from the detector
    _detectorSub = _detector?.forbiddenEventStream.listen((event) {
      debugPrint("manager: detected word event: $event");
      _forbiddenEventController?.add(event);
    }, onError: (e) => debugPrint('FWMM detector stream error: $e'));
  }

  /// Stops speech detection, cancels subscriptions, and closes streams.
  Future<void> stopForbidenWords() async {
    if (!isInitialized || _detector == null) {
      debugPrint(
        'ForbiddenWordsModManager is not initialized or detector is null.',
      );
      return;
    }
    // 1) Stop speech detector
    await safeCall(() => _detector!.stopDetection());

    // 2) Cancel detector’s local stream
    await _detectorSub?.cancel();
    _detectorSub = null;

    // 4) Optional: reset detector if you want to recreate next time
    _detector = null;

    // 5) Close our broadcast controller (so listeners know we’re done)
    if (_forbiddenEventController != null) {
      await _forbiddenEventController?.close();
    }
  }

  // import 'dart:html' as html; // already present in your manager file

  Future<bool> ensureMicPermissionWeb() async {
    return html.ensureMicPermissionWebImpl();
  }

  /// Chooses a suitable locale for speech recognition based on [baseLang].
  /// On web, uses browser navigator; on mobile, queries device locales.
  ///
  /// Returns the selected locale ID or empty string if none match.
  static Future<String> pickSupportedLocale(String baseLang) async {
    final lowerBase = baseLang.toLowerCase();

    if (kIsWeb) {
      return await html.pickSupportedLocaleWebImpl(baseLang);
    }

    final speech = stt.SpeechToText();

    // 1. Initialize the speech engine.
    bool initialized = await speech.initialize(
      onError: (e) => debugPrint('STT init error: $e'),
      onStatus: (s) => debugPrint('STT status: $s'),
    );
    if (!initialized) {
      debugPrint('Speech initialize() failed');
      return "";
    }

    // 3. On mobile, query the true list of supported locales.
    final available = await speech.locales();
    final ids = available.map((l) => l.localeId).toList();
    debugPrint('▶ LOG: [mobile] available locales: $ids');

    // 4. Pick the first that matches your baseLang.
    for (var id in ids) {
      if (id.toLowerCase().startsWith(lowerBase)) {
        debugPrint('▶ LOG: picking locale $id');
        return id;
      }
    }

    debugPrint('▶ LOG: no matching mobile locale for $baseLang');
    return "";
  }

  /// Validates a list of forbidden words:
  /// - checks minimum length
  /// - ensures same detected language
  /// - confirms device support
  ///
  /// Returns an error message or empty string if valid.
  static Future<String> validate(List<String> words) async {
    if (words.isEmpty) return 'No words provided.';

    // 1. Length check
    for (final w in words) {
      if (w.length < 2) {
        return 'The word "$w" is too short.';
      }
    }

    // 3. Detect language of each word
    String? baseLang;
    for (final w in words) {
      try {
        final lang = await LanguageDetector.getLanguageCode(content: w);
        if (lang.isEmpty) {
          return 'Could not detect language for "$w".';
        } else {
          debugPrint('Detected language: $lang');
        }

        if (baseLang == null) {
          baseLang = lang;
        } else if (lang != baseLang) {
          return 'All words must be in the same language.';
        }
      } catch (e) {
        return 'Language detection failed for "$w".';
      }
    }

    // 4. Check device support
    String match = await pickSupportedLocale(baseLang!);
    if (match.isEmpty) {
      return 'Your device does not support this language.';
    }

    return '';
  }
}
