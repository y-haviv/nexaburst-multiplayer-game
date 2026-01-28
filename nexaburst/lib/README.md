# NexaBurst Application Core (`lib/` Directory)

## Overview

This directory contains the complete Flutter application logic, UI, state management, and data models. The codebase follows the **MVVM (Model-View-ViewModel)** architectural pattern for clean separation of concerns.

---

## Directory Structure

```
lib/
├── main.dart                    # Application entrypoint and route configuration
├── constants.dart               # App-wide constants, themes, and configuration
│
├── Screens/                     # UI Layer (Views) - Feature-based organization
│   ├── authorization/           # Auth screens (login, signup, welcome)
│   ├── menu/                    # Main menu screens (home, settings, avatars)
│   ├── room/                    # Game room and lobby screens
│   └── [game_stages]/           # Individual game stage UIs
│
├── model_view/                  # ViewModel Layer - Business logic and state
│   ├── authorization/
│   │   ├── auth_manager.dart    # Authentication state and logic
│   │   └── auth_manager_interface.dart  # Abstract interface for testing
│   │
│   ├── room/
│   │   ├── players_view_model/  # Player state and management
│   │   ├── game/                # Game logic and stage management
│   │   │   └── Levels/          # Individual game stage logic
│   │   ├── waiting_room/        # Room lobby state
│   │   ├── sync_manager.dart    # Real-time Firebase synchronization
│   │   └── time_manager.dart    # Turn/round timing logic
│   │
│   ├── user_data_view_model.dart # Global user profile and settings
│   └── [feature]_view_model.dart  # Feature-specific ViewModels
│
├── models/                      # Model Layer - Data structures and DTOs
│   ├── authorization/
│   │   ├── user_model.dart      # User profile and auth data
│   │   └── credentials.dart     # Login/signup request models
│   │
│   ├── data/
│   │   ├── game_round.dart      # Round configuration and state
│   │   ├── player.dart          # Player profile and stats
│   │   ├── room.dart            # Game room data
│   │   └── [entity].dart        # Other domain models
│   │
│   ├── structures/              # Complex nested data structures
│   │   ├── game_stage_state.dart   # Stage-specific game state
│   │   └── [structure].dart     # Other structured models
│   │
│   ├── server/                  # Server-side models and modes
│   │   ├── modes/               # Game modes (drinking, forbidden words, etc.)
│   │   └── [server_entity].dart # Firebase schema models
│   │
│   └── [entity_type]/           # Organized by domain
│
├── debug/                       # Development & Testing Tools
│   ├── fake_models/             # Mock data for testing
│   │   ├── fake_player.dart     # Fake player data
│   │   └── [fake_entity].dart   # Other mock entities
│   │
│   ├── fake_view_model/         # Mock ViewModels
│   │   ├── fake_auth_manager.dart
│   │   └── [fake_vm].dart       # Other mock ViewModels
│   │
│   ├── fake_screens/            # Standalone debug screens
│   │   └── debug_test_screen.dart
│   │
│   ├── helpers/
│   │   ├── command_registry.dart # Debug command system
│   │   └── debug_utils.dart     # Debug utilities
│   │
│   └── debug_loading_overlay.dart  # Debug UI overlay
│
├── web/                         # Web platform-specific code
│   ├── web_utils_web.dart       # Actual web implementations
│   ├── web_utils_stub.dart      # Platform-agnostic stub
│   └── [web_feature].dart       # Web-specific features
│
├── not_using/                   # Deprecated/Archived code
│   └── [old_feature].dart       # Code removed from active flow
│
└── assets/                      # In-app assets (see nexaburst/assets/)
    └── [embedded resources]
```

---

## Architectural Pattern: MVVM

### Layer Responsibilities

#### **Model Layer** (`models/`)
- **Pure data representations** without business logic
- Handles serialization/deserialization (JSON ↔ Dart objects)
- Immutable where possible (consider `@immutable` or freezed)
- Represents domain entities (User, Room, GameRound, etc.)

```dart
// Example
class Player {
  final String id;
  final String name;
  final int score;
  
  Player({required this.id, required this.name, this.score = 0});
  
  factory Player.fromJson(Map<String, dynamic> json) { /*...*/ }
  Map<String, dynamic> toJson() { /*...*/ }
}
```

