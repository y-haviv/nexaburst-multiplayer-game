
// nexaburst/lib/models/structures/sync_model.dart

/// Synchronization payload shared among players each round,
/// tracking who’s ready, release flag, and current round index.
class SyncModel {
  /// Map of player IDs to readiness state (true if ready).
  final Map<String,bool> players;
  /// Indicates whether the round should be released to players.
  final bool releaseFlag;
  /// Zero‐based index of the current game round.
  final int round;

  /// Constructs a [SyncModel] with optional release flag and round number.
  SyncModel({
    required this.players,
    this.releaseFlag = false,
    this.round = 0,
  });

  /// Converts sync state to a map for network transmission or storage.
  Map<String, dynamic> toMap() {
    return {
      'players': players,
      'releaseFlag': releaseFlag,
      'round': round,
    };
  }

  /// Creates a [SyncModel] from a map, providing defaults for missing keys.
  factory SyncModel.fromMap(Map<String, dynamic> map) {
    return SyncModel(
      players: map['players'] ?? {},
      releaseFlag: map['releaseFlag'] ?? false, // Ensure ID is always set
      round: map['round'] ?? 0,
    );
  }
}
