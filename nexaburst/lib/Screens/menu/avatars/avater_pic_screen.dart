// nexaburst/lib/screens/menu/avatars/avatar_pic_screen.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/menu/avatars/avatar_custom.dart';
import 'package:nexaburst/Screens/menu/avatars/avatar_ui_helper.dart';
import 'package:nexaburst/Screens/main_components/app_button.dart';
import 'package:nexaburst/Screens/main_components/app_text.dart';
import 'package:nexaburst/Screens/main_components/background_enter.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

/// A screen that allows the user to choose or upload a profile avatar.
///
/// Users can pick from built-in male or female avatars, or upload a custom
/// image from the camera or gallery. Upon saving, the avatar is updated in
/// the user's profile.
class AvatarScreen extends StatefulWidget {
  /// List of predefined male avatar asset paths.
  final List<String> builtInMaleAvatars = [...Avatars.maleAvatars];

  /// List of predefined female avatar asset paths.
  final List<String> builtInFemaleAvatars = [...Avatars.femaleAvatars];

  /// The initial avatar to display, based on the current user's saved avatar
  /// or the default avatar if none is set.
  final String startAvatar =
      UserData.instance.user?.avatar ?? Avatars.defaultAvatarPath;

  /// Creates the [AvatarScreen] widget with default avatar data.
  AvatarScreen({super.key});

  @override
  _AvatarScreenState createState() => _AvatarScreenState();
}

/// The state for the [AvatarScreen] widget, managing avatar selection,
/// saving, and UI interactions.
class _AvatarScreenState extends State<AvatarScreen> {
  /// Holds the currently selected avatar (either built-in or custom).
  String? _newAvatar;

  /// Indicates whether an avatar is currently being saved to prevent duplicate actions.
  bool _saving = false;

  /// Currently selected gender category to filter available built-in avatars.
  String selectedGender = 'male';

  /// Initializes the screen by setting the initial avatar selection.
  @override
  void initState() {
    super.initState();
    _newAvatar = _newAvatar ?? widget.startAvatar;
  }

  /// Saves the new avatar if it was changed, and shows feedback via a snackbar.
  ///
  /// If the avatar was updated successfully, the user is returned to the previous screen.
  /// If an error occurs, a failure message is shown instead.
  Future<void> _saveIfChanged() async {
    if (_saving) return;
    if (_newAvatar != null &&
        _newAvatar != (UserData.instance.user?.avatar ?? widget.startAvatar)) {
      setState(() => _saving = true);
      try {
        await UserData.instance.updateProfile(avatar: _newAvatar!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.instance.t(
                'screens.settings.avatar_update_success',
              ),
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error saving avatar: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.instance.t(
                'screens.settings.avatar_update_fails',
              ),
            ),
          ),
        );
      } finally {
        setState(() => _saving = false);
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Selects a built-in avatar by its asset path [id].
  void _selectBuiltIn(String id) => setState(() => _newAvatar = id);

  /// Launches the camera to pick and upload a custom avatar.
  Future<void> _pickFromCamera() async {
    await _pickCustom(ImageSource.camera);
  }

  /// Opens the gallery to pick and upload a custom avatar.
  Future<void> _pickFromGallery() async {
    await _pickCustom(ImageSource.gallery);
  }

  /// Handles picking, cropping, and uploading an avatar image from the given [source].
  ///
  /// This method requests permission if needed, shows a loading dialog during
  /// processing, and updates the selected avatar if the upload was successful.
  Future<void> _pickCustom(ImageSource source) async {
    if (!kIsWeb) {
      PermissionStatus status;

      if (source == ImageSource.camera) {
        status = await Permission.camera.request();
      } else {
        // For gallery
        if (await Permission.photos.isGranted ||
            await Permission.photos.request().isGranted) {
          status = PermissionStatus.granted;
        } else {
          status = await Permission.photos.request();
        }
      }

      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.instance.t('errors.common.permission_denied'),
            ),
          ),
        );
        return;
      }
    }
    // show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 200),
          child: SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );

    String? result = await AvatarUploader().pickCropAndUpload(
      source: source,
      context: context,
    );
    if (result != null) {
      debugPrint(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.instance.t(
              'errors.user_data.image_upload_failed',
            ),
          ),
        ),
      );
    } else {
      setState(() {
        _newAvatar = UserData.instance.user?.avatar;
      });
    }
    Navigator.of(context).pop();
  }

  /// Returns a list of built-in avatar paths based on the selected gender.
  List<String> _getAvatarsForGender() {
    return selectedGender == 'male'
        ? widget.builtInMaleAvatars
        : widget.builtInFemaleAvatars;
  }

  /// Builds a gender selection button for either 'male' or 'female'.
  ///
  /// The [gender] argument must be either 'male' or 'female'.
  /// The [selected] argument controls the button's highlight state.
  Widget _buildGenderButton(String gender, bool selected) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: selected ? Colors.pink : Colors.grey[300],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
      ),
      onPressed: () {
        setState(() {
          selectedGender = gender;
        });
      },
      child: Text(
        gender == 'male' ? 'Male' : 'Female',
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds the main UI for the avatar selection screen.
  ///
  /// Includes:
  /// - Avatar preview
  /// - Camera/gallery buttons
  /// - Gender switch
  /// - Built-in avatar grid
  /// - Save and back button
  @override
  Widget build(BuildContext context) {
    return Background(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bigRadius =
                min(constraints.maxWidth, constraints.maxHeight) * 0.15;
            final smallRadius = bigRadius * 0.33;
            final space =
                (constraints.maxHeight - bigRadius * 2 - smallRadius * 2.5) / 6;
            double iconSize = min(constraints.maxWidth * 0.1, 32);
            double widSpace = min(16, constraints.maxWidth * 0.05);

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AppButton.icon(
                              icon: Icons.arrow_back,
                              onPressed: _saving ? () {} : _saveIfChanged,
                              color: Colors.black,
                              size: iconSize,
                            ),
                          ),
                          AppText.build(
                            TranslationService.instance.t(
                              'screens.settings.avatar_change_hint',
                            ),
                            context: context,
                            type: TextType.subtitle,
                            backgroundColor: Colors.black.withOpacity(0.4),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: space),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.camera_alt,
                              size: iconSize,
                              color: Colors.black87,
                            ),
                            onPressed: _pickFromCamera,
                          ),
                          SizedBox(width: widSpace),
                          if (_newAvatar != null)
                            SpriteAvatar(id: _newAvatar!, radius: bigRadius),
                          SizedBox(width: widSpace),
                          IconButton(
                            icon: Icon(
                              Icons.photo,
                              size: iconSize,
                              color: Colors.black87,
                            ),
                            onPressed: _pickFromGallery,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: space),
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      padding: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(167, 255, 255, 255),
                        border: Border.all(color: Colors.pink, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _buildGenderButton(
                                  'male',
                                  selectedGender == 'male',
                                ),
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: _buildGenderButton(
                                  'female',
                                  selectedGender == 'female',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: _getAvatarsForGender().map((id) {
                                  final selected = id == _newAvatar;
                                  return GestureDetector(
                                    onTap: () => _selectBuiltIn(id),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SpriteAvatar(
                                          id: id,
                                          radius: smallRadius,
                                        ),
                                        if (selected)
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: smallRadius,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
