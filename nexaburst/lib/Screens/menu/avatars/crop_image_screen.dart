// nexaburst/lib/screens/menu/avatars/crop_image_screen.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// A full-screen UI for cropping an image to a square region and returning it.
///
/// Accepts raw image data and outputs a cropped square image of the given size.
class CropImageScreen extends StatefulWidget {
  /// The raw image bytes to be displayed and cropped.
  final Uint8List imageData;

  /// The size in pixels of the final cropped output image. Defaults to 512.
  final int outputSize;

  const CropImageScreen({
    super.key,
    required this.imageData,
    this.outputSize = 512,
  });
  @override
  _CropImageScreenState createState() => _CropImageScreenState();
}

/// State implementation for [CropImageScreen].
/// Handles image decoding, cropping, and interactive drag gestures.
class _CropImageScreenState extends State<CropImageScreen> {
  /// The decoded image used for display and cropping.
  ui.Image? _decoded;

  /// The current top-left offset of the cropping square.
  Offset _squarePos = Offset.zero;

  /// The scaled display size of the image based on screen constraints.
  Size _imageDisplaySize = Size.zero;

  /// The size of the square cropping area.
  double _squareSize = 0;

  /// Initializes the state and triggers decoding of the input image.
  @override
  void initState() {
    super.initState();
    _decode();
  }

  /// Decodes the raw image bytes into a [ui.Image] for display and processing.
  Future<void> _decode() async {
    final codec = await ui.instantiateImageCodec(widget.imageData);
    final frame = await codec.getNextFrame();
    setState(() {
      _decoded = frame.image;
    });
  }

  /// Updates the cropping square position in response to drag gestures,
  /// keeping it within image bounds.
  void _onPan(DragUpdateDetails d) {
    setState(() {
      final newPos = _squarePos + d.delta;
      final maxX = _imageDisplaySize.width - _squareSize;
      final maxY = _imageDisplaySize.height - _squareSize;
      _squarePos = Offset(
        newPos.dx.clamp(0.0, maxX),
        newPos.dy.clamp(0.0, maxY),
      );
    });
  }

  /// Crops the selected area of the image and returns it as a PNG-encoded byte array.
  Future<Uint8List> _crop() async {
    final img = _decoded!;
    final srcX = (_squarePos.dx / _imageDisplaySize.width) * img.width;
    final srcY = (_squarePos.dy / _imageDisplaySize.height) * img.height;
    final srcSize = (_squareSize / _imageDisplaySize.width) * img.width;
    final srcRect = Rect.fromLTWH(srcX, srcY, srcSize, srcSize);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final dst = Rect.fromLTWH(
      0,
      0,
      widget.outputSize.toDouble(),
      widget.outputSize.toDouble(),
    );
    canvas.drawImageRect(img, srcRect, dst, Paint());
    final pic = recorder.endRecording();
    final outImg = await pic.toImage(widget.outputSize, widget.outputSize);
    final bytes = await outImg.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  /// Builds the interactive UI for image cropping,
  /// including drag gesture area and confirm button.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          TranslationService.instance.t('screens.settings.crop_image_title'),
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: _decoded == null
          ? Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (c, cons) {
                final scale = min(
                  cons.maxWidth / _decoded!.width,
                  cons.maxHeight / _decoded!.height,
                );
                _imageDisplaySize = Size(
                  _decoded!.width * scale,
                  _decoded!.height * scale,
                );

                _squareSize =
                    min(_imageDisplaySize.width, _imageDisplaySize.height) * .6;

                final maxX = _imageDisplaySize.width - _squareSize;
                final maxY = _imageDisplaySize.height - _squareSize;
                if (_squarePos == Offset.zero) {
                  _squarePos = Offset(maxX / 2, maxY / 2);
                } else {
                  _squarePos = Offset(
                    _squarePos.dx.clamp(0.0, maxX),
                    _squarePos.dy.clamp(0.0, maxY),
                  );
                }

                final imgLeft = (cons.maxWidth - _imageDisplaySize.width) / 2;
                final imgTop = (cons.maxHeight - _imageDisplaySize.height) / 2;

                return Stack(
                  children: [
                    Positioned(
                      left: imgLeft,
                      top: imgTop,
                      width: _imageDisplaySize.width,
                      height: _imageDisplaySize.height,
                      child: IgnorePointer(
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.5),
                            BlendMode.darken,
                          ),
                          child: Image.memory(
                            widget.imageData,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: imgLeft + _squarePos.dx,
                      top: imgTop + _squarePos.dy,
                      width: _squareSize,
                      height: _squareSize,
                      child: GestureDetector(
                        onPanUpdate: _onPan,
                        child: Stack(
                          children: [
                            ClipRect(
                              child: OverflowBox(
                                maxWidth: _imageDisplaySize.width,
                                maxHeight: _imageDisplaySize.height,
                                alignment: Alignment.topLeft,
                                child: Transform.translate(
                                  offset: Offset(
                                    -_squarePos.dx,
                                    -_squarePos.dy,
                                  ),
                                  child: Image.memory(
                                    widget.imageData,
                                    width: _imageDisplaySize.width,
                                    height: _imageDisplaySize.height,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),

                            Container(
                              width: _squareSize,
                              height: _squareSize,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.open_with,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 20,
                      left: (cons.maxWidth - cons.maxWidth * 0.6) / 2,
                      child: SizedBox(
                        width: cons.maxWidth * 0.6,
                        child: ElevatedButton(
                          onPressed: () async {
                            final bytes = await _crop();
                            Navigator.of(context).pop(bytes);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            TranslationService.instance.t(
                              'screens.settings.done_button',
                            ),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
