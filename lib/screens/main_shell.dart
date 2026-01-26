import 'package:flutter/material.dart';
import 'package:facecode/screens/home_screen_new.dart';
import 'package:facecode/screens/leaderboard_screen.dart';
import 'package:facecode/screens/badges_screen.dart';
import 'package:facecode/screens/profile_screen.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/widgets/streak_celebration_overlay.dart';
import 'package:provider/provider.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/widgets/daily_best_announcement.dart';

/// Main navigation shell with bottom navigation bar
/// Matches modern Play Store game hub style
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreenNew(),
    LeaderboardScreen(),
    BadgesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Listen for streak milestones
    final progressProvider = context.watch<ProgressProvider>();
    if (progressProvider.hasStreakMilestonePending) {
      // Defer to next frame to avoid build conflicts
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Double check to ensure we don't spam and widget is still active
        if (mounted && progressProvider.hasStreakMilestonePending) {
           await StreakCelebrationOverlay.show(context, progressProvider.progress.currentStreak);
           if (!context.mounted) return;
           context.read<ProgressProvider>().consumeStreakEvent();
        }
      });
    }

    // Listen for daily titles
    if (progressProvider.hasDailyTitlesPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted && progressProvider.hasDailyTitlesPending) {
           DailyBestAnnouncement.show(context, progressProvider.progress.activeDailyTitles);
           context.read<ProgressProvider>().consumeDailyTitlesEvent();
        }
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          border: Border(
            top: BorderSide(
              color: AppConstants.borderColor,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.leaderboard_rounded, Icons.leaderboard_outlined, 'Ranks'),
                _buildNavItem(2, Icons.emoji_events_rounded, Icons.emoji_events_outlined, 'Badges'),
                _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    
    return PremiumTap(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppConstants.primaryColor : AppConstants.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppConstants.primaryColor : AppConstants.textMuted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
