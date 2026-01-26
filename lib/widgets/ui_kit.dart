import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/utils/motion.dart';

import 'package:flutter/services.dart';
import 'package:facecode/services/sound_manager.dart';
import 'package:provider/provider.dart';
import 'package:facecode/providers/progress_provider.dart';

export 'package:facecode/widgets/premium_switch.dart';

/// Standard Premium Touch Scale wrapper
/// Gives subtle scale feedback on tap
class PremiumTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleMin;
  final bool enableSound;
  final bool enableHaptics;

  const PremiumTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleMin = 0.95,
    this.enableSound = true,
    this.enableHaptics = true,
  });

  @override
  State<PremiumTap> createState() => _PremiumTapState();
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _PremiumTapState extends State<PremiumTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.durationShort,
      reverseDuration: AppMotion.durationShort,
    );
    // Tap scales down (e.g. 0.95), Hover scales up (e.g. 1.02)
    // We'll manage target scale dynamically in listener or simply use the controller for tap
    // and a separate implied scale for hover.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    if (widget.enableHaptics) HapticFeedback.lightImpact();
    if (widget.enableSound) SoundManager().playUiSound(SoundManager.sfxUiTap);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    // Determine target scale:
    // If tapping (controller.value > 0), we want to scale DOWN to scaleMin.
    // If hovering, we want to scale UP slightly (e.g. 1.02).
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double scale = 1.0;
          
          // Tap effect (priority)
          if (_controller.value > 0) {
            scale = 1.0 - (_controller.value * (1.0 - widget.scaleMin));
          } 
          // Hover effect
          else if (_isHovered && widget.onTap != null) {
            scale = 1.02;
          }

          return Transform.translate(
            offset: _isHovered && widget.onTap != null ? const Offset(0, -4) : Offset.zero,
            child: Transform.scale(
              scale: scale,
              child: widget.child,
            ),
          ).animate(target: _isHovered ? 1 : 0) // Optional extra gloss on hover if needed
          ; 
        },
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          onTap: _handleTap,
          behavior: HitTestBehavior.translucent,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Primary actionable button that pulses to attract attention
class AddictivePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final double? height;
  final double? fontSize;

  const AddictivePrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.height,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumTap(
      onTap: onPressed,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: height,
        padding: EdgeInsets.symmetric(vertical: height == null ? 16 : 0, horizontal: 24),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize ?? 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2000.ms, delay: 3.seconds, color: Colors.white.withValues(alpha: 0.2))
        .scaleXY(begin: 1.0, end: 1.02, duration: 2000.ms, curve: Curves.easeInOut);
  }
}

/// Secondary ghost button for "Sign up later" etc.
class AddictiveSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AddictiveSecondaryButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppConstants.primaryColor.withValues(alpha: 0.9),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Icon Button with PremiumTap
class PremiumIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? tooltip;

  const PremiumIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 24.0,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.transparent, // Hit target
        borderRadius: BorderRadius.circular(50),
      ),
      child: Icon(icon, size: size, color: color ?? Colors.white),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip, child: button);
    }

    return PremiumTap(
      onTap: onPressed,
      child: button,
    );
  }
}

/// Game Card with subtle motion
class LiveGameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final VoidCallback onTap;
  final Color baseColor;

  const LiveGameCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.onTap,
    this.baseColor = const Color(0xFF2A2A2A),
  });

  @override
  Widget build(BuildContext context) {
    // Using native InkWell instead of PremiumTap to guarantee clicks work
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint('🎮 Game card clicked: $title');
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// XP / Streak Bar
class XPStreakBar extends StatelessWidget {
  const XPStreakBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.watch<ProgressProvider>().getLevelBadge(),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final progress = context.watch<ProgressProvider>().progress;
                      return Row(
                        children: [
                          Text(
                            'Level ${progress.level}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${progress.currentXP}/${progress.xpForNextLevel} XP',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  // Progress Bar
                  Builder(
                    builder: (context) {
                      final percent = context.watch<ProgressProvider>().progress.progressPercent;
                      return Container(
                        width: 120,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: percent.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppConstants.primaryGradient,
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
          // Spacer
          const Spacer(),
          Container(height: 24, width: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(width: 16),
          
          // New Animated Streak Counter
          const StreakCounter(),
        ],
      ),
    );
  }
}

class StreakCounter extends StatelessWidget {
  const StreakCounter({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final streak = provider.progress.currentStreak;
    final isAtRisk = provider.isStreakAtRisk;
    final isActiveToday = provider.isStreakActiveToday;

    // Color Logic
    Color flameColor;
    if (streak < 3) {
      flameColor = Colors.orange;
    } else if (streak < 7) {
      flameColor = Colors.deepOrangeAccent;
    } else {
      flameColor = Colors.purpleAccent; // Epic
    }
    
    if (isAtRisk) flameColor = Colors.redAccent;

    return Row(
      children: [
        // Flame Icon with Pulse Loop or Warning Shake
        Icon(
          Icons.local_fire_department_rounded,
          size: 20,
          color: flameColor,
        )
        .animate(
          target: isActiveToday ? 1 : 0, 
          onPlay: (c) => c.repeat(reverse: true)
        )
        .scaleXY(begin: 1.0, end: 1.3, duration: 1.seconds) // Healthy pulse
        .animate(
          target: isAtRisk ? 1 : 0,
          onPlay: (c) => c.repeat()
        )
        .shake(hz: 4, duration: 1.seconds) // Nervous shake if at risk
        .tint(color: Colors.red, duration: 500.ms), // Flash red

        const SizedBox(width: 6),
        
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  streak > 0 ? '$streak' : '-',
                  style: TextStyle(
                    color: flameColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "Day${streak == 1 ? '' : 's'}",
                  style: TextStyle(
                    color: flameColor.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (isAtRisk)
              Text(
                "PLAY NOW",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 500.ms).then().fadeOut(duration: 500.ms),
          ],
        ),
      ],
    );
  }
}

/// Friendly Empty State Widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 300.ms),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              AddictivePrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                fullWidth: false,
              ).animate().fadeIn(delay: 400.ms).scale(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Base Skeleton Widget with Shimmer
class SkeletonBase extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;
  final Color? color;

  const SkeletonBase({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (c) => c.repeat())
    .shimmer(duration: 1.5.seconds, color: Colors.white.withValues(alpha: 0.1));
  }
}

/// Skeleton List Item
class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SkeletonBase(width: 40, height: 40, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBase(width: 120, height: 16),
                const SizedBox(height: 8),
                const SkeletonBase(width: 80, height: 12),
              ],
            ),
          ),
          const SkeletonBase(width: 60, height: 24, radius: 4),
        ],
      ),
    );
  }
}
