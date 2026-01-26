/// Types of shareable content
enum ShareType {
  achievement,
  personalBest,
  levelUp,
  streak,
  badge,
  funnyMoment,
  challenge,
  profile,
}

/// Share content model
class ShareContent {
  final ShareType type;
  final String title;
  final String subtitle;
  final String message;
  final Map<String, dynamic> metadata;

  const ShareContent({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.message,
    this.metadata = const {},
  });

  /// Create achievement share content
  factory ShareContent.achievement({
    required String title,
    required String subtitle,
    String? customMessage,
    Map<String, dynamic>? metadata,
  }) {
    return ShareContent(
      type: ShareType.achievement,
      title: title,
      subtitle: subtitle,
      message: customMessage ?? _generateAchievementMessage(title, subtitle),
      metadata: metadata ?? {},
    );
  }

  /// Create personal best share content
  factory ShareContent.personalBest({
    required String gameTitle,
    required String scoreText,
    String? percentile,
    Map<String, dynamic>? metadata,
  }) {
    return ShareContent(
      type: ShareType.personalBest,
      title: '🎯 NEW RECORD!',
      subtitle: '$gameTitle: $scoreText',
      message: _generatePersonalBestMessage(gameTitle, scoreText, percentile),
      metadata: metadata ?? {},
    );
  }

  /// Create level up share content
  factory ShareContent.levelUp({
    required int level,
    required int totalXP,
    Map<String, dynamic>? metadata,
  }) {
    return ShareContent(
      type: ShareType.levelUp,
      title: '🎊 LEVEL $level REACHED!',
      subtitle: '$totalXP XP earned',
      message: _generateLevelUpMessage(level, totalXP),
      metadata: metadata ?? {},
    );
  }

  /// Create streak share content
  factory ShareContent.streak({
    required int days,
    Map<String, dynamic>? metadata,
  }) {
    return ShareContent(
      type: ShareType.streak,
      title: '🔥 $days DAY STREAK!',
      subtitle: 'Played every day${days >= 30 ? " for ${(days / 30).floor()} months!" : "!"}',
      message: _generateStreakMessage(days),
      metadata: metadata ?? {},
    );
  }

  /// Create badge unlock share content
  factory ShareContent.badge({
    required String badgeName,
    required String description,
    String? rarity,
    Map<String, dynamic>? metadata,
  }) {
    return ShareContent(
      type: ShareType.badge,
      title: '🏆 $badgeName',
      subtitle: description,
      message: _generateBadgeMessage(badgeName, description, rarity),
      metadata: metadata ?? {},
    );
  }

  /// Create challenge share content
  factory ShareContent.challenge({
    required String gameTitle,
    required String challengeText,
    Map<String, dynamic>? metadata,
  }) {
    return ShareContent(
      type: ShareType.challenge,
      title: '💪 Challenge!',
      subtitle: challengeText,
      message: _generateChallengeMessage(gameTitle, challengeText),
      metadata: metadata ?? {},
    );
  }

  // Message generators
  static String _generateAchievementMessage(String title, String subtitle) {
    return '🎉 $title\n$subtitle\n\nJoin me on FaceCode!';
  }

  static String _generatePersonalBestMessage(String game, String score, String? percentile) {
    final percentText = percentile != null ? ' (Top $percentile)' : '';
    return '🎯 I just set a new record in FaceCode!\n$game: $score$percentText\n\nThink you can beat me?';
  }

  static String _generateLevelUpMessage(int level, int xp) {
    String milestone = '';
    if (level >= 100) {
      milestone = ' - Legendary!';
    } else if (level >= 50) {
      milestone = ' - Elite player!';
    } else if (level >= 25) {
      milestone = ' - Veteran!';
    } else if (level >= 10) {
      milestone = ' - Rising star!';
    }
    
    return '🎊 Level $level Reached!$milestone\n$xp XP earned\n\nJoin me on FaceCode!';
  }

  static String _generateStreakMessage(int days) {
    return '🔥 $days day streak in FaceCode!\nPlayed every day${days >= 30 ? " for ${(days / 30).floor()} months" : ""}\n\nCan you keep up? Join me!';
  }

  static String _generateBadgeMessage(String badge, String desc, String? rarity) {
    final rarityText = rarity != null ? '\n$rarity badge' : '';
    return '🏆 Badge Unlocked: $badge!\n$desc$rarityText\n\nGet yours on FaceCode!';
  }

  static String _generateChallengeMessage(String game, String challenge) {
    return '💪 I just completed: $challenge in $game!\n\nCan you do it? Download FaceCode and try!';
  }

  @override
  String toString() {
    return 'ShareContent(type: $type, title: $title)';
  }
}
