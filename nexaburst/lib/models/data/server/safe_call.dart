// nexaburst/lib/models/server/safe_call.dart

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';

/// Executes [action] within comprehensive error handling.
///
/// On specific failures, reports via [ErrorService] and:
///  - returns [fallbackValue] if provided, otherwise rethrows.
///
/// Handles [FirebaseException], [SocketException], [TimeoutException],
/// [FormatException], and generic errors.
///
/// Returns the result of [action] on success or [fallbackValue] on handled failures.
Future<T> safeCall<T>(
  /// Asynchronous operation to execute safely.
  Future<T> Function() action, {

  /// Value to return instead of propagating errors.
  T? fallbackValue,
}) async {
  try {
    return await action();
  } on FirebaseException catch (e) {
    // Determine if it's a "not found" error, otherwise treat as general Firestore error
    final type = (e.code == 'not-found')
        ? ErrorType.notFound
        : ErrorType.firestore;

    ErrorService.instance.report(error: type);
    if (fallbackValue != null) return fallbackValue;
    rethrow;
  } on SocketException {
    ErrorService.instance.report(error: ErrorType.network);
    if (fallbackValue != null) return fallbackValue;
    rethrow;
  } on TimeoutException {
    ErrorService.instance.report(error: ErrorType.timeout);
    if (fallbackValue != null) return fallbackValue;
    rethrow;
  } on FormatException {
    ErrorService.instance.report(error: ErrorType.parse);
    if (fallbackValue != null) return fallbackValue;
    rethrow;
  } catch (_) {
    ErrorService.instance.report(error: ErrorType.unknown);
    if (fallbackValue != null) return fallbackValue;
    rethrow;
  }
}
