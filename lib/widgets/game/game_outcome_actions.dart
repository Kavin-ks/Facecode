import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/widgets/game/mystery_reward_overlay.dart';
import 'package:facecode/services/game_feedback_service.dart';
import 'package:facecode/utils/constants.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GameOutcomeActions extends StatelessWidget {
  final VoidCallback onReplay;
  final VoidCallback onTryAnother;
  final String? gameId;

  const GameOutcomeActions({
    super.key,
    required this.onReplay,
    required this.onTryAnother,
    this.gameId,
  });

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final hasRewards = progressProvider.hasPendingRewards;

    final isMystery = progressProvider.isMysteryReward;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasRewards) ...[
          _buildClaimButton(context, progressProvider, isMystery),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'Play Again',
                icon: Icons.refresh_rounded,
                onPressed: () {
                  GameFeedbackService.tap();
                  if (hasRewards) {
                    _showClaimFirstWarning(context);
                  } else {
                    onReplay();
                  }
                },
                isPrimary: !hasRewards,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                label: 'Other Games',
                icon: Icons.games_outlined,
                onPressed: () {
                  GameFeedbackService.tap();
                  if (hasRewards) {
                    _showClaimFirstWarning(context);
                  } else {
                    onTryAnother();
                  }
                },
                isPrimary: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClaimButton(BuildContext context, ProgressProvider provider, bool isMystery) {
    return GestureDetector(
      onTap: () async {
        if (isMystery) {
          await MysteryRewardOverlay.show(
            context,
            xp: provider.pendingRewardXp,
            coins: provider.pendingRewardCoins,
          );
        } else {
          GameFeedbackService.success();
        }
        
        await provider.claimRewards();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isMystery ? 'Mystery rewards claimed! 🎁' : 'Rewards claimed! 🎉'),
              backgroundColor: AppConstants.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isMystery 
                ? [AppConstants.accentGold, AppConstants.cardOrange]
                : [AppConstants.primaryColor, AppConstants.secondaryColor],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isMystery ? AppConstants.accentGold : AppConstants.primaryColor).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMystery ? Icons.card_giftcard_rounded : Icons.stars_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMystery ? 'OPEN MYSTERY BOX' : 'CLAIM REWARDS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  isMystery 
                      ? 'Surprise rewards inside!' 
                      : '+${provider.pendingRewardXp} XP  •  ${provider.pendingRewardCoins} Coins',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat())
       .shimmer(duration: 2.seconds, color: Colors.white24)
       .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 1.seconds, curve: Curves.easeInOut),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? AppConstants.primaryColor : Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : AppConstants.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : AppConstants.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClaimFirstWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Claim your rewards first! 🏆'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
