import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/models/game_metadata.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/services/game_feedback_service.dart';

class GameResultScreen extends StatefulWidget {
  final GameMetadata gameInfo;
  final int score;
  final bool isWin;
  final VoidCallback onReplay;
  final VoidCallback? onHome;
  final String? customMessage;

  const GameResultScreen({
    super.key,
    required this.gameInfo,
    required this.score,
    required this.isWin,
    required this.onReplay,
    this.onHome,
    this.customMessage,
  });

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _xpAwarded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    
    // Record result only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_xpAwarded) {
        if (!mounted) return;
        final xp = widget.isWin ? widget.gameInfo.xpReward : (widget.gameInfo.xpReward ~/ 4);
        context.read<ProgressProvider>().recordGameResult(
          gameId: widget.gameInfo.id,
          won: widget.isWin,
          xpAward: xp,
        );
        if (widget.isWin) {
          GameFeedbackService.success();
        } else {
          GameFeedbackService.error();
        }
        _xpAwarded = true;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>().progress;
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
              
              // Result Icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isWin 
                          ? AppConstants.successColor.withAlpha(20) 
                          : AppConstants.errorColor.withAlpha(20),
                      border: Border.all(
                        color: widget.isWin ? AppConstants.successColor : AppConstants.errorColor,
                        width: 4,
                      ),
                    ),
                    child: Icon(
                      widget.isWin ? Icons.emoji_events : Icons.close,
                      size: 60,
                      color: widget.isWin ? AppConstants.successColor : AppConstants.errorColor,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                widget.isWin ? 'VICTORY!' : 'GAME OVER',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Text(
                widget.customMessage ?? (widget.isWin ? 'You are amazing!' : 'Better luck next time!'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Stats Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Score', '${widget.score}'),
                        Container(height: 40, width: 1, color: AppConstants.borderColor),
                        _buildStat('XP Earned', '+${widget.isWin ? widget.gameInfo.xpReward : (widget.gameInfo.xpReward ~/ 4)}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Streak', '${progress.currentStreak}'),
                        Container(height: 40, width: 1, color: AppConstants.borderColor),
                        _buildStat('Total Wins', '${progress.totalWins}'),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (widget.onHome != null) {
                              widget.onHome!();
                            } else {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppConstants.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Home'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed(widget.gameInfo.route);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Play Again',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
