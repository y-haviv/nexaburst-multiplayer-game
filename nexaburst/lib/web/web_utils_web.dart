// Only compiled on Web
import 'dart:html' as html;

void logToConsole(String? message) {
  html.window.console.log(message);
}

Future<bool> ensureMicPermissionWebImpl() async {
  try {
    final md = html.window.navigator.mediaDevices;
    if (md == null) {
      return false;
    }
    await md.getUserMedia({'audio': true});
    return true;
  } catch (_) {
    return false;
  }
}

Future<String> pickSupportedLocaleWebImpl(String baseLang) async {
  final lowerBase = baseLang.toLowerCase();
  final langs = (html.window.navigator.languages as List)
      .cast<String>()
      .map((s) => s.toLowerCase())
      .toList();

  for (var lang in langs) {
    if (lang.startsWith(lowerBase)) return lang;
  }
  return html.window.navigator.language ?? '';
}
