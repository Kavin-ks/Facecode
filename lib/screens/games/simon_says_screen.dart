import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:facecode/screens/games/common/game_base_screen.dart';
import 'package:facecode/screens/games/common/game_result_screen.dart';
import 'package:facecode/utils/game_catalog.dart';
import 'package:facecode/services/game_feedback_service.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/premium_ui.dart';

class SimonSaysScreen extends StatefulWidget {
  const SimonSaysScreen({super.key});

  @override
  State<SimonSaysScreen> createState() => _SimonSaysScreenState();
}

enum _SimonStage { intro, showing, input, failed }

class _SimonSaysScreenState extends State<SimonSaysScreen> {
  final Random _rng = Random();
  final List<int> _sequence = [];
  int _currentStep = 0;
  int _round = 0;
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _isBonusRound = false;
  int? _activePadIndex;
  _SimonStage _stage = _SimonStage.intro;

  final List<List<Color>> _paletteSets = [
    [const Color(0xFFFF1744), const Color(0xFF2979FF), const Color(0xFF00E676), const Color(0xFFFFEA00)],
    [const Color(0xFFFF6D00), const Color(0xFF00B0FF), const Color(0xFF76FF03), const Color(0xFFD500F9)],
    [const Color(0xFFFF4081), const Color(0xFF7C4DFF), const Color(0xFF1DE9B6), const Color(0xFFFFD740)],
  ];
  late List<Color> _padColors;

  @override
  void initState() {
    super.initState();
    _padColors = List.from(_paletteSets.first);
  }

  void _startGame() {
    GameFeedbackService.tap();
    _sequence.clear();
    _round = 0;
    _score = 0;
    _streak = 0;
    _bestStreak = 0;
    _nextRound();
  }

  void _nextRound() {
    _round++;
    _currentStep = 0;
    _isBonusRound = _round % 5 == 0;
    _padColors = List.from(_paletteSets[_rng.nextInt(_paletteSets.length)]);
    _sequence.add(_rng.nextInt(4));
    _showSequence();
  }

  Future<void> _showSequence() async {
    if (!mounted) return;
    setState(() {
      _stage = _SimonStage.showing;
      _activePadIndex = null;
    });

    await Future.delayed(const Duration(milliseconds: 450));
    final flashMs = _flashDurationMs;
    final gapMs = max(140, flashMs ~/ 2);

    for (final index in _sequence) {
      if (!mounted) return;
      setState(() => _activePadIndex = index);
      GameFeedbackService.tap();
      await Future.delayed(Duration(milliseconds: flashMs));
      if (!mounted) return;
      setState(() => _activePadIndex = null);
      await Future.delayed(Duration(milliseconds: gapMs));
    }

    if (!mounted) return;
    setState(() {
      _stage = _SimonStage.input;
    });
  }

  int get _flashDurationMs {
    final base = 520 - (_round * 18);
    final bonus = _isBonusRound ? -60 : 0;
    return max(180, base + bonus);
  }

  void _onPadTap(int index) {
    if (_stage != _SimonStage.input) return;

    GameFeedbackService.tap();
    setState(() => _activePadIndex = index);
    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _activePadIndex = null);
    });

    if (index == _sequence[_currentStep]) {
      _currentStep++;
      if (_currentStep >= _sequence.length) {
        GameFeedbackService.success();
        _streak++;
        _bestStreak = max(_bestStreak, _streak);
        final baseScore = 40 + (_round * 6);
        final bonus = _isBonusRound ? 40 : 0;
        final streakBonus = min(_streak * 5, 60);
        _score += baseScore + bonus + streakBonus;
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          _nextRound();
        });
      }
    } else {
      GameFeedbackService.error();
      _streak = 0;
      _endGame();
    }
  }

  void _endGame() {
    setState(() {
      _stage = _SimonStage.failed;
    });
    final gameInfo = GameCatalog.allGames.firstWhere((g) => g.id == 'simon_says', orElse: () => GameCatalog.allGames[0]);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameInfo: gameInfo,
          score: _score,
          isWin: _round >= 5,
          customMessage: 'Round $_round • Best streak $_bestStreak',
          onReplay: () => Navigator.of(context).pushReplacementNamed('/simon-says'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameBaseScreen(
      title: 'Simon Says',
      score: _score,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _stage == _SimonStage.intro ? _buildIntro() : _buildGame(),
      ),
    );
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
                const Text('Watch the pattern and repeat it. The sequence grows each round.', style: TextStyle(color: AppConstants.textSecondary)),
                const SizedBox(height: 8),
                const Text('Speed increases. Every 5th round is a bonus round.', style: TextStyle(color: AppConstants.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: [
                _buildStatRow('Best Streak', '$_bestStreak'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _startGame,
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

  Widget _buildGame() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopBar(),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _stage == _SimonStage.input && _sequence.isNotEmpty
              ? _currentStep / _sequence.length
              : 0,
          minHeight: 6,
          backgroundColor: Colors.white.withAlpha(10),
          valueColor: AlwaysStoppedAnimation<Color>(
            _isBonusRound ? AppConstants.accentGold : AppConstants.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              margin: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildPad(0),
                        const SizedBox(width: 10),
                        _buildPad(1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(
                      children: [
                        _buildPad(2),
                        const SizedBox(width: 10),
                        _buildPad(3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        GlassCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Speed ${_flashDurationMs}ms', style: const TextStyle(color: Colors.white70)),
              Text(_stage == _SimonStage.showing ? 'Watch...' : 'Your turn', style: const TextStyle(color: Colors.white70)),
              Text('Sequence ${_sequence.length}', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _buildChip('Round $_round', AppConstants.secondaryColor),
        const SizedBox(width: 8),
        _buildChip('Streak $_streak', AppConstants.accentGold),
        const SizedBox(width: 8),
        _buildChip('Best $_bestStreak', AppConstants.successColor),
        const Spacer(),
        if (_isBonusRound) _buildChip('BONUS', AppConstants.warningColor),
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

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppConstants.textSecondary)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPad(int index) {
    final isActive = _activePadIndex == index;
    final color = _padColors[index];
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _onPadTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: isActive ? color : color.withAlpha(60),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isActive ? Colors.white : Colors.white24,
              width: isActive ? 4 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(isActive ? 180 : 80),
                blurRadius: isActive ? 28 : 18,
                spreadRadius: isActive ? 6 : 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
