import 'dart:math';
import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';

class SpinnerWheel extends StatefulWidget {
  final List<String> names;
  final Duration duration;
  final Function(int) onResult;

  const SpinnerWheel({
    super.key,
    required this.names,
    this.duration = const Duration(seconds: 4),
    required this.onResult,
  });

  @override
  State<SpinnerWheel> createState() => SpinnerWheelState();
}

class SpinnerWheelState extends State<SpinnerWheel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentAngle = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void spin() {
    if (_controller.isAnimating) return;

    final random = Random();
    // Spin at least 5 times + random offset
    final double targetAngle = _currentAngle + (10 * pi) + (random.nextDouble() * 2 * pi);
    
    _animation = Tween<double>(begin: _currentAngle, end: targetAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
    );

    _controller.reset();
    _controller.forward().whenComplete(() {
      _currentAngle = targetAngle;
      
      // Determine winner
      int count = widget.names.length;
      
      // The pointer is at the top (-pi/2 or 3pi/2).
      // If we rotate clockwise by A, the name at the top is the one that was at (offset - A)
      // Top offset is 3pi/2 (270 degrees) if 0 is right.
      
      // Simplified: index = (count - (normalized / segment).floor()) % count
      // We need to account for initial offset if 0 isn't top. 
      // Most canvases draw 0 at right.
      
      int index = ((targetAngle / (2 * pi)) * count).floor() % count;
      // Invert because rotation moves names past pointer
      index = (count - 1 - index) % count;
      
      widget.onResult(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // The Wheel
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.isAnimating ? _animation.value : _currentAngle,
              child: CustomPaint(
                size: const Size(300, 300),
                painter: WheelPainter(names: widget.names),
              ),
            );
          },
        ),
        
        // The Pointer
        Positioned(
          top: 0,
          child: Container(
            width: 30,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15))
            ),
            child: const Icon(Icons.arrow_drop_down, color: AppConstants.backgroundColor, size: 30),
          ),
        ),
        
        // Center Pin
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)]
          ),
          child: const Center(
            child: Text("SPIN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppConstants.backgroundColor)),
          ),
        ),
      ],
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> names;
  final List<Color> colors = [
    const Color(0xFF6C5CE7), const Color(0xFFE84393), const Color(0xFF00CEC9),
    const Color(0xFFFDCB6E), const Color(0xFF0984E3), const Color(0xFF636E72),
    const Color(0xFFD63031), const Color(0xFFE17055)
  ];

  WheelPainter({required this.names});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final int count = names.length;
    final double sweepAngle = (2 * pi) / count;

    for (int i = 0; i < count; i++) {
      final Paint paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw Name
      final textPainter = TextPainter(
        text: TextSpan(
          text: names[i],
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      // Rotate to segment center
      canvas.translate(center.dx, center.dy);
      canvas.rotate((i * sweepAngle) + (sweepAngle / 2));
      // Move to edge
      canvas.translate(radius * 0.6, 0);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
    
    // Outer Border
    final Paint borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
