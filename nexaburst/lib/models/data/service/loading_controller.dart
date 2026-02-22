// nexaburst/lib/models/service/loading_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';

/// Singleton service broadcasting loading status messages via a stream.
class LoadingService {
  /// Private constructor for singleton pattern.
  LoadingService._internal();
  static final LoadingService _instance = LoadingService._internal();

  /// Returns the shared [LoadingService] instance.
  factory LoadingService() => _instance;

  /// Broadcasts loading messages (or `null` to clear) to listeners.
  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();

  /// Tracks whether the stream controller has been closed.
  bool _isClosed = false;

  /// Last message sent, used to suppress duplicates.
  String? _currentMessage; // 🆕 Keep track of the last message

  /// Stream of loading messages; emits `null` to indicate no message.
  Stream<String?> get messageStream => _controller.stream;

  /// Broadcasts [message] if different from the last one.
  ///
  /// If the stream is closed, logs a warning and does nothing.
  void show(String message) {
    if (_isClosed) {
      debugPrint('⚠️ Tried to show loading message after stream was closed.');
      return;
    }

    if (_currentMessage != message) {
      _currentMessage = message;
      _controller.add(message);
    } else {
      debugPrint('ℹ️ Same message, not re-sending.');
    }
  }

  /// Clears the current loading message by emitting `null`.
  ///
  /// If the stream is closed, logs a warning.
  void clear() {
    if (_isClosed) {
      debugPrint('⚠️ Tried to clear loading message after stream was closed.');
      return;
    }
    if (_currentMessage != null) {
      _currentMessage = null;
      _controller.add(null);
    }
  }

  /// Closes the stream controller if not already closed.
  ///
  /// Subsequent calls to `show` or `clear` will be ignored.
  void dispose() {
    if (!_isClosed) {
      _controller.close();
      _isClosed = true;
      debugPrint('✅ LoadingService stream closed.');
    }
  }

  /// Returns `true` if the service’s stream has been closed.
  bool get isClosed => _isClosed;
}
