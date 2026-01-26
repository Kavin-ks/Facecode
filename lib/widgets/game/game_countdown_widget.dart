import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Reusable countdown widget for games
/// Shows 3, 2, 1, GO! countdown before game starts
class GameCountdownWidget extends StatefulWidget {
  final int seconds;
  final VoidCallback onComplete;
  final String? message;
  final TextStyle? textStyle;

  const GameCountdownWidget({
    super.key,
    this.seconds = 3,
    required this.onComplete,
    this.message,
    this.textStyle,
  });

  @override
  State<GameCountdownWidget> createState() => _GameCountdownWidgetState();
}

class _GameCountdownWidgetState extends State<GameCountdownWidget> {
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _startCountdown();
  }

  void _startCountdown() async {
    while (_remaining > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _remaining--);
      }
    }

    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: 80,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.message != null) ...[
            Text(
              widget.message!,
              style: const TextStyle(
                fontSize: 24,
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
          ],
          Text(
            _remaining > 0 ? '$_remaining' : 'GO!',
            key: ValueKey(_remaining),
            style: widget.textStyle ?? defaultStyle,
          )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 200.ms),
        ],
      ),
    );
  }
}
