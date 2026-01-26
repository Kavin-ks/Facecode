import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/providers/analytics_provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/utils/game_catalog.dart';
import 'package:facecode/models/game_metadata.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/login_screen.dart';
import 'package:facecode/screens/register_screen.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/widgets/daily_challenge_card.dart';
import 'package:facecode/utils/motion.dart';
// import 'package:facecode/screens/auth_gate_screen.dart';

class PublicGamesScreen extends StatelessWidget {
  const PublicGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final games = GameCatalog.allGames;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Custom Header
            _buildHeader(context, auth),

            // 2. Scrollable Content
            Expanded(
              child: ListView(
                 padding: const EdgeInsets.all(20),
                 children: [
                   // XP / Streak Bar
                   const XPStreakBar().animate().fadeIn().slideX(begin: -0.1, end: 0),
                   
                   const SizedBox(height: 16),

                   // Daily Challenge Card
                   const DailyChallengeCard(),
                   
                   const SizedBox(height: 24),
                   
                   const Text(
                     "Recommended for You",
                     style: TextStyle(
                       color: Colors.white,
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                     ),
                   ).animate().fadeIn(delay: 200.ms),
                   
                   const SizedBox(height: 12),

                   // Game Cards List
                   ...games.asMap().entries.map((entry) {
                     final index = entry.key;
                     final game = entry.value;
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 8.0),
                       child: KeepAliveWrapper(
                         child: LiveGameCard(
                           title: game.name,
                           subtitle: game.description,
                           emoji: _getEmojiForGame(game.id),
                           baseColor: _getColorForGame(game.id),
                           onTap: () => _navigateToGame(context, game, auth.isSignedIn),
                         ).animate(delay: AppMotion.stagger(index)).fadeIn(duration: AppMotion.durationMedium).slideY(begin: 0.1, end: 0, 
                             duration: AppMotion.durationMedium, curve: AppMotion.curveStandard),
                       ),
                     );
                   }),

                   const SizedBox(height: 40),
                 ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back 👋",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                auth.user?.displayName ?? "Guest Player",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // Profile Icon / Settings Row
          Row(
            children: [
              // Settings - Native IconButton
              IconButton(
                onPressed: () {
                  debugPrint('⚙️ Settings clicked');
                  Navigator.of(context).pushNamed('/settings');
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings, color: Colors.white, size: 20),
                ),
                tooltip: 'Settings',
              ),

              const SizedBox(width: 4),

              // Profile - Native IconButton
              IconButton(
                onPressed: () {
                  debugPrint('👤 Profile clicked');
                  if (auth.isSignedIn && !auth.user!.isAnonymous) {
                    Navigator.of(context).pushNamed('/profile');
                  } else {
                    _showAuthPrompt(context, reason: "Login to view your full profile.");
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppConstants.primaryColor, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
                tooltip: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getEmojiForGame(String id) {
    if (id.contains('truth')) return '🎲';
    if (id.contains('draw')) return '🎨';
    if (id.contains('would')) return '🤔';
    if (id.contains('two')) return '🤥';
    if (id.contains('fast')) return '⚡';
    if (id.contains('simon')) return '🧠';
    return '🎮';
  }

  Color _getColorForGame(String id) {
    if (id.contains('truth')) return const Color(0xFFE94560);
    if (id.contains('draw')) return Colors.purple.shade900;
    if (id.contains('would')) return Colors.blue.shade900;
    if (id.contains('two')) return Colors.teal.shade900;
    return const Color(0xFF2A2A2A);
  }

  void _navigateToGame(BuildContext context, GameMetadata game, bool isSignedIn) {
    // Track game start
    context.read<AnalyticsProvider>().trackGameStart(game.id);
    Navigator.of(context).pushNamed(game.route);
  }

  static void _showAuthPrompt(BuildContext context, {required String reason}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Unlock full access', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 8),
                Text(reason, style: const TextStyle(color: AppConstants.textSecondary)),
                const SizedBox(height: 20),
                
                AddictivePrimaryButton(
                  label: "SIGN UP NOW",
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(AppRoute.fadeSlide(const RegisterScreen()));
                  },
                ),
                
                const SizedBox(height: 12),
                
                TextButton(
                  onPressed: () {
                     Navigator.of(context).pop();
                     Navigator.of(context).push(AppRoute.fadeSlide(const LoginScreen()));
                  },
                  child: const Text("I already have an account"),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
