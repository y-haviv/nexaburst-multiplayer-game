# NexaBurst — Cross-Platform Social Party Game

NexaBurst is a multiplayer social party game built with Flutter and Dart. This document covers the application architecture, code structure, game mechanics, feature implementation, and developer workflows.

---

## Table of Contents

1. [Overview](#overview)
2. [Application Architecture](#application-architecture)
3. [Game Flow and Stages](#game-flow-and-stages)
4. [User System and Authentication](#user-system-and-authentication)
5. [Game Modes and Rules](#game-modes-and-rules)
6. [Code Structure and Organization](#code-structure-and-organization)
7. [Key Features and Implementation](#key-features-and-implementation)
8. [Backend Integration](#backend-integration)
9. [Localization System](#localization-system)
10. [Development Sandbox and Testing](#development-sandbox-and-testing)
11. [Building and Running](#building-and-running)
12. [Troubleshooting](#troubleshooting)

---

## Overview

NexaBurst enables groups of friends to join private multiplayer game rooms and compete across a series of short, fast-paced mini-games. The app emphasizes social interaction, scalability, and a responsive user experience across Android, iOS, and Web platforms.

**Key characteristics:**
- Cross-platform Flutter application (Android, iOS, Web)
- Real-time multiplayer using Firebase Realtime Database
- MVVM architecture with clear separation of concerns
- Extensible stage system for adding new game types
- Support for 100+ languages via automated localization

---

## Application Architecture

### MVVM Pattern

NexaBurst uses the **Model–View–ViewModel** pattern to organize code:

```
┌─────────────────────────────────────────────────────────┐
│  UI Layer (Screens, Widgets)                           │
│  - Stateless/Stateful Flutter widgets                   │
│  - Event handlers and user interactions                 │
└──────────────────┬──────────────────────────────────────┘
                   │
                   │ Binds to
                   ▼
┌─────────────────────────────────────────────────────────┐
│  ViewModel Layer (Business Logic, State Management)    │
│  - model_view/ directory                               │
│  - Manages screen state and game logic                  │
│  - Handles Firebase communication                       │
└──────────────────┬──────────────────────────────────────┘
                   │
                   │ Uses
                   ▼
┌─────────────────────────────────────────────────────────┐
│  Model Layer (Data Structures, Services)               │
│  - models/ directory (DTOs, data classes)              │
│  - Firebase service layer                              │
│  - Local data operations                               │
└─────────────────────────────────────────────────────────┘
```

**Benefits:**
- Clean separation of UI logic and business logic
- Testable, reusable view models
- Easy to add new screens or stages

---

## Game Flow and Stages

### Typical User Session Flow

```
1. Authentication
   ├─ Sign up (email, password)
   └─ Sign in or persistent login
   
2. Room Management
   ├─ Create room → assign room code
   └─ Join room → enter room code
   
3. Game Configuration
   ├─ Set number of rounds
   ├─ Enable/disable global modes
   └─ Wait for players to ready up
   
4. Gameplay Loop
   ├─ Stage 1: Trivia
   ├─ Stage 2: Lucky / Wheel
   ├─ Stage 3: Logic & Puzzle
   ├─ Stage 4: Social Prediction
   ├─ Stage 5: Reaction
   └─ Stage 6: Strategic Decision
   
5. Results
   ├─ Final scoreboard
   ├─ Winner announcement
   └─ Option to play again or exit
```

### Game Stages (Detailed)

#### 1. Trivia Stage
- **Mechanics**: Multiple-choice questions fetched from external API.
- **Duration**: ~60 seconds per question, configurable.
- **Scoring**: Points awarded based on correctness and speed (faster answers = higher score).
- **Code location**: `Screens/room/` (Trivia-related screens); `model_view/` (Trivia ViewModel).
- **Flow**:
  - Question displayed with 4 options
  - Player selects answer
  - Correct/incorrect feedback
  - Score updated

#### 2. Lucky / Wheel Stage
- **Mechanics**: Spinning wheel with weighted outcomes (prizes, penalties, multipliers).
- **Duration**: ~30–45 seconds per round.
- **Scoring**: Points determined by wheel outcome.
- **Code location**: `Screens/room/` (Wheel UI); `models/` (wheel data structures).
- **Flow**:
  - Wheel animates with random stopping point
  - Outcome calculated from segment weights
  - Bonus or penalty applied to player score

#### 3. Logic & Puzzle Stage
- **Mechanics**: Time-limited puzzles (math, pattern recognition, logic).
- **Duration**: ~45–90 seconds per puzzle.
- **Scoring**: Points awarded for correct solutions; bonuses for speed.
- **Code location**: `Screens/room/` (Puzzle screens); `models/` (puzzle data).
- **Flow**:
  - Puzzle displayed
  - Player enters answer
  - Validation and scoring

#### 4. Social Prediction Stage
- **Mechanics**: Players predict other players' answers or rankings.
- **Duration**: Two phases: answer phase (~30s) + guess phase (~30s).
- **Scoring**: Comparative scoring based on accuracy of guesses.
- **Code location**: `Screens/room/` (Social stage screens); `model_view/` (prediction logic).
- **Flow**:
  - Question shown (e.g., "How many push-ups can you do?")
  - Players answer privately
  - After answers collected, players guess other players' answers
  - Scoring based on proximity to actual answers

#### 5. Reaction Stage
- **Mechanics**: Tap-based challenges measuring speed and accuracy (Whack-a-Mole inspired).
- **Duration**: ~30 seconds of active gameplay.
- **Scoring**: Points based on taps and accuracy.
- **Code location**: `Screens/room/` (Reaction stage); sprite and animation assets in `assets/sprites/`.
- **Flow**:
  - Targets appear randomly on screen
  - Player taps targets before they disappear
  - Missed taps or slow reactions reduce score

#### 6. Strategic Decision Stage
- **Mechanics**: Prisoner's Dilemma–inspired game where players choose cooperative or competitive actions.
- **Duration**: Multiple rounds (~30s each).
- **Scoring**: Group and individual scoring based on collective choices.
- **Code location**: `Screens/room/` (Decision stage); `model_view/` (game theory logic).
- **Flow**:
  - Players choose: cooperate or defect
  - Payoff matrix applied
  - Scores updated based on choices and others' actions

---

## User System and Authentication

### Registration and Login

**Code location:** `Screens/authorization/`

- **Email-based authentication**: Users register with email and password.
- **Password recovery**: Reset link sent to registered email.
- **Session persistence**: Logged-in state saved locally using SharedPreferences or secure storage.

### User Profile

**Code location:** `model_view/user_data_view_model.dart`, `models/` (User DTO)

**Profile fields:**
- Username (display name)
- Age
- Language preference
- Avatar (built-in avatars or custom upload)
- Audio preferences (mute/unmute)
- Display preferences (brightness, text size)
- Privacy settings

**Profile image storage:** Images uploaded to Cloudinary; URL stored in Firebase.

### Session and Reconnection

- **Persistent login**: Authentication token stored locally.
- **Disconnect handling**: If connection lost during gameplay, app attempts to reconnect and restore room state.
- **Logout**: Clears local session and returns to login screen.

---

## Game Modes and Rules

### Drinking Mode

**Mechanics:**
- Global mode that applies across all stages.
- When a player loses a round or answers incorrectly, a "drink" penalty is assigned.
- Drinking counter shown on scoreboard.

**Implementation:**
- Flag in game configuration toggles the mode.
- ViewModel checks mode flag and applies penalties accordingly.
- UI displays drinking progress or counter.

**Code location:** `model_view/`, game rules engine.

### Forbidden Words Mode

**Mechanics:**
- Players are given a list of forbidden words before gameplay starts.
- During game, microphone listens for speech (STT—Speech-to-Text).
- If a forbidden word is detected, the player incurs a score penalty or drinking penalty.

**Implementation:**
- STT service (e.g., Google Cloud Speech API or Flutter's speech_recognition package) processes audio.
- Transcribed text compared against forbidden word list.
- Penalty applied if match found.

**Code location:** `model_view/`, STT integration; `models/` (ForbiddenWord DTO).

---

## Code Structure and Organization

### Directory Layout

```
nexaburst/
├── lib/
│   ├── main.dart                          # App entry point and route setup
│   ├── constants.dart                     # Global constants and config toggles
│   ├── model_view/                        # ViewModels and state management
│   │   ├── user_data_view_model.dart      # User and session state
│   │   ├── authorization/                 # Login/signup ViewModels
│   │   ├── room/                          # Room and game ViewModels
│   │   └── ...
│   ├── models/                            # Data models and DTOs
│   │   ├── authorization/                 # Auth-related DTOs (User, Session)
│   │   ├── data/                          # Game data structures
│   │   ├── structures/                    # Reusable entities (Question, Player, Score)
│   │   └── ...
│   ├── Screens/                           # UI screens and widgets
│   │   ├── authorization/                 # Login, sign-up, password recovery screens
│   │   ├── main_components/               # Home, menu, profile screens
│   │   ├── room/                          # Game room and stage screens
│   │   ├── menu/                          # Settings, pause, options screens
│   │   └── ...
│   ├── assets/texts/                      # Localization JSONs
│   │   ├── static_text.json               # UI text (buttons, labels)
│   │   ├── lv01_questions.json            # Trivia stage questions
│   │   ├── lv02_wheel.json                # Wheel stage outcomes
│   │   ├── lv03.json                      # Logic stage data
│   │   └── lv04.json                      # Social stage data
│   ├── debug/                             # Development sandbox
│   │   ├── fake_models/                   # Mock data
│   │   ├── fake_screens/                  # Test screens
│   │   ├── fake_view_model/               # Mock ViewModels
│   │   └── helpers/                       # Debug utilities
│   ├── not_using/                         # Deprecated or experimental code (kept for reference)
│   └── web/                               # Web-specific implementations
├── assets/                                # App assets
│   ├── images/                            # UI graphics, buttons, backgrounds
│   ├── sprites/                           # Game sprites and animations
│   ├── avatars/                           # User avatars
│   ├── icons/                             # App icons
│   ├── audio/                             # Sound effects and music
│   ├── texts/                             # Localization JSONs (same as lib/assets/texts)
│   └── flags/                             # Language flag icons
├── android/                               # Android platform-specific code
├── ios/                                   # iOS platform-specific code
├── web/                                   # Web platform files
├── test/                                  # Unit and widget tests
├── pubspec.yaml                           # Flutter dependencies
└── analysis_options.yaml                  # Linting rules
```

### Key Files and Their Purposes

#### `lib/main.dart`
- Initializes the app and Firebase.
- Sets up root route navigation.
- Configures theme and localization providers.

**To understand**: Start here to see app initialization flow.

#### `lib/constants.dart`
- Global toggles for debugging, sandbox mode, etc.
- Default configuration values.
- Hard-coded thresholds or timeouts.

#### `lib/model_view/user_data_view_model.dart`
- Manages global user state (logged-in user, preferences).
- Provides methods for login, signup, logout, profile updates.
- Listens to Firebase authentication changes.

**To understand**: Study this to see how app state flows between screens.

#### `lib/model_view/room/` (and other subdirectories)
- Feature-specific ViewModels (one per major feature).
- Examples: `GameRoomViewModel`, `TriviaStageViewModel`, `WheelStageViewModel`.

#### `lib/models/` (Data structures)
- Example: `Player` (player info), `Question` (trivia data), `GameRound` (round state).
- These are pure data classes with minimal logic.

#### `lib/Screens/room/`
- Game stage UI screens.
- Each stage has a screen that listens to its corresponding ViewModel.

#### `lib/debug/`
- Sandbox mode to test without Firebase.
- Fake ViewModels return mock data.
- Use this during development for fast iteration.

---

## Key Features and Implementation

### Real-Time Multiplayer (Firebase Realtime Database)

**Architecture:**
- All players in a room listen to a shared game state in Firebase.
- When one player makes a move, the state is updated in Firebase.
- Other players' clients receive updates via listeners.

**Code location:** `model_view/room/` (Firebase listeners), `models/` (data structures).

**Example flow (Trivia round):**
1. Game state: `{ stage: "trivia", currentQuestion: {...}, playerAnswers: {...} }`
2. Player A selects answer → writes to Firebase.
3. Firebase updates `playerAnswers[playerA] = "Option B"`.
4. All listening clients (Player B, C, D) receive update.
5. When timer expires or all players answer, ViewModel advances to next question.

### Animations and UI Polish

**Code location:** `Screens/` (Animated widgets, custom painters).

- **Wheel animation**: `assets/sprites/` contains wheel sprite; Flutter animation rotates it.
- **Stage transitions**: Custom page transitions between stages.
- **Score animations**: Counter animations when scores update.

**Tools used:** Flutter's `AnimationController`, `Tween`, custom `CustomPainter`.

### Localization

**System:**
- All UI text stored in JSON files in `assets/texts/`.
- Language selection persists in SharedPreferences.
- At runtime, selected language JSON is loaded; UI updates dynamically.

**Code location:** `lib/` (localization provider); `assets/texts/` (language JSONs).

**To add a new language:**
1. Create a new JSON file in `assets/texts/`.
2. Add language to supported list in constants.
3. Use scripts in `used_scripts/` to auto-generate translations if needed.

---

## Backend Integration

### Firebase

**Services used:**
- **Authentication**: Email/password sign-up and sign-in.
- **Realtime Database**: Game state, room data, player scores.
- **Storage**: User profile images (via Cloudinary redirect).

**Code location:** Integration code in `model_view/` (Firebase calls), `models/` (DTOs).

**Setup:**
- Add `google-services.json` to `android/app/` for Android.
- Add `GoogleService-Info.plist` to `ios/Runner/` for iOS.

### Third-Party APIs

**Trivia API:**
- Fetches quiz questions.
- Called when Trivia stage starts.
- Response parsed into `Question` DTO.

**Speech-to-Text (for Forbidden Words mode):**
- Uses device microphone.
- Processes audio using cloud STT service or local engine.
- Transcribed text compared against forbidden words list.

---

## Localization System

### File Structure

Each language has its own JSON file in `assets/texts/`:

```json
{
  "app_name": "NexaBurst",
  "login": "Login",
  "username": "Username",
  "password": "Password",
  "stage_trivia": "Trivia",
  "stage_wheel": "Wheel",
  ...
}
```

### Runtime Switching

- Language preference stored in SharedPreferences.
- At app startup, correct language JSON is loaded.
- UI uses localization provider to fetch text keys dynamically.
- Changing language mid-session triggers UI rebuild with new language.

### Adding New Languages

1. Create `assets/texts/lang_<code>.json` (e.g., `lang_es.json` for Spanish).
2. Add language to `constants.dart` supported languages list.
3. Use automation scripts in `used_scripts/` to bulk-generate translations.

---

## Development Sandbox and Testing

### Sandbox Mode

**Purpose:** Test app without Firebase or real multiplayer.

**Location:** `debug/` folder; toggle in `constants.dart`.

**Features:**
- Use mock ViewModels that return fake data.
- Navigate directly to any screen without authentication.
- Override timers and stage progression for fast testing.

**Example usage:**
1. Set `USE_SANDBOX = true` in `constants.dart`.
2. Run app.
3. Home screen shows "Sandbox Mode" banner.
4. Quick buttons to jump to specific stages.

### Mock Data

**Location:** `debug/fake_models/`

- `FakeGameRoomViewModel` returns hardcoded players and scores.
- `FakeTriviaViewModel` provides sample questions.
- `FakeWheelViewModel` returns preset wheel outcomes.

### Testing

**Recommended additions:**
- Unit tests for ViewModels (test state changes and calculations).
- Widget tests for critical screens (login, room creation).
- Integration tests for full game flow.

---

## Building and Running

### Prerequisites

- Flutter SDK (stable channel): https://flutter.dev
- Android Studio or VS Code with Flutter plugin
- Android SDK (for Android builds) or Xcode (for iOS builds)
- A device or emulator for testing

### Setup

```powershell
# Clone repository
git clone https://github.com/y-haviv/nexaburst-multiplayer-game.git
cd nexaburst-multiplayer-game/nexaburst

# Get dependencies
flutter pub get

# For iOS (if building for iOS)
cd ios
pod install
cd ..
```

### Running on Android

```powershell
# List available devices/emulators
flutter devices

# Run on specific device
flutter run -d <device-id>

# Or just run (uses default device)
flutter run
```

### Running on iOS

```powershell
# Run on iOS device/simulator
flutter run -d <device-id>
```

### Building for Release

**Android:**
```powershell
flutter build apk --release
# Or for App Bundle (for Google Play):
flutter build appbundle --release
```

**iOS:**
```powershell
flutter build ios --release
```

---

## Troubleshooting

### Firebase Not Configured

**Error:** `PlatformException` when trying to authenticate.

**Solution:**
1. Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in the correct location.
2. Use sandbox mode for development without Firebase.

### Emulator/Device Not Detected

**Error:** `No connected devices.`

**Solution:**
1. Ensure Android emulator is running: `flutter emulators --launch <name>`
2. Or connect physical device and enable USB debugging.
3. Run `flutter doctor` to diagnose environment issues.

### Build Errors

**Common issues:**
- **Dart syntax errors**: Run `flutter analyze`.
- **Dependency conflicts**: Run `flutter pub get` or `flutter clean && flutter pub get`.
- **Platform-specific issues**: Check iOS/Android build logs in `android/` or `ios/` folders.

### Performance Issues

**Optimization tips:**
- Use the `flutter run --profile` to profile performance.
- Check the frame rate in debug overlay (toggle with Ctrl+P).
- Reduce animation complexity or increase timers if device is slow.

### Networking/Firebase Issues

- Check that device has internet connectivity.
- Verify Firebase project credentials are correct.
- Use Firefox DevTools or Dart DevTools to inspect network requests.

---

## Next Steps for Development

1. **Add tests**: Unit tests for critical ViewModels; widget tests for screens.
2. **Enhance stages**: Extend the stage system by adding new stage types (see existing stages as templates).
3. **Optimize performance**: Profile the app and optimize hot-path code.
4. **Add CI/CD**: Set up GitHub Actions to run tests and lint checks on every PR.
5. **Refine UX**: Gather user feedback on gameplay and UI/UX refinements.

---

This README is designed to be a comprehensive reference for developers working on or reviewing the NexaBurst codebase. For questions about specific features or code sections, refer to inline code comments or explore the relevant files listed above.
