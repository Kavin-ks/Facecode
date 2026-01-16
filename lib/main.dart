import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:facecode/providers/game_provider.dart';
import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/screens/splash_screen.dart';
import 'package:facecode/utils/theme.dart';

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
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FaceCode',
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
