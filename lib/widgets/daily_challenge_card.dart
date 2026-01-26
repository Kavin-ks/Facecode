import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/widgets/streak_fire.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:facecode/providers/progress_provider.dart';

import 'package:facecode/utils/game_catalog.dart';
import 'dart:async';

class DailyChallengeCard extends StatefulWidget {
  const DailyChallengeCard({super.key});

  @override
  State<DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends State<DailyChallengeCard> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeLeft());
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    
    if (mounted) {
      setState(() {
        _timeLeft = diff;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  void _playGame(BuildContext context, String id) {
    // Navigate using named routes from GameCatalog
    final game = GameCatalog.getById(id);
    if (game != null) {
      Navigator.pushNamed(context, game.route);
    } else {
      // Fallback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Game not available yet!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>().progress;
    final isCompleted = progress.dailyChallengeCompleted;
    final streak = progress.currentStreak;
    final gameId = progress.dailyChallengeGameId ?? 'emoji_translator';
    final game = GameCatalog.getById(gameId);
    final gameName = game?.name ?? "Mystery Game";

    return GlassCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.accentGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: AppConstants.accentGold, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Daily Challenge",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              // Streak Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    StreakFire(streakDays: streak, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "$streak Day Streak",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Challenge Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.cardPurple.withValues(alpha: 0.3),
                  AppConstants.cardBlue.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCompleted ? "Challenge Complete!" : "Play $gameName",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!isCompleted)
                        Text(
                          "Reward: 100 XP + Streak Bonus",
                          style: TextStyle(
                            color: AppConstants.accentGold,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        const Text(
                          "Come back tomorrow for more!",
                          style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
                        ),
                    ],
                  ),
                ),
                
                if (isCompleted)
                  const Icon(Icons.check_circle_rounded, color: AppConstants.primaryColor, size: 32)
                else
                  AddictivePrimaryButton(
                    label: "PLAY",
                    onPressed: () => _playGame(context, gameId),
                    fullWidth: false,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Footer / Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: AppConstants.textMuted),
              const SizedBox(width: 6),
              Text(
                "Resets in ${_formatDuration(_timeLeft)}",
                style: TextStyle(
                  color: AppConstants.textMuted,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
