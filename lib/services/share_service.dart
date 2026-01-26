import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:facecode/models/share_content.dart';

/// Service for handling social sharing
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  /// Share text content
  Future<void> shareText({
    required String text,
    String? subject,
  }) async {
    try {
      await Share.share(
        text,
        subject: subject,
      );
      
      debugPrint('📤 Shared: $text');
    } catch (e) {
      debugPrint('Error sharing: $e');
    }
  }

  /// Share achievement with pre-formatted message
  Future<void> shareAchievement(ShareContent content) async {
    final text = _formatShareText(content);
    await shareText(text: text, subject: content.title);
  }

  /// Share with app link
  Future<void> shareWithLink({
    required String message,
    String? deepLink,
  }) async {
    final appLink = deepLink ?? 'https://facecode.app'; // Replace with actual link
    final fullMessage = '$message\n\nDownload FaceCode: $appLink';
    
    await shareText(text: fullMessage);
  }

  /// Share personal best
  Future<void> sharePersonalBest({
    required String gameTitle,
    required String scoreText,
    String? percentile,
  }) async {
    final content = ShareContent.personalBest(
      gameTitle: gameTitle,
      scoreText: scoreText,
      percentile: percentile,
    );
    
    await shareAchievement(content);
  }

  /// Share level up
  Future<void> shareLevelUp({
    required int level,
    required int totalXP,
  }) async {
    final content = ShareContent.levelUp(
      level: level,
      totalXP: totalXP,
    );
    
    await shareAchievement(content);
  }

  /// Share streak milestone
  Future<void> shareStreak(int days) async {
    final content = ShareContent.streak(days: days);
    await shareAchievement(content);
  }

  /// Share badge unlock
  Future<void> shareBadge({
    required String badgeName,
    required String description,
    String? rarity,
  }) async {
    final content = ShareContent.badge(
      badgeName: badgeName,
      description: description,
      rarity: rarity,
    );
    
    await shareAchievement(content);
  }

  /// Share challenge to friends
  Future<void> shareChallenge({
    required String gameTitle,
    required String challengeText,
    String? roomCode,
  }) async {
    String message = challengeText;
    if (roomCode != null) {
      message += '\n\nJoin my room: $roomCode';
    }
    
    final content = ShareContent.challenge(
      gameTitle: gameTitle,
      challengeText: message,
    );
    
    await shareAchievement(content);
  }

  /// Check if sharing is available
  bool get isAvailable => true; // share_plus handles platform availability

  // Helper to format share text
  String _formatShareText(ShareContent content) {
    return content.message;
  }


}
