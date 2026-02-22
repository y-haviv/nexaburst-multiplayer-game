// nexaburst/lib/models/structures/errors/app_error.dart

import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// Categorizes error scenarios with associated translation keys
/// for user‑facing messages.
enum ErrorType {
  onePlayerLeft('only_one_player_remaining'),
  playerDisconnected('net_error'),
  network('net_error'), // e.g. no internet / socket exceptions
  timeout('device_error_removed'), // e.g. our own timeout or “too long”
  firestore(
    'device_error_removed',
  ), // any Firestore‐specific problem (permission, missing doc, etc.)
  parse('device_error_removed'), // data came back in an unexpected format
  unknown('device_error_removed'), // any other unexpected exception
  notFound(
    'device_error_removed',
  ), // “document not found” vs. “collection missing”
  notInitialized(
    'device_error_removed',
  ), // used when the ErrorService is not initialized
  localDatabase(
    'device_error_removed',
  ), // used when there is an issue with local database operations
  invalidInput(
    'device_error_removed',
  ); // used when there is an issue with user input

  final String rawValue;

  /// Associates each [ErrorType] case with its raw translation key.
  const ErrorType(this.rawValue);

  /// Parses a raw key string (case‑insensitive) into an [ErrorType],
  /// defaulting to [ErrorType.unknown] if unrecognized.
  factory ErrorType.fromString(String value) {
    return ErrorType.values.firstWhere(
      (e) => e.rawValue.toLowerCase() == value.toLowerCase(),
      orElse: () => ErrorType.unknown,
    );
  }

  /// Returns the localized error message by translating
  /// 'errors.game.$rawValue' via [TranslationService].
  @override
  String toString() => TranslationService.instance.t('errors.game.$rawValue');
}