#### **ViewModel Layer** (`model_view/`)
- **Business logic and state management**
- Orchestrates data flow between UI and models
- Manages Firebase interactions and synchronization
- Handles user input validation and processing
- Uses Provider for reactive updates

```dart
// Example
class AuthManager extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  User? _currentUser;
  
  User? get currentUser => _currentUser;
  
  Future<void> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = result.user;
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
}
```

#### **View Layer** (`Screens/`)
- **UI presentation only**
- Minimal business logic
- Reads state from ViewModels via Provider
- Triggers ViewModel methods on user interaction
- Leverages Flutter widgets for responsiveness

```dart
// Example
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthManager>(
      builder: (context, authManager, _) {
        return Scaffold(
          body: LoginForm(
            onLogin: (email, password) {
              authManager.login(email, password);
            },
          ),
        );
      },
    );
  }
}
```

---

## Key Features & Components

### 1. **Authentication System** (`model_view/authorization/`)

Manages user registration, login, and session persistence.

- `auth_manager.dart` — Main authentication logic
- Firebase Auth integration
- Secure token storage with `flutter_secure_storage`
- Session validation and auto-logout

### 2. **Multiplayer Room System** (`model_view/room/`)

Handles game room creation, joining, and player synchronization.

**Key Components:**
- `players_view_model/` — Player list and state
- `waiting_room/` — Lobby and game start logic
- `sync_manager.dart` — Real-time Firebase Realtime Database sync
- `time_manager.dart` — Turn and round timing

### 3. **Game Stage System** (`model_view/room/game/Levels/`)

Extensible architecture for adding game stages.

**Pattern:**
```
Levels/
├── level_factory/
│   └── game_levels_factory_manager.dart  # Factory for creating stages
├── Lv01_Trivia/
├── Lv02_Wheel/
├── Lv03_Logic/
├── Lv04_SocialPrediction/
├── Lv05_Reaction/
└── Lv06_StrategicDecision/
```

Each stage has:
- Logic ViewModel (game rules, scoring)
- UI Screens (game presentation)
- Models (stage-specific data)
- Scoring system

### 4. **Localization System** (`models/data/service/translation_controllers.dart`)

Manages multi-language support (100+ languages).

- JSON-based translation loading
- Dynamic language switching
- Per-stage translation management
- Fallback to English for missing translations

### 5. **Game Modes** (`models/server/modes/`)

Extensible mode system for game rule variations.

**Current Modes:**
- **Drinking Mode** — Special scoring and challenges
- **Forbidden Words Mode** — Speech-to-text detection

**Architecture:**
```dart
abstract class GameMode {
  void applyRules(GameRound round);
  int calculateScore(PlayerAction action);
}

class DrinkingMode extends GameMode { /*...*/ }
class ForbiddenWordsMode extends GameMode { /*...*/ }
```

### 6. **Debug Sandbox** (`debug/`)

Development environment for rapid iteration without backend.

**Features:**
- Fake data generation (`fake_models/`)
- Mock ViewModels (`fake_view_model/`)
- Command registry for debug shortcuts
- Debug overlay for testing

**Usage:**
```dart
// Build with debug mode
flutter run --dart-define=DEBUG_MODE=true

// Access debug commands from debug panel
DebugCommandRegistry.execute('jump_to_screen', 'GameStage');
```

---

## Design Patterns Used

### 1. **MVVM (Model-View-ViewModel)**
Clear separation of UI from business logic.

### 2. **Factory Pattern**
`game_levels_factory_manager.dart` creates game stages dynamically.

### 3. **Strategy Pattern**
Game modes implement different rule sets.

### 4. **Singleton Pattern**
Auth manager and other singletons for app-wide state.

### 5. **Observer Pattern**
Provider for reactive state management.

### 6. **Dependency Injection**
Provider injection for testability.

### 7. **Interface Segregation**
Abstract interfaces (`*_interface.dart`) for mocking and testing.

---

## State Management with Provider

### Setup
```dart
// main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthManager()),
    ChangeNotifierProvider(create: (_) => PlayersViewModel()),
    ChangeNotifierProvider(create: (_) => UserDataViewModel()),
    // ... more providers
  ],
  child: MyApp(),
)
```

### Consuming State
```dart
// Read-only
final authManager = context.read<AuthManager>();

// Reactive watching
Consumer<AuthManager>(
  builder: (context, authManager, _) {
    return Text('User: ${authManager.currentUser?.email}');
  },
)

// Listening for changes
context.listen<AuthManager>(
  (previous, current) {
    if (current.currentUser != previous.currentUser) {
      // Navigate on login
    }
  },
)
```

