import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/models/badge_data.dart';
import 'package:facecode/providers/analytics_provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/settings/edit_profile_screen.dart';
import 'package:facecode/screens/settings/notifications_screen.dart';
import 'package:facecode/screens/settings/privacy_screen.dart';
import 'package:facecode/screens/settings/help_support_screen.dart';
import 'package:facecode/screens/login_screen.dart';
import 'package:facecode/utils/app_dialogs.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:facecode/screens/engagement_dashboard_screen.dart';
import 'package:facecode/screens/admin/admin_debug_dashboard.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:facecode/widgets/badge_frame.dart';
import 'package:facecode/models/cosmetic_item.dart';

/// Modern Profile Screen matching Play Store game hub style
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>().progress;
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.displayName ?? 'Player';
    final userAvatar = auth.user?.avatarEmoji ?? (auth.user?.initial ?? '🙂');

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  PremiumIconButton(
                    icon: Icons.shopping_bag_outlined,
                    onPressed: () => Navigator.of(context).pushNamed('/shop'),
                    tooltip: 'Cosmetic Shop',
                  ),
                  const SizedBox(width: 8),
                  PremiumIconButton(
                    icon: Icons.share_rounded,
                    onPressed: () {
                      // Placeholder for share functionality
                      AppDialogs.showSnack(context, 'Sharing profile...');
                    },
                    tooltip: 'Share Profile',
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Profile Card
              _buildProfileCard(context, progress, userName, userAvatar),
              
              const SizedBox(height: 20),
              
              // XP Progress Card
              _buildXpProgressCard(context, progress),
              
              const SizedBox(height: 20),
              
              // Stats Grid
              _buildStatsGrid(context, progress),
              
              const SizedBox(height: 12),
              
              // Secondary Stats
              _buildStatRow(context, progress),
              
              const SizedBox(height: 24),

              // Best Games
              _buildBestGamesList(context, progress),

              const SizedBox(height: 24),

              // Badges
              _buildBadgesGrid(context, progress),

              const SizedBox(height: 24),
              
              // Menu Options
              _buildMenuSection(context),
              
              const SizedBox(height: 24),
              
              // Logout Button
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic progress, String userName, String userInitial) {
    return GlassCard(
      radius: 20,
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onLongPress: () {
              HapticFeedback.heavyImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDebugDashboard()),
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.primaryColor.withAlpha(40),
                    AppConstants.cardPink.withAlpha(40),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppConstants.primaryColor.withAlpha(50),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(userInitial, style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.3)).scaleXY(begin: 1.0, end: 1.05, duration: 2.seconds, curve: Curves.easeInOut),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (progress.activeDailyTitles.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _buildDailyBestBadge(context),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      progress.playerRank.icon,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      progress.playerRank.label.toUpperCase(),
                      style: TextStyle(
                        color: progress.playerRank.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  progress.lastPlayedDate == null ? 'New player' : 'Active streak: ${progress.currentStreak} days',
                  style: const TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.military_tech_rounded,
                        color: AppConstants.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Level ${progress.level}',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!progress.isElite) ...[
                  const SizedBox(width: 8),
                  AddictiveSecondaryButton(
                    label: 'ELITE',
                    onTap: () => Navigator.of(context).pushNamed('/elite'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpProgressCard(BuildContext context, dynamic progress) {
    final progressPercent = progress.currentXP / progress.xpForNextLevel;
    
    return GlassCard(
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP Progress',
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${progress.currentXP} / ${progress.xpForNextLevel}',
                style: TextStyle(
                  color: AppConstants.accentGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 10,
              backgroundColor: AppConstants.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${progress.xpForNextLevel - progress.currentXP} XP until Level ${progress.level + 1}',
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid(BuildContext context, dynamic progress) {
    const badges = BadgeData.allBadges;

    return GlassCard(
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Badges',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
            physics: const NeverScrollableScrollPhysics(),
            children: badges.map((badge) {
              final earned = progress.badges.contains(badge.id);
              final equippedFrameId = progress.equippedItems[CosmeticType.badgeFrame.name];
              final equippedFrame = equippedFrameId != null ? CosmeticItem.allItems.firstWhere((i) => i.id == equippedFrameId) : null;

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: earned ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: earned ? badge.color.withValues(alpha: 0.6) : Colors.white10,
                    width: earned ? 1.5 : 1,
                  ),
                  boxShadow: earned ? [
                    BoxShadow(color: badge.color.withValues(alpha: 0.2), blurRadius: 8),
                  ] : null,
                ),
                child: Opacity(
                  opacity: earned ? 1.0 : 0.4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BadgeFrame(
                        frameItem: earned ? equippedFrame : null,
                        isEarned: earned,
                        child: Text(badge.icon, style: const TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        badge.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: earned ? badge.color : AppConstants.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                       Text(
                        badge.description,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppConstants.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, dynamic progress) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '🎮',
            '${progress.totalGamesPlayed}',
            'Games Played',
            AppConstants.cardBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '🏆',
            '${progress.totalWins}',
            'Total Wins',
            AppConstants.accentGold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '🔥',
            '${progress.currentStreak}',
            'Day Streak',
            AppConstants.cardOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, dynamic progress) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Best Streak', '${progress.longestStreak}'),
          Container(height: 40, width: 1, color: Colors.white12),
          _buildStatItem('Avg Session', '${context.watch<AnalyticsProvider>().averageSessionLengthMinutes.toStringAsFixed(1)}m'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: AppConstants.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBestGamesList(BuildContext context, dynamic progress) {
    // Sort games by wins
    final winsMap = Map<String, int>.from(progress.gameWins);
    
    if (winsMap.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Best Played',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Container(
             width: double.infinity,
             padding: const EdgeInsets.all(24),
             decoration: BoxDecoration(
               color: AppConstants.surfaceColor,
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
             ),
             child: Column(
               children: [
                 const Icon(Icons.videogame_asset_outlined, color: Colors.white54, size: 32),
                 const SizedBox(height: 12),
                 const Text("No history yet", style: TextStyle(color: Colors.white70)),
                 const SizedBox(height: 12),
                 AddictiveSecondaryButton(
                   label: "Start Playing!",
                   onTap: () => Navigator.of(context).pop(), // Go back to home
                 ),
               ],
             ),
          ),
        ],
      );
    }

    final sortedEntries = winsMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topGames = sortedEntries.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Best Played',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: topGames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final entry = topGames[index];
              final gameId = entry.key;
              final wins = entry.value;
              // Clean up ID for display (game-would_rather -> Would Rather)
              String name = gameId.replaceAll('game-', '').replaceAll('_', ' ').capitalize();
              if (name == "Reflex") name = "Reaction Time"; // Manual fix for clean name

              return Container(
                width: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$wins Wins',
                      style: const TextStyle(
                        color: AppConstants.accentGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                     Text(
                      'Best Streak: ${progress.gameBestStreak[gameId] ?? 0}',
                      style: TextStyle(
                        color: AppConstants.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.workspace_premium_rounded,
          label: 'Facecode Elite',
          onTap: () => Navigator.of(context).pushNamed('/elite'),
        ),
        _buildMenuItem(
          icon: Icons.storefront_outlined,
          label: 'Cosmetic Shop',
          onTap: () => Navigator.of(context).pushNamed('/shop'),
        ),
        _buildMenuItem(
          icon: Icons.insights_rounded,
          label: 'Engagement Insights',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EngagementDashboardScreen()),
          ),
        ),
        _buildMenuItem(
          icon: Icons.person_outline_rounded,
          label: 'Edit Profile',
          onTap: () => Navigator.of(context).push(AppRoute.fadeSlide(const EditProfileScreen())),
        ),
        _buildMenuItem(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          onTap: () => Navigator.of(context).push(AppRoute.fadeSlide(const NotificationsScreen())),
        ),
        _buildMenuItem(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy',
          onTap: () => Navigator.of(context).push(AppRoute.fadeSlide(const PrivacyScreen())),
        ),
        _buildMenuItem(
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
          onTap: () => Navigator.of(context).push(AppRoute.fadeSlide(const HelpSupportScreen())),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppConstants.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppConstants.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _confirmLogout(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppConstants.errorColor.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppConstants.errorColor.withAlpha(40),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: AppConstants.errorColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Log Out',
              style: TextStyle(
                color: AppConstants.errorColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Log out?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 8),
                Text('You will need to sign in again to access your account.', style: TextStyle(color: AppConstants.textMuted)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final auth = dialogCtx.read<AuthProvider>();
                        await auth.signOut();
                        if (!dialogCtx.mounted) return;
                        Navigator.of(dialogCtx).pop();
                        Navigator.of(context).pushAndRemoveUntil(
                          AppRoute.fadeSlide(const LoginScreen()),
                          (route) => false,
                        );
                        AppDialogs.showSnack(context, 'Logged out');
                      },
                      child: Text('Log Out', style: TextStyle(color: AppConstants.errorColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyBestBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConstants.accentGold, AppConstants.cardOrange],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppConstants.accentGold.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          const Text(
            "TODAY'S BEST",
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat())
     .shimmer(duration: 2.seconds, color: Colors.white24)
     .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds, curve: Curves.easeInOut);
  }
}


extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}