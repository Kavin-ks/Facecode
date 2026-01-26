import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facecode/models/premium_status.dart';

/// Provider for managing premium subscription state
class PremiumProvider extends ChangeNotifier {
  PremiumStatus _status = const PremiumStatus();

  PremiumStatus get status => _status;
  PremiumTier get tier => _status.effectiveTier;
  bool get isPremium => tier != PremiumTier.free;
  bool get isElite => tier == PremiumTier.elite;

  static const String _storageKey = 'premium_status';

  /// Initialize and load saved premium status
  Future<void> initialize() async {
    await _loadStatus();
  }

  /// Check if user has access to a feature
  bool hasFeature(PremiumFeature feature) {
    return _status.hasFeature(feature);
  }

  /// Check if user can access premium cosmetic
  bool canUnlockCosmetic(String cosmeticId) {
    // Premium cosmetics require premium tier
    if (cosmeticId.startsWith('premium_') || cosmeticId.startsWith('elite_')) {
      return hasFeature(PremiumFeature.premiumCosmetics);
    }
    return true; // Free cosmetics available to all
  }

  /// Activate premium subscription
  Future<void> activatePremium({
    required PremiumTier tier,
    required Duration duration,
    String? subscriptionId,
  }) async {
    final now = DateTime.now();
    _status = _status.copyWith(
      tier: tier,
      subscriptionStart: now,
      subscriptionExpiry: now.add(duration),
      subscriptionId: subscriptionId,
      isLifetime: false,
    );

    await _saveStatus();
    notifyListeners();

    debugPrint('✨ Premium activated: $tier for ${duration.inDays} days');
  }

  /// Activate lifetime premium
  Future<void> activateLifetime({
    required PremiumTier tier,
    String? purchaseId,
  }) async {
    _status = _status.copyWith(
      tier: tier,
      subscriptionStart: DateTime.now(),
      subscriptionExpiry: null,
      isLifetime: true,
      subscriptionId: purchaseId,
    );

    await _saveStatus();
    notifyListeners();

    debugPrint('✨ Lifetime premium activated: $tier');
  }

  /// Start free trial
  Future<void> startTrial({
    required PremiumTier tier,
    required Duration duration,
  }) async {
    if (_status.isTrial) {
      debugPrint('⚠️ Trial already active or used');
      return;
    }

    final now = DateTime.now();
    _status = _status.copyWith(
      tier: tier,
      isTrial: true,
      trialExpiry: now.add(duration),
      subscriptionStart: now,
    );

    await _saveStatus();
    notifyListeners();

    debugPrint('🎁 Trial started: $tier for ${duration.inDays} days');
  }

  /// Cancel subscription (keeps access until expiry)
  Future<void> cancelSubscription() async {
    // Don't clear expiry - let it run out naturally
    _status = _status.copyWith(
      subscriptionId: null, // Clear subscription ID to indicate cancellation
    );

    await _saveStatus();
    notifyListeners();

    debugPrint('❌ Subscription cancelled (access until ${_status.subscriptionExpiry})');
  }

  /// Restore purchases (for IAP)
  Future<void> restorePurchases() async {
    // TODO: Implement with IAP SDK
    debugPrint('🔄 Restoring purchases...');
    
    // Mock: For testing, restore a premium subscription
    if (kDebugMode) {
      await activatePremium(
        tier: PremiumTier.premium,
        duration: const Duration(days: 30),
        subscriptionId: 'restored_mock',
      );
    }
  }

  /// Check and update subscription status (call periodically)
  Future<void> checkSubscriptionStatus() async {
    if (_status.isLifetime) return;

    final wasActive = _status.isActive;
    final isActive = _status.isActive; // Re-evaluate

    if (wasActive && !isActive) {
      // Subscription expired
      _status = _status.copyWith(tier: PremiumTier.free);
      await _saveStatus();
      notifyListeners();
      debugPrint('⏰ Subscription expired');
    }
  }

  // Persistence
  Future<void> _loadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final json = jsonDecode(jsonString);
        _status = PremiumStatus.fromJson(json);
        
        // Check if expired
        await checkSubscriptionStatus();
        
        notifyListeners();
        debugPrint('💎 Premium status loaded: ${_status.effectiveTier.name}');
      }
    } catch (e) {
      debugPrint('Error loading premium status: $e');
    }
  }

  Future<void> _saveStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_status.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving premium status: $e');
    }
  }

  /// Debug: Grant premium for testing
  Future<void> debugGrantPremium() async {
    if (!kDebugMode) return;

    await activatePremium(
      tier: PremiumTier.premium,
      duration: const Duration(days: 365),
      subscriptionId: 'debug_grant',
    );
  }

  /// Debug: Grant elite for testing
  Future<void> debugGrantElite() async {
    if (!kDebugMode) return;

    await activateLifetime(
      tier: PremiumTier.elite,
      purchaseId: 'debug_elite',
    );
  }

  /// Debug: Reset to free
  Future<void> debugResetToFree() async {
    if (!kDebugMode) return;

    _status = const PremiumStatus();
    await _saveStatus();
    notifyListeners();
  }
}
