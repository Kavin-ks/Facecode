import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';

/// Modern Badges Screen matching Play Store game hub style
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final badges = _badges();
    final unlockedCount = badges.where((b) => b['unlocked']).length;
    
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Your Badges',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$unlockedCount of ${badges.length} unlocked',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            
            // Progress Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: _buildProgressCard(context, unlockedCount, badges.length),
              ),
            ),
            
            // Badges Grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final badge = badges[index];
                    return _buildBadgeCard(
                      context,
                      badge['title'],
                      badge['emoji'],
                      badge['color'],
                      badge['unlocked'],
                    );
                  },
                  childCount: badges.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, int unlocked, int total) {
    final progress = unlocked / total;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collection Progress',
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppConstants.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('🎖️', '$unlocked', 'Earned'),
              Container(
                width: 1,
                height: 40,
                color: AppConstants.borderColor,
              ),
              _buildStatItem('🔒', '${total - unlocked}', 'Locked'),
              Container(
                width: 1,
                height: 40,
                color: AppConstants.borderColor,
              ),
              _buildStatItem('⭐', '$total', 'Total'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(BuildContext context, String title, String emoji, Color color, bool unlocked) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: unlocked
            ? Border.all(color: color.withAlpha(60), width: 1)
            : Border.all(color: AppConstants.borderColor, width: 1),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Badge Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: unlocked ? color.withAlpha(30) : AppConstants.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: TextStyle(
                        fontSize: 26,
                        color: unlocked ? null : Colors.white24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Title
                Text(
                  title,
                  style: TextStyle(
                    color: unlocked ? Colors.white : AppConstants.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Lock overlay
          if (!unlocked)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppConstants.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.lock_rounded,
                  color: AppConstants.textMuted,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _badges() {
    return [
      {'title': 'Social Butterfly', 'emoji': '🦋', 'color': AppConstants.cardPink, 'unlocked': true},
      {'title': 'Quick Win', 'emoji': '⚡', 'color': AppConstants.cardOrange, 'unlocked': true},
      {'title': 'Game Starter', 'emoji': '🎮', 'color': AppConstants.cardBlue, 'unlocked': true},
      {'title': 'Winner', 'emoji': '🏆', 'color': AppConstants.accentGold, 'unlocked': false},
      {'title': 'Game Master', 'emoji': '👑', 'color': AppConstants.cardPurple, 'unlocked': false},
      {'title': 'Streak King', 'emoji': '🔥', 'color': AppConstants.cardOrange, 'unlocked': true},
      {'title': 'Truth Seeker', 'emoji': '🔍', 'color': AppConstants.cardTeal, 'unlocked': false},
      {'title': 'Combo Master', 'emoji': '💥', 'color': AppConstants.cardPink, 'unlocked': false},
      {'title': 'Veteran', 'emoji': '⭐', 'color': AppConstants.accentGold, 'unlocked': true},
    ];
  }
}
