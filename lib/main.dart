import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:facecode/providers/game_provider.dart';
import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/providers/user_preferences_provider.dart';
import 'package:facecode/providers/settings_provider.dart'; // Added
import 'package:facecode/providers/two_truths_provider.dart';
import 'package:facecode/providers/truth_dare_provider.dart';
import 'package:facecode/providers/shop_provider.dart';
import 'package:facecode/providers/elite_provider.dart';
import 'package:facecode/providers/analytics_provider.dart';
import 'package:facecode/screens/splash_screen.dart';
import 'package:facecode/screens/main_shell.dart';
import 'package:facecode/screens/mode_selection_screen.dart';
import 'package:facecode/screens/profile_screen.dart';
import 'package:facecode/screens/leaderboard_screen.dart';
import 'package:facecode/screens/badges_screen.dart';
import 'package:facecode/screens/games/truth_dare_screen.dart';
import 'package:facecode/screens/games/would_rather_screen.dart';
import 'package:facecode/screens/games/reaction_time_screen.dart';
import 'package:facecode/screens/games/draw_guess_screen_v2.dart';
import 'package:facecode/screens/games/memory_cards_screen.dart';
import 'package:facecode/screens/games/simon_says_screen.dart';
import 'package:facecode/screens/games/tic_tac_toe_screen.dart';
import 'package:facecode/screens/games/fastest_finger_screen.dart';
import 'package:facecode/screens/games/two_truths_screen.dart';
import 'package:facecode/models/cosmetic_item.dart';
import 'package:facecode/utils/theme.dart';
import 'package:facecode/screens/landing_screen.dart';
import 'package:facecode/screens/public_games_screen.dart';
import 'package:facecode/screens/login_screen.dart';
import 'package:facecode/screens/auth_gate_screen.dart';
import 'package:facecode/screens/settings_screen.dart';
import 'package:facecode/screens/shop/cosmetic_shop_screen.dart';
import 'package:facecode/screens/elite/elite_landing_screen.dart';
import 'package:facecode/services/sound_navigation_observer.dart';
import 'package:facecode/services/error_handler_service.dart';
import 'package:facecode/services/network_connectivity_service.dart';
import 'package:facecode/widgets/error_boundary.dart';
import 'package:facecode/widgets/network_status_banner.dart';

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

  // Initialize global error handling
  ErrorHandlerService.initialize();

  // Initialize network connectivity monitoring
  await NetworkConnectivityService().initialize();

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
        ChangeNotifierProxyProvider<ProgressProvider, ShopProvider>(
          create: (context) => ShopProvider(context.read<ProgressProvider>()),
          update: (context, progress, previous) => ShopProvider(progress),
        ),
        ChangeNotifierProxyProvider<ProgressProvider, EliteProvider>(
          create: (context) => EliteProvider(context.read<ProgressProvider>()),
          update: (context, progress, previous) => EliteProvider(progress),
        ),
        ChangeNotifierProvider(create: (_) => UserPreferencesProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()), // Added
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => NetworkConnectivityService()),
      ],
      // We use a Builder to access the SettingsProvider from the context below MultiProvider
      child: Builder(
        builder: (context) {
          final settings = context.watch<SettingsProvider>();
          final progress = context.watch<ProgressProvider>().progress;
          
          // Determine cosmetic palette
          Map<String, Color>? cosmeticPalette;
          AppThemeMode modeToUse = settings.themeMode;

          final equippedThemeId = progress.equippedItems[CosmeticType.theme.name];
          if (equippedThemeId != null) {
            final themeItem = CosmeticItem.allItems.firstWhere((i) => i.id == equippedThemeId);
            if (themeItem.metadata != null) {
              cosmeticPalette = Map<String, Color>.from(themeItem.metadata!);
              modeToUse = AppThemeMode.cosmetic;
            }
          }

          // Apply equipped Sound Pack
          final equippedSoundPackId = progress.equippedItems[CosmeticType.soundPack.name];
          // We call this in build which is a bit unconventional but common for global side effects in Flutter
          // when reacting to state changes that affect non-UI services.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            settings.setSoundPack(equippedSoundPackId);
          });

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            // Dynamic Theme
            theme: AppTheme.getTheme(
              modeToUse, 
              accentColor: settings.accentColor,
              customPalette: cosmeticPalette,
            ),
            navigatorObservers: [SoundNavigationObserver()],
            
            builder: (context, widget) {
              // Wrap entire app in error boundary and network status banner
              return Stack(
                children: [
                  ErrorBoundary(
                    context: 'App Root',
                    child: widget ?? const SizedBox.shrink(),
                  ),
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: NetworkStatusBanner(),
                  ),
                ],
              );
            },
            title: 'FaceCode',
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/': (context) => const LandingScreen(),
              '/public-games': (context) => const PublicGamesScreen(),
              '/main': (context) => const MainShell(),
              '/modes': (context) => const ModeSelectionScreen(),
              '/settings': (context) => const SettingsScreen(), // Added
              '/shop': (context) => const CosmeticShopScreen(),
              '/elite': (context) => const EliteLandingScreen(),
              
              // Auth Routes
              '/login': (context) => const LoginScreen(),
              
              // Feature Routes with Route Guards
              '/profile': (context) {
                final user = context.read<AuthProvider>().user;
                if (user == null || user.isAnonymous) return const AuthGateScreen(message: "Sign in to view your profile and stats");
                return const ProfileScreen();
              },
              '/leaderboard': (context) {
                 final user = context.read<AuthProvider>().user;
                 if (user == null || user.isAnonymous) return const AuthGateScreen(message: "Sign in to compete on the leaderboard");
                 return const LeaderboardScreen();
              },
              '/badges': (context) {
                 final user = context.read<AuthProvider>().user;
                 if (user == null || user.isAnonymous) return const AuthGateScreen(message: "Sign in to earn and view badges");
                 return const BadgesScreen();
              },

              // Game Routes
              '/game-truth-dare': (context) => const TruthDareScreen(),
              '/game-would-rather': (context) => const WouldYouRatherScreen(),
              '/game-reaction': (context) => const ReactionTimeScreen(),
              '/game-draw-guess': (context) => const DrawGuessScreen(),
              '/game-memory': (context) => const MemoryCardsScreen(),
              '/game-simon': (context) => const SimonSaysScreen(),
              '/game-tictactoe': (context) => const TicTacToeScreen(),
              '/game-fastest': (context) => const FastestFingerScreen(),
              '/game-two-truths': (context) => const TwoTruthsScreen(),

              // Legacy/catalog route aliases (used by GameCatalog.game.route)
              '/mode-selection': (context) => const ModeSelectionScreen(),
              '/truth-dare': (context) => const TruthDareScreen(),
              '/would-rather': (context) => const WouldYouRatherScreen(),
              '/two-truths': (context) => const TwoTruthsScreen(),
              '/reaction-time': (context) => const ReactionTimeScreen(),
              '/fastest-finger': (context) => const FastestFingerScreen(),
              '/memory-cards': (context) => const MemoryCardsScreen(),
              '/simon-says': (context) => const SimonSaysScreen(),
              '/tic-tac-toe': (context) => const TicTacToeScreen(),
              '/draw-guess': (context) => const DrawGuessScreen(),

            },
          );
        }
      ),
    );
  }
}
