// nexaburst/lib/screens/menu/avatars/avatar_custom.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/menu/avatars/crop_image_screen.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// A singleton class responsible for handling avatar selection,
/// cropping, and uploading.
class AvatarUploader {
  static final AvatarUploader _instance = AvatarUploader._internal();

  /// Returns the single instance of [AvatarUploader].
  factory AvatarUploader() => _instance;

  /// Private internal constructor for the singleton pattern.
  AvatarUploader._internal();

  /// Opens the device image picker and allows the user to select an image
  /// from the given [source].
  ///
  /// Returns a [XFile] if an image is picked, or `null` if canceled or failed.
  Future<XFile?> _pickImage(ImageSource source) async {
    try {
      return await ImagePicker().pickImage(source: source, imageQuality: 85);
    } catch (e) {
      debugPrint('Image picking error: $e');
      return null;
    }
  }

  /// Allows the user to pick an image, crop it, and upload it to the server.
  ///
  /// [source] - Source of the image (e.g., camera or gallery).
  /// [context] - BuildContext for pushing the cropping screen.
  ///
  /// Returns `null` if successful, or a user-facing error message otherwise.
  Future<String?> pickCropAndUpload({
    required ImageSource source,
    required BuildContext context,
  }) async {
    try {
      final picked = await _pickImage(source);
      if (picked == null) {
        return "Having a problem getting the image, try again.";
      }
      final pickedToBytes = await picked.readAsBytes();

      final Uint8List? croppedBytes = await Navigator.of(context)
          .push<Uint8List?>(
            MaterialPageRoute(
              builder: (_) =>
                  CropImageScreen(imageData: pickedToBytes, outputSize: 512),
            ),
          );

      if (croppedBytes == null) {
        return "Having a problem cropping the image, try again.";
      }

      final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';

      if (kIsWeb) {
        await UserData.instance.uploadImage(croppedBytes, filename: filename);
      } else {
        final tmp = await getTemporaryDirectory();
        final outFile = File('${tmp.path}/$filename');
        await outFile.writeAsBytes(croppedBytes);
        final fileToUpload = XFile(outFile.path);
        await UserData.instance.uploadImage(
          await fileToUpload.readAsBytes(),
          filename: fileToUpload.name,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error picking/cropping image: $e');
      return "Unexpected error occurred, let's try again.";
    }
  }
}
