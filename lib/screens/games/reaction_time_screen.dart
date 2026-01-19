import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/premium_ui.dart';

/// Reaction Time mini-game
class ReactionTimeScreen extends StatefulWidget {
  const ReactionTimeScreen({super.key});

  @override
  State<ReactionTimeScreen> createState() => _ReactionTimeScreenState();
}

class _ReactionTimeScreenState extends State<ReactionTimeScreen> {
  late ConfettiController _confettiController;
  
  GameState _state = GameState.ready;
  Timer? _delayTimer;
  DateTime? _showTime;
  int? _reactionTime;
  int _bestTime = 999999;
  int _attempts = 0;
  final List<int> _recentTimes = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startGame() {
    if (_state != GameState.ready) return;

    setState(() {
      _state = GameState.waiting;
      _reactionTime = null;
    });

    HapticFeedback.lightImpact();

    // Random delay between 1-5 seconds
    final random = Random();
    final delay = 1000 + random.nextInt(4000);

    _delayTimer = Timer(Duration(milliseconds: delay), () {
      if (mounted && _state == GameState.waiting) {
        setState(() {
          _state = GameState.tap;
          _showTime = DateTime.now();
        });
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _onTap() {
    if (_state == GameState.waiting) {
      // Too early!
      _delayTimer?.cancel();
      setState(() {
        _state = GameState.tooEarly;
      });
      HapticFeedback.heavyImpact();
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _state = GameState.ready;
          });
        }
      });
    } else if (_state == GameState.tap && _showTime != null) {
      // Calculate reaction time
      final now = DateTime.now();
      final diff = now.difference(_showTime!).inMilliseconds;
      
      setState(() {
        _reactionTime = diff;
        _attempts++;
        _recentTimes.add(diff);
        if (_recentTimes.length > 5) {
          _recentTimes.removeAt(0);
        }
        
        if (diff < _bestTime) {
          _bestTime = diff;
          _confettiController.play();
        }
        
        _state = GameState.result;
      });

      HapticFeedback.mediumImpact();
      
      // Award XP based on performance
      final progress = context.read<ProgressProvider>();
      if (diff < 200) {
        progress.awardXP(50); // Amazing!
      } else if (diff < 300) {
        progress.awardXP(30); // Great!
      } else if (diff < 400) {
        progress.awardXP(20); // Good
      } else {
        progress.awardXP(10); // Try again
      }
    }
  }

  void _reset() {
    setState(() {
      _state = GameState.ready;
      _reactionTime = null;
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Reaction Time',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'Best',
                            value: _bestTime == 999999 ? '-' : '${_bestTime}ms',
                            icon: Icons.star,
                            gradientColors: AppConstants.goldGradient,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: 'Attempts',
                            value: '$_attempts',
                            icon: Icons.repeat,
                            gradientColors: AppConstants.primaryGradient,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: 'Avg',
                            value: _recentTimes.isEmpty 
                                ? '-' 
                                : '${(_recentTimes.reduce((a, b) => a + b) / _recentTimes.length).round()}ms',
                            icon: Icons.trending_up,
                            gradientColors: const [Color(0xFF00E5FF), Color(0xFF536DFE)],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Game Area
                  Expanded(
                    child: GestureDetector(
                      onTap: _onTap,
                      child: _buildGameArea(),
                    ),
                  ),

                  // Instructions/Button
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: _buildBottomSection(),
                  ),
                ],
              ),
            ),
            
            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.05,
                shouldLoop: false,
                colors: const [
                  AppConstants.accentGold,
                  AppConstants.primaryColor,
                  AppConstants.secondaryColor,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameArea() {
    Color backgroundColor;
    Widget content;

    switch (_state) {
      case GameState.ready:
        backgroundColor = AppConstants.surfaceColor;
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              size: 100,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Ready?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to start',
              style: TextStyle(
                fontSize: 18,
                color: AppConstants.textMuted,
              ),
            ),
          ],
        );
        break;

      case GameState.waiting:
        backgroundColor = const Color(0xFFFF4081);
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.access_time,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'Wait...',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Get ready to tap!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
          ],
        );
        break;

      case GameState.tap:
        backgroundColor = const Color(0xFF00E676);
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.flash_on,
              size: 120,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'TAP NOW!',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        );
        break;

      case GameState.tooEarly:
        backgroundColor = const Color(0xFFFF5252);
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.cancel,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'Too Early!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Wait for green!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
          ],
        );
        break;

      case GameState.result:
        backgroundColor = AppConstants.surfaceColor;
        final time = _reactionTime ?? 0;
        String rating;
        Color ratingColor;

        if (time < 200) {
          rating = 'AMAZING! 🔥';
          ratingColor = AppConstants.accentGold;
        } else if (time < 300) {
          rating = 'GREAT! ⚡';
          ratingColor = AppConstants.successColor;
        } else if (time < 400) {
          rating = 'GOOD! 👍';
          ratingColor = AppConstants.primaryColor;
        } else {
          rating = 'TRY AGAIN! 💪';
          ratingColor = AppConstants.secondaryColor;
        }

        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${time}ms',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              rating,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: ratingColor,
              ),
            ),
            if (time == _bestTime && _attempts > 1) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppConstants.goldGradient,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🏆 NEW BEST!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        );
        break;
    }

    return AnimatedContainer(
      duration: AppConstants.animationFast,
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withAlpha(100),
            blurRadius: 20,
          ),
        ],
      ),
      child: Center(child: content),
    );
  }

  Widget _buildBottomSection() {
    if (_state == GameState.ready) {
      return GradientButton(
        text: 'Start',
        icon: Icons.play_arrow,
        onPressed: _startGame,
      );
    } else if (_state == GameState.result) {
      return GradientButton(
        text: 'Try Again',
        icon: Icons.refresh,
        onPressed: _reset,
      );
    } else {
      return NeonCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              color: AppConstants.secondaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              _state == GameState.waiting
                  ? 'Wait for the green screen!'
                  : 'Don\'t tap too early!',
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
  }
}

enum GameState {
  ready,
  waiting,
  tap,
  tooEarly,
  result,
}
