// nexaburst/lib/model_view/room/players_view_model/players_interface.dart

import 'dart:async';
import 'package:nexaburst/models/structures/player_model.dart';

/// Defines the interface for retrieving the list of players in a room.
abstract class Players {
  /// Prepares the players service for the given [roomId].
  Future<void> initialization({required String roomId});

  /// Returns a stream of `Player` lists for UI binding.
  Future<Stream<List<Player>>> players();

  /// Cleans up any subscriptions or controllers held by the players service.
  void dispose();
}
