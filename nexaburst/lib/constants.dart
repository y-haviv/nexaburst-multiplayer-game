// nexaburst/lib/constants.dart

import 'package:flutter/material.dart';

/// Whether the app is running in debug mode, as defined by the DEBUG_MODE environment variable.
const bool debug = bool.fromEnvironment('DEBUG_MODE', defaultValue: false);

/// Static file system paths for all avatar sprites and icon/background assets.
class PicPaths {
  /// Path to the male avatar spritesheet.
  static const String maleSheet = 'assets/avatars/avatars_male.png';

  /// Path to the female avatar spritesheet.
  static const String femaleSheet = 'assets/avatars/avatars_female.png';

  /// Path to the default avatar image.
  static const String defaultAvatarPath = 'assets/avatars/default_avatar.png';

  /// Path to the welcome icon.
  static const String enterPic = "assets/icons/welcome.webp";

  /// Path to the input field background image.
  static const String inputBackground = "assets/icons/input_background.webp";

  /// Path to the app title icon.
  static const String titlePath = "assets/icons/title.webp";

  /// Path to the main game background image.
  static const String mainBackground = "assets/images/background1.webp";

  /// Path to the wheel background image.
  static const String weelBackground = "assets/images/weelBackground.webp";

  /// Path to the gold coin image.
  static const String goldCoin = "assets/images/gold_coin.png";

  /// Path to the black coin image.
  static const String blackCoin = "assets/images/black_coin.png";

  /// Path to the cup image.
  static const String cup = "assets/images/cup.png";

  /// Path to the hole sprite.
  static const String hole = 'assets/sprites/hole.png';

  /// Path to the character spritesheet.
  static const String character = 'assets/sprites/character_sheet.png';

  /// Path to the hit/miss sprite.
  static const String hitMiss = 'assets/sprites/hitMiss.png';

  /// Path to the hit/hurt sprite.
  static const String hitHurt = 'assets/sprites/hitHurt.png';

  /// Path to the level‑5 background sprite.
  static const String lv05Background = 'assets/sprites/gameBackGround.png';
}

/// Static file system paths for all in‑game audio assets.
class AudioPaths {
  /// Background audio played in the waiting room.
  static const String waiting_room = "assets/audio/Waiting_room.mp3";

  /// Sound effect for taking a drink.
  static const String drink_sound = "assets/audio/chug_sound.mp3";

  /// Audio loop for drinking chant music.
  static const String drink_music = "assets/audio/chant_chug.mp3";

  /// Sound effect for drink failure (boo).
  static const String drink_fail = "assets/audio/boo.mp3";

  /// Sound effect for drink success (cheer).
  static const String drink_success = "assets/audio/applause_cheer.mp3";

  /// Timer tick sound.
  static const String tikTak = "assets/audio/timer_tick.mp3";

  /// Sound effect when revealing cups.
  static const String revealCups = "assets/audio/reveal.mp3";

  /// Sound effect when shuffling cups.
  static const String shuffleCups = "assets/audio/shuffle.mp3";

  /// Audio for wheel spinning.
  static const String wheelSpin = "assets/audio/wheel_spinning.mp3";

  /// Sound effect when missing a whack.
  static const String missHit = "assets/audio/whackMiss.mp3";

  /// Sound effect when hitting in whack‑a‑mole.
  static const String hitHurt = "assets/audio/whackHit.mp3";

  /// Sound effect for squirrel popping up.
  static const String squirrelPop = "assets/audio/squirrelPopAudio.mp3";

  /// Sound effect for squirrel going in.
  static const String squirrelIn = "assets/audio/squirrelInAudio.mp3";

  /// List of correct answer sound effect file paths.
  static const List<String> correctSounds = [
    'assets/audio/correct1.mp3',
    'assets/audio/correct2.mp3',
    'assets/audio/correct3.mp3',
  ];

  /// List of wrong answer sound effect file paths.
  static const List<String> wrongSounds = [
    'assets/audio/wrong1.mp3',
    'assets/audio/wrong2.mp3',
  ];
}

/// Static file system paths for all JSON text and question assets.
class TextPaths {
  /// Path to the main static text JSON.
  static const String texts = 'assets/texts/static_text.json';

  /// Path to level‑1 trivia questions JSON.
  static const String lv01 = "assets/texts/lv01_questions.json";

