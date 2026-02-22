// nexaburst/lib/screens/room/game/Lv05/game_screen.dart

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/room/game/manager_screens/loading_screen.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/server/levels/level5/lv05.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/models/structures/levels/level5/Lv05_model.dart';

/// A responsive Whack‑A‑Mole game screen powered by [Lv05] controller.
/// Shows holes in a grid, listens to streams for per‑hole updates,
/// and renders sprites and animations efficiently.
class GameScreen extends StatefulWidget {
  /// The game logic controller exposing hole streams and update methods.
  final Lv05 controller;
  /// Whether the local player is currently the mole (controls tapping behavior).
  final bool isMolePlayer;
  /// Creates a [GameScreen] bound to [controller] and indicating mole role.
  const GameScreen({
    super.key,
    required this.controller,
    required this.isMolePlayer,
  });

  /// Creates mutable state for [GameScreen].
  @override
  _GameScreenState createState() => _GameScreenState();
}

/// Holds loaded sprite images and builds the interactive hole grid.
class _GameScreenState extends State<GameScreen> {
  ui.Image? _holeImg, _charImg, _batMissImg, _batHurtImg, _bgImg;
  List<int>? _holeIds;
  Map<int, HoleModel>? _holeMap;
  late bool isMolePlayer;

  /// Holds loaded sprite images and builds the interactive hole grid.
  @override
  void initState() {
    super.initState();
    isMolePlayer = widget.isMolePlayer;
    _loadSprites();
  }

  /// Asynchronously loads and decodes sprite images for background,
/// hole, character, and bat frames.
  Future<void> _loadSprites() async {
    final holeProv = const AssetImage(PicPaths.hole);
    final charProv = const AssetImage(PicPaths.character);
    final missBatProv = const AssetImage(PicPaths.hitMiss);
    final hurtBatProv = const AssetImage(PicPaths.hitHurt);
    final bgProv = const AssetImage(PicPaths.lv05Background);

    Future<ui.Image> toImg(ImageProvider prov) {
      final completer = Completer<ui.Image>();
      final stream = prov.resolve(const ImageConfiguration());
      void listener(ImageInfo info, bool _) {
        completer.complete(info.image);
        stream.removeListener(ImageStreamListener(listener));
      }

      stream.addListener(ImageStreamListener(listener));
      return completer.future;
    }

    final imgs = await Future.wait([
      toImg(bgProv),
      toImg(holeProv),
      toImg(charProv),
      toImg(missBatProv),
      toImg(hurtBatProv),
    ]);
    if (!mounted) return;

    setState(() {
      _bgImg = imgs[0];
      _holeImg = imgs[1];
      _charImg = imgs[2];
      _batMissImg = imgs[3];
      _batHurtImg = imgs[4];
    });
  }

