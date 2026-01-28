// nexaburst/lib/screens/main_components/app_text.dart

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:intl/intl.dart' as intl;

/// Defines common text styles used throughout the application.
///
/// Each enum value represents a predefined style for a specific use case,
/// such as headlines, subtitles, captions, or error messages.
enum TextType {
  headline,
  subtitle,
  body,
  caption,
  button,
  warning,
  error,
  disabled,
}

/// Utility class for building consistent and responsive text styles.
///
/// Includes methods for font scaling and rendering styled `Text` widgets
/// with additional visual effects like background blur or outlines.
///
/// This class is not meant to be instantiated.
class AppText {
  /// Private constructor to prevent instantiation of the utility class.
  AppText._();

  /// Calculates a scaled font size based on screen dimensions and user settings.
  ///
  /// The result is clamped within a min and max range to ensure readability.
  ///
  /// - [context]: The build context for accessing screen and user settings.
  /// - [base]: The base font size to scale from.
  ///
  /// Returns a `double` representing the scaled and clamped font size.
  double f(BuildContext context, double base) {
    final size = MediaQuery.of(context).size;
    final diagonal = sqrt(size.width * size.width + size.height * size.height);
    const baseDiag = 375 * 375 + 667 * 667;
    final scale = diagonal / sqrt(baseDiag);
    final userScale = MediaQuery.of(context).textScaleFactor;
    final raw = base * scale * userScale;

    final minFontSize = size.height * 0.03;
    final maxFontSize = size.height * 0.08;

    return raw.clamp(minFontSize, maxFontSize);
  }

  /// Returns a `TextStyle` object for the specified [type], scaled to screen size.
  ///
  /// Optionally adjusts the font size relative to a container’s height.
  ///
  /// - [context]: The build context.
  /// - [type]: The type of text style to return.
  /// - [containerHeight]: Optional height of the container to influence font size.
  ///
  /// Returns a `TextStyle` configured for the selected [TextType].
  static TextStyle style(
    BuildContext context,
    TextType type, {
    double? containerHeight,
  }) {
    switch (type) {
      case TextType.headline:
        return TextStyle(
          fontSize: containerHeight != null
              ? containerHeight * 0.7
              : AppText._().f(context, 24),
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText,
          height: 1.3,
        );
      case TextType.subtitle:
        return TextStyle(
          fontSize: containerHeight != null
              ? containerHeight * 0.7
              : AppText._().f(context, 20),
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
          height: 1.25,
        );
      case TextType.body:
        return TextStyle(
          fontSize: containerHeight != null
              ? containerHeight * 0.7
              : AppText._().f(context, 16),
          fontWeight: FontWeight.normal,
          color: AppColors.secondaryText,
          height: 1.5,
        );
      case TextType.caption:
        return TextStyle(
          fontSize: containerHeight != null
              ? containerHeight * 0.7
              : AppText._().f(context, 12),
          fontWeight: FontWeight.normal,
          color: AppColors.secondaryText,
          height: 1.2,
        );
      case TextType.button:
        return TextStyle(
          fontSize: containerHeight != null
              ? containerHeight * 0.7
              : AppText._().f(context, 18),
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
        );
      case TextType.warning:
        return TextStyle(
          fontSize: containerHeight != null
              ? containerHeight * 0.7
              : AppText._().f(context, 16),
          fontWeight: FontWeight.normal,
          color: AppColors.warning,
        );
      case TextType.error:
        return TextStyle(
          fontSize: containerHeight != null
              ? containerHeight * 0.7
              : AppText._().f(context, 16),
          fontWeight: FontWeight.bold,
          color: AppColors.error,
        );
      case TextType.disabled:
        return TextStyle(
          fontSize: containerHeight != null
              ? containerHeight * 0.7
              : AppText._().f(context, 16),
          fontWeight: FontWeight.normal,
          color: AppColors.disabledText,
        );
    }
  }

  /// Builds a styled and optionally decorated text widget with support for:
  /// - Right-to-left text detection
  /// - Background color
  /// - Border radius
  /// - Backdrop blur
  /// - Outline or shadow effects
  ///
  /// - [data]: The text to render.
  /// - [context]: The build context.
  /// - [type]: The text style type to apply.
  /// - [align]: The alignment of the text (default is [TextAlign.start]).
  /// - [maxLines]: Optional maximum number of lines.
  /// - [overflow]: Text overflow behavior (default is [TextOverflow.ellipsis]).
  /// - [shadow]: Optional shadow to apply to the text.
  /// - [outline]: Optional paint to render text with a foreground outline.
  /// - [backgroundColor]: Optional background color.
  /// - [padding]: Optional padding around the text.
  /// - [borderRadius]: Optional border radius for background.
  /// - [blurBackdrop]: Whether to apply a blur effect behind the text.
  /// - [blurSigma]: Blur intensity (only used if [blurBackdrop] is true).
  /// - [containerHeight]: Optional container height used to scale font size.
  ///
  /// Returns a `Widget` representing the fully styled text element.
  static Widget build(
    String data, {
    required BuildContext context,
    required TextType type,
    TextAlign align = TextAlign.start,
    int? maxLines,
    TextOverflow overflow = TextOverflow.ellipsis,
    Shadow? shadow,
    Paint? outline,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    bool blurBackdrop = false,
    double blurSigma = 8.0,
    double? containerHeight,
  }) {
    final dir = intl.Bidi.detectRtlDirectionality(data)
        ? TextDirection.rtl
        : TextDirection.ltr;
    TextStyle ts = style(context, type, containerHeight: containerHeight);
    if (shadow != null) ts = ts.copyWith(shadows: [shadow]);
    if (outline != null) ts = ts.copyWith(foreground: outline);

    Widget textWidget = Directionality(
      textDirection: dir,
      child: Text(
        data,
        style: ts,
        textAlign: align,
        maxLines: maxLines ?? 1,
        overflow: overflow,
      ),
    );

    if (backgroundColor != null || blurBackdrop) {
      final pad =
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      final radius = borderRadius ?? BorderRadius.circular(8);
      if (blurBackdrop) {
        textWidget = ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              padding: pad,
              color: (backgroundColor ?? Colors.white.withOpacity(0.2)),
              child: textWidget,
            ),
          ),
        );
      } else {
        textWidget = Container(
          padding: pad,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: radius,
          ),
          child: textWidget,
        );
      }
    }

    return textWidget;
  }
}
