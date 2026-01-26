import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:facecode/utils/constants.dart';

class StreakFire extends StatelessWidget {
  final int streakDays;
  final double size;

  const StreakFire({
    super.key,
    required this.streakDays,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    // If no streak, show a grayed out flame
    if (streakDays == 0) {
      return Icon(
        Icons.local_fire_department_rounded,
        size: size,
        color: Colors.white.withValues(alpha: 0.2),
      );
    }

    final isHotStreak = streakDays >= 5;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Glow
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isHotStreak ? Colors.red.withValues(alpha: 0.6) : Colors.orange.withValues(alpha: 0.4),
                blurRadius: size * 0.8,
                spreadRadius: size * 0.2,
              ),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.2, 1.2),
          duration: isHotStreak ? 600.ms : 1.seconds,
        ),

        // Core Flame
        Icon(
          Icons.local_fire_department_rounded,
          size: size,
          color: isHotStreak ? const Color(0xFFFF4500) : AppConstants.cardOrange,
        ).animate(onPlay: (c) => c.repeat(reverse: true)).tint(
          color: Colors.yellow,
          begin: 0.0,
          end: 0.3,
          duration: 1.seconds,
        ),
      ],
    );
  }
}
