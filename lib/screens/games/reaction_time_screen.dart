import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:facecode/services/game_feedback_service.dart';
import 'package:facecode/providers/analytics_provider.dart';
import 'package:facecode/widgets/game/game_outcome_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // persistence keys
  static const _kAllKey = 'reaction_history_ms';
  static const _kBestKey = 'reaction_best_ms';
  static const _kDailyPrefix = 'reaction_daily_';
  List<int> _historyAll = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kAllKey) ?? [];
    setState(() {
      _historyAll = list.map((s) => int.tryParse(s) ?? 0).where((v) => v > 0).toList();
      if (_historyAll.isNotEmpty) {
        _bestTime = prefs.getInt(_kBestKey) ?? _historyAll.reduce(min);
        _attempts = _historyAll.length;
        // keep recentTimes as last up to 6 for the small chart
        final r = _historyAll.reversed.take(6).toList().reversed.toList();
        _recentTimes.clear();
        _recentTimes.addAll(r);
      }
    });
  }

  Future<void> _recordResult(int ms) async {
    final prefs = await SharedPreferences.getInstance();
    _historyAll.add(ms);
    _attempts = _historyAll.length;
    _recentTimes.insert(0, ms);
    if (_recentTimes.length > 6) _recentTimes.removeLast();
    if (ms < _bestTime) {
      _bestTime = ms;
      await prefs.setInt(_kBestKey, _bestTime);
      _confettiController.play();
    }
    await prefs.setStringList(_kAllKey, _historyAll.map((e) => e.toString()).toList());
    // daily
    final today = DateTime.now().toIso8601String().split('T').first;
    final dailyKey = '$_kDailyPrefix$today';
    final daily = prefs.getStringList(dailyKey) ?? [];
    daily.add(ms.toString());
    await prefs.setStringList(dailyKey, daily);
    setState(() {});
  }

  static const double sqrt2 = 1.4142135623730951;

  double _percentileFor(int ms) {
    // approximate percentile using mean ~250ms sd ~60ms
    const double mu = 250.0;
    const double sigma = 60.0;
    final z = (ms - mu) / sigma;
    final cdf = 0.5 * (1 + _erf(z / sqrt2));
    var p = (1 - cdf) * 100;
    if (p < 1) p = 1;
    if (p > 99) p = 99;
    return p;
  }

  double _erf(double x) {
    // Abramowitz and Stegun approximation
    final sign = x < 0 ? -1 : 1;
    const double a1 =  0.254829592;
    const double a2 = -0.284496736;
    const double a3 =  1.421413741;
    const double a4 = -1.453152027;
    const double a5 =  1.061405429;
    const double p =  0.3275911;
    final absX = x.abs();
    final t = 1.0 / (1.0 + p * absX);
    var y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * (exp(-absX * absX));
    return sign * y;
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

    GameFeedbackService.tap();

    // Random delay between 1-5 seconds
    final random = Random();
    final delay = 1000 + random.nextInt(4000);

    _delayTimer = Timer(Duration(milliseconds: delay), () {
      if (mounted && _state == GameState.waiting) {
        setState(() {
          _state = GameState.tap;
          _showTime = DateTime.now();
        });
        GameFeedbackService.success();
      }
    });
  }

  Future<void> _onTap() async {
    if (_state == GameState.waiting) {
      // Too early!
      _delayTimer?.cancel();
      setState(() {
        _state = GameState.tooEarly;
      });
      GameFeedbackService.error();
      
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
        _state = GameState.result;
      });

      GameFeedbackService.success();

      // record result persistently + update UI
      await _recordResult(diff);

      // Award XP based on performance + track result
      int xp = 10;
      if (diff < 200) {
        xp = 50; // Amazing!
      } else if (diff < 300) {
        xp = 30; // Great!
      } else if (diff < 400) {
        xp = 20; // Good
      }

      if (!mounted) return;
        context.read<ProgressProvider>().recordGameResult(
          gameId: 'game-reaction-time',
          won: true,
          xpAward: xp,
          reactionTimeMs: _reactionTime,
          analytics: context.read<AnalyticsProvider>(),
        );
    }
  }

  void _reset() {
    setState(() {
      _state = GameState.ready;
      _reactionTime = null;
    });
    GameFeedbackService.tap();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
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
            // Full screen color overlay to mimic pure red/green reaction test
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: AnimatedContainer(
              duration: AppConstants.animationFast,
              color: _state == GameState.tap
                  ? const Color(0xFF00E676)
                  : (_state == GameState.waiting ? const Color(0xFFFF4081) : Colors.transparent),
            ),
          ),
        ),
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

                  // Main Game Area - Using GestureDetector instead of PremiumTap for reliable taps
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        debugPrint('🎯 Reaction game tapped! State: $_state');
                        _onTap();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: _buildGameArea(),
                    ),
                  ),

                  // Recent attempts chart (Fixed: reduced padding to prevent overflow)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Recent attempts',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 80,
                            child: _recentTimes.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No attempts yet',
                                      style: TextStyle(color: AppConstants.textSecondary),
                                    ),
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: _recentTimes.map((t) {
                                      final maxVal = max(350, _recentTimes.reduce(max));
                                      final normalizedHeight = (t / maxVal).clamp(0.2, 1.0);
                                      final h = normalizedHeight * 48;
                                      final isBest = t == _bestTime;
                                      
                                      return Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                '$t',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                height: h,
                                                decoration: BoxDecoration(
                                                  color: isBest
                                                      ? AppConstants.accentGold
                                                      : AppConstants.primaryColor,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ],
                      ),
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
            AnimatedScale(
              scale: _state == GameState.tap ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                Icons.touch_app,
                size: 100,
                color: AppConstants.primaryColor,
              ),
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
          children: [
            AnimatedScale(
              scale: _state == GameState.tap ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: const Icon(
                Icons.access_time,
                size: 100,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
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
          children: [
            AnimatedScale(
              scale: _state == GameState.tap ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: const Icon(
                Icons.flash_on,
                size: 120,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
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
          children: [
            AnimatedScale(
              scale: _state == GameState.tooEarly ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: const Icon(
                Icons.cancel,
                size: 100,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 12),
            if (time > 0) Text('${_percentileFor(time).toStringAsFixed(0)}th percentile', style: const TextStyle(color: AppConstants.textSecondary)),

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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameOutcomeActions(
            gameId: 'game-reaction-time',
            onReplay: _reset,
            onTryAnother: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _showDailyLeaderboard,
            child: const Text('Today\'s Reaction Leaderboard'),
          ),
        ],
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

  Future<void> _showDailyLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    final list = prefs.getStringList('$_kDailyPrefix$today') ?? [];
    final times = list.map((s) => int.tryParse(s) ?? 0).where((v) => v > 0).toList();
    if (times.isEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Today\'s leaderboard'),
          content: const Text('No entries yet for today.'),
          actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close'))],
        ),
      );
      return;
    }
    times.sort();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (c) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Today\'s Reaction Leaderboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              ...List.generate(min(times.length, 10), (i) {
                final t = times[i];
                return ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text('$t ms'),
                );
              }),
              TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close')),
            ],
          ),
        );
      },
    );
  }
}

enum GameState {
  ready,
  waiting,
  tap,
  tooEarly,
  result,
}
