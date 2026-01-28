// nexaburst/lib/screens/main_components/app_button.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'app_text.dart';

/// A utility class for building consistent and reusable button widgets.
///
/// Provides several static methods to create various types of buttons,
/// including primary, secondary, text, icon, and boolean toggle buttons.
///
/// This class is not meant to be instantiated.
class AppButton {
  /// Private constructor to prevent instantiation of this utility class.
  AppButton._();

  /// Builds a primary styled button using [ElevatedButton].
  ///
  /// Used for main call-to-action buttons with rounded corners and accent color.
  ///
  /// - [context]: The build context.
  /// - [label]: The button text.
  /// - [onPressed]: Callback executed when the button is pressed.
  /// - [enabled]: If false, the button is disabled.
  /// - [width]: Optional fixed width for the button.
  /// - [height]: Optional fixed height for the button.
  /// - [widthFactor]: Fractional width of parent if [width] is not provided.
  /// - [key]: Optional key for the button.
  ///
  /// Returns a styled [Widget] representing the primary button.
  static Widget primary({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    bool enabled = true,
    double? width,
    double? height,
    double widthFactor = 0.8,
    String? key,
  }) {
    double textHeight = height != null ? height * 0.5 : 20;
    Widget button = SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        key: ValueKey(key),
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? AppColors.accent1
              : AppColors.secondaryText.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 2,
        ),
        child: AppText.build(
          label,
          context: context,
          type: TextType.button,
          align: TextAlign.center,
          containerHeight: textHeight,
          maxLines: 2,
        ),
      ),
    );
    if (width == null) {
      button = FractionallySizedBox(widthFactor: widthFactor, child: button);
    }

    return button;
  }

  /// Builds a secondary styled button using [OutlinedButton].
  ///
  /// Suitable for less prominent actions with a border and flat appearance.
  ///
  /// - [context]: The build context.
  /// - [label]: The button text.
  /// - [onPressed]: Callback executed when the button is pressed.
  /// - [enabled]: If false, the button is disabled.
  /// - [width]: Optional fixed width.
  /// - [height]: Optional fixed height.
  /// - [widthFactor]: Fractional width of parent if [width] is not provided.
  /// - [key]: Optional key for the button.
  ///
  /// Returns a styled [Widget] representing the secondary button.
  static Widget secondary({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    bool enabled = true,
    double? width,
    double? height,
    double widthFactor = 0.6,
    String? key,
  }) {
    double textHeight = height != null ? height * 0.5 : 20;
    Widget button = SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        key: ValueKey(key),
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: enabled
                ? AppColors.secondaryButtonBorder
                : AppColors.disabledText,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: AppText.build(
          label,
          context: context,
          type: TextType.button,
          align: TextAlign.center,
          containerHeight: textHeight,
          maxLines: 2,
        ),
      ),
    );

    if (width == null) {
      button = FractionallySizedBox(widthFactor: widthFactor, child: button);
    }

    return button;
  }

  /// Builds a minimal text button using [TextButton].
  ///
  /// Ideal for inline or low-priority actions without background styling.
  ///
  /// - [context]: The build context.
  /// - [label]: The button text.
  /// - [onPressed]: Callback executed when the button is pressed.
  /// - [enabled]: If false, the button is disabled.
  /// - [style]: Optional custom text style to override default.
  ///
  /// Returns a [TextButton] widget.
  static Widget text({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    bool enabled = true,
    TextStyle? style,
  }) {
    return TextButton(
      onPressed: enabled ? onPressed : null,
      child: Text(
        label,
        style:
            style ??
            AppText.style(context, TextType.body).copyWith(
              color: enabled ? AppColors.accent2 : AppColors.disabledText,
            ),
      ),
    );
  }

  /// Builds an icon-only button using [IconButton].
  ///
  /// Can be used for compact or symbolic interactions, optionally with a tooltip.
  ///
  /// - [icon]: The icon to display.
  /// - [onPressed]: Callback executed when the button is pressed.
  /// - [enabled]: If false, the button is disabled.
  /// - [size]: The size of the icon.
  /// - [color]: Optional icon color (defaults to primary text color).
  /// - [tooltip]: Optional tooltip text for accessibility.
  ///
  /// Returns an [IconButton] widget.
  static Widget icon({
    required IconData icon,
    required VoidCallback onPressed,
    bool enabled = true,
    double size = 24,
    Color? color,
    String? tooltip,
  }) {
    if (tooltip == null || tooltip.isEmpty) {
      tooltip = "";
    }
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(
        icon,
        size: size,
        color: enabled
            ? color ?? AppColors.primaryText
            : AppColors.disabledText,
      ),
      tooltip: tooltip,
    );
  }

  /// Builds a labeled boolean toggle using a [Row] with a [Switch].
  ///
  /// Useful for on/off settings or preferences with an inline label.
  ///
  /// - [context]: The build context.
  /// - [label]: Text label displayed next to the switch.
  /// - [value]: Current state of the switch.
  /// - [onChanged]: Callback executed when the switch value changes.
  /// - [labelType]: Text style type for the label.
  /// - [align]: Text alignment for the label.
  /// - [spacing]: Space between the label and the switch (scaled by screen size).
  ///
  /// Returns a [Row] widget containing a styled label and switch.
  static Widget boolean({
    required BuildContext context,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    TextType labelType = TextType.body,
    TextAlign align = TextAlign.start,
    double spacing = 12.0,
  }) {
    final width = MediaQuery.of(context).size.width;
    final scale = width / 375.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.build(
          label,
          context: context,
          type: labelType,
          align: align,
          borderRadius: BorderRadius.circular(8),
          maxLines: 1,
        ),
        SizedBox(width: spacing * scale),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.accent1,
          inactiveThumbColor: AppColors.disabledText,
          inactiveTrackColor: AppColors.secondaryText.withOpacity(0.3),
        ),
      ],
    );
  }
}