  /// Builds the grid of holes with [crossCnt] columns, [spacing] gap,
/// and square cells of size [cellSize].
  Widget _buildGrid(int crossCnt, double spacing, double cellSize) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCnt,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 1.0,
      ),
      itemCount: _holeIds!.length,
      itemBuilder: (ctxCell, idx) {
        final id = _holeIds![idx];
        return StreamBuilder<HoleModel>(
          stream: widget.controller.holeStream(id),
          initialData: _holeMap![id],
          builder: (ctxHole, singleSnap) {
            // error handling for single hole stream
            if (singleSnap.hasError) {
              debugPrint('Error loading hole $id: ${singleSnap.error}');
              return Center(
                child: Text(
                  "${TranslationService.instance.t('errors.game.lv05_hole_ui')}: $id",
                  style: const TextStyle(color: Colors.red),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }
            final hole = singleSnap.data!;
            return RepaintBoundary(
              child: SizedBox(
                width: cellSize,
                height: cellSize,
                child: _HoleWidget(
                  key: ValueKey(hole.id),
                  hole: hole,
                  isMyTurn: widget.isMolePlayer,
                  onTap: () {
                    if (widget.isMolePlayer) {
                      widget.controller.updateHoleState(hole.id);
                    } else {
                      widget.controller.tryHitHole(hole.id);
                    }
                  },
                  holeImg: _holeImg!,
                  charImg: _charImg!,
                  hitHurtImg: _batHurtImg!,
                  hitMissImg: _batMissImg!,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the entire UI:
/// - Shows loading indicator until sprites are ready
/// - Centers a responsive grid of holes on the background
  @override
  Widget build(BuildContext context) {
    // still wait for all sprites to load
    if (_holeImg == null ||
        _charImg == null ||
        _batMissImg == null ||
        _batHurtImg == null ||
        _bgImg == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, bc) {
        final totalWidth = bc.maxWidth;
        final totalHeight = bc.maxHeight;
        const spacing = 8.0;

        return Stack(
          children: [
            // full‐screen background
            Positioned.fill(
              child: RawImage(image: _bgImg, fit: BoxFit.cover),
            ),

            // the “grid area” also fills, but we will center the grid inside it
            Positioned.fill(
              child: StreamBuilder<List<HoleModel>>(
                stream: widget.controller.holes,
                builder: (ctx, snap) {
                  // error handling
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        TranslationService.instance.t('errors.game.lv05_hole_ui'),
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }

                  final holes = snap.data ?? [];
                  if (holes.isEmpty) return LoadingScreen();

                  // existing caching of holeIds & holeMap
                  if (_holeIds == null || holes.length != _holeIds!.length) {
                    _holeMap = {for (var h in holes) h.id: h};
                    _holeIds = holes.map((h) => h.id).toList();
                  }

                  // dynamic layout calculations
                  final count = holes.length;
                  // pick columns so that each cell is ~100px wide, but never more than count
                  final crossCount = (totalWidth / 100).floor().clamp(2, count);
                  final rowCount = (count / crossCount).ceil();

                  // max size per cell to fit width
                  final maxCellW =
                      (totalWidth - (crossCount - 1) * spacing) / crossCount;
                  // max size per cell to fit height
                  final maxCellH =
                      (totalHeight - (rowCount - 1) * spacing) / rowCount;
                  // square cells: take the smaller
                  const minCellSize =
                      48.0; // the smallest “hole” you can tolerate
                  final cellSizeRaw = min(maxCellW, maxCellH);

                  // 1) Round to avoid fractional pixels
                  final cellSizeRounded = cellSizeRaw.floorToDouble();

                  // 2) Clamp to your minimum
                  final cellSize = max(minCellSize, cellSizeRounded);

                  // compute actual grid dimensions
                  final gridWidth =
                      crossCount * cellSize + (crossCount - 1) * spacing;
                  final gridHeight =
                      rowCount * cellSize + (rowCount - 1) * spacing;
                  final fits = gridHeight <= totalHeight;

                  return Center(
                    child: SizedBox(
                      width: gridWidth,
                      // Only constrain height when the grid actually fits:
                      height: fits ? gridHeight : null,
                      child: fits
                          // non-scrolling, fixed-size grid
                          ? _buildGrid(crossCount, spacing, cellSize)
                          // scrolling fallback — no outer height constraint
                          : SingleChildScrollView(
                              child: SizedBox(
                                height: gridHeight,
                                child: _buildGrid(
                                  crossCount,
                                  spacing,
                                  cellSize,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// One hole: draws static hole + animates character and bat using AnimationController.
/// A single hole widget that paints the hole sprite and
/// animates character popping and bat hits.
class _HoleWidget extends StatefulWidget {
  /// The current hole state model from [controller.holeStream].
  final HoleModel hole;
  /// True if this client controls the mole and can tap to whack.
  final bool isMyTurn;
  /// Callback when the user taps this hole.
  final VoidCallback onTap;
  /// Hole base image sprite.
  final ui.Image holeImg, charImg, hitHurtImg, hitMissImg;

  /// Creates a hole widget displaying [hole] using provided sprites.
  const _HoleWidget({
    super.key,
    required this.hole,
    required this.isMyTurn,
    required this.onTap,
    required this.holeImg,
    required this.charImg,
    required this.hitHurtImg,
    required this.hitMissImg,
  });

  /// Creates mutable state for a single hole animation and hit logic.
  @override
  _HoleWidgetState createState() => _HoleWidgetState();
}

/// One hole: draws static hole + animates character and bat with two Animationmodel_view.
/// Manages character and bat animation controllers, reacts to hole state changes.
class _HoleWidgetState extends State<_HoleWidget>
    with TickerProviderStateMixin {
  late final AnimationController _charCtrl;
  late final AnimationController _batCtrl;

  List<Rect> _charFrames = [];
  List<Rect> _batFrames = [];

  int _charFrameIdx = 0;
  int _batFrameIdx = 0;

  bool _charActive = false;
  bool _batActive = false;

  late ui.Image _currentBatImg;
  bool _charShouldClearOnComplete = false;

  /// Loads initial frame data and sets up animation controllers for character and bat.
  @override
  void initState() {
    super.initState();
    _currentBatImg = widget.hitMissImg;

    _charCtrl = AnimationController(vsync: this)
      ..addListener(() {
        final idx = (_charCtrl.value * (_charFrames.length - 1)).floor();
        if (idx != _charFrameIdx) {
          setState(() => _charFrameIdx = idx);
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (_charShouldClearOnComplete) {
            setState(() => _charFrames = []);
          } else {
            setState(() => _charFrameIdx = _charFrames.length - 1);
          }
          _charActive = false;
        }
      });

    _batCtrl = AnimationController(vsync: this)
      ..addListener(() {
        final idx = (_batCtrl.value * (_batFrames.length - 1)).floor();
        if (idx != _batFrameIdx) {
          setState(() => _batFrameIdx = idx);
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _batFrames = []);
          _batActive = false;
        }
      });
  }

  /// Called when the hole stream state changes or a whack begins.
/// Triggers appropriate character or bat animation and plays sounds.
  @override
  void didUpdateWidget(covariant _HoleWidget old) {
    super.didUpdateWidget(old);

    final stateChanged = old.hole.state != widget.hole.state;
    final whackStarted = !old.hole.whacking && widget.hole.whacking;

    if (whackStarted) {
      final hit = widget.hole.state == 'occupied';
      _currentBatImg = hit ? widget.hitHurtImg : widget.hitMissImg;
      String audioPath = hit ? AudioPaths.hitHurt : AudioPaths.missHit;
      final batF = _batFramesList(start: 0, count: 9);

      _startBat(batF);
      _playSound(audioPath);

      if (hit) {
        final charF = _charFramesList(row: 1, cols: [0, 1, 2, 3]);
        _startChar(
          charF,
          clearOnComplete: false,
          onComplete: () {
            // after hit reaction done, keep last frame
          },
        );
      }
    } else if (stateChanged) {
      if (widget.hole.state == 'occupied') {
        final charF = _charFramesList(row: 0, cols: [1, 2, 3]);
        _playSound(AudioPaths.squirrelPop);
        _startChar(charF);
      } else {
        _playSound(AudioPaths.squirrelIn);
        if (old.hole.gotHit) {
          final charF = _charFramesList(row: 2, cols: [0, 1, 2, 3]);
          _startChar(charF, clearOnComplete: true);
        } else {
          final charF = _charFramesList(row: 0, cols: [2, 1]);
          _startChar(charF, clearOnComplete: true);
        }
      }
    }
  }

  /// Plays a sound at [path] via [UserData].
  Future<void> _playSound(String path) async {
    await UserData.instance.playSound(path);
  }

  /// Starts character animation through the given frame [frames].
/// Clears frames on completion if [clearOnComplete] is true.
  void _startChar(
    List<Rect> frames, {
    bool clearOnComplete = false,
    VoidCallback? onComplete,
  }) {
    if (frames.isEmpty) return;

    setState(() {
      _charFrames = frames;
      _charFrameIdx = 0;
      _charShouldClearOnComplete = clearOnComplete;
      _charActive = true;
    });

    _charCtrl.duration = Duration(milliseconds: frames.length * 100);
    _charCtrl.forward(from: 0).then((_) {
      if (!mounted) return;
      if (onComplete != null) onComplete();
    });
  }

  /// Starts bat‑swing animation using [frames].
  void _startBat(List<Rect> frames) {
    if (frames.isEmpty) return;
    _batFrames = frames;
    _batFrameIdx = 0;
    _batActive = true;
    _batCtrl.duration = Duration(milliseconds: frames.length * 100);
    _batCtrl.forward(from: 0);
  }

  /// Generates character sprite frames from sheet row [row] and columns [cols].
  List<Rect> _charFramesList({required int row, required List<int> cols}) {
    final w = widget.charImg.width / 4;
    final h = widget.charImg.height / 3;
    return cols.map((c) => Rect.fromLTWH(c * w, row * h, w, h)).toList();
  }

  /// Generates bat‑sprite frames starting at [start] for [count] frames.
  List<Rect> _batFramesList({required int start, required int count}) {
    const cols = 3;
    final w = _currentBatImg.width / cols;
    final h = _currentBatImg.height / cols;
    return List.generate(count, (i) {
      final idx = start + i;
      return Rect.fromLTWH((idx % cols) * w, (idx ~/ cols) * h, w, h);
    });
  }

  /// Disposes animation controllers when the hole is removed.
  @override
  void dispose() {
    _charCtrl.dispose();
    _batCtrl.dispose();
    super.dispose();
  }

  /// Paints hole, character, and bat layers based on current animation frames.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: CustomPaint(
        painter: _HolePainter(
          hole: widget.holeImg,
          char: widget.charImg,
          bat: _currentBatImg,
          charFrames: _charFrames,
          batFrames: _batFrames,
          charFrameIdx: _charFrameIdx,
          batFrameIdx: _batFrameIdx,
        ),
      ),
    );
  }
}

/// Painter now draws both char and bat layers if active.
/// Custom painter that draws:
/// 1. The static hole base
/// 2. The character frame if any
/// 3. The bat frame on top if any
class _HolePainter extends CustomPainter {
  final ui.Image hole, char, bat;
  final List<Rect> charFrames, batFrames;
  final int charFrameIdx, batFrameIdx;

  _HolePainter({
    required this.hole,
    required this.char,
    required this.bat,
    required this.charFrames,
    required this.batFrames,
    required this.charFrameIdx,
    required this.batFrameIdx,
  });

  /// Paints the hole and optional sprite frames into [size].
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dest = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );

    // draw hole
    canvas.drawImageRect(
      hole,
      Rect.fromLTWH(0, 0, hole.width.toDouble(), hole.height.toDouble()),
      dest,
      Paint(),
    );

    // draw char if active
    if (charFrames.isNotEmpty) {
      final src = charFrames[charFrameIdx.clamp(0, charFrames.length - 1)];
      canvas.drawImageRect(char, src, dest, Paint());
    }

    // draw bat on top if active
    if (batFrames.isNotEmpty) {
      final src = batFrames[batFrameIdx.clamp(0, batFrames.length - 1)];
      canvas.drawImageRect(bat, src, dest, Paint());
    }
  }

  /// Returns true if any frame index or frame list has changed.
  @override
  bool shouldRepaint(covariant _HolePainter old) {
    return old.charFrameIdx != charFrameIdx ||
        old.batFrameIdx != batFrameIdx ||
        old.charFrames != charFrames ||
        old.batFrames != batFrames;
  }
}
