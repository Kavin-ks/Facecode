import 'dart:math';
import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/models/cosmetic_item.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BadgeFrame extends StatelessWidget {
  final Widget child;
  final CosmeticItem? frameItem;
  final bool isEarned;

  const BadgeFrame({
    super.key,
    required this.child,
    this.frameItem,
    this.isEarned = true,
  });

  @override
  Widget build(BuildContext context) {
    if (frameItem == null || !isEarned) return child;

    return Stack(
      alignment: Alignment.center,
      children: [
        // The Frame Border
        _buildBorder(frameItem!),
        // The Badge Content
        child,
      ],
    );
  }

  Widget _buildBorder(CosmeticItem item) {
    if (item.id == 'frame_diamond') {
      return CustomPaint(
        painter: DiamondFramePainter(),
        size: const Size(80, 80),
      ).animate(onPlay: (c) => c.repeat())
       .shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.5));
    }

    // Default Fallback Frame
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppConstants.primaryColor,
          width: 2,
        ),
      ),
    );
  }
}

class DiamondFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFE5E4E2), // Platinum
          const Color(0xFFB9F2FF), // Diamond Blue
          const Color(0xFFE5E4E2),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw an octagonal-ish frame
    final path = Path();
    const int sides = 8;
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * pi) / sides;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
    
    // Inner Glow
    final Paint glowPaint = Paint()
      ..color = const Color(0xFFB9F2FF).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
