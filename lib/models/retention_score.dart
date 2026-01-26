class RetentionScore {
  final double totalScore;
  final double streakWeight;
  final double frequencyWeight;
  final double volumeWeight;
  
  final int streak;
  final int uniqueDaysInLast14;
  final int totalGamesPlayed;
  final int totalUniqueDaysActive;

  RetentionScore({
    required this.totalScore,
    required this.streakWeight,
    required this.frequencyWeight,
    required this.volumeWeight,
    required this.streak,
    required this.uniqueDaysInLast14,
    required this.totalGamesPlayed,
    required this.totalUniqueDaysActive,
  });
}
