import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/models/data/server/presence/pesence_manager_interface.dart';

/// No-op debug implementation of [IPresenceManager].
class FakePresenceManager implements IPresenceManager {
  /// Creates a fake presence manager for local development flows.
  FakePresenceManager();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> disconnect() async {}

  @override
  void start() {}

  /// Completes disposal path used by production implementations.
  @override
  Future<void> dispose() async {
    debugPrint('[Presence] Disposed for player');
  }
}
