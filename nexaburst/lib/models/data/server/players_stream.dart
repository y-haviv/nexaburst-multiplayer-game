// nexaburst/lib/models/server/players_stream.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexaburst/models/structures/player_model.dart';

/// Provides a real‑time stream of players in a given room,
/// sorted by descending score.
class PlayersModel {
  final CollectionReference _playersRef;

  /// Constructs with [roomId], setting up the Firestore reference
  /// to `/rooms/{roomId}/players`.
  PlayersModel(String roomId)
    : _playersRef = FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('players');

  /// Emits updated player lists whenever the Firestore collection changes.
  ///
  /// Maps each document to [Player], then sorts by `totalScore` descending.
  Stream<List<Player>> get playersStream => _playersRef.snapshots().map(
    (snap) =>
        snap.docs
            .map((d) => Player.fromJson(d.data()! as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.totalScore.compareTo(a.totalScore)),
  );
}
