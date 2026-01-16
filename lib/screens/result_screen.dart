import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:facecode/models/game_room.dart';
import 'package:facecode/providers/game_provider.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/game_screen.dart';
import 'package:facecode/screens/home_screen.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/error_listener.dart';

/// Round results screen with scores + confetti on correct guess.
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
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GameProvider>();
      if (provider.lastRoundWasCorrect) {
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

          return Scaffold(
            appBar: AppBar(
              title: const Text('Results'),
              automaticallyImplyLeading: false,
            ),
            body: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppConstants.softBackgroundGradient,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confetti,
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.08,
                    numberOfParticles: 18,
                    maxBlastForce: 12,
                    minBlastForce: 6,
                    gravity: 0.25,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.largePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppConstants.defaultPadding),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppConstants.primaryColor.withAlpha(46),
                                AppConstants.secondaryColor.withAlpha(31),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppConstants.borderRadius),
                            border: Border.all(
                              color: AppConstants.primaryColor.withAlpha(89),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.lastRoundWasCorrect
                                    ? 'Correct Guess!'
                                    : (provider.lastRoundEndedByTime
                                        ? 'Time Expired'
                                        : 'Round Over'),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Answer',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppConstants.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                answer,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.06, end: 0),

                        const SizedBox(height: AppConstants.largePadding),

                        Text(
                          'Leaderboard',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppConstants.smallPadding),

                        Expanded(
                          child: ListView.builder(
                            itemCount: players.length,
                            itemBuilder: (context, index) {
                              final p = players[index];
                              final medal = index == 0
                                  ? '🥇'
                                  : index == 1
                                      ? '🥈'
                                      : index == 2
                                          ? '🥉'
                                          : '🎮';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: Text(medal, style: const TextStyle(fontSize: 22)),
                                  title: Text(p.name),
                                  trailing: Text(
                                    '${p.score} pts',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(color: AppConstants.secondaryColor),
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: (70 * index).ms)
                                  .slideX(begin: -0.04, end: 0);
                            },
                          ),
                        ),

                        const SizedBox(height: AppConstants.defaultPadding),

                        if (provider.isHost)
                          ElevatedButton.icon(
                            onPressed: () => _nextRound(context),
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Next Round'),
                          )
                        else
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppConstants.defaultPadding),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(strokeWidth: 2),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Waiting for host…',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: AppConstants.defaultPadding),

                        OutlinedButton.icon(
                          onPressed: () => _backToHome(context),
                          icon: const Icon(Icons.home_outlined),
                          label: const Text('Exit to Home'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
