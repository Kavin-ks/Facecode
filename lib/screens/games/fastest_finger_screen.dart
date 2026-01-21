import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/screens/games/common/game_base_screen.dart';
import 'package:facecode/screens/games/common/game_result_screen.dart';
import 'package:facecode/utils/game_catalog.dart';
import 'package:facecode/services/game_feedback_service.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:facecode/providers/progress_provider.dart';

class FastestFingerScreen extends StatefulWidget {
  const FastestFingerScreen({super.key});

  @override
  State<FastestFingerScreen> createState() => _FastestFingerScreenState();
}

enum _FastestFingerStage { intro, countdown, question, feedback, finished }
enum _FastestFingerDifficulty { easy, medium, hard, extreme }

extension on _FastestFingerDifficulty {
  String get label {
    switch (this) {
      case _FastestFingerDifficulty.easy:
        return 'Easy';
      case _FastestFingerDifficulty.medium:
        return 'Medium';
      case _FastestFingerDifficulty.hard:
        return 'Hard';
      case _FastestFingerDifficulty.extreme:
        return 'Extreme';
    }
  }

  Color get color {
    switch (this) {
      case _FastestFingerDifficulty.easy:
        return const Color(0xFF00C853);
      case _FastestFingerDifficulty.medium:
        return const Color(0xFF2979FF);
      case _FastestFingerDifficulty.hard:
        return const Color(0xFFFF6D00);
      case _FastestFingerDifficulty.extreme:
        return const Color(0xFFD500F9);
    }
  }

  int get timeLimitMs {
    switch (this) {
      case _FastestFingerDifficulty.easy:
        return 6000;
      case _FastestFingerDifficulty.medium:
        return 5500;
      case _FastestFingerDifficulty.hard:
        return 5000;
      case _FastestFingerDifficulty.extreme:
        return 4500;
    }
  }

  int get baseScore {
    switch (this) {
      case _FastestFingerDifficulty.easy:
        return 50;
      case _FastestFingerDifficulty.medium:
        return 75;
      case _FastestFingerDifficulty.hard:
        return 100;
      case _FastestFingerDifficulty.extreme:
        return 125;
    }
  }
}

class _MathQuestion {
  final String text;
  final int answer;
  final List<int> options;

  const _MathQuestion({
    required this.text,
    required this.answer,
    required this.options,
  });
}

class _FastestFingerScreenState extends State<FastestFingerScreen> with TickerProviderStateMixin {
  final Random _rng = Random();
  _FastestFingerStage _stage = _FastestFingerStage.intro;
  _FastestFingerDifficulty _difficulty = _FastestFingerDifficulty.easy;
  int _countdownSeconds = 3;
  bool _versusMode = false; // false => solo with AI fallback

  static const int _totalRounds = 5;
  int _roundIndex = 0;
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _correctCount = 0;

  _MathQuestion? _currentQuestion;
  int? _selectedAnswerP1;
  int? _selectedAnswerP2;
  String _feedbackMessage = '';
  double _lastReactionMs = 0;
  double? _bestReactionMs;
  List<double> _topTimes = [];

  Timer? _countdownTimer;
  Timer? _tickTimer;
  Timer? _aiTimer;
  int _countdownRemaining = 0;
  int _elapsedMs = 0;

  @override
  void initState() {
    super.initState();
    _loadBestTimes();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tickTimer?.cancel();
    _aiTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBestTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _leaderboardKey(_difficulty);
    final stored = prefs.getStringList(key) ?? [];
    final times = stored.map((e) => double.tryParse(e)).whereType<double>().toList();
    times.sort();
    if (!mounted) return;
    setState(() {
      _topTimes = times;
      _bestReactionMs = times.isNotEmpty ? times.first : null;
    });
  }

  String _leaderboardKey(_FastestFingerDifficulty difficulty) => 'fastest_finger_times_${difficulty.label.toLowerCase()}';

