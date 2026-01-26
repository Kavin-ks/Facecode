import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';

enum BadgeRarity { common, rare, legendary }

class BadgeData {
  final String id;
  final String label;
  final String description;
  final String icon;
  final BadgeRarity rarity;

  const BadgeData({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    this.rarity = BadgeRarity.common,
  });

  Color get color {
    switch (rarity) {
      case BadgeRarity.common:
        return AppConstants.cardBlue;
      case BadgeRarity.rare:
        return AppConstants.primaryColor;
      case BadgeRarity.legendary:
        return AppConstants.accentGold;
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case BadgeRarity.common: return 'COMMON';
      case BadgeRarity.rare: return 'RARE';
      case BadgeRarity.legendary: return 'LEGENDARY';
    }
  }

  // Centralized Badge Definitions
  static const List<BadgeData> allBadges = [
    BadgeData(
      id: 'newbie',
      label: 'Newbie',
      description: 'Played your first game',
      icon: '🐣',
      rarity: BadgeRarity.common,
    ),
    BadgeData(
      id: 'hot_streak',
      label: 'Hot Streak',
      description: 'Reached a 5-day streak',
      icon: '🔥',
      rarity: BadgeRarity.rare,
    ),
    BadgeData(
      id: 'artist',
      label: 'Artist',
      description: 'Created 10 drawings',
      icon: '🎨',
      rarity: BadgeRarity.common,
    ),
    BadgeData(
      id: 'thinker',
      label: 'Thinker',
      description: 'Won 3 "Would You Rather" games',
      icon: '🧠',
      rarity: BadgeRarity.rare,
    ),
    BadgeData(
      id: 'party_king',
      label: 'Party King',
      description: 'Top tier player performance',
      icon: '👑',
      rarity: BadgeRarity.legendary,
    ),
    BadgeData(
      id: 'veteran_50_games',
      label: 'Veteran',
      description: 'Played 50 games total',
      icon: '🎖️',
      rarity: BadgeRarity.rare,
    ),
    BadgeData(
      id: 'first_win',
      label: 'First Victory',
      description: 'Won your first game ever',
      icon: '🏆',
      rarity: BadgeRarity.common,
    ),
    BadgeData(
      id: 'fast_thinker',
      label: 'Lightning Reflexes',
      description: 'Reaction time under 200ms',
      icon: '⚡️',
      rarity: BadgeRarity.rare,
    ),
    BadgeData(
      id: 'party_starter',
      label: 'Public Host',
      description: 'Played 3 different party games',
      icon: '🎉',
      rarity: BadgeRarity.rare,
    ),
    BadgeData(
      id: 'game_master',
      label: 'Legendary Status',
      description: 'Level 20 + 50 wins',
      icon: '👑',
      rarity: BadgeRarity.legendary,
    ),
    BadgeData(
      id: 'streak_10',
      label: 'Unstoppable',
      description: 'Reached a 10-day streak',
      icon: '🚀',
      rarity: BadgeRarity.legendary,
    ),
    BadgeData(
      id: 'lucky_charm',
      label: 'Lucky Charm',
      description: 'Unlocked a rare surprise bonus',
      icon: '🍀',
      rarity: BadgeRarity.rare,
    ),
    BadgeData(
      id: 'mystery_solver',
      label: 'Mystery Solver',
      description: 'Opened a high-tier mystery box',
      icon: '🕵️‍♂️',
      rarity: BadgeRarity.legendary,
    ),
  ];

  static BadgeData? getById(String id) {
    try {
      return allBadges.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
