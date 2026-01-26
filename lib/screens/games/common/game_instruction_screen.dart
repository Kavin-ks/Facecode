import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/models/game_metadata.dart';
import 'package:facecode/services/game_feedback_service.dart';
import 'package:facecode/widgets/ui_kit.dart';

class GameInstructionScreen extends StatefulWidget {
  final GameMetadata gameInfo;
  final VoidCallback onStart;

  const GameInstructionScreen({
    super.key,
    required this.gameInfo,
    required this.onStart,
  });

  @override
  State<GameInstructionScreen> createState() => _GameInstructionScreenState();
}

class _GameInstructionScreenState extends State<GameInstructionScreen> {
  bool _showInstructions = false;

  @override
  void initState() {
    super.initState();
    // staged reveal of instructions
    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      setState(() => _showInstructions = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameInfo = widget.gameInfo;
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Align(
                alignment: Alignment.topLeft,
                child: PremiumTap(
                  onTap: () {
                    GameFeedbackService.tap();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ).animate(delay: 80.ms).fadeIn(duration: 260.ms).scaleXY(begin: 0.96, end: 1.0, curve: Curves.easeOutBack),
              ),
              
              const Spacer(),
              
              // Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gameInfo.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gameInfo.gradientColors.first.withAlpha(100),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    gameInfo.icon,
                    size: 40,
                    color: Colors.white,
                  ),
                ).animate(delay: 160.ms).scaleXY(begin: 0.8, end: 1.0, curve: Curves.elasticOut).fadeIn(duration: 320.ms),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                gameInfo.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ).animate(delay: 260.ms).scaleXY(begin: 0.92, end: 1.0, curve: Curves.easeOutBack).fadeIn(duration: 320.ms),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                gameInfo.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ).animate(delay: 340.ms).fadeIn(duration: 340.ms, curve: Curves.easeOut),
              
              const SizedBox(height: 32),
              
              // Instructions (Mockup for now, could be passed or looked up)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                child: _showInstructions
                    ? Container(
                        key: const ValueKey('instructions'),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HOW TO PLAY',
                              style: TextStyle(
                                color: AppConstants.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildRule(1, 'Read the instructions carefully.'),
                            _buildRule(2, 'Complete the task before time runs out.'),
                            _buildRule(3, 'Earn XP and climb the leaderboard!'),
                          ],
                        ),
                      ).animate().fadeIn(duration: 420.ms).slide(begin: const Offset(0, 0.04), end: const Offset(0, 0), curve: Curves.easeOutBack)
                    : const SizedBox.shrink(),
              ),
              
              const Spacer(),
              
              // Start Button
              Center(
                child: PremiumTap(
                  onTap: () {
                    GameFeedbackService.tap();
                    widget.onStart();
                  },
                  child: ElevatedButton(
                    onPressed: () {
                      GameFeedbackService.tap();
                      widget.onStart();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Start Game',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.04, duration: 1200.ms, curve: Curves.easeInOut),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRule(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
