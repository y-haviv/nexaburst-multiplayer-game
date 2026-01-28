import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/main.dart';

typedef CommandHandler = FutureOr<void> Function(String? arg);

class CommandRegistry {
  CommandRegistry._();
  static final CommandRegistry instance = CommandRegistry._();

  final Map<String, String> _instructions = {};
  final Map<String, CommandHandler> _handlers = {};
  StreamSubscription<String>? _stdinSub;

  OverlayEntry? _consoleEntry;
  bool _isBusy = false;

  // ─── Public API ────────────────────────────────────────────────────

  /// Register a command with its one-line instruction.
  void register(String name, String instruction, CommandHandler handler) {
    _handlers[name] = handler;
    _instructions[name] = instruction;
    _debugPrintMenu();
  }

  /// Unregister a command.
  void unregister(String name) {
    _handlers.remove(name);
    _instructions.remove(name);
    _debugPrintMenu();
  }

  /// Start both input sources:
  /// - stdin on non-web
  /// - on-screen console on web (and anywhere else)
  void start() {
    _startStdin();
    ensureConsoleOverlay();
    _debugPrintMenu();
  }

  /// Stop everything and clear all commands.
  Future<void> dispose() async {
    await _stdinSub?.cancel();
    _stdinSub = null;
    _hideConsole();
    _handlers.clear();
    _instructions.clear();
  }

  // ─── Internal implementation ────────────────────────────────────────

  void _startStdin() {
    if (kIsWeb) return;
    if (_stdinSub != null) return;
    _stdinSub = stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_dispatch);
  }

  void _dispatch(String line) async {
    if (_isBusy) {
      debugPrint('⏳ Busy – ignoring input: $line');
      return;
    }

    _isBusy = true;
    try {
      final parts = line.trim().split(' ');
      final name = parts.first;
      final arg = parts.length > 1 ? parts.sublist(1).join(' ') : null;
      final h = _handlers[name];
      if (h != null) {
        await h(arg); // תומך בפונקציות אסינכרוניות
      } else {
        debugPrint('⚠️ Unknown command: $name');
      }
    } catch (e, s) {
      debugPrint('❌ Error during command: $e\n$s');
    } finally {
      _isBusy = false;
    }
  }

  void _debugPrintMenu() {
    debugPrint('\n=== DEBUG COMMANDS ===');
    _instructions.forEach((cmd, instr) {
      debugPrint('- $cmd : $instr');
    });
    debugPrint('======================\n');
  }

  // ─── On-screen console (for Web & desktop) ─────────────────────────

  void ensureConsoleOverlay() {
    if (_consoleEntry != null) return;

    final key = GlobalKey<_DebugConsoleState>();
    _consoleEntry = OverlayEntry(
      builder: (_) => DebugConsole(key: key, registry: this),
    );

    void tryInsert() {
      final navState = debugNavKey.currentState;
      if (navState != null && navState.overlay != null) {
        navState.overlay!.insert(_consoleEntry!);
        debugPrint('✅ Debug console inserted');
      } else {
        // עדיין לא קיים – ננסה שוב אחרי frame הבא
        WidgetsBinding.instance.addPostFrameCallback((_) => tryInsert());
      }
    }

    tryInsert();
  }

  OverlayEntry? get consoleEntry => _consoleEntry;

  void _hideConsole() {
    _consoleEntry?.remove();
    _consoleEntry = null;
  }

  /// Called by the on-screen console when user submits a line.
  void dispatchFromConsole(String line) => _dispatch(line);
}

// ─── DebugConsole Widget ─────────────────────────────────────────────

class DebugConsole extends StatefulWidget {
  final CommandRegistry registry;
  const DebugConsole({super.key, required this.registry});
  @override
  _DebugConsoleState createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final _controller = TextEditingController();
  bool _visible = false;

  void _toggle() => setState(() => _visible = !_visible);

  @override
  Widget build(BuildContext context) {
    final isBusy = CommandRegistry.instance._isBusy;

    return Positioned(
      top: 10,
      right: 10,
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Icon(Icons.bug_report, color: Colors.redAccent),
          ),
          if (_visible)
            Material(
              color: const Color.fromARGB(100, 0, 0, 0),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 300,
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        enabled: !isBusy, // <-- כאן!
                        controller: _controller,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: isBusy ? '⏳ Processing...' : 'cmd args…',
                          hintStyle: TextStyle(
                            color: const Color.fromARGB(150, 0, 0, 0),
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (cmd) {
                          widget.registry.dispatchFromConsole(cmd);
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: _toggle,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
