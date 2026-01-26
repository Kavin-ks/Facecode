import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facecode/providers/analytics_provider.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/models/retention_score.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminDebugDashboard extends StatelessWidget {
  const AdminDebugDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final progress = context.watch<ProgressProvider>().progress;
    
    final score = analytics.calculateRetentionScore(
      streak: progress.currentStreak,
      totalGamesPlayed: progress.totalGamesPlayed,
    );

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildRetentionCard(score),
                      const SizedBox(height: 24),
                      _buildBreakdownGrid(score),
                      const SizedBox(height: 24),
                      _buildRawStats(score, analytics.sessions.length),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
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
            icon: Icons.close,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Dashboard',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Confidential Retention & Debug Data',
                style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionCard(RetentionScore score) {
    final color = _getScoreColor(score.totalScore);
    
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          const Text(
            'USER RETENTION SCORE',
            style: TextStyle(color: AppConstants.textSecondary, letterSpacing: 2, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: score.totalScore / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.white10,
                  color: color,
                ),
              ),
              Text(
                '${score.totalScore.round()}',
                style: TextStyle(color: color, fontSize: 48, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _getScoreLabel(score.totalScore),
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack);
  }

  Widget _buildBreakdownGrid(RetentionScore score) {
    return Column(
      children: [
        _buildScoreBar('Streak (30%)', score.streakWeight, 30, AppConstants.primaryColor),
        const SizedBox(height: 16),
        _buildScoreBar('Frequency (40%)', score.frequencyWeight, 40, AppConstants.secondaryColor),
        const SizedBox(height: 16),
        _buildScoreBar('Volume (30%)', score.volumeWeight, 30, AppConstants.accentGold),
      ],
    );
  }

  Widget _buildScoreBar(String label, double value, double max, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('${value.toStringAsFixed(1)} / $max', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / max,
            minHeight: 8,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1);
  }

  Widget _buildRawStats(RetentionScore score, int sessionCount) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatItem('Total Sessions', '$sessionCount', Icons.history),
        _buildStatItem('Unique Days', '${score.totalUniqueDaysActive}', Icons.calendar_today),
        _buildStatItem('14d Active', '${score.uniqueDaysInLast14}', Icons.timer),
        _buildStatItem('Current Streak', '${score.streak}', Icons.whatshot),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppConstants.textSecondary, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppConstants.successColor;
    if (score >= 50) return AppConstants.accentGold;
    if (score >= 20) return AppConstants.warningColor;
    return AppConstants.errorColor;
  }

  String _getScoreLabel(double score) {
    if (score >= 90) return 'LOYAL SUPERSTAR';
    if (score >= 70) return 'CONSISTENT PLAYER';
    if (score >= 40) return 'CASUAL USER';
    if (score >= 20) return 'AT RISK';
    return 'CHURNED/COLD';
  }
}
