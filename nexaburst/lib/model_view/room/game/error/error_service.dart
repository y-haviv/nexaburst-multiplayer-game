// nexaburst/lib/model_view/room/game/error/error_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';

/// Singleton service that broadcasts application errors.
/// Models call `ErrorService.instance.report(...)` and the UI listens
/// via `errors()` to display alerts or snackbars.
class ErrorService {
  /// Private constructor for the singleton pattern.
  ErrorService._internal();
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;

  /// Provides the singleton instance of `ErrorService`.
  static ErrorService get instance => _instance;

  late StreamController<ErrorType> _controller;
  bool _initialized = false;

  /// Initializes the internal error stream controller.
  /// Safe to call multiple times; only creates once.
  void init() {
    // Any initialization logic can go here if needed.
    if (!_initialized) {
      _controller = StreamController<ErrorType>.broadcast();
      _initialized = true;
    }
  }

  /// Returns a broadcast stream of reported `ErrorType` events.
  /// If not yet initialized, calls `init()` automatically.
  Stream<ErrorType> errors() {
    if (!_initialized) {
      debugPrint('ErrorService not initialized. Call init() first.');
      init();
    }
    return _controller.stream;
  }

  /// Reports a new error of the given `error` type.
  /// Adds it to the internal stream for UI consumption.
  void report({required ErrorType error}) {
    if (!_initialized) return;
    // (Optionally) log it, send it to Crashlytics, etc.:
    // debugPrint('Reporting error: $error');
    _controller.add(error);
  }

  /// Closes the error stream and resets initialization state.
  void dispose() {
    if (!_initialized) return;
    _initialized = false;
    _controller.close();
  }
}
