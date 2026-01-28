// nexaburst/lib/screens/menu/avatars/avatar_ui_helper.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexaburst/constants.dart';

/// A helper class that provides access to sprite sheets and avatar mappings
/// for male and female avatars.
class Avatars {
  /// Path to the male avatar sprite sheet.
  static const String maleSheet = PicPaths.maleSheet;

  /// Path to the female avatar sprite sheet.
  static const String femaleSheet = PicPaths.femaleSheet;

  /// Path to the default fallback avatar image.
  static const String defaultAvatarPath = PicPaths.defaultAvatarPath;

  /// A mapping of male avatar identifiers to their positions in the sprite sheet.
  static final Map<String, Rect> spriteMaleMap = {
    for (var row = 0; row < 4; row++)
      for (var col = 0; col < 4; col++)
        'male_${row * 4 + col + 1}': Rect.fromLTWH(
          col * 256.0,
          row * 256.0,
          256.0,
          256.0,
        ),
  };

  /// A mapping of female avatar identifiers to their positions in the sprite sheet.
  static final Map<String, Rect> spriteFemaleMap = {
    for (var row = 0; row < 4; row++)
      for (var col = 0; col < 4; col++)
        'female_${row * 4 + col + 1}': Rect.fromLTWH(
          col * 256.0,
          row * 256.0,
          256.0,
          256.0,
        ),
  };

  /// Returns a list of all available male avatar identifiers.
  static List<String> get maleAvatars => spriteMaleMap.keys.toList();

  /// Returns a list of all available female avatar identifiers.
  static List<String> get femaleAvatars => spriteFemaleMap.keys.toList();

  /// Returns the appropriate sprite sheet path based on the avatar [id].
  static String sheetFor(String id) =>
      id.startsWith('male_') ? maleSheet : femaleSheet;
}

/// A simple in-memory cache for loaded sprite sheet images.
class _SheetCache {
  /// Stores future image loads keyed by asset path to prevent redundant loads.
  static final Map<String, Future<ui.Image>> _cache = {};

  /// Loads an image asset, caching it for future use.
  ///
  /// [asset] - The path to the image asset.
  ///
  /// Returns a [Future] containing the loaded [ui.Image].
  static Future<ui.Image> load(String asset) {
    return _cache.putIfAbsent(asset, () async {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 1024,
        targetHeight: 1024,
      );
      return (await codec.getNextFrame()).image;
    });
  }
}

/// A circular widget that displays an avatar image from one of three sources:
/// a sprite sheet, a network URL, or a local asset.
class SpriteAvatar extends StatelessWidget {
  /// The identifier for the avatar. Can be a sprite key, network URL, or asset path.
  final String id;

  /// The radius of the circular avatar.
  final double radius;

  /// The background color shown behind sprite avatars.
  final Color backgroundColor;

  const SpriteAvatar({
    super.key,
    required this.id,
    required this.radius,
    this.backgroundColor = const ui.Color.fromARGB(174, 0, 0, 0),
  });

  /// Returns `true` if [id] corresponds to a sprite-based avatar.
  bool get _isSpriteId =>
      Avatars.spriteMaleMap.containsKey(id) ||
      Avatars.spriteFemaleMap.containsKey(id) ||
      id.startsWith('male_') ||
      id.startsWith('female_');

  /// Returns `true` if [id] is a network URL.
  bool get _isNetwork => id.startsWith('http');

  /// Builds the widget tree for displaying the avatar.
  @override
  Widget build(BuildContext context) {
    final bgCircle = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
    );

    Widget foreground;
    if (_isSpriteId) {
      final sheetAsset = Avatars.sheetFor(id);
      final srcRect = Avatars.spriteMaleMap[id] ?? Avatars.spriteFemaleMap[id]!;

      foreground = FutureBuilder<ui.Image>(
        future: _SheetCache.load(sheetAsset),
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return SizedBox(
              width: radius * 2,
              height: radius * 2,
              child: Center(
                child: SizedBox(
                  width: radius,
                  height: radius,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return ClipOval(
            child: CustomPaint(
              size: Size.square(radius * 2),
              painter: _SpritePainter(
                image: snap.data!,
                srcRect: srcRect,
                dstSize: Size.square(radius * 2),
              ),
            ),
          );
        },
      );
    } else if (_isNetwork) {
      foreground = ClipOval(
        child: FadeInImage.assetNetwork(
          placeholder: PicPaths.defaultAvatarPath,
          image: id,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          imageErrorBuilder: (_, __, ___) {
            return Image.asset(
              Avatars.defaultAvatarPath,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
            );
          },
          fadeInDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      foreground = ClipOval(
        child: Image.asset(
          id,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        ),
      );
    }

    return _isSpriteId
        ? Stack(alignment: Alignment.center, children: [bgCircle, foreground])
        : foreground;
  }
}

/// A custom painter that renders a section of a sprite sheet image into a destination size.
class _SpritePainter extends CustomPainter {
  /// The full sprite sheet image.
  final ui.Image image;

  /// The source rectangle within the sprite sheet to render.
  final Rect srcRect;

  /// The size of the destination area where the sprite will be drawn.
  final Size dstSize;

  _SpritePainter({
    required this.image,
    required this.srcRect,
    required this.dstSize,
  });

  /// Paints the cropped sprite image into the canvas area.
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(image, srcRect, Offset.zero & dstSize, Paint());
  }

  /// Determines whether the painter should repaint.
  ///
  /// Returns `true` if the source or destination properties have changed.
  @override
  bool shouldRepaint(covariant _SpritePainter old) =>
      old.image != image || old.srcRect != srcRect || old.dstSize != dstSize;
}
