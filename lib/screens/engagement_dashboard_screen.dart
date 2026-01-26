import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facecode/providers/analytics_provider.dart';
import 'package:facecode/models/engagement_stats.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:facecode/utils/game_catalog.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EngagementDashboardScreen extends StatelessWidget {
  const EngagementDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final stats = analytics.gameEngagementStats.values.toList();
    
    // Sort by play count for the "Heat" effect
    stats.sort((a, b) => b.playCount.compareTo(a.playCount));

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: stats.isEmpty ? _buildEmptyState() : _buildStatsList(stats),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          PremiumIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Game Engagement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Heat Tracking & Usage Insights',
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.analytics_outlined,
      title: 'No Data Yet',
      subtitle: 'Play a few games to see engagement metrics here.',
    );
  }

  Widget _buildStatsList(List<GameEngagementStats> stats) {
    final maxPlays = stats.first.playCount;
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final s = stats[index];
        final game = GameCatalog.allGames.firstWhere(
          (g) => g.id == s.gameId || s.gameId.contains(g.id),
          orElse: () => GameCatalog.allGames[0],
        );

        // Heat color calculation
        final intensity = maxPlays > 0 ? s.playCount / maxPlays : 0.0;
        final heatColor = Color.lerp(Colors.blueAccent, Colors.redAccent, intensity)!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: heatColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: heatColor.withValues(alpha: 0.5)),
                      ),
                      child: Center(
                        child: Text(
                          game.bannerImage,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Text(
                          '${s.playCount} sessions • ${(s.totalDurationMs / 1000 / 60).toStringAsFixed(1)} min total',
                          style: const TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildHeatBadge(s.playCount, heatColor),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('Replay Rate', '${s.replayRate.toStringAsFixed(1)}x'),
                  _buildMiniStat('Abandon', '${s.abandonRate.round()}%'),
                  _buildMiniStat('Avg Time', '${(s.averageDurationMs / 1000).toStringAsFixed(1)}s'),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildHeatBadge(int plays, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.whatshot, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$plays',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
