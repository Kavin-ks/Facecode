import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/login_screen.dart';
import 'package:facecode/services/stats_service.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/utils/app_dialogs.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _gamesPlayed = 0;
  int _wins = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    final games = await StatsService.getGamesPlayed(uid);
    final wins = await StatsService.getWins(uid);
    setState(() {
      _gamesPlayed = games;
      _wins = wins;
      _loading = false;
    });
  }

  Future<void> _confirmLogout() async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Logout', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppConstants.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppConstants.textMuted)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.pop(context, true),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final auth = context.read<AuthProvider>();
      await auth.signOut();
      if (!mounted) return;
      
      HapticFeedback.mediumImpact();
      AppDialogs.showSnack(context, 'Logged out successfully');
      
      Navigator.of(context).pushAndRemoveUntil(
        AppRoute.fadeSlide(const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0D12),
              Color(0xFF1A1A2E),
              Color(0xFF0D0D12),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor.withAlpha(150),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.borderColor),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                
                const SizedBox(height: 30),
                
                // Avatar with glow
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withAlpha(80),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: AppConstants.premiumGradient),
                        border: Border.all(
                          color: AppConstants.primaryColor.withAlpha(100),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user?.initial ?? '?',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.elasticOut)
                    .fadeIn(),
                
                const SizedBox(height: AppConstants.largePadding),
                
                // Display name with gradient
                Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: AppConstants.neonGradient,
                    ).createShader(bounds),
                    child: Text(
                      user?.displayName ?? 'User',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 100.ms),
                
                const SizedBox(height: 8),
                
                // Email
                if (user?.email.isNotEmpty == true)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor.withAlpha(100),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppConstants.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.email_outlined, size: 16, color: AppConstants.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            user!.email,
                            style: TextStyle(
                              color: AppConstants.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 150.ms),
                
                const SizedBox(height: AppConstants.xlPadding),
                
                // Stats card
                Container(
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor.withAlpha(150),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppConstants.borderColor),
                  ),
                  child: _loading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bar_chart_rounded, color: AppConstants.goldAccent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'GAME STATS',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppConstants.goldAccent,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.largePadding),
                            Row(
                              children: [
                                Expanded(
                                  child: _PremiumStatItem(
                                    icon: Icons.sports_esports,
                                    label: 'Games',
                                    value: '$_gamesPlayed',
                                    color: AppConstants.neonBlue,
                                  ),
                                ),
                                Expanded(
                                  child: _PremiumStatItem(
                                    icon: Icons.emoji_events,
                                    label: 'Wins',
                                    value: '$_wins',
                                    color: AppConstants.goldAccent,
                                  ),
                                ),
                                Expanded(
                                  child: _PremiumStatItem(
                                    icon: Icons.percent,
                                    label: 'Win Rate',
                                    value: _gamesPlayed > 0
                                        ? '${((_wins / _gamesPlayed) * 100).toStringAsFixed(0)}%'
                                        : '0%',
                                    color: AppConstants.neonPink,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: AppConstants.xlPadding),
                
                // Achievement teaser
                Container(
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor.withAlpha(100),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppConstants.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConstants.goldAccent.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: AppConstants.goldAccent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Keep Playing!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Achievements coming soon...',
                              style: TextStyle(
                                color: AppConstants.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: AppConstants.xlPadding),
                
                // Logout button
                GestureDetector(
                  onTap: _confirmLogout,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF416C).withAlpha(60),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.white, size: 22),
                        SizedBox(width: 12),
                        Text(
                          'LOGOUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms),
                
                const SizedBox(height: AppConstants.largePadding),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _PremiumStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppConstants.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
