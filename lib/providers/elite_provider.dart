import 'package:flutter/material.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/services/sound_manager.dart';

class EliteProvider with ChangeNotifier {
  final ProgressProvider _progressProvider;

  EliteProvider(this._progressProvider);

  bool get isElite => _progressProvider.progress.isElite;
  DateTime? get eliteSince => _progressProvider.progress.eliteSince;
  String? get eliteTier => _progressProvider.progress.eliteTier;

  /// Upgrade to Facecode Elite
  Future<void> joinElite({String tier = 'Legendary'}) async {
    if (isElite) return;

    final now = DateTime.now();
    final updatedProgress = _progressProvider.progress.copyWith(
      isElite: true,
      eliteSince: now,
      eliteTier: tier,
      // Award premium bonus coins
      coins: _progressProvider.progress.coins + 500,
    );

    await _progressProvider.updateShopProgress(updatedProgress);
    
    // Play celebratory sound
    SoundManager().playGameSound(SoundManager.sfxBadgeUnlock, haptic: HapticType.heavy);
    
    notifyListeners();
  }

  /// Check if an item should be restricted to Elite users
  bool canAccessEliteFeature() {
    return isElite;
  }

  /// Get the matchmaking weight for priority matchmaking
  int get matchmakingPriority {
    return isElite ? 10 : 0;
  }
}
