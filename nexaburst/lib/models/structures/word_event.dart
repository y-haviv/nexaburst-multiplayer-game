// nexaburst/lib/models/structures/word_event.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single spoken‐word event in the game, including who said it
/// and when. Provides utilities for serialization and debouncing repeat words.
class WordEvent {
  /// The word the player just spoke or submitted.
  final String word;

  /// Unique identifier of the player who triggered this event.
  final String playerId;

  /// Display name of the player who triggered this event.
  final String playerName;

  /// Time when this event was recorded; defaults to server timestamp if unset.
  final dynamic timeStamp;

  /// Constructs a [WordEvent] for the given [word], optional [playerId],
  /// [playerName], and [timeStamp]. If [timeStamp] is null, uses
  /// Firestore server time.
  WordEvent({
    required this.word,
    this.playerId = '',
    this.playerName = '',
    dynamic timeStamp,
  }) : timeStamp = timeStamp ?? FieldValue.serverTimestamp();

  /// Returns true if at least 3 seconds have passed since [timeStamp],
  /// used to ignore rapid duplicate events.
  bool isDifferent() {
    final now = DateTime.now();
    if (now.difference(timeStamp).inSeconds < 3) {
      return false;
    }
    return true;
  }

  /// Converts this event to a Firestore‐compatible map for saving.
  /// Note: always uses a fresh server timestamp for the 'timestamp' key.
  Map<String, dynamic> toMap() {
    return {
      'playerName': playerName,
      'playerId': playerId,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  /// Creates a [WordEvent] from a Firestore map and the given [word].
  /// Safely parses the 'timestamp' field (supports [Timestamp] or [DateTime]).
  factory WordEvent.fromMap(Map<String, dynamic> map, String word) {
    final raw = map['timestamp'];
    final ts = raw is Timestamp
        ? raw.toDate()
        : raw is DateTime
        ? raw
        : DateTime.fromMillisecondsSinceEpoch(0);
    return WordEvent(
      word: word,
      playerName: map['playerName'] ?? "",
      playerId: map['playerId'] ?? "",
      timeStamp: ts,
    );
  }
}
