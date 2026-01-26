import 'package:flutter/material.dart';

enum CosmeticType { theme, wheelSkin, soundPack, badgeFrame }

enum CosmeticRarity { common, rare, legendary }

class CosmeticItem {
  final String id;
  final String name;
  final String description;
  final CosmeticType type;
  final CosmeticRarity rarity;
  final int price;
  final String? previewAsset;
  final Map<String, dynamic>? metadata;
  final bool isEliteOnly;

  const CosmeticItem({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.rarity = CosmeticRarity.common,
    required this.price,
    this.previewAsset,
    this.metadata,
    this.isEliteOnly = false,
  });

  static const List<CosmeticItem> allItems = [
    // THEMES
    CosmeticItem(
      id: 'theme_cyberpunk',
      name: 'Neon Tokyo',
      description: 'Futuristic vibrant neon theme with high contrast.',
      type: CosmeticType.theme,
      rarity: CosmeticRarity.legendary,
      price: 1250,
      metadata: {
        'primary': Color(0xFF00FFF2), // Cyan neon
        'background': Color(0xFF0D0221), // Midnight blue
        'surface': Color(0xFF1B0245), // Deep purple
        'text': Colors.white,
      },
    ),
    CosmeticItem(
      id: 'theme_oceanic',
      name: 'Deep Sea',
      description: 'Calming blue and teal tones for a relaxed vibe.',
      type: CosmeticType.theme,
      rarity: CosmeticRarity.rare,
      price: 500,
      metadata: {
        'primary': Color(0xFF008080), // Teal
        'background': Color(0xFF001F3F), // Navy
        'surface': Color(0xFF003366), // Blue
        'text': Color(0xFFE0F7FA),
      },
    ),
    CosmeticItem(
      id: 'theme_elite_obsidian',
      name: 'Obsidian & Gold',
      description: 'The definitive Elite theme. Deep obsidian with liquid gold accents.',
      type: CosmeticType.theme,
      rarity: CosmeticRarity.legendary,
      price: 2500,
      isEliteOnly: true,
      metadata: {
        'primary': Color(0xFFFFD700), // Gold
        'background': Color(0xFF0D0221), // Midnight
        'surface': Color(0xFF1B0245), // Deep
        'text': Colors.white,
      },
    ),
    
    // WHEEL SKINS
    CosmeticItem(
      id: 'wheel_glow',
      name: 'Cyber-Tread',
      description: 'Glowing circuitry patterns for the spinner wheel.',
      type: CosmeticType.wheelSkin,
      rarity: CosmeticRarity.rare,
      price: 250,
      metadata: {
        'colors': [
          Color(0xFF00FFF2), // Cyan
          Color(0xFF10002B), // Deep Purple
        ],
        'glowColor': Color(0xFF00FFF2),
      },
    ),
    CosmeticItem(
      id: 'wheel_gold',
      name: 'Midas Touch',
      description: 'Solid gold finish with premium reflections.',
      type: CosmeticType.wheelSkin,
      rarity: CosmeticRarity.legendary,
      price: 1000,
      metadata: {
        'colors': [
          Color(0xFFFFD700), // Gold
          Color(0xFFB8860B), // Dark Gold
        ],
        'glowColor': Color(0xFFFFD700),
      },
    ),

    // SOUND PACKS
    CosmeticItem(
      id: 'sound_retro',
      name: 'Synth Wave',
      description: 'Classic 80s synthesizer sounds for every interaction.',
      type: CosmeticType.soundPack,
      rarity: CosmeticRarity.rare,
      price: 500,
    ),
    CosmeticItem(
      id: 'sound_mechanical',
      name: 'Tactile Click',
      description: 'Satisfying mechanical keyboard sounds.',
      type: CosmeticType.soundPack,
      rarity: CosmeticRarity.common,
      price: 200,
    ),

    // BADGE FRAMES
    CosmeticItem(
      id: 'frame_diamond',
      name: 'Platinum Elite',
      description: 'Animated diamond-encrusted frame for your badges.',
      type: CosmeticType.badgeFrame,
      rarity: CosmeticRarity.legendary,
      price: 750,
    ),
  ];
}
