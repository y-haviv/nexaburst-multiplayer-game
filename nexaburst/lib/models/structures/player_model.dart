// nexaburst/lib/models/structures/player_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a game participant’s public profile and stats.
class Player {
  /// Unique player identifier (e.g., Firebase user ID).
  final String id; // Unique identifier for the player (e.g., Firebase UID)
  /// Display name chosen by the player.
  final String username;

  /// Cumulative score of this player across all rounds.
  final int totalScore;

  /// URL or asset key for the player’s avatar image.
  final String avatar;

  /// Number of games this player has won.
  final int wins;

  /// Constructs a [Player] profile with optional default score and wins.
  Player({
    required this.id,
    required this.username,
    this.totalScore = 0,
    required this.avatar,
    this.wins = 0,
  });

  /// Converts this player to a Firestore map, updating ‘lastSeen’ to
  /// the current server timestamp.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'total_score': totalScore,
      'avatar': avatar,
      'wins': wins,
      'lastSeen': FieldValue.serverTimestamp(),
    };
  }

  /// Builds a [Player] from a Firestore map, reading core stats fields.
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      username: json['username'] as String,
      totalScore: json['total_score'] as int,
      avatar: json['avatar'] as String,
      wins: json['wins'] as int,
    );
  }
}
