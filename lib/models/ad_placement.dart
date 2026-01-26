/// Ad placement locations in the app
enum AdPlacement {
  /// Game result screen - 2x XP bonus
  gameResultBonus,
  
  /// Shop screen - Free coins
  shopCoins,
  
  /// Daily bonus - Triple rewards
  dailyBonusTriple,
  
  /// Badge progress boost
  badgeProgress,
  
  /// Leaderboard profile boost
  leaderboardBoost,
}

/// Result of showing a rewarded ad
class AdResult {
  final bool watched;
  final bool rewarded;
  final String? error;

  const AdResult({
    required this.watched,
    required this.rewarded,
    this.error,
  });

  factory AdResult.success() {
    return const AdResult(watched: true, rewarded: true);
  }

  factory AdResult.cancelled() {
    return const AdResult(watched: false, rewarded: false);
  }

  factory AdResult.error(String message) {
    return AdResult(
      watched: false,
      rewarded: false,
      error: message,
    );
  }

  bool get isSuccess => watched && rewarded;
  bool get isCancelled => !watched && error == null;
  bool get hasError => error != null;
}

/// Ad configuration for different placements
class AdConfig {
  final AdPlacement placement;
  final String title;
  final String description;
  final int estimatedDurationSeconds;

  const AdConfig({
    required this.placement,
    required this.title,
    required this.description,
    this.estimatedDurationSeconds = 30,
  });

  static const Map<AdPlacement, AdConfig> configs = {
    AdPlacement.gameResultBonus: AdConfig(
      placement: AdPlacement.gameResultBonus,
      title: '2x XP Bonus',
      description: 'Double your XP by watching a short ad',
      estimatedDurationSeconds: 30,
    ),
    AdPlacement.shopCoins: AdConfig(
      placement: AdPlacement.shopCoins,
      title: 'Get 100 Coins',
      description: 'Watch an ad to earn free coins',
      estimatedDurationSeconds: 30,
    ),
    AdPlacement.dailyBonusTriple: AdConfig(
      placement: AdPlacement.dailyBonusTriple,
      title: '3x Daily Bonus',
      description: 'Triple your daily login rewards',
      estimatedDurationSeconds: 30,
    ),
    AdPlacement.badgeProgress: AdConfig(
      placement: AdPlacement.badgeProgress,
      title: 'Badge Progress',
      description: 'Get +1 progress toward this badge',
      estimatedDurationSeconds: 15,
    ),
    AdPlacement.leaderboardBoost: AdConfig(
      placement: AdPlacement.leaderboardBoost,
      title: 'Leaderboard Boost',
      description: 'Highlight your profile for 1 hour',
      estimatedDurationSeconds: 15,
    ),
  };

  static AdConfig? getConfig(AdPlacement placement) {
    return configs[placement];
  }
}
