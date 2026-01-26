import 'package:flutter/material.dart';
import 'package:facecode/models/leaderboard_entry.dart';
import 'package:facecode/models/badge_data.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:facecode/widgets/badge_frame.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PublicProfileScreen extends StatelessWidget {
  final LeaderboardEntry entry;

  const PublicProfileScreen({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
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
                  PremiumIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Player Profile',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Profile Card
              _buildProfileCard(context),
              
              const SizedBox(height: 24),
              
              // Stats Card
              _buildStatsCard(context),
              
              const SizedBox(height: 24),
              
              // Badges Section
              _buildBadgesSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return GlassCard(
      radius: 20,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppConstants.primaryColor, AppConstants.cardPink],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                entry.avatar,
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          
          const SizedBox(width: 20),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                if (entry.rankTitle != null)
                  Row(
                    children: [
                      Text(
                        "🏆",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.rankTitle!.toUpperCase(),
                        style: TextStyle(
                          color: entry.rankColor ?? AppConstants.accentGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Level ${entry.level}',
                    style: const TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Row(
      children: [
        _buildStatItem('RANK', '#${entry.rank}', AppConstants.accentGold),
        const SizedBox(width: 12),
        _buildStatItem('SCORE', '${entry.score}', AppConstants.primaryColor),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: GlassCard(
        radius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppConstants.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context) {
    if (entry.badges.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 16),
          child: Text(
            'BADGES COLLECTED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: entry.badges.length,
          itemBuilder: (context, index) {
            final badgeId = entry.badges[index];
            // Since we might not have the full BadgeData for bots, 
            // we'll use a placeholder if not found in BadgeData.allBadges
            final badge = BadgeData.allBadges.firstWhere(
              (b) => b.id == badgeId,
              orElse: () => BadgeData(
                id: badgeId,
                label: 'Secret Badge',
                description: 'A mysterious achievement.',
                icon: '🎖️',
              ),
            );

            return BadgeFrame(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      badge.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (index * 50).ms).scale(duration: 400.ms, curve: Curves.easeOutBack);
          },
        ),
      ],
    );
  }
}
