import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/premium_ui.dart';

/// Truth or Dare mini-game
class TruthDareScreen extends StatefulWidget {
  const TruthDareScreen({super.key});

  @override
  State<TruthDareScreen> createState() => _TruthDareScreenState();
}

class _TruthDareScreenState extends State<TruthDareScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _flipController;
  
  bool _safeMode = true;
  String? _currentChallenge;
  bool _isTruth = true;
  int _roundsCompleted = 0;

  static final List<String> _safeTruths = [
    "What's your most embarrassing moment?",
    "What's the weirdest dream you've ever had?",
    "If you could have dinner with anyone, who would it be?",
    "What's your guilty pleasure song?",
    "What's the last lie you told?",
    "What's your biggest fear?",
    "If you could be invisible for a day, what would you do?",
    "What's the most childish thing you still do?",
    "What's your secret talent?",
    "If you could read minds for a day, whose would you read?",
    "What's the worst gift you've ever received?",
    "What's your most used emoji?",
    "What's the longest you've gone without showering?",
    "What's your phone wallpaper?",
    "What's the last thing you googled?",
  ];

  static final List<String> _wildTruths = [
    "What's the most rebellious thing you've ever done?",
    "What's your biggest secret?",
    "Have you ever cheated on a test?",
    "What's your most controversial opinion?",
    "What's something you've never told your parents?",
    ..._safeTruths,
  ];

  static final List<String> _safeDares = [
    "Do 10 pushups",
    "Sing the chorus of your favorite song",
    "Dance for 30 seconds",
    "Speak in an accent for 2 minutes",
    "Do your best celebrity impression",
    "Tell a joke",
    "Act like a chicken for 30 seconds",
    "Try to lick your elbow",
    "Do the robot dance",
    "Spin around 10 times",
    "Make a funny face and hold it for 30 seconds",
    "Talk without closing your mouth",
    "Moonwalk across the room",
    "Imitate someone in the room",
    "Laugh maniacally for 30 seconds",
  ];

  static final List<String> _wildDares = [
    "Call a random contact and sing to them",
    "Post an embarrassing photo on social media",
    "Let someone else post a status on your behalf",
    "Do 20 burpees",
    ..._safeDares,
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _generateChallenge(bool isTruth) {
    final random = Random();
    final truths = _safeMode ? _safeTruths : _wildTruths;
    final dares = _safeMode ? _safeDares : _wildDares;
    
    setState(() {
      _isTruth = isTruth;
      _currentChallenge = isTruth 
          ? truths[random.nextInt(truths.length)]
          : dares[random.nextInt(dares.length)];
    });

    _flipController.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _completeChallenge() {
    setState(() {
      _roundsCompleted++;
    });
    
    _confettiController.play();
    HapticFeedback.heavyImpact();
    
    // Award XP
    final progress = context.read<ProgressProvider>();
    progress.awardXP(25);
    
    // Show completion snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Challenge completed! +25 XP'),
        backgroundColor: AppConstants.successColor,
        duration: Duration(seconds: 2),
      ),
    );
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
            'Truth or Dare',
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
                  'Rounds: $_roundsCompleted',
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
                    // Safe Mode Toggle
                    NeonCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _safeMode ? Icons.shield : Icons.warning,
                            color: _safeMode 
                                ? AppConstants.successColor 
                                : AppConstants.warningColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Safe Mode',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.textPrimary,
                                  ),
                                ),
                                Text(
                                  _safeMode 
                                      ? 'Family-friendly challenges' 
                                      : 'Wild & crazy challenges',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppConstants.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _safeMode,
                            onChanged: (value) {
                              setState(() {
                                _safeMode = value;
                                _currentChallenge = null;
                              });
                              HapticFeedback.lightImpact();
                            },
                            activeTrackColor: AppConstants.successColor,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Challenge Display
                    Expanded(
                      child: _currentChallenge == null
                          ? _buildChoiceButtons()
                          : _buildChallengeCard(),
                    ),

                    // Action Buttons
                    if (_currentChallenge != null) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: NeonOutlinedButton(
                              text: 'Skip',
                              icon: Icons.skip_next,
                              onPressed: () {
                                setState(() {
                                  _currentChallenge = null;
                                });
                                HapticFeedback.lightImpact();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GradientButton(
                              text: 'Done!',
                              icon: Icons.check_circle,
                              onPressed: () {
                                _completeChallenge();
                                setState(() {
                                  _currentChallenge = null;
                                });
                              },
                              gradientColors: const [
                                AppConstants.successColor,
                                Color(0xFF00C853),
                              ],
                            ),
                          ),
                        ],
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
                numberOfParticles: 50,
                gravity: 0.05,
                shouldLoop: false,
                colors: const [
                  AppConstants.primaryColor,
                  AppConstants.secondaryColor,
                  AppConstants.accentNeon,
                  AppConstants.accentGold,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Choose wisely...',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 32),
        
        // Truth Button
        GestureDetector(
          onTap: () => _generateChallenge(true),
          child: NeonCard(
            gradientColors: const [Color(0xFF536DFE), Color(0xFF7C4DFF)],
            child: SizedBox(
              height: 160,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.question_answer,
                      size: 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'TRUTH',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Dare Button
        GestureDetector(
          onTap: () => _generateChallenge(false),
          child: NeonCard(
            gradientColors: const [Color(0xFFFF4081), Color(0xFFFF6E40)],
            child: SizedBox(
              height: 160,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.local_fire_department,
                      size: 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'DARE',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard() {
    return AnimatedBuilder(
      animation: _flipController,
      builder: (context, child) {
        final angle = _flipController.value * 3.14159;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: angle < 3.14159 / 2 ? _buildCardFront() : _buildCardBack(),
        );
      },
    );
  }

  Widget _buildCardFront() {
    return NeonCard(
      gradientColors: _isTruth 
          ? const [Color(0xFF536DFE), Color(0xFF7C4DFF)]
          : const [Color(0xFFFF4081), Color(0xFFFF6E40)],
      child: Center(
        child: Icon(
          _isTruth ? Icons.question_answer : Icons.local_fire_department,
          size: 100,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159),
      child: NeonCard(
        gradientColors: _isTruth 
            ? const [Color(0xFF536DFE), Color(0xFF7C4DFF)]
            : const [Color(0xFFFF4081), Color(0xFFFF6E40)],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isTruth ? 'TRUTH' : 'DARE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white.withAlpha(200),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _currentChallenge ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
