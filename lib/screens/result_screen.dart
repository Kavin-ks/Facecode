import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:facecode/models/game_room.dart';
import 'package:facecode/providers/game_provider.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/game_screen.dart';
import 'package:facecode/screens/home_screen.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/error_listener.dart';

/// Premium round results screen with scores + confetti on correct guess.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GameProvider>();
      if (provider.lastRoundWasCorrect) {
        HapticFeedback.heavyImpact();
        _confetti.play();
      }
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _nextRound(BuildContext context) {
    HapticFeedback.mediumImpact();
    final provider = context.read<GameProvider>();
    provider.nextRound();
    Navigator.of(context).pushReplacement(AppRoute.fadeSlide(const GameScreen()));
  }

  void _backToHome(BuildContext context) {
    context.read<GameProvider>().leaveRoom();
    Navigator.of(context).pushAndRemoveUntil(
      AppRoute.fadeSlide(const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorListener(
      child: Consumer<GameProvider>(
        builder: (context, provider, _) {
          final room = provider.currentRoom;
          if (room == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (room.state != GameState.results) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                AppRoute.fadeSlide(const GameScreen()),
              );
            });
          }

          final answer = provider.lastCorrectAnswer ?? '—';
          final players = [...room.players]..sort((a, b) => b.score.compareTo(a.score));
          final wasCorrect = provider.lastRoundWasCorrect;
          final wasTimeout = provider.lastRoundEndedByTime;

          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D0D12),
                    Color(0xFF1A1A2E),
                    Color(0xFF0D0D12),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Confetti
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confetti,
                      blastDirectionality: BlastDirectionality.explosive,
                      emissionFrequency: 0.06,
                      numberOfParticles: 25,
                      maxBlastForce: 15,
                      minBlastForce: 8,
                      gravity: 0.2,
                      colors: const [
                        AppConstants.primaryColor,
                        AppConstants.secondaryColor,
                        AppConstants.neonPink,
                        AppConstants.neonBlue,
                        AppConstants.goldAccent,
                      ],
                    ),
                  ),
                  
                  SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConstants.largePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          
                          // Result header
                          _buildResultHeader(wasCorrect, wasTimeout, answer),

                          const SizedBox(height: AppConstants.xlPadding),

                          // Leaderboard
                          _buildLeaderboard(players),

                          const SizedBox(height: AppConstants.xlPadding),

                          // Action buttons
                          if (provider.isHost)
                            _buildNextRoundButton()
                          else
                            _buildWaitingCard(),

                          const SizedBox(height: AppConstants.defaultPadding),

                          _buildExitButton(),
                          
                          const SizedBox(height: AppConstants.largePadding),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultHeader(bool wasCorrect, bool wasTimeout, String answer) {
    final resultEmoji = wasCorrect ? '🎉' : (wasTimeout ? '⏰' : '😔');
    final resultText = wasCorrect ? 'Correct!' : (wasTimeout ? 'Time Up!' : 'Round Over');
    final resultColor = wasCorrect ? AppConstants.successColor : (wasTimeout ? AppConstants.goldAccent : AppConstants.errorColor);

    return Container(
      padding: const EdgeInsets.all(AppConstants.xlPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            resultColor.withAlpha(30),
            resultColor.withAlpha(15),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: resultColor.withAlpha(80),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: resultColor.withAlpha(30),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            resultEmoji,
            style: const TextStyle(fontSize: 60),
          )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 800.ms,
              ),
          
          const SizedBox(height: 16),
          
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: wasCorrect 
                  ? [AppConstants.successColor, AppConstants.neonBlue]
                  : [resultColor, resultColor.withAlpha(180)],
            ).createShader(bounds),
            child: Text(
              resultText,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor.withAlpha(150),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'THE ANSWER WAS',
              style: TextStyle(
                color: AppConstants.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
          
          const SizedBox(height: 12),
          
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: AppConstants.neonGradient,
            ).createShader(bounds),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildLeaderboard(List<dynamic> players) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withAlpha(150),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.leaderboard, color: AppConstants.goldAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'LEADERBOARD',
                style: TextStyle(
                  color: AppConstants.goldAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.largePadding),
          
          ...players.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            
            return _buildLeaderboardItem(player, index);
          }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLeaderboardItem(dynamic player, int index) {
    final medals = ['🥇', '🥈', '🥉'];
    final medal = index < 3 ? medals[index] : '${index + 1}';
    final isTop3 = index < 3;
    final colors = [
      AppConstants.goldAccent,
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTop3 
            ? colors[index].withAlpha(15) 
            : AppConstants.backgroundColor.withAlpha(100),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTop3 
              ? colors[index].withAlpha(50) 
              : AppConstants.borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isTop3 ? colors[index].withAlpha(30) : AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                medal,
                style: TextStyle(
                  fontSize: isTop3 ? 22 : 16,
                  fontWeight: FontWeight.bold,
                  color: isTop3 ? null : AppConstants.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              player.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: isTop3 ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: isTop3 && index == 0
                  ? const LinearGradient(colors: AppConstants.premiumGradient)
                  : null,
              color: isTop3 && index == 0 ? null : AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${player.score}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 300 + (index * 80)))
        .slideX(begin: -0.05, end: 0);
  }

  Widget _buildNextRoundButton() {
    return GestureDetector(
      onTap: () => _nextRound(context),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: AppConstants.premiumGradient),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withAlpha(100),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.skip_next_rounded, color: Colors.white, size: 26),
            SizedBox(width: 12),
            Text(
              'NEXT ROUND',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 500.ms)
        .scale(begin: const Offset(0.9, 0.9))
        .then()
        .shimmer(duration: 2000.ms, color: Colors.white24);
  }

  Widget _buildWaitingCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withAlpha(100),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Waiting for host...',
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 15,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn()
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.02, 1.02),
          duration: 1200.ms,
        );
  }

  Widget _buildExitButton() {
    return GestureDetector(
      onTap: () => _backToHome(context),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppConstants.surfaceColor.withAlpha(150),
          border: Border.all(color: AppConstants.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, color: AppConstants.textMuted, size: 22),
            const SizedBox(width: 10),
            Text(
              'Exit to Home',
              style: TextStyle(
                color: AppConstants.textMuted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}
