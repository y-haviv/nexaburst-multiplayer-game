// Nexaburst/lib/main.dart

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/authorization/login/login_screen.dart';
import 'package:nexaburst/Screens/authorization/signup/signup_screen.dart';
import 'package:nexaburst/Screens/authorization/Welcome/welcome_screen.dart';
import 'package:nexaburst/Screens/menu/avatars/avater_pic_screen.dart';
import 'package:nexaburst/Screens/menu/home_settings_screen.dart';
import 'package:nexaburst/Screens/menu/menu_screen.dart';
import 'package:nexaburst/constants.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nexaburst/model_view/authorization/auth_manager.dart';
import 'package:nexaburst/model_view/authorization/auth_manager_interface.dart';
import 'package:nexaburst/model_view/room/game/Levels/level_factory/game_levels_factory_manager.dart';
import 'package:nexaburst/model_view/room/game/presence_view_model.dart';
import 'package:nexaburst/model_view/room/players_view_model/players_interface.dart';
import 'package:nexaburst/model_view/room/players_view_model/players_view_model.dart';
import 'package:nexaburst/model_view/room/waiting_room/start_game_interface.dart';
import 'package:nexaburst/model_view/room/waiting_room/start_game_view_model.dart';
import 'package:nexaburst/debug/fake_screens/debug_loading_overlay.dart';
import 'package:nexaburst/debug/fake_view_model/fake_auth_manager.dart';
import 'package:nexaburst/debug/fake_view_model/fake_players_view.dart';
import 'package:nexaburst/debug/fake_models/fake_start_game_service.dart';
import 'package:nexaburst/model_view/room/sync_manager.dart';
import 'package:nexaburst/model_view/room/time_manager.dart';
import 'package:nexaburst/debug/helpers/command_registry.dart';
import 'package:nexaburst/models/data/server/modes/drinking/drink_manager.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Conditional import
import 'package:nexaburst/web/web_utils_stub.dart'
    if (dart.library.html) 'package:nexaburst/web/web_utils_web.dart'
    as html;

/*
# for debug builds
flutter run \
  --dart-define=DEBUG_MODE=true

# for release builds
flutter build apk --release \
  --dart-define=DEBUG_MODE=false

*/

/// Global key used to control navigation during debug sessions.
final GlobalKey<NavigatorState> debugNavKey = GlobalKey<NavigatorState>();

