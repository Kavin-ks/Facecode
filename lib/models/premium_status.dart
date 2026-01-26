/// Premium subscription tiers
enum PremiumTier {
  free,
  premium,
  elite,  // Future: higher tier
}

extension PremiumTierExtension on PremiumTier {
  String get displayName {
    switch (this) {
      case PremiumTier.free:
        return 'Free';
      case PremiumTier.premium:
        return 'Premium';
      case PremiumTier.elite:
        return 'Elite';
    }
  }

  String get description {
    switch (this) {
      case PremiumTier.free:
        return 'Standard experience';
      case PremiumTier.premium:
        return 'Unlock exclusive features';
      case PremiumTier.elite:
        return 'Ultimate VIP experience';
    }
  }

  /// Monthly price in USD (for future IAP)
  double get monthlyPriceUSD {
    switch (this) {
      case PremiumTier.free:
        return 0.0;
      case PremiumTier.premium:
        return 4.99;
      case PremiumTier.elite:
        return 9.99;
    }
  }
}

/// Premium features that can be gated
enum PremiumFeature {
  // Cosmetics
  premiumCosmetics,
  exclusiveThemes,
  customAvatars,
  
  // Gameplay
  unlimitedLives,
  skipAds,
  doubleXP,
  
  // Social
  customRoomCodes,
  privateRooms,
  
  // Analytics
  detailedStats,
  performanceInsights,
  
  // Future
  prioritySupport,
  earlyAccess,
}

extension PremiumFeatureExtension on PremiumFeature {
  String get displayName {
    switch (this) {
      case PremiumFeature.premiumCosmetics:
        return 'Premium Cosmetics';
      case PremiumFeature.exclusiveThemes:
        return 'Exclusive Themes';
      case PremiumFeature.customAvatars:
        return 'Custom Avatars';
      case PremiumFeature.unlimitedLives:
        return 'Unlimited Lives';
      case PremiumFeature.skipAds:
        return 'No Ads';
      case PremiumFeature.doubleXP:
        return '2x XP Boost';
      case PremiumFeature.customRoomCodes:
        return 'Custom Room Codes';
      case PremiumFeature.privateRooms:
        return 'Private Rooms';
      case PremiumFeature.detailedStats:
        return 'Detailed Statistics';
      case PremiumFeature.performanceInsights:
        return 'Performance Insights';
      case PremiumFeature.prioritySupport:
        return 'Priority Support';
      case PremiumFeature.earlyAccess:
        return 'Early Access';
    }
  }

  /// Minimum tier required for this feature
  PremiumTier get requiredTier {
    switch (this) {
      case PremiumFeature.premiumCosmetics:
      case PremiumFeature.skipAds:
      case PremiumFeature.doubleXP:
        return PremiumTier.premium;
      case PremiumFeature.exclusiveThemes:
      case PremiumFeature.customAvatars:
      case PremiumFeature.customRoomCodes:
      case PremiumFeature.privateRooms:
      case PremiumFeature.detailedStats:
        return PremiumTier.premium;
      case PremiumFeature.unlimitedLives:
      case PremiumFeature.performanceInsights:
      case PremiumFeature.prioritySupport:
      case PremiumFeature.earlyAccess:
        return PremiumTier.elite;
    }
  }
}

/// User's premium status and subscription details
class PremiumStatus {
  final PremiumTier tier;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionExpiry;
  final bool isLifetime;
  final String? subscriptionId; // For IAP tracking
  final bool isTrial;
  final DateTime? trialExpiry;

  const PremiumStatus({
    this.tier = PremiumTier.free,
    this.subscriptionStart,
    this.subscriptionExpiry,
    this.isLifetime = false,
    this.subscriptionId,
    this.isTrial = false,
    this.trialExpiry,
  });

  /// Check if subscription is currently active
  bool get isActive {
    if (tier == PremiumTier.free) return false;
    if (isLifetime) return true;
    if (subscriptionExpiry == null) return false;
    return DateTime.now().isBefore(subscriptionExpiry!);
  }

  /// Check if trial is active
  bool get isTrialActive {
    if (!isTrial) return false;
    if (trialExpiry == null) return false;
    return DateTime.now().isBefore(trialExpiry!);
  }

  /// Get effective tier (considering trial and expiry)
  PremiumTier get effectiveTier {
    if (isLifetime || isActive || isTrialActive) {
      return tier;
    }
    return PremiumTier.free;
  }

  /// Days remaining in subscription
  int? get daysRemaining {
    if (isLifetime) return null;
    if (subscriptionExpiry == null) return null;
    final diff = subscriptionExpiry!.difference(DateTime.now());
    return diff.inDays;
  }

  /// Check if user has access to a feature
  bool hasFeature(PremiumFeature feature) {
    final required = feature.requiredTier;
    final effective = effectiveTier;
    
    // Elite > Premium > Free
    if (effective == PremiumTier.elite) return true;
    if (effective == PremiumTier.premium && required != PremiumTier.elite) return true;
    if (effective == PremiumTier.free && required == PremiumTier.free) return true;
    
    return false;
  }

  PremiumStatus copyWith({
    PremiumTier? tier,
    DateTime? subscriptionStart,
    DateTime? subscriptionExpiry,
    bool? isLifetime,
    String? subscriptionId,
    bool? isTrial,
    DateTime? trialExpiry,
  }) {
    return PremiumStatus(
      tier: tier ?? this.tier,
      subscriptionStart: subscriptionStart ?? this.subscriptionStart,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      isLifetime: isLifetime ?? this.isLifetime,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      isTrial: isTrial ?? this.isTrial,
      trialExpiry: trialExpiry ?? this.trialExpiry,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier.name,
      'subscription_start': subscriptionStart?.toIso8601String(),
      'subscription_expiry': subscriptionExpiry?.toIso8601String(),
      'is_lifetime': isLifetime,
      'subscription_id': subscriptionId,
      'is_trial': isTrial,
      'trial_expiry': trialExpiry?.toIso8601String(),
    };
  }

  factory PremiumStatus.fromJson(Map<String, dynamic> json) {
    return PremiumStatus(
      tier: PremiumTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => PremiumTier.free,
      ),
      subscriptionStart: json['subscription_start'] != null
          ? DateTime.parse(json['subscription_start'])
          : null,
      subscriptionExpiry: json['subscription_expiry'] != null
          ? DateTime.parse(json['subscription_expiry'])
          : null,
      isLifetime: json['is_lifetime'] ?? false,
      subscriptionId: json['subscription_id'],
      isTrial: json['is_trial'] ?? false,
      trialExpiry: json['trial_expiry'] != null
          ? DateTime.parse(json['trial_expiry'])
          : null,
    );
  }

  @override
  String toString() {
    return 'PremiumStatus(tier: $tier, active: $isActive, lifetime: $isLifetime)';
  }
}