  /// Path to level‑2 wheel data JSON.
  static const String lv02 = "assets/texts/lv02_wheel.json";

  /// Path to level‑3 data JSON.
  static const String lv03 = "assets/texts/lv03.json";

  /// Path to level‑4 data JSON.
  static const String lv04 = "assets/texts/lv04.json";
}

/// Default timing durations (in seconds) used across all game screens.
class ScreenDurations {
  /// Default time allotted for most game actions.
  static const int defaultTime = 20;

  /// Duration for showing instructions.
  static const int instructionsTime = 10;

  /// Time allotted for general gameplay.
  static const int generalGameTime = 30;

  /// Duration of the final result screen.
  static const int finalResultTime = 10;

  /// Duration of intermediate result screens.
  static const int resultTime = 8;

  /// Time shown on the drinking penalty screen.
  static const int drinkScreenTime = 30;

  /// Per‑player time in Whack‑a‑Mole (level 5).
  static const int level05PerPlayerTime = 15;

  /// Pre‑game discussion time in Prisoner’s Dilemma (level 6).
  static const int level06PreGameTime = 30;
}

/// Configuration and validation for number of rounds per level.
class LevelsRounds {
  /// Maximum allowed rounds per level.
  static const int maxLevelRounds = 10;

  /// Minimum allowed rounds per level.
  static const int minlevelRounds = 2;

  /// Default number of rounds if none specified.
  static const int defaultlevelRounds = 3;

  /// Returns the default number of rounds.
  static int defaultLevelRound() {
    return defaultlevelRounds;
  }

  /// Returns the maximum number of rounds.
  static int maxLevelRound() {
    return maxLevelRounds;
  }

  /// Returns the minimum number of rounds.
  static int minLevelRound() {
    return minlevelRounds;
  }

  /// Ensures a given input is within the allowed rounds range.
  /// - If `input` exceeds max, returns `maxLevelRounds`.
  /// - If `input` is below min, returns `minlevelRounds`.
  /// - Otherwise, returns `input`.
  static int checkRoundInput(int input) {
    if (input > maxLevelRounds) {
      return maxLevelRounds;
    } else if (input < minlevelRounds) {
      return minlevelRounds;
    } else {
      return input;
    }
  }
}

/// Centralized color palette (and gradients) used throughout the app UI.
class AppColors {
  /// Prevents instantiation; this class only provides static constants.
  AppColors._();

  /// Primary brand color for buttons and highlights.
  static const Color kPrimaryColor = Color(0xFF6F35A5);

  /// Lighter version of the primary brand color.
  static const Color kPrimaryLightColor = Color(0xFFF1E6FF);

  /// Deep blue accent for backgrounds or big areas.
  static const Color chacking = Color.fromARGB(255, 6, 8, 151);

  /// Main text color for high contrast on dark backgrounds.
  static const Color primaryText = Color.fromARGB(255, 255, 255, 255);

  /// Secondary text color for less prominent labels.
  static const Color secondaryText = Color(0xFFE0E0E0);

  /// Disabled text color for inactive elements.
  static const Color disabledText = Color(0xFF777777);

  /// Accent color used for primary action buttons and links.
  static const Color accent1 = Color(0xFF00E5FF);

  /// Accent color for inline highlights and secondary links.
  static const Color accent2 = Color(0xFFFF3EC8);

  /// Accent color indicating success states.
  static const Color accent3 = Color(0xFF8AE6CB);

  /// Additional accent color for general use.
  static const Color accent4 = Color(0xFF6F35A5);

  /// Warning color for intermediate alerts.
  static const Color warning = Color(0xFFFFC107);

  /// Error color for validation and error states.
  static const Color error = Color(0xFFE74C3C);

  /// Semi‑transparent background for secondary (outline) buttons.
  static const Color secondaryButtonBackground = Color.fromRGBO(
    255,
    255,
    255,
    0.15,
  );

  /// Border color for secondary (outline) buttons.
  static const Color secondaryButtonBorder = Color(0xFFFFFFFF);

  /// Dark overlay for modal and tutorial screens.
  static const Color overlayDark = Color.fromRGBO(0, 0, 0, 0.6);
}

/// Numeric constants used throughout the app for spacing and opacity.
class AppNumbers {
  /// Default overlay opacity (0.0–1.0).
  static const double overlayOpacity = 0.2;

  /// Standard padding value used in layouts.
  static const double defaultPadding = 16.0;
}
