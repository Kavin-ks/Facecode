import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:facecode/models/wyr_question.dart';
import 'package:facecode/services/wyr_service.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/services/game_feedback_service.dart';

class WouldYouRatherScreen extends StatefulWidget {
  const WouldYouRatherScreen({super.key});

  @override
  State<WouldYouRatherScreen> createState() => _WouldYouRatherScreenState();
}

class _WouldYouRatherScreenState extends State<WouldYouRatherScreen> {
  final WyrService _service = WyrService();
  
  WyrQuestion? _currentQuestion;
  bool _isLoading = true;
  bool _hasVoted = false;
  String? _selectedOptionId; // 'A' or 'B'
  String? _aiChoice; // 'A' or 'B'
  
  // Stats for animation
  double _percentA = 0.5;
  double _percentB = 0.5;

  @override
  void initState() {
    super.initState();
    _loadNextQuestion();
  }

  Future<void> _loadNextQuestion() async {
    setState(() {
      _isLoading = true;
      _hasVoted = false;
      _selectedOptionId = null;
      _aiChoice = null;
    });

    final q = await _service.getRandomQuestion();
    
    if (mounted) {
      if (q != null) {
        setState(() {
          _currentQuestion = q;
          _isLoading = false;
          // Pre-calc percentages for initial state (hidden)
          _percentA = q.percentA / 100;
          _percentB = q.percentB / 100;
        });
      } else {
        // Retry or error
         setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleVote(bool isOptionA) async {
    if (_hasVoted || _currentQuestion == null) return;

    setState(() {
      _hasVoted = true;
      _selectedOptionId = isOptionA ? 'A' : 'B';
    });

    GameFeedbackService.tap();

    try {
      final updatedQ = await _service.vote(_currentQuestion!.id, isOptionA);
      if (mounted && updatedQ != null) {
        setState(() {
          _currentQuestion = updatedQ;
          _percentA = updatedQ.percentA / 100;
          _percentB = updatedQ.percentB / 100;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final updated = _service.voteLocal(_currentQuestion!, isOptionA);
      setState(() {
        _currentQuestion = updated;
        _percentA = updated.percentA / 100;
        _percentB = updated.percentB / 100;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Offline mode: vote saved locally.")),
      );
    }

    _setAiChoice();

    if (mounted) {
      context.read<ProgressProvider>().recordGameResult(
        gameId: 'would_rather',
        won: false,
        xpAward: 10,
      );
    }
  }

  void _setAiChoice() {
    if (_currentQuestion == null) return;
    final aWeight = _currentQuestion!.percentA / 100;
    _aiChoice = (aWeight >= 0.5) ? 'A' : 'B';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BackButton(color: Colors.white, onPressed: () => Navigator.pop(context)),
                  const Text(
                    "WOULD YOU RATHER",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _currentQuestion == null
                      ? _buildErrorView()
                      : _buildGameView(),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_hasVoted)
                    ElevatedButton.icon(
                      onPressed: _loadNextQuestion,
                      icon: const Icon(Icons.refresh),
                      label: const Text("NEXT QUESTION"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.backgroundColor,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ).animate().fadeIn().scale(),
                  if (!_hasVoted)
                    TextButton(
                      onPressed: _loadNextQuestion,
                      child: const Text("SKIP QUESTION", style: TextStyle(color: Colors.white54)),
                    )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text("Could not load questions.", style: TextStyle(color: Colors.white)),
          TextButton(onPressed: _loadNextQuestion, child: const Text("Retry"))
        ],
      ),
    );
  }

  Widget _buildGameView() {
    final totalVotes = _currentQuestion?.totalVotes ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('Votes', totalVotes.toString()),
                _buildStat('You', _hasVoted ? 'Voted' : 'Pending'),
                _buildStat('AI', _aiChoice == null ? '--' : 'Chose $_aiChoice'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildOptionCard(
              text: _currentQuestion!.optionA,
              isOptionA: true,
              percent: _percentA,
              color: const Color(0xFFE94057),
            ),
          ),
          Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Center(
              child: Text(
                "OR",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppConstants.backgroundColor),
              ),
            ),
          ),
          Expanded(
            child: _buildOptionCard(
              text: _currentQuestion!.optionB,
              isOptionA: false,
              percent: _percentB,
              color: const Color(0xFF4285F4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String text,
    required bool isOptionA,
    required double percent,
    required Color color,
  }) {
    final isSelected = _selectedOptionId == (isOptionA ? 'A' : 'B');
    final isOtherSelected = _hasVoted && !isSelected;
    
    return GestureDetector(
      onTap: _hasVoted ? null : () => _handleVote(isOptionA),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? color : (isOtherSelected ? color.withValues(alpha: 0.25) : color),
          borderRadius: BorderRadius.circular(20),
          boxShadow: _hasVoted
              ? []
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (_hasVoted)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: isSelected ? 0.0 : 0.25,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: isOtherSelected ? 0.6 : 1.0),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_hasVoted) ...[
                      _buildPercentBar(percent, color, isSelected),
                      const SizedBox(height: 10),
                      Text(
                        "${(percent * 100).toInt()}%",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn().scale(),
                      const Text(
                        "of people chose this",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ] else
                      const Text('Tap to vote', style: TextStyle(color: Colors.white70)),
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Icon(Icons.check_circle, color: Colors.white, size: 32),
                      ).animate().fadeIn(),
                  ],
                ),
              ),
              if (!_hasVoted)
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleVote(isOptionA),
                      splashColor: Colors.white24,
                    ),
                  ),
                )
            ],
          ),
        ),
      ).animate(target: _hasVoted ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(0.98, 0.98)),
    );
  }

  Widget _buildPercentBar(double value, Color color, bool isSelected) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: width * value,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white70,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppConstants.textSecondary, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
