// nexaburst/lib/models/server/modes/forbidden_words/forbidden_words_detector_interface.dart

import 'dart:async';

/// Defines the contract for local and server‐side forbidden‐words detection.
abstract class IForbiddenWordsDetector {
  /// Performs any asynchronous setup (e.g. speech engine initialization).
  ///
  /// Returns `true` if initialization succeeded, `false` otherwise.
  Future<bool> initialize();

  /// Begins local speech recognition to detect forbidden words in real time.
  void startDetection();

  /// Stops local detection and cleans up any listeners.
  Future<void> stopDetection();

  /// Subscribes to server‐side forbidden word events from Firestore.
  void startListeningToForbiddenEvents();

  /// Broadcast stream of forbidden‐word events with keys:
  /// `word`, `playerId`, `playerName`, and `timestamp`.
  Stream<Map<String, dynamic>> get forbiddenEventStream;
}
