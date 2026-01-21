import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:facecode/utils/constants.dart';

/// Premium gradient background with animated particles effect
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool showParticles;

  const GradientBackground({
    super.key,
    required this.child,
    this.showParticles = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppConstants.backgroundGradient,
        ),
      ),
      child: child,
    );
  }
}

/// Glassmorphism card with blur + subtle gradient
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? [
      Colors.white.withAlpha(12),
      Colors.white.withAlpha(4),
    ];

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withAlpha(30)),
            ),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(AppConstants.defaultPadding),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple shimmer effect for skeleton loaders
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            final gradient = LinearGradient(
              begin: Alignment(-1.0 + _controller.value * 2, -0.3),
              end: Alignment(1.0 + _controller.value * 2, 0.3),
              colors: [
                Colors.white.withAlpha(20),
                Colors.white.withAlpha(60),
                Colors.white.withAlpha(20),
              ],
              stops: const [0.1, 0.5, 0.9],
            );
            return gradient.createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    required this.height,
    required this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  final double height;
  final double width;
  const SkeletonLine({super.key, this.height = 12, this.width = double.infinity});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      height: height,
      width: width,
      borderRadius: BorderRadius.circular(8),
    );
  }
}

/// Neon glowing card with gradient border
class NeonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  const NeonCard({
    super.key,
    required this.child,
    this.padding,
    this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? AppConstants.primaryGradient;
    
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          gradient: LinearGradient(
            colors: colors.map((c) => c.withAlpha(30)).toList(),
          ),
          border: Border.all(
            color: colors.first.withAlpha(50),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withAlpha(30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppConstants.defaultPadding),
          child: child,
        ),
      ),
    );
  }
}

/// Premium gradient button with glow effect
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color>? gradientColors;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradientColors,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors ?? AppConstants.primaryGradient;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : () {
        HapticFeedback.mediumImpact();
        widget.onPressed?.call();
      },
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        width: widget.width ?? double.infinity,
        height: AppConstants.buttonHeight,
        transform: Matrix4.identity()..scaleByDouble(_isPressed ? 0.97 : 1.0, _isPressed ? 0.97 : 1.0, 1.0, 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.onPressed == null 
                ? [Colors.grey.shade700, Colors.grey.shade800]
                : colors,
          ),
          boxShadow: widget.onPressed == null ? null : [
            BoxShadow(
              color: colors.first.withAlpha(_isPressed ? 60 : 100),
              blurRadius: _isPressed ? 15 : 25,
              offset: Offset(0, _isPressed ? 4 : 8),
            ),
          ],
        ),
        child: Center(
          child: widget.isLoading 
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Outlined button with neon glow
class NeonOutlinedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;

  const NeonOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.icon,
  });

  @override
  State<NeonOutlinedButton> createState() => _NeonOutlinedButtonState();
}

class _NeonOutlinedButtonState extends State<NeonOutlinedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppConstants.secondaryColor;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onPressed?.call();
      },
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        width: double.infinity,
        height: AppConstants.buttonHeight,
        transform: Matrix4.identity()..scaleByDouble(_isPressed ? 0.97 : 1.0, _isPressed ? 0.97 : 1.0, 1.0, 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: color, width: 2),
          color: _isPressed ? color.withAlpha(20) : Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(_isPressed ? 40 : 20),
              blurRadius: _isPressed ? 15 : 10,
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: color, size: 22),
                const SizedBox(width: 10),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated logo with glow effect
class AnimatedLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const AnimatedLogo({
    super.key,
    this.size = 120,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showGlow ? BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withAlpha(60),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ) : null,
      child: Text(
        '😎',
        style: TextStyle(fontSize: size),
      ),
    );
  }
}

/// Section title with accent line
class SectionTitle extends StatelessWidget {
  final String title;
  final Color? accentColor;

  const SectionTitle({
    super.key,
    required this.title,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppConstants.primaryColor;
    
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withAlpha(100)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Glowing avatar circle
class GlowingAvatar extends StatelessWidget {
  final String initial;
  final double size;
  final Color? color;

  const GlowingAvatar({
    super.key,
    required this.initial,
    this.size = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = color ?? AppConstants.primaryColor;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [avatarColor, avatarColor.withAlpha(150)],
        ),
        boxShadow: [
          BoxShadow(
            color: avatarColor.withAlpha(60),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Premium stat card
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color>? gradientColors;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? AppConstants.primaryGradient;
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.map((c) => c.withAlpha(20)).toList(),
        ),
        border: Border.all(
          color: colors.first.withAlpha(40),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.first, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: colors.first,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
