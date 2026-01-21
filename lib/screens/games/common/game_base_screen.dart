import 'dart:async';
import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/services/game_feedback_service.dart';

class GameBaseScreen extends StatefulWidget {
  final String title;
  final Widget child;
  final Widget? bottomAction;
  final int? timeLimit; // in seconds
  final VoidCallback? onTimerExpired;
  final int score;
  final Function(int)? onValidation; // Function to validate answer

  const GameBaseScreen({
    super.key,
    required this.title,
    required this.child,
    this.bottomAction,
    this.timeLimit,
    this.onTimerExpired,
    this.score = 0,
    this.onValidation,
  });

  @override
  State<GameBaseScreen> createState() => _GameBaseScreenState();
}

class _GameBaseScreenState extends State<GameBaseScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _remainingTime = 0;
  final bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    if (widget.timeLimit != null) {
      _remainingTime = widget.timeLimit!;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _timer?.cancel();
        if (widget.onTimerExpired != null) {
          widget.onTimerExpired!();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Timer Bar (if applicable)
            if (widget.timeLimit != null)
              LinearProgressIndicator(
                value: _remainingTime / widget.timeLimit!,
                backgroundColor: AppConstants.surfaceColor,
                color: _remainingTime < 5 ? AppConstants.errorColor : AppConstants.primaryColor,
                minHeight: 4,
              ),

            // Game Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: widget.child,
              ),
            ),
            
            // Bottom Action (optional)
            if (widget.bottomAction != null)
              widget.bottomAction!,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Close/Back Button
          GestureDetector(
            onTap: () {
              GameFeedbackService.tap();
               Navigator.of(context).maybePop();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          
          // Score/Timer
          if (widget.timeLimit != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.warningColor.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppConstants.warningColor.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: AppConstants.warningColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$_remainingTime s',
                    style: const TextStyle(
                      color: AppConstants.warningColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.successColor.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppConstants.successColor.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: AppConstants.successColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${widget.score}',
                  style: const TextStyle(
                    color: AppConstants.successColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
