// Compiled on non-Web (desktop, mobile)
void logToConsole(String? message) {
  // No-op or use debugPrint
  if (message != null) {
    // fallback
    print(message);
  }
}

Future<bool> ensureMicPermissionWebImpl() async {
  // No-op, always true/false depending on your logic
  return true;
}

Future<String> pickSupportedLocaleWebImpl(String baseLang) async {
  // Stub fallback
  return '';
}