/// Entry point of the application.
///
/// Initializes essential services like Firebase, user data,
/// synchronization, game logic, and debug tools. Then launches
/// the app inside a guarded error zone to catch unhandled exceptions.
void main() async {
  runZonedGuarded(
    () async {
      /// Ensures that the Flutter engine is fully initialized before using plugins or framework-dependent features.
      WidgetsFlutterBinding.ensureInitialized();

      final bool dm = debug;

      /// Customizes debug print behavior for web to log to browser console.

      debugPrint = (String? message, {int? wrapWidth}) {
        html.logToConsole(message);
      };

      /// Initializes Firebase only if not in debug mode.
      ///
      /// Web and non-web environments are handled separately.

      if (!dm) {
        if (Firebase.apps.isEmpty) {
          if (kIsWeb) {
            /// Loads environment variables from the .env file for configuration, such as Firebase keys.
            await dotenv.load(fileName: ".env");
            await Firebase.initializeApp(
              options: FirebaseOptions(
                apiKey: dotenv.env['FIREBASE_API_KEY']!,
                authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
                projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
                storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
                messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
                appId: dotenv.env['FIREBASE_APP_ID']!,
                databaseURL: dotenv.env['FIREBASE_DATABASE_URL']!,
              ),
            );
          } else {
            await Firebase.initializeApp();
          }
        }
      }

      /// Initializes user data, synchronization, timing, and other game-related services.
      ///
      /// Behavior may differ between debug and release modes.

      SyncManager.init(isDebug: dm);
      TimerManager.init(isDebug: dm);
      DrinkManager.init(isDebug: dm);
      GameLevelsFactoryManager.init(isDebug: dm);
      PresenceManager.configure(debugMode: dm);

      /// Overrides Flutter's default error handling to log errors to the console.
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
      };

      /// Launches the Flutter application with the appropriate service providers.
      ///
      /// Depending on the mode, uses real or fake implementations for core services.
      runApp(
        ChangeNotifierProvider.value(
          value: UserData.instance,
          child: MultiProvider(
            providers: [
              Provider<AuthManagerInterface>(
                create: (_) => dm ? FakeAuthManager() : AuthManager(),
              ),
              Provider<IStartGameService>(
                create: (_) =>
                    dm ? FakeStartGameService() : StartGameViewModelLogic(),
              ),
              Provider<Players>(
                create: (_) => dm ? FakePlayersView() : PlayersViewModel(),
              ),
            ],
            child: const MyApp(),
          ),
        ),
      );
    },
    (Object error, StackTrace stack) {
      debugPrint('🛑 Unhandled zone error:\n$error\n$stack');
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// The root widget of the application.
///
/// Builds the main `MaterialApp` and determines initial screen,
/// localization, theming, and navigation.
class _MyAppState extends State<MyApp> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = UserData.instance.init(debugMode: debug);

    if (debug) {
      /// Starts the command registry, used in debug mode for injecting and triggering debug commands.
      CommandRegistry.instance.start();

      /// Initializes the debug loading overlay, which can simulate loading states for testing.
      DebugLoadingOverlay.instance.init();
    }
  }

  /// Builds the `MaterialApp` with localization, routing, and UI theme settings.
  ///
  /// Determines the initial screen based on the user's login state.

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(home: SplashScreen());
        }

        final user = UserData.instance.user;
        final langCode = user?.language ?? 'en';

        return MaterialApp(
          debugShowMaterialGrid: false,
          showSemanticsDebugger: false,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => child!,

          navigatorKey: debugNavKey,
          locale: Locale(langCode),
          supportedLocales: TranslationService.instance.supportedLocales,

          /// Chooses the app locale based on the device's language settings.
          ///
          /// Defaults to English if no match is found.
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (deviceLocale == null) return const Locale('en');
            return supportedLocales.firstWhere(
              (l) => l.languageCode == deviceLocale.languageCode,
              orElse: () => const Locale('en'),
            );
          },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          title: 'Nexaburst',
          theme: ThemeData(
            primaryColor: AppColors.kPrimaryColor,
            scaffoldBackgroundColor: Colors.transparent,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                foregroundColor: Colors.white,
                backgroundColor: AppColors.kPrimaryColor,
                shape: const StadiumBorder(),
                maximumSize: const Size(double.infinity, 56),
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: AppColors.kPrimaryLightColor,
              iconColor: AppColors.kPrimaryColor,
              prefixIconColor: AppColors.kPrimaryColor,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppNumbers.defaultPadding,
                vertical: AppNumbers.defaultPadding,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          /// Chooses the initial screen based on the user's data:
          /// - Shows a splash screen while initializing
          /// - Shows the main menu if the user is logged in
          /// - Otherwise, shows the welcome screen
          home: user != null ? const Menu() : const WelcomeScreen(),

          /// Defines the named navigation routes in the app.
          ///
          /// More screens will be added here as development progresses.
          routes: {
            '/welcome': (_) => const WelcomeScreen(),
            '/signup': (_) => const SignUpScreen(),
            '/login': (_) => const LoginScreen(),
            '/menu': (_) => const Menu(),
            '/privateSetting': (_) => const PrivacySettingsScreen(),
            '/avatar': (_) => AvatarScreen(),
          },
        );
      },
    );
  }
}

/// A temporary loading screen shown while user data is being initialized.
///
/// Displays a circular loading indicator in the center.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// Builds the splash screen with a loading spinner.
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
