import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/services/game_feedback_service.dart';
import 'package:facecode/services/sound_manager.dart';
import 'package:facecode/providers/shop_provider.dart';
import 'package:facecode/models/cosmetic_item.dart';
import 'package:provider/provider.dart';

class SpinnerWheel extends StatefulWidget {
  final List<String> names;
  final Duration duration;
  final Function(int) onResult;

  const SpinnerWheel({
    super.key,
    required this.names,
    this.duration = const Duration(seconds: 5),
    required this.onResult,
  });

  @override
  State<SpinnerWheel> createState() => SpinnerWheelState();
}

class SpinnerWheelState extends State<SpinnerWheel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentAngle = 0;
  int _lastSelectedIndex = -1;

  // For tick sounds and pointer bounce
  int _lastTickIndex = -1;
  DateTime? _lastTickAt;

  // Wobble offset for final settle
  double _wobbleOffset = 0.0;
  AnimationController? _wobbleController;
  Animation<double>? _wobbleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Listen for angle updates to play tick sounds as segments pass the pointer
    _controller.addListener(() {
      final angle = _controller.isAnimating ? _animation.value : _currentAngle;
      final int idx = _indexAtPointer(angle, widget.names.length);

      if (_controller.isAnimating && idx != _lastTickIndex) {
        _lastTickIndex = idx;
        _lastTickAt = DateTime.now();
        // play a subtle tick sound and light haptic
        GameFeedbackService.tick();
        SoundManager().playGameSound(SoundManager.sfxTimerTick);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _wobbleController?.dispose();
    super.dispose();
  }

  void spin() {
    if (_controller.isAnimating) return;

    // Haptic feedback on spin start
    HapticFeedback.mediumImpact();
    
    final random = Random();
    
    // Advanced physics: More realistic spinning
    // Spin between 8-12 full rotations + random offset
    final baseRotations = 8 + random.nextDouble() * 4; // 8-12 spins
    
    // Calculate target ensuring we don't repeat the same player
    int targetIndex;
    do {
      targetIndex = random.nextInt(widget.names.length);
    } while (targetIndex == _lastSelectedIndex && widget.names.length > 1);
    
    // Calculate exact angle to land on target segment
    final segmentAngle = (2 * pi) / widget.names.length;
    final targetSegmentAngle = targetIndex * segmentAngle + (segmentAngle / 2);
    final double targetAngle = _currentAngle + (baseRotations * 2 * pi) + targetSegmentAngle;
    
    _animation = Tween<double>(begin: _currentAngle, end: targetAngle).animate(
      CurvedAnimation(
        parent: _controller, 
        curve: Curves.easeOutQuart, // More natural deceleration with a crisp finish
      ),
    );

    _lastTickIndex = -1;
    _controller.reset();
    _controller.forward().whenComplete(() async {
      _currentAngle = targetAngle % (2 * pi); // Normalize angle
      _lastSelectedIndex = targetIndex;

      // Short settle wobble for anticipation
      _wobbleController?.dispose();
      _wobbleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
      _wobbleAnim = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.12).chain(CurveTween(curve: Curves.easeOut)), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.06).chain(CurveTween(curve: Curves.easeInOut)), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 1),
      ]).animate(_wobbleController!);
      _wobbleAnim!.addListener(() { _wobbleOffset = _wobbleAnim!.value; setState(() {}); });
      await _wobbleController!.forward();
      _wobbleController!.dispose();
      _wobbleController = null;
      _wobbleAnim = null;
      _wobbleOffset = 0.0;

      // Strong haptic on completion and final tick
      HapticFeedback.heavyImpact();
      SoundManager().playGameSound(SoundManager.sfxPop);
      widget.onResult(targetIndex);
    });
  }

  int _indexAtPointer(double angle, int count) {
    final sweep = (2 * pi) / count;
    final v = (pi / 2 - angle) / sweep;
    int idx = v.floor() % count;
    if (idx < 0) idx += count;
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final shop = context.watch<ShopProvider>();
            final equippedSkin = shop.getEquippedItem(CosmeticType.wheelSkin);
            final glowColor = equippedSkin?.metadata?['glowColor'] as Color? ?? AppConstants.primaryColor;

            return Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: _controller.isAnimating ? 0.6 : 0.3),
                    blurRadius: _controller.isAnimating ? 40 : 20,
                    spreadRadius: _controller.isAnimating ? 10 : 5,
                  )
                ],
              ),
            );
          },
        ),
        
        // The Wheel
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final shop = context.watch<ShopProvider>();
            final equippedSkin = shop.getEquippedItem(CosmeticType.wheelSkin);
            final customColors = (equippedSkin?.metadata?['colors'] as List?)?.cast<Color>();

            final angle = _controller.isAnimating ? _animation.value : (_currentAngle + _wobbleOffset);
            return Transform.rotate(
              angle: angle,
              child: CustomPaint(
                size: const Size(300, 300),
                painter: WheelPainter(
                  names: widget.names,
                  customColors: customColors,
                ),
              ),
            );
          },
        ),
        
        // The Pointer (Arrow at top) with subtle bounce on ticks
        Positioned(
          top: -8,
          child: Builder(
            builder: (context) {
              double scale = 1.0;
              if (_lastTickAt != null) {
                final dt = DateTime.now().difference(_lastTickAt!).inMilliseconds;
                if (dt < 160) {
                  scale = 1.08 - (dt / 160) * 0.08;
                }
              }
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 40,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.yellow.shade600, Colors.orange.shade700],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20), 
                      bottomRight: Radius.circular(20)
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_drop_down, 
                    color: Colors.white, 
                    size: 40,
                  ),
                ),
              );
            },
          ),
        ),
        
        // Center Pin with spin indicator
        GestureDetector(
          onTap: () => spin(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey.shade300,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3), 
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ],
                  border: Border.all(
                    color: AppConstants.primaryColor,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: _controller.isAnimating
                      ? const Icon(
                          Icons.motion_photos_on,
                          color: AppConstants.primaryColor,
                          size: 28,
                        )
                      : const Icon(
                          Icons.touch_app,
                          color: AppConstants.primaryColor,
                          size: 28,
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> names;
  final List<Color> colors = [
    const Color(0xFF6C5CE7), // Purple
    const Color(0xFFE84393), // Pink
    const Color(0xFF00CEC9), // Cyan
    const Color(0xFFFDCB6E), // Yellow
    const Color(0xFF0984E3), // Blue
    const Color(0xFF00B894), // Green
    const Color(0xFFD63031), // Red
    const Color(0xFFE17055), // Orange
    const Color(0xFFA29BFE), // Light Purple
    const Color(0xFFFF7675), // Light Red
  ];

  final List<Color>? customColors;

  WheelPainter({required this.names, this.customColors});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final int count = names.length;
    final double sweepAngle = (2 * pi) / count;

    // Draw segments
    for (int i = 0; i < count; i++) {
      final colorList = customColors ?? colors;
      final Paint paint = Paint()
        ..color = colorList[i % colorList.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle - (pi / 2), // Start from top
        sweepAngle,
        true,
        paint,
      );

      // Draw segment borders
      final Paint borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle - (pi / 2),
        sweepAngle,
        true,
        borderPaint,
      );

      // Draw Name with better positioning
      final textPainter = TextPainter(
        text: TextSpan(
          text: names[i],
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 14, 
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(1, 1),
                blurRadius: 2,
              )
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      // Rotate to segment center
      canvas.translate(center.dx, center.dy);
      canvas.rotate((i * sweepAngle) + (sweepAngle / 2) - (pi / 2));
      // Move to edge (closer to center for better visibility)
      canvas.translate(radius * 0.55, 0);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
    
    // Outer Border with gradient effect
    final Paint outerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, outerBorderPaint);
    
    // Inner circle for depth
    final Paint innerCirclePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius * 0.3, innerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
