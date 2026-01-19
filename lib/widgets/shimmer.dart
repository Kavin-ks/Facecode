import 'package:flutter/material.dart';
import 'package:facecode/utils/color_ext.dart';

/// Lightweight shimmer effect using ShaderMask and animated gradient
class Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const Shimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

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
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: ShaderMask(
            shaderCallback: (bounds) {
              final width = bounds.width;
              final gradientPosition = (_controller.value * 2 - 0.5);
              return LinearGradient(
                begin: Alignment(-1 - gradientPosition, -0.3),
                end: Alignment(1 - gradientPosition, 0.3),
                colors: [
                  Colors.white.withOpacitySafe(0.05),
                  Colors.white.withOpacitySafe(0.15),
                  Colors.white.withOpacitySafe(0.05),
                ],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(Rect.fromLTWH(0, 0, width, bounds.height));
            },
            blendMode: BlendMode.srcATop,
            child: Container(
              width: widget.width,
              height: widget.height,
              color: Colors.white.withOpacitySafe(0.02),
            ),
          ),
        );
      },
    );
  }
}
