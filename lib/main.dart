import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:facecode/providers/game_provider.dart';
import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/providers/user_preferences_provider.dart';
import 'package:facecode/providers/two_truths_provider.dart';
import 'package:facecode/providers/truth_dare_provider.dart';
import 'package:facecode/screens/splash_screen.dart';
import 'package:facecode/screens/main_shell.dart';
import 'package:facecode/screens/mode_selection_screen.dart';
import 'package:facecode/screens/profile_screen.dart';
import 'package:facecode/screens/leaderboard_screen.dart';
import 'package:facecode/screens/badges_screen.dart';
import 'package:facecode/screens/games/truth_dare_screen.dart';
import 'package:facecode/screens/games/would_rather_screen.dart';
import 'package:facecode/screens/games/reaction_time_screen.dart';
import 'package:facecode/screens/games/draw_guess_screen.dart';
import 'package:facecode/screens/games/memory_cards_screen.dart';
import 'package:facecode/screens/games/simon_says_screen.dart';
import 'package:facecode/screens/games/tic_tac_toe_screen.dart';
import 'package:facecode/screens/games/fastest_finger_screen.dart';
import 'package:facecode/screens/games/two_truths_screen.dart';
import 'package:facecode/utils/theme.dart';
import 'package:facecode/utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyA5SwlDNYXKQW1nAkElIsDzQlmP7F6qA-A",
          authDomain: "facecode-411fa.firebaseapp.com",
          projectId: "facecode-411fa",
          storageBucket: "facecode-411fa.firebasestorage.app",
          messagingSenderId: "241739364015",
          appId: "1:241739364015:web:19bd0824d953ef9340865a",
          measurementId: "G-DFPQS95YEB",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // If Firebase isn't configured, app will still run but auth will show an error.
  }

  runApp(const FaceCodeApp());
}

/// Root app widget for FaceCode.
class FaceCodeApp extends StatefulWidget {
  const FaceCodeApp({super.key});

  @override
  State<FaceCodeApp> createState() => _FaceCodeAppState();
}

class _FaceCodeAppState extends State<FaceCodeApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Keep timer stable when app is backgrounded.
    try {
      final provider = context.read<GameProvider>();
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        provider.onAppPaused();
      } else if (state == AppLifecycleState.resumed) {
        provider.onAppResumed();
      }
    } catch (_) {
      // Ignore lifecycle events before Provider is ready.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => TwoTruthsProvider()),
        ChangeNotifierProvider(create: (_) => TruthDareProvider()),
        ChangeNotifierProvider(
          create: (_) => ProgressProvider()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => UserPreferencesProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, widget) {
          // Custom error widget
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
             return Scaffold(
               backgroundColor: AppConstants.backgroundColor,
               body: Center(
                 child: Padding(
                   padding: const EdgeInsets.all(20),
                   child: Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                        Icon(Icons.error_outline, color: AppConstants.errorColor, size: 48),
                        const SizedBox(height: 16),
                        const Text("Something went wrong", style: TextStyle(color: Colors.white, fontSize: 18)),
                        const SizedBox(height: 8),
                         Text(errorDetails.exceptionAsString(), 
                          style: TextStyle(color: AppConstants.textSecondary, fontSize: 12),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                        ),
                     ],
                   ),
                 ),
               ),
             );
          };
          return widget!;
        },
        title: 'FaceCode',
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
        routes: {
          '/game-hub': (context) => const MainShell(),
          '/profile': (context) => const ProfileScreen(),
          '/leaderboard': (context) => const LeaderboardScreen(),
          '/badges': (context) => const BadgesScreen(),
          '/mode-selection': (context) => const ModeSelectionScreen(),
          '/truth-dare': (context) => const TruthDareScreen(),
          '/would-rather': (context) => const WouldYouRatherScreen(),
          '/reaction-time': (context) => const ReactionTimeScreen(),
          '/draw-guess': (context) => const DrawGuessScreen(),
          '/memory-cards': (context) => const MemoryCardsScreen(),
          '/simon-says': (context) => const SimonSaysScreen(),
          '/tic-tac-toe': (context) => const TicTacToeScreen(),
          '/fastest-finger': (context) => const FastestFingerScreen(),
          '/two-truths': (context) => const TwoTruthsScreen(),
        },

      ),
    );
  }
}