---

## Testing

### Unit Tests
Test ViewModels with fake dependencies:

```dart
// test/model_view/auth_manager_test.dart
void main() {
  test('login updates currentUser', () async {
    final authManager = AuthManager();
    // Use fake auth provider
    await authManager.login('test@test.com', 'password');
    expect(authManager.currentUser, isNotNull);
  });
}
```

### Widget Tests
Test UI with mock ViewModels:

```dart
// test/screens/login_screen_test.dart
testWidgets('login button calls authManager.login', (tester) async {
  final mockAuth = FakeAuthManager();
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthManager>(
      create: (_) => mockAuth,
      child: MyApp(),
    ),
  );
  
  await tester.tap(find.byKey(Key('loginButton')));
  expect(mockAuth.loginCalled, isTrue);
});
```

### Debug Utilities
Use fake models for rapid prototyping:

```dart
// In debug mode
final fakePlayer = FakePlayer.random();
final fakeRoom = FakeGameRoom(players: [fakePlayer]);
```

---

## Performance Considerations

### Optimization Tips

1. **Use `const` constructors** for widgets
2. **Memoize expensive computations** with Provider's `.watch()`
3. **Lazy load** screens and data
4. **Use `RepaintBoundary`** for expensive widget trees
5. **Profile with DevTools** — https://flutter.dev/docs/development/tools/devtools

### Firebase Optimization

- Index critical queries
- Paginate large result sets
- Cache frequently accessed data
- Use transactions for consistency

---

## Adding New Features

### Step-by-Step Guide

#### 1. Create Model
```dart
// lib/models/my_entity.dart
class MyEntity {
  final String id;
  final String name;
  // ...
}
```

#### 2. Create ViewModel
```dart
// lib/model_view/my_entity_view_model.dart
class MyEntityViewModel extends ChangeNotifier {
  final _repo = MyEntityRepository();
  MyEntity? _entity;
  
  MyEntity? get entity => _entity;
  
  Future<void> load(String id) async {
    _entity = await _repo.get(id);
    notifyListeners();
  }
}
```

#### 3. Register in Provider
```dart
// lib/main.dart
ChangeNotifierProvider(create: (_) => MyEntityViewModel()),
```

#### 4. Create UI
```dart
// lib/Screens/my_entity_screen.dart
Consumer<MyEntityViewModel>(
  builder: (context, vm, _) {
    return Text(vm.entity?.name ?? 'Loading...');
  },
)
```

#### 5. Add Tests
```dart
// test/model_view/my_entity_view_model_test.dart
test('load fetches entity', () async {
  // Test implementation
});
```

---

## Code Standards

### Naming Conventions
- **Classes**: PascalCase (e.g., `AuthManager`, `PlayerViewModel`)
- **Files**: snake_case (e.g., `auth_manager.dart`)
- **Variables/Methods**: camelCase (e.g., `currentUser`, `fetchPlayers()`)
- **Constants**: camelCase with `const` prefix (e.g., `const maxPlayers = 4;`)

### File Organization
- One class per file (exceptions for small related classes)
- Imports sorted (dart, package, relative)
- Documentation comments (///) for public APIs

### Code Style
```bash
# Format code
flutter format lib/

# Analyze for issues
flutter analyze

# Run tests
flutter test
```

---

## Documentation

- Inline comments for complex logic
- Doc comments (///) for public APIs
- README.md at directory level for complex features
- Type annotations for all variables and parameters

---

## Troubleshooting

### Common Issues

**Provider value not updating:**
- Ensure ViewModels extend `ChangeNotifier`
- Call `notifyListeners()` after state changes

**Firebase sync issues:**
- Check `sync_manager.dart` for connection status
- Verify Firebase security rules allow operations

**Memory leaks:**
- Dispose providers properly
- Test with DevTools memory profiler

**Navigation errors:**
- Check route names match `main.dart` routing
- Verify ViewModels are provided at correct scope

---

## Resources

- [MVVM Pattern Guide](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel)
- [Provider Documentation](https://pub.dev/packages/provider)
- [Flutter Architecture Best Practices](https://flutter.dev/docs/app-architecture)
- [Firebase for Flutter](https://firebase.flutter.dev/)

---

*Last Updated: 2026-01-28*
