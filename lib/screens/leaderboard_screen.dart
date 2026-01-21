import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/models/user_progress.dart';
import 'package:facecode/widgets/premium_ui.dart';

/// Modern Leaderboard Screen matching Play Store game hub style
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Weekly', 'All Time'];

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>().progress;
    final totalXp = _totalXp(progress);
    final tiers = _buildTiers(totalXp);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Leaderboard',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: AppConstants.textSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // Your Rank Card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildYourRankCard(totalXp, progress.level),
            ),

            // Tab Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildTabChip(index, _tabs[index]),
                  );
                }),
              ),
            ),

            // Season Ladder
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: tiers.length,
                itemBuilder: (context, index) {
                  final tier = tiers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildTierCard(tier),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourRankCard(int totalXp, int level) {
    return GlassCard(
      radius: 16,
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Lv $level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Season Ladder',
                  style: TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your current tier',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.accentGold.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppConstants.accentGold,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatXp(totalXp)} XP',
                  style: const TextStyle(
                    color: AppConstants.accentGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(int index, String label) {
    final isSelected = _selectedTab == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : AppConstants.borderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppConstants.textSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard(Map<String, dynamic> tier) {
    final isActive = tier['isActive'] as bool;
    return GlassCard(
      radius: 14,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (tier['color'] as Color).withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (tier['color'] as Color).withAlpha(60)),
            ),
            child: Center(
              child: Text(tier['icon'] as String, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier['name'] as String,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tier['range'] as String,
                  style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppConstants.accentGold.withAlpha(25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Current',
                style: TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}K';
    }
    return xp.toString();
  }

  int _totalXp(UserProgress progress) {
    int total = 0;
    for (int level = 1; level < progress.level; level++) {
      total += UserProgress.xpForLevel(level);
    }
    total += progress.currentXP;
    return total;
  }

  List<Map<String, dynamic>> _buildTiers(int totalXp) {
    final tiers = [
      {'name': 'Bronze', 'min': 0, 'max': 1000, 'icon': '🥉', 'color': const Color(0xFFCD7F32)},
      {'name': 'Silver', 'min': 1000, 'max': 2500, 'icon': '🥈', 'color': const Color(0xFFC0C0C0)},
      {'name': 'Gold', 'min': 2500, 'max': 5000, 'icon': '🥇', 'color': AppConstants.accentGold},
      {'name': 'Platinum', 'min': 5000, 'max': 10000, 'icon': '💎', 'color': AppConstants.cardBlue},
      {'name': 'Diamond', 'min': 10000, 'max': 20000, 'icon': '👑', 'color': AppConstants.cardPurple},
    ];

    return tiers.map((tier) {
      final min = tier['min'] as int;
      final max = tier['max'] as int;
      final active = totalXp >= min && totalXp < max;
      return {
        'name': tier['name'],
        'range': '${_formatXp(min)} - ${_formatXp(max)} XP',
        'icon': tier['icon'],
        'color': tier['color'],
        'isActive': active,
      };
    }).toList();
  }
}
