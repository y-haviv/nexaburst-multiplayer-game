

// lib/debug/debug_loading_overlay.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/room/game/manager_screens/loading_screen.dart';
import 'package:nexaburst/debug/helpers/command_registry.dart';
import 'package:nexaburst/main.dart';
import 'package:nexaburst/models/data/service/loading_controller.dart';

class DebugLoadingOverlay {
  static final DebugLoadingOverlay instance = DebugLoadingOverlay._();
  DebugLoadingOverlay._();

  OverlayEntry? _entry;
  bool _visible = false;
  bool _commandsRegistered = false;

  void init() {
    if (_commandsRegistered) return;
    _commandsRegistered = true;

    // Register console commands
    CommandRegistry.instance.register(
      'showLoading',
      'display the loading overlay (optionally supply message)',
      _onShow,
    );
    CommandRegistry.instance.register(
      'hideLoading',
      'hide the loading overlay',
      (_) => _hide(),
    );
  }

  Future<void> _onShow(String? arg) async {
    // Update the loading message if one was passed
    if (arg != null && arg.isNotEmpty) {
      LoadingService().show(arg);
    }
    _show();
  }

  void _show() {
  if (_visible) return;
  final nav = debugNavKey.currentState;
  if (nav == null) return;
  final overlay = nav.overlay;
  if (overlay == null) return;

  _entry = OverlayEntry(builder: (_) => const _LoadingOverlayWidget());

  // הכנס את הטעינה מתחת לקונסולה אם קיימת
  if (CommandRegistry.instance.consoleEntry != null) {
    overlay.insert(_entry!, below: CommandRegistry.instance.consoleEntry);
  } else {
    overlay.insert(_entry!);
  }

  _visible = true;
}



  void _hide() {
    if (!_visible) return;
    _entry?.remove();
    _entry = null;
    _visible = false;
    
  }

  void dispose() {
    if (_visible) _hide();
  }
}

/// Wraps your existing LoadingScreen into a full‐screen modal overlay.
class _LoadingOverlayWidget extends StatelessWidget {
  const _LoadingOverlayWidget();

  @override
  Widget build(BuildContext context) {
    // A full‐screen black translucent background:
    return Material(
      color: Colors.black54,
      child: Center(child: LoadingScreen()),
    );
  }
}
