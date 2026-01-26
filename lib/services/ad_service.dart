import 'package:facecode/models/ad_placement.dart';

/// Abstract ad service interface
/// Implement with real ad SDK when ready to monetize
abstract class AdService {
  /// Check if a rewarded ad is ready for the given placement
  Future<bool> isRewardedAdReady(AdPlacement placement);

  /// Show a rewarded ad for the given placement
  /// Returns AdResult indicating success/failure
  Future<AdResult> showRewardedAd(AdPlacement placement);

  /// Preload an ad for better UX
  Future<void> preloadAd(AdPlacement placement);

  /// Initialize the ad service
  Future<void> initialize();

  /// Dispose and cleanup
  void dispose();
}
