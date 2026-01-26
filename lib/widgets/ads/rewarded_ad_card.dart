import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/models/ad_placement.dart';

/// Card widget offering rewarded ad with clear value proposition
class RewardedAdCard extends StatefulWidget {
  final AdPlacement placement;
  final String rewardTitle;
  final String rewardDescription;
  final IconData rewardIcon;
  final VoidCallback onWatch;
  final VoidCallback? onSkip;
  final Color? accentColor;

  const RewardedAdCard({
    super.key,
    required this.placement,
    required this.rewardTitle,
    required this.rewardDescription,
    required this.onWatch,
    this.rewardIcon = Icons.card_giftcard,
    this.onSkip,
    this.accentColor,
  });

  @override
  State<RewardedAdCard> createState() => _RewardedAdCardState();
}

class _RewardedAdCardState extends State<RewardedAdCard> {
  bool _isWatching = false;

  void _handleWatch() {
    if (_isWatching) return;

    setState(() => _isWatching = true);

    // Call the callback
    widget.onWatch();

    // Reset state after a delay (callback handles async logic)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isWatching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = AdConfig.getConfig(widget.placement);
    final accentColor = widget.accentColor ?? AppConstants.primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.15),
            accentColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.rewardIcon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎬 BONUS REWARD',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.rewardTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            widget.rewardDescription,
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 14,
            ),
          ),

          if (config != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AppConstants.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '~${config.estimatedDurationSeconds}s video',
                  style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isWatching ? null : _handleWatch,
                  icon: _isWatching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text(_isWatching ? 'Loading...' : 'Watch'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (widget.onSkip != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isWatching ? null : widget.onSkip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.textSecondary,
                      side: BorderSide(
                        color: AppConstants.borderColor,
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
