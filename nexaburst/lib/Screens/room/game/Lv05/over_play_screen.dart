// nexaburst/lib/screens/room/game/Lv05/over_play_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexaburst/models/data/server/levels/level5/lv05.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:tuple/tuple.dart';

/// Wraps the Whack‑A‑Mole gameplay with:
/// 1. Live message feed (up to 3 recent messages)
/// 2. Main game [screen]
/// 3. Horizontal mole‑order list highlighting the current mole
class Lv05WhackAMoleScreenWrapper extends StatefulWidget {
  /// Controller providing live feed and mole order streams.
  final Lv05 controller;

  /// The current sub‑screen widget (gameplay, switch, or drink).
  final Widget screen;

  /// Creates a wrapper around the gameplay [screen] using [controller].
  const Lv05WhackAMoleScreenWrapper({
    super.key,
    required this.controller,
    required this.screen,
  });

  /// Creates mutable state for [Lv05WhackAMoleScreenWrapper].
  @override
  _Lv05WhackAMoleScreenWrapperState createState() =>
      _Lv05WhackAMoleScreenWrapperState();
}

/// State class that subscribes to the controller’s live text feed,
/// maintains recent messages, and renders the full layout.
class _Lv05WhackAMoleScreenWrapperState
    extends State<Lv05WhackAMoleScreenWrapper> {
  final List<String> _recentMessages = [];
  StreamSubscription<String>? _liveSub;

  /// Initializes subscription to `liveStreamingText` for incoming messages.
  @override
  void initState() {
    super.initState();
    _liveSub = widget.controller.liveStreamingText.listen(
      (msg) {
        final text = msg.trim();
        if (text.isEmpty) return;
        debugPrint('📥 Live message received: "$text"');

        setState(() {
          _recentMessages.insert(0, text);
          if (_recentMessages.length > 3) _recentMessages.removeLast();
        });
      },
      onError: (err) {
        debugPrint('❌ Live‐stream error: $err');
      },
    );
  }

  /// Cancels the live‑feed subscription when disposing.
  @override
  void dispose() {
    _liveSub?.cancel();
    super.dispose();
  }

  /// Builds the three vertical sections:
  /// - Live feed panel
  /// - Expanded [screen]
  /// - Horizontal mole‑order list with title
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        double sectionHieght = height * 0.12;

        double topH = sectionHieght.clamp(80.0, 200.0);
        double bottomH = sectionHieght.clamp(80.0, 180.0);
        if (topH + bottomH >= height * 0.8) {
          const minBottomContents = 16 /*padding*/ + 14 /*text*/ + 4 /*spacer*/;
          bottomH = (height * 0.3 < minBottomContents)
              ? minBottomContents.toDouble()
              : (height * 0.3);
          topH = (height - bottomH) * 0.4;
        }

        return SafeArea(
          child: Column(
            children: [
              // ── 1) Live feed ──
              Container(
                height: topH,
                width: double.infinity,
                color: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: _recentMessages.isEmpty
                    ? Center(
                        child: Text(
                          TranslationService.instance.t(
                            'screens.common.loading',
                          ),
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        shrinkWrap: true,
                        physics: BouncingScrollPhysics(),
                        itemCount: _recentMessages.length,
                        itemBuilder: (context, index) {
                          final text = _recentMessages[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
              ),

              // ── 2) Game screen ──
              Expanded(child: widget.screen),

              // ── 3) Player list with title ──
              Container(
                height: bottomH,
                width: double.infinity,
                color: Colors.black.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title above the player-order list
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${TranslationService.instance.t('game.levels.level5.mole_order')}:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: bottomH >= 80
                                ? 16
                                : min(16, bottomH * 0.3),
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // The horizontal list of players
                    Flexible(
                      child: StreamBuilder<Tuple2<List<String>, int>>(
                        stream: widget.controller.moleOrder,
                        builder: (context, moleSnap) {
                          if (!moleSnap.hasData) {
                            debugPrint('🔄 Waiting for level document...');
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (moleSnap.hasError || moleSnap.data == null) {
                            debugPrint('⚠️ Error or no data in level document');
                            return Center(
                              child: Text(
                                TranslationService.instance.t(
                                  'screens.common.loading',
                                ),
                                style: TextStyle(color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }
                          final data = moleSnap.data!;
                          final names = data.item1;
                          final molePlayerIndex = data.item2;

                          if (names.isEmpty ||
                              molePlayerIndex < 0 ||
                              molePlayerIndex >= names.length) {
                            debugPrint(
                              '⚠️ Invalid molePlayerIndex or empty list!',
                            );
                            return Center(
                              child: Text(
                                TranslationService.instance.t(
                                  'screens.common.loading',
                                ),
                                style: TextStyle(color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: names.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final name = names[i];
                              final isMole = i == molePlayerIndex;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isMole
                                      ? Colors.yellow
                                      : Colors.white70,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isMole
                                      ? Border.all(
                                          color: Colors.orangeAccent,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isMole
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isMole
                                        ? Colors.black
                                        : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
