

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/models/data/server/presence/pesence_manager_interface.dart';


class FakePresenceManager implements IPresenceManager {

  // Private constructor
  FakePresenceManager();

  @override
  Future<void> initialize() async {}


  @override
  Future<void> disconnect() async {}

  @override
  void start() {}


  /// Cancels listeners to prevent memory leaks.
  @override
  Future<void> dispose() async {
    debugPrint('[Presence] Disposed for player');
  }

}
