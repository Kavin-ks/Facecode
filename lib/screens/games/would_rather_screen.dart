import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/premium_ui.dart';

/// Question model for Would You Rather
class WouldYouRatherQuestion {
  final String optionA;
  final String optionB;
  
  const WouldYouRatherQuestion(this.optionA, this.optionB);
}

/// Would You Rather mini-game
class WouldYouRatherScreen extends StatefulWidget {
  const WouldYouRatherScreen({super.key});

  @override
  State<WouldYouRatherScreen> createState() => _WouldYouRatherScreenState();
}

class _WouldYouRatherScreenState extends State<WouldYouRatherScreen> {
  late ConfettiController _confettiController;
  
  int _currentQuestionIndex = 0;
  String? _selectedOption;
  int _votesA = 0;
  int _votesB = 0;
  int _totalAnswered = 0;

  static final List<WouldYouRatherQuestion> _questions = [
    const WouldYouRatherQuestion(
      'Have the ability to fly',
      'Have the ability to become invisible',
    ),
    const WouldYouRatherQuestion(
      'Travel back to the past',
      'Travel forward to the future',
    ),
    const WouldYouRatherQuestion(
      'Be able to speak all languages',
      'Be able to talk to animals',
    ),
    const WouldYouRatherQuestion(
      'Live without music',
      'Live without movies',
    ),
    const WouldYouRatherQuestion(
      'Always be 10 minutes late',
      'Always be 20 minutes early',
    ),
    const WouldYouRatherQuestion(
      'Have unlimited money',
      'Have unlimited time',
    ),
    const WouldYouRatherQuestion(
      'Never use social media again',
      'Never watch TV/movies again',
    ),
    const WouldYouRatherQuestion(
      'Live in a treehouse',
      'Live on a boat',
    ),
    const WouldYouRatherQuestion(
      'Be famous when you are alive',
      'Be famous after you die',
    ),
    const WouldYouRatherQuestion(
      'Have a rewind button',
      'Have a pause button',
    ),
    const WouldYouRatherQuestion(
      'Always have to say everything on your mind',
      'Never speak again',
    ),
    const WouldYouRatherQuestion(
      'Live forever',
      'Die tomorrow',
    ),
    const WouldYouRatherQuestion(
      'Eat pizza for every meal',
      'Eat tacos for every meal',
    ),
    const WouldYouRatherQuestion(
      'Have a personal chef',
      'Have a personal driver',
    ),
    const WouldYouRatherQuestion(
      'Win the lottery',
      'Find your true love',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _shuffleQuestions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _shuffleQuestions() {
    final random = Random();
    final index = random.nextInt(_questions.length);
    setState(() {
      _currentQuestionIndex = index;
      _selectedOption = null;
      _votesA = 0;
      _votesB = 0;
    });
  }

  void _selectOption(String option) {
    if (_selectedOption != null) return;

    setState(() {
      _selectedOption = option;
      _totalAnswered++;
      
      // Simulate votes (in real multiplayer, this would come from other players)
      final random = Random();
      if (option == 'A') {
        _votesA = 1;
        _votesB = random.nextInt(2);
      } else {
        _votesB = 1;
        _votesA = random.nextInt(2);
      }
    });

    _confettiController.play();
    HapticFeedback.mediumImpact();
    
    // Award XP
    final progress = context.read<ProgressProvider>();
    progress.awardXP(20);
  }

  void _nextQuestion() {
    _shuffleQuestions();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestionIndex];
    final totalVotes = _votesA + _votesB;
    final percentA = totalVotes > 0 ? (_votesA / totalVotes * 100).round() : 0;
    final percentB = totalVotes > 0 ? (_votesB / totalVotes * 100).round() : 0;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Would You Rather',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Answered: $_totalAnswered',
                  style: TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    // Title Card
                    NeonCard(
                      padding: const EdgeInsets.all(20),
                      child: const Text(
                        'Would You Rather...',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Options
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildOptionCard(
                            'A',
                            question.optionA,
                            percentA,
                            const [Color(0xFF00E5FF), Color(0xFF536DFE)],
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textMuted,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          
                          _buildOptionCard(
                            'B',
                            question.optionB,
                            percentB,
                            const [Color(0xFFFF4081), Color(0xFFFF6E40)],
                          ),
                        ],
                      ),
                    ),

                    // Next Button
                    if (_selectedOption != null) ...[
                      const SizedBox(height: 24),
                      GradientButton(
                        text: 'Next Question',
                        icon: Icons.arrow_forward,
                        onPressed: _nextQuestion,
                      ),
                    ],
                  ],
                ),
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
                numberOfParticles: 40,
                gravity: 0.05,
                shouldLoop: false,
                colors: const [
                  AppConstants.primaryColor,
                  AppConstants.secondaryColor,
                  AppConstants.accentNeon,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(String letter, String text, int percent, List<Color> colors) {
    final isSelected = _selectedOption == letter;
    final showResults = _selectedOption != null;

    return GestureDetector(
      onTap: _selectedOption == null ? () => _selectOption(letter) : null,
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        child: NeonCard(
          gradientColors: colors,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (showResults) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: Colors.white.withAlpha(50),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSelected ? 'Your choice ✓' : '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
