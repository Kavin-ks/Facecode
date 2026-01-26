import 'package:flutter/material.dart';

enum DrawPhase { home, lobby, choosingWord, drawing, reveal, scoreboard }

enum WordDifficulty { easy, medium, hard, mixed }

enum WordCategory { objects, animals, movies, food, actions, random }

class GameSettings {
  int rounds; // 0 = endless
  int drawTime; // seconds
  WordDifficulty difficulty;
  WordCategory category;
  String language;
  bool aiFallback;
  int aiLevel; // 1 = casual, 2 = balanced, 3 = sharp

  GameSettings({
    this.rounds = 5,
    this.drawTime = 80,
    this.difficulty = WordDifficulty.mixed,
    this.category = WordCategory.random,
    this.language = 'EN',
    this.aiFallback = true,
    this.aiLevel = 2,
  });
}

class Player {
  final String id;
  final String name;
  int score;
  bool isDrawer;
  bool isAI;
  String? avatar;

  Player({
    required this.id,
    required this.name,
    this.score = 0,
    this.isDrawer = false,
    this.isAI = false,
    this.avatar,
  });
}

class Room {
  final String code;
  final List<Player> players;
  int round;
  final GameSettings settings;
  final String hostId;

  Room({
    required this.code,
    required this.players,
    required this.round,
    required this.settings,
    required this.hostId,
  });
}

class Stroke {
  final List<Offset?> points;
  final Color color;
  final double thickness;
  final bool isEraser;

  Stroke({
    required this.points,
    required this.color,
    required this.thickness,
    required this.isEraser,
  });
}

class GuessMessage {
  final String name;
  final String text;
  final bool isCorrect;
  final bool isSystem;

  const GuessMessage({
    required this.name,
    required this.text,
    this.isCorrect = false,
    this.isSystem = false,
  });
}