  Future<void> _saveTime(double ms) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _leaderboardKey(_difficulty);
    final times = [..._topTimes, ms]..sort();
    final trimmed = times.take(5).toList();
    await prefs.setStringList(key, trimmed.map((e) => e.toStringAsFixed(0)).toList());
    if (!mounted) return;
    setState(() {
      _topTimes = trimmed;
      _bestReactionMs = trimmed.isNotEmpty ? trimmed.first : null;
    });
  }

  void _startCountdown() {
    GameFeedbackService.tap();
    _countdownTimer?.cancel();
    _tickTimer?.cancel();
    _aiTimer?.cancel();
    setState(() {
      _stage = _FastestFingerStage.countdown;
      _countdownRemaining = _countdownSeconds;
      _selectedAnswerP1 = null;
      _selectedAnswerP2 = null;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownRemaining <= 1) {
        timer.cancel();
        _startQuestion();
        return;
      }
      GameFeedbackService.tick();
      setState(() {
        _countdownRemaining--;
      });
    });
  }

  void _startQuestion() {
    _currentQuestion = _generateQuestion(_difficulty);
    _selectedAnswerP1 = null;
    _selectedAnswerP2 = null;
    _elapsedMs = 0;
    setState(() {
      _stage = _FastestFingerStage.question;
    });
    _startTickTimer();
    _scheduleAiAnswer();
  }

  void _startTickTimer() {
    _tickTimer?.cancel();
    final limitMs = _difficulty.timeLimitMs;
    _tickTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      _elapsedMs += 50;
      if (_elapsedMs >= limitMs) {
        timer.cancel();
        _handleTimeout();
      } else {
        setState(() {});
      }
    });
  }

  void _scheduleAiAnswer() {
    _aiTimer?.cancel();
    if (_versusMode) return;
    final aiDelay = _aiReactionMs(_difficulty);
    _aiTimer = Timer(Duration(milliseconds: aiDelay), () {
      if (!mounted || _stage != _FastestFingerStage.question) return;
      final correct = _rng.nextDouble() < _aiAccuracy(_difficulty);
      final answer = correct
          ? _currentQuestion!.answer
          : _currentQuestion!.options.firstWhere((o) => o != _currentQuestion!.answer);
      _handleAnswer(player: 2, answer: answer);
    });
  }

  int _aiReactionMs(_FastestFingerDifficulty difficulty) {
    switch (difficulty) {
      case _FastestFingerDifficulty.easy:
        return 900 + _rng.nextInt(900);
      case _FastestFingerDifficulty.medium:
        return 850 + _rng.nextInt(900);
      case _FastestFingerDifficulty.hard:
        return 800 + _rng.nextInt(900);
      case _FastestFingerDifficulty.extreme:
        return 750 + _rng.nextInt(900);
    }
  }

  double _aiAccuracy(_FastestFingerDifficulty difficulty) {
    switch (difficulty) {
      case _FastestFingerDifficulty.easy:
        return 0.85;
      case _FastestFingerDifficulty.medium:
        return 0.78;
      case _FastestFingerDifficulty.hard:
        return 0.68;
      case _FastestFingerDifficulty.extreme:
        return 0.6;
    }
  }

  void _handleTimeout() {
    _tickTimer?.cancel();
    _aiTimer?.cancel();
    GameFeedbackService.error();
    setState(() {
      _feedbackMessage = 'Time\'s up';
      _stage = _FastestFingerStage.feedback;
      _streak = 0;
    });
    _nextRoundAfterDelay();
  }

  void _handleAnswer({required int player, required int answer}) {
    if (_stage != _FastestFingerStage.question) return;
    if (_selectedAnswerP1 != null && _selectedAnswerP2 != null) return;
    if (player == 1 && _selectedAnswerP1 != null) return;
    if (player == 2 && _selectedAnswerP2 != null) return;

    final correct = answer == _currentQuestion!.answer;
    final elapsed = _elapsedMs.clamp(0, _difficulty.timeLimitMs).toDouble();
    _lastReactionMs = elapsed;

    if (player == 1) {
      _selectedAnswerP1 = answer;
    } else {
      _selectedAnswerP2 = answer;
    }

    _tickTimer?.cancel();
    _aiTimer?.cancel();

    if (player == 1) {
      if (correct) {
        GameFeedbackService.success();
        _correctCount++;
        _streak++;
        _bestStreak = max(_bestStreak, _streak);
        final timeBonus = max(0, ((_difficulty.timeLimitMs - elapsed) / 100).round());
        final streakBonus = min(_streak * 5, 40);
        _score += _difficulty.baseScore + timeBonus + streakBonus;
        _saveTime(elapsed);
        _feedbackMessage = 'Correct • ${elapsed.toStringAsFixed(0)} ms';
      } else {
        GameFeedbackService.error();
        _streak = 0;
        _feedbackMessage = 'Wrong Answer';
      }
    } else {
      if (correct) {
        GameFeedbackService.error();
        _feedbackMessage = _versusMode ? 'Player 2 wins' : 'AI wins';
      } else {
        GameFeedbackService.success();
        _feedbackMessage = _versusMode ? 'Player 2 missed' : 'AI missed';
      }
    }

    setState(() {
      _stage = _FastestFingerStage.feedback;
    });
    _nextRoundAfterDelay();
  }

  void _nextRoundAfterDelay() {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _roundIndex++;
      if (_roundIndex >= _totalRounds) {
        _finishGame();
      } else {
        _startCountdown();
      }
    });
  }

  void _finishGame() {
    setState(() {
      _stage = _FastestFingerStage.finished;
    });
    final gameInfo = GameCatalog.allGames.firstWhere((g) => g.id == 'fastest_finger', orElse: () => GameCatalog.allGames[0]);
    final win = _correctCount >= 3;
    final message = win
      ? 'Great reflexes! $_correctCount/$_totalRounds correct'
      : 'Keep practicing! $_correctCount/$_totalRounds correct';

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameInfo: gameInfo,
          score: _score,
          isWin: win,
          customMessage: message,
          onReplay: () => Navigator.of(context).pushReplacementNamed('/fastest-finger'),
        ),
      ),
    );
  }

  _MathQuestion _generateQuestion(_FastestFingerDifficulty difficulty) {
    int a;
    int b;
    int c;
    String op1;
    String op2;
    int answer;

    switch (difficulty) {
      case _FastestFingerDifficulty.easy:
        a = _rng.nextInt(9) + 1;
        b = _rng.nextInt(9) + 1;
        op1 = _rng.nextBool() ? '+' : '-';
        answer = op1 == '+' ? a + b : a - b;
        return _buildQuestion('$a $op1 $b', answer);
      case _FastestFingerDifficulty.medium:
        a = _rng.nextInt(90) + 10;
        b = _rng.nextInt(90) + 10;
        op1 = _rng.nextBool() ? '+' : '-';
        answer = op1 == '+' ? a + b : a - b;
        return _buildQuestion('$a $op1 $b', answer);
      case _FastestFingerDifficulty.hard:
        a = _rng.nextInt(900) + 100;
        b = _rng.nextInt(900) + 100;
        op1 = _rng.nextBool() ? '+' : '-';
        answer = op1 == '+' ? a + b : a - b;
        return _buildQuestion('$a $op1 $b', answer);
      case _FastestFingerDifficulty.extreme:
        a = _rng.nextInt(90) + 10;
        b = _rng.nextInt(90) + 10;
        c = _rng.nextInt(9) + 1;
        op1 = _rng.nextBool() ? '+' : '-';
        op2 = _rng.nextBool() ? '×' : '+';
        final first = op1 == '+' ? a + b : a - b;
        answer = op2 == '×' ? first * c : first + c;
        return _buildQuestion('($a $op1 $b) $op2 $c', answer);
    }
  }

  _MathQuestion _buildQuestion(String text, int answer) {
    final options = <int>{answer};
    while (options.length < 4) {
      final delta = _rng.nextInt(15) + 1;
      final sign = _rng.nextBool() ? 1 : -1;
      options.add(answer + delta * sign);
    }
    final list = options.toList()..shuffle();
    return _MathQuestion(text: text, answer: answer, options: list);
  }

  double get _progressValue {
    if (_stage != _FastestFingerStage.question) return 1.0;
    return 1 - (_elapsedMs / _difficulty.timeLimitMs).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>().progress;
    return GameBaseScreen(
      title: 'Fastest Finger',
      score: _score,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(progress.level),
          const SizedBox(height: 12),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildTopBar(int level) {
    return Row(
      children: [
        _buildChip('Round ${min(_roundIndex + 1, _totalRounds)}/$_totalRounds', AppConstants.secondaryColor),
        const SizedBox(width: 8),
        _buildChip(_difficulty.label, _difficulty.color),
        const SizedBox(width: 8),
        _buildChip(_versusMode ? '2 Players' : 'VS AI', AppConstants.primaryColor),
        const Spacer(),
        _buildChip('Streak $_streak', AppConstants.accentGold),
        const SizedBox(width: 8),
        _buildChip('Lv $level', AppConstants.successColor),
      ],
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _FastestFingerStage.intro:
        return _buildIntro();
      case _FastestFingerStage.countdown:
      case _FastestFingerStage.question:
      case _FastestFingerStage.feedback:
        return _buildGame();
      case _FastestFingerStage.finished:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildIntro() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How to play', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Solve the math fast. First tap wins the round.', style: TextStyle(color: AppConstants.textSecondary)),
                const SizedBox(height: 8),
                const Text('Score = difficulty + speed bonus + streak bonus.', style: TextStyle(color: AppConstants.textSecondary)),
                const SizedBox(height: 8),
                const Text('5 rounds • Best time tracked • XP awarded.', style: TextStyle(color: AppConstants.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Difficulty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _FastestFingerDifficulty.values.map((d) {
                    final selected = _difficulty == d;
                    return ChoiceChip(
                      label: Text(d.label),
                      selected: selected,
                      selectedColor: d.color.withAlpha(60),
                      backgroundColor: Colors.white.withAlpha(10),
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                      onSelected: (_) {
                        setState(() {
                          _difficulty = d;
                        });
                        _loadBestTimes();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Countdown', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [3, 5, 7].map((sec) {
                    final selected = _countdownSeconds == sec;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text('${sec}s'),
                        selected: selected,
                        selectedColor: AppConstants.primaryColor.withAlpha(70),
                        backgroundColor: Colors.white.withAlpha(10),
                        labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                        onSelected: (_) => setState(() => _countdownSeconds = sec),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('VS AI'),
                      selected: !_versusMode,
                      selectedColor: AppConstants.secondaryColor.withAlpha(70),
                      backgroundColor: Colors.white.withAlpha(10),
                      labelStyle: TextStyle(color: !_versusMode ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                      onSelected: (_) => setState(() => _versusMode = false),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('2 Players'),
                      selected: _versusMode,
                      selectedColor: AppConstants.primaryColor.withAlpha(70),
                      backgroundColor: Colors.white.withAlpha(10),
                      labelStyle: TextStyle(color: _versusMode ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                      onSelected: (_) => setState(() => _versusMode = true),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: [
                _buildLeaderboard(),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _startCountdown,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('START', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    if (_topTimes.isEmpty) {
      return const Text('No times yet. Set the first record!', style: TextStyle(color: AppConstants.textSecondary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Best Times', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        for (int i = 0; i < _topTimes.length && i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('#${i + 1}  ${_topTimes[i].toStringAsFixed(0)} ms', style: const TextStyle(color: Colors.white70)),
          ),
      ],
    );
  }

  Widget _buildGame() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: _progressValue,
          minHeight: 6,
          backgroundColor: Colors.white.withAlpha(10),
          valueColor: AlwaysStoppedAnimation<Color>(
            _progressValue < 0.2 ? AppConstants.errorColor : AppConstants.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: SizedBox(
            height: 160,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _stage == _FastestFingerStage.countdown
                    ? Text(
                        '$_countdownRemaining',
                        key: ValueKey('countdown_$_countdownRemaining'),
                        style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold),
                      )
                    : _stage == _FastestFingerStage.feedback
                        ? Text(
                            _feedbackMessage,
                            key: ValueKey('feedback_$_feedbackMessage'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          )
                        : Text(
                            _currentQuestion?.text ?? 'Get Ready',
                            key: const ValueKey('question'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_stage == _FastestFingerStage.question) _buildOptions(),
        const SizedBox(height: 16),
        GlassCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Time: ${_lastReactionMs.toStringAsFixed(0)} ms', style: const TextStyle(color: Colors.white70)),
              Text('Best: ${_bestReactionMs?.toStringAsFixed(0) ?? '--'} ms', style: const TextStyle(color: Colors.white70)),
              Text('Best Streak: $_bestStreak', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptions() {
    final options = _currentQuestion?.options ?? [];
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_versusMode) {
      return Column(
        children: [
          _buildPlayerRow('Player 1', Colors.blueAccent, options, 1),
          const SizedBox(height: 12),
          _buildPlayerRow('Player 2', Colors.redAccent, options, 2),
        ],
      );
    }

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: options.map((option) {
        final selected = _selectedAnswerP1 == option;
        return _buildAnswerButton(option, selected, 1, AppConstants.primaryColor);
      }).toList(),
    );
  }

  Widget _buildPlayerRow(String label, Color color, List<int> options, int player) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: options.map((option) {
              final selected = player == 1 ? _selectedAnswerP1 == option : _selectedAnswerP2 == option;
              return _buildAnswerButton(option, selected, player, color);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(int option, bool selected, int player, Color color) {
    return ElevatedButton(
      onPressed: _stage == _FastestFingerStage.question
          ? () => _handleAnswer(player: player, answer: option)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? color : Colors.white.withAlpha(12),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(option.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }
}
