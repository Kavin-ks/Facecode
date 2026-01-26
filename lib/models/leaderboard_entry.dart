import 'package:flutter/material.dart';

class LeaderboardEntry {
  final String id;
  final String name;
  final String avatar; // Emoji or initial
  final int score;
  final int level;
  final List<String> badges;
  final int rank;
  final bool isUser;
  final bool isDailyBest;
  final int change; // +1, -2, 0 (rank change)

  final String? rankTitle;
  final Color? rankColor;

  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.avatar,
    required this.score,
    this.level = 1,
    this.badges = const [],
    required this.rank,
    this.isUser = false,
    this.isDailyBest = false,
    this.change = 0,
    this.rankTitle,
    this.rankColor,
  });
}
