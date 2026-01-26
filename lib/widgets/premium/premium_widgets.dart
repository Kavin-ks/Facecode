import 'package:flutter/material.dart';
import 'package:facecode/models/premium_status.dart';
import 'package:facecode/utils/constants.dart';

/// Badge showing premium tier
class PremiumBadge extends StatelessWidget {
  final PremiumTier tier;
  final double size;

  const PremiumBadge({
    super.key,
    required this.tier,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (tier == PremiumTier.free) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.4,
        vertical: size * 0.2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tier == PremiumTier.elite
              ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
              : [AppConstants.primaryColor, AppConstants.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tier == PremiumTier.elite ? Icons.diamond : Icons.star,
            color: Colors.white,
            size: size * 0.7,
          ),
          SizedBox(width: size * 0.2),
          Text(
            tier.displayName.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.6,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lock icon for premium-only features
class PremiumLockIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const PremiumLockIcon({
    super.key,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConstants.accentGold, Color(0xFFFFA500)],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.lock,
        size: size,
        color: color ?? Colors.white,
      ),
    );
  }
}

/// Card promoting premium upgrade
class PremiumUpgradeCard extends StatelessWidget {
  final PremiumTier targetTier;
  final String title;
  final String description;
  final List<String> benefits;
  final VoidCallback onUpgrade;

  const PremiumUpgradeCard({
    super.key,
    this.targetTier = PremiumTier.premium,
    required this.title,
    required this.description,
    required this.benefits,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final isElite = targetTier == PremiumTier.elite;
    final gradient = isElite
        ? const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          )
        : const LinearGradient(
            colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
          );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient.scale(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isElite ? const Color(0xFFFFD700) : AppConstants.primaryColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                isElite ? Icons.diamond : Icons.star,
                color: isElite ? const Color(0xFFFFD700) : AppConstants.primaryColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Benefits
          ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: isElite ? const Color(0xFFFFD700) : AppConstants.successColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 16),

          // Upgrade button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: isElite ? const Color(0xFFFFD700) : AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Upgrade to ${targetTier.displayName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
