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
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
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
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppConstants.softBackgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppConstants.primaryColor,
                    child: Text(
                      user?.initial ?? '?',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                      .animate()
                      .scale(duration: 400.ms, curve: Curves.easeOutBack),
                ),
                
                const SizedBox(height: AppConstants.largePadding),
                
                // Display name
                Text(
                  user?.displayName ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 100.ms),
                
                const SizedBox(height: AppConstants.smallPadding),
                
                // Email
                if (user?.email.isNotEmpty == true)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email, size: 18, color: AppConstants.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        user!.email,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 150.ms),
                
                // Email (if available)
                if (user?.email.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: AppConstants.smallPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.email_outlined, size: 18, color: AppConstants.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          user!.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 200.ms),
                  ),
                
                const SizedBox(height: AppConstants.largePadding * 2),
                
                // Stats card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.largePadding),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Game Stats',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppConstants.defaultPadding),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatItem(
                                      icon: Icons.sports_esports,
                                      label: 'Games',
                                      value: '$_gamesPlayed',
                                    ),
                                  ),
                                  Expanded(
                                    child: _StatItem(
                                      icon: Icons.emoji_events,
                                      label: 'Wins',
                                      value: '$_wins',
                                    ),
                                  ),
                                  Expanded(
                                    child: _StatItem(
                                      icon: Icons.percent,
                                      label: 'Win Rate',
                                      value: _gamesPlayed > 0
                                          ? '${((_wins / _gamesPlayed) * 100).toStringAsFixed(0)}%'
                                          : '0%',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.1, end: 0),
                
                const Spacer(),
                
                // Logout button
                ElevatedButton.icon(
                  onPressed: _confirmLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms),
                
                const SizedBox(height: AppConstants.defaultPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }
}
