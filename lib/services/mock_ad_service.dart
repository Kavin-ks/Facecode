import 'package:facecode/models/ad_placement.dart';
import 'package:facecode/services/ad_service.dart';
import 'package:flutter/foundation.dart';

/// Mock ad service for development
/// Simulates ad behavior without actual ads
class MockAdService implements AdService {
  static final MockAdService _instance = MockAdService._internal();
  factory MockAdService() => _instance;
  MockAdService._internal();

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('📺 Mock Ad Service initialized (no real ads)');
    _initialized = true;
  }

  @override
  Future<bool> isRewardedAdReady(AdPlacement placement) async {
    // Simulate ad availability check
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Always ready in mock
    return true;
  }

  @override
  Future<AdResult> showRewardedAd(AdPlacement placement) async {
    debugPrint('📺 Mock: Showing ad for ${placement.name}');

    // Simulate ad loading
    await Future.delayed(const Duration(milliseconds: 500));

    final config = AdConfig.getConfig(placement);
    final duration = config?.estimatedDurationSeconds ?? 30;

    // Simulate ad watching
    debugPrint('📺 Mock: User watching ad ($duration seconds)...');
    await Future.delayed(Duration(seconds: kDebugMode ? 2 : duration));

    // Simulate successful completion
    debugPrint('📺 Mock: Ad completed successfully');
    return AdResult.success();
  }

  @override
  Future<void> preloadAd(AdPlacement placement) async {
    debugPrint('📺 Mock: Preloading ad for ${placement.name}');
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    debugPrint('📺 Mock Ad Service disposed');
  }
}
