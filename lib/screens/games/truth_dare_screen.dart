import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/models/truth_dare_models.dart';
import 'package:facecode/models/player.dart';
import 'package:facecode/providers/truth_dare_provider.dart';
import 'package:facecode/widgets/spinner_wheel.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/services/game_feedback_service.dart';
import 'package:facecode/providers/analytics_provider.dart';
import 'package:facecode/services/sound_manager.dart';
import 'package:facecode/widgets/game/game_outcome_actions.dart';

class TruthDareScreen extends StatefulWidget {
  const TruthDareScreen({super.key});

  @override
  State<TruthDareScreen> createState() => _TruthDareScreenState();
}

class _TruthDareScreenState extends State<TruthDareScreen> {
  final GlobalKey<SpinnerWheelState> _wheelKey = GlobalKey<SpinnerWheelState>();
  final TextEditingController _nameController = TextEditingController();
  late ConfettiController _confettiController;
  bool _useAiFill = true;
  int _targetTurns = 10; // 0 = endless
  int _turnCount = 0;
  final List<String> _aiNames = ['Nova', 'Pixel', 'Echo', 'Blitz', 'Luna', 'Orion', 'Vega'];
  
  bool _showQuestion = false;
  String _history = "";
  // Whether the user has started the spinning session (explicit start)
  bool _started = false;

  // UI pop for selected player
  bool _playerPop = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TruthDareProvider>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(provider),
            Expanded(
              child: _buildMainContent(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(TruthDareProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (provider.mode != null) {
                provider.resetGame();
                setState(() { _started = false; });
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const Text(
            "TRUTH OR DARE",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          if (provider.mode == TruthDareMode.withQuestions)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              onPressed: () => _showSettings(provider),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMainContent(TruthDareProvider provider) {
    if (provider.mode == null) {
      return _buildModeSelection(provider);
    }

    // If there are less than 2 players, we stay in setup.
    if (provider.players.length < 2) {
      return _buildPlayerSetup(provider);
    }

    // Allow adding arbitrary number of players before explicitly starting the session.
    if (!_started) {
      return _buildPlayerSetup(provider);
    }

    return _buildGameView(provider);
  }

  // --- PHASE 1: MODE SELECTION ---
  Widget _buildModeSelection(TruthDareProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppConstants.backgroundColor,
            AppConstants.backgroundColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title with glow effect
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                "CHOOSE GAME MODE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ).animate().fadeIn().scale(),
            
            const SizedBox(height: 20),
            
            // Add small instruction about spinner momentum
            const Text(
              "Tip: Tap SPIN to give the wheel some momentum — listen for the ticks!",
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ).animate(delay: 80.ms).fadeIn(),
            const Text(
              "How do you want to play?",
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 50),
            
            _buildEnhancedModeCard(
              title: "With Questions",
              subtitle: "Play with curated truths & dares",
              description: "150+ questions • Multiple categories • Safe mode",
              icon: Icons.question_answer_rounded,
              gradient: LinearGradient(
                colors: [AppConstants.cardPurple, AppConstants.cardPurple.withValues(alpha: 0.7)],
              ),
              onTap: () => provider.setMode(TruthDareMode.withQuestions),
            ),
            
            const SizedBox(height: 20),
            
            _buildEnhancedModeCard(
              title: "Spinner Only",
              subtitle: "Just pick a random player",
              description: "No questions • Quick setup • Party mode",
              icon: Icons.refresh_rounded,
              gradient: LinearGradient(
                colors: [AppConstants.cardBlue, AppConstants.cardBlue.withValues(alpha: 0.7)],
              ),
              onTap: () => provider.setMode(TruthDareMode.withoutQuestions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedModeCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: Colors.white, size: 40),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
          ],
        ),
      ).animate().slideX(begin: 0.1, duration: 400.ms).fadeIn(),
    );
  }

  Widget _buildPlayerSetup(TruthDareProvider provider) {
    return Column(
      children: [
        // Show filter selection for "With Questions" mode
        if (provider.mode == TruthDareMode.withQuestions && provider.players.isEmpty)
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.cardPurple.withValues(alpha: 0.3),
                  AppConstants.cardPurple.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppConstants.cardPurple.withValues(alpha: 0.5), width: 2),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.filter_alt, color: AppConstants.cardPurple),
                    SizedBox(width: 12),
                    Text(
                      "QUICK SETUP",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickFilterChip(
                        label: provider.safeMode ? "🛡️ Safe Mode ON" : "🔓 Safe Mode OFF",
                        color: provider.safeMode ? Colors.green : Colors.orange,
                        onTap: () {
                          provider.setSafeMode(!provider.safeMode);
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickFilterChip(
                        label: _getAgeGroupLabel(provider.selectedAgeGroup).split(' ')[0],
                        color: AppConstants.primaryColor,
                        onTap: () => _showSettings(provider),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildQuickFilterChip(
                  label: "Category: ${provider.selectedCategory.name.toUpperCase()}",
                  color: AppConstants.secondaryColor,
                  onTap: () => _showSettings(provider),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => _showSettings(provider),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text("MORE SETTINGS"),
                  style: TextButton.styleFrom(
                    foregroundColor: AppConstants.cardPurple,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1),
        
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text("ADD PLAYERS", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                "Minimum 2 players required",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (v) => _addPlayer(provider),
                      decoration: InputDecoration(
                        hintText: "Enter player name",
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: AppConstants.surfaceColor,
                        prefixIcon: const Icon(Icons.person_add, color: Colors.white30),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => _addPlayer(provider),
                      icon: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSessionSettings(provider),
            ],
          ),
        ),
        Expanded(
          child: provider.players.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_add,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No players yet",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: provider.players.length,
                  itemBuilder: (context, index) {
                    final player = provider.players[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppConstants.primaryColor,
                          child: Text(
                            player.name[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          player.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Player ${index + 1}',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                          onPressed: () => provider.removePlayer(player.id),
                        ),
                      ),
                    ).animate().fadeIn().slideX();
                  },
                ),
        ),
        if (provider.players.length >= 2)
           Container(
             padding: const EdgeInsets.all(24.0),
             decoration: BoxDecoration(
               gradient: LinearGradient(
                 begin: Alignment.bottomCenter,
                 end: Alignment.topCenter,
                 colors: [
                   AppConstants.backgroundColor,
                   AppConstants.backgroundColor.withValues(alpha: 0.0),
                 ],
               ),
             ),
             child: SizedBox(
               width: double.infinity,
               child: ElevatedButton.icon(
                 onPressed: () {
                   if (provider.players.length < 2) {
                     if (_useAiFill && provider.players.isNotEmpty) {
                       _ensureAiPlayers(provider);
                     } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Add at least 2 players to start.')),
                       );
                       return;
                     }
                   }
                   HapticFeedback.heavyImpact();
                   setState(() {
                     _turnCount = 0;
                     _started = true;
                   });
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppConstants.successColor,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 18),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                   elevation: 10,
                 ),
                 icon: const Icon(Icons.play_arrow, size: 28),
                 label: const Text(
                   "START GAME",
                   style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
                 ),
               ),
             ),
           ).animate().slideY(begin: 0.2).fadeIn(),
      ],
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  void _addPlayer(TruthDareProvider provider) {
    if (_nameController.text.isNotEmpty) {
      final added = provider.addPlayer(_nameController.text);
      if (!added) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duplicate name. Pick a unique name.')),
        );
        return;
      }
      _nameController.clear();
      HapticFeedback.lightImpact();
    }
  }

  // --- PHASE 3: GAME VIEW ---
  Widget _buildGameView(TruthDareProvider provider) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 24, right: 24),
              child: Row(
                children: [
                  _buildChip('Turn ${_turnCount + 1}', AppConstants.secondaryColor),
                  const SizedBox(width: 8),
                  _buildChip('${provider.players.length} players', AppConstants.primaryColor),
                  const Spacer(),
                  if (_targetTurns > 0)
                    Text('$_turnCount/$_targetTurns', style: const TextStyle(color: AppConstants.textSecondary)),
                ],
              ),
            ),
            if (_targetTurns > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 24, right: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_turnCount / _targetTurns).clamp(0, 1),
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                    minHeight: 8,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // Current Player Status
            if (provider.currentPlayer != null)
               Container(
                 margin: const EdgeInsets.only(top: 20),
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                 decoration: BoxDecoration(
                   gradient: LinearGradient(
                     colors: [
                       AppConstants.accentGold.withValues(alpha: 0.3),
                       AppConstants.accentGold.withValues(alpha: 0.1),
                     ],
                   ),
                   borderRadius: BorderRadius.circular(30),
                   border: Border.all(color: AppConstants.accentGold.withValues(alpha: 0.5)),
                 ),
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     const Icon(Icons.stars, color: AppConstants.accentGold, size: 20),
                     const SizedBox(width: 8),
                     Text(
                       "It's ${provider.currentPlayer!.name.toUpperCase()}'s turn!",
                       style: const TextStyle(
                         color: AppConstants.accentGold,
                         fontSize: 18,
                         fontWeight: FontWeight.w900,
                         letterSpacing: 1.5,
                       ),
                     ),
                     const SizedBox(width: 8),
                     const Icon(Icons.stars, color: AppConstants.accentGold, size: 20),
                   ],
                 ),
               ).animate().fadeIn().scale().shimmer(duration: 1500.ms),
            
            // BIG PROMINENT TURN BANNER - Shows whose turn it is
            if (provider.currentPlayer != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.accentGold,
                      AppConstants.accentGold.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.accentGold.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.arrow_downward, color: Colors.white, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      "🎯 IT'S ${provider.currentPlayer!.name.toUpperCase()}'s TURN! 🎯",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Spin again or choose next action",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            
            const Spacer(),
            
            // Spinner Wheel
            Center(
              child: SpinnerWheel(
                key: _wheelKey,
                names: provider.players.map((p) => p.name).toList(),
                onResult: (index) {
                  debugPrint('🎯 WHEEL RESULT: Player index $index selected');
                  HapticFeedback.heavyImpact();
                  provider.setCurrentPlayer(index);
                  debugPrint('✅ Current player set to: ${provider.players[index].name}');
                  _turnCount += 1;
                  setState(() {
                    _history = "${provider.players[index].name}'s turn\n$_history";
                    _playerPop = true;
                  });
                  
                  debugPrint('📊 Mode: ${provider.mode}, withQuestions: ${provider.mode == TruthDareMode.withQuestions}');
                  
                  // Show question selection dialog after a short delay to ensure UI is ready
                  if (provider.mode == TruthDareMode.withQuestions) {
                    debugPrint('🎲 Showing question selection dialog...');
                    Future.delayed(const Duration(milliseconds: 800), () {
                      if (mounted) {
                        _showQuestionSelection(provider);
                      }
                    });
                  }
                  
                  // Reset pop after a short moment
                  Future.delayed(const Duration(milliseconds: 700), () {
                    if (!mounted) return;
                    setState(() => _playerPop = false);
                  });

                  if (_targetTurns > 0 && _turnCount >= _targetTurns) {
                    _showSessionComplete(provider);
                  }
                },
              ),
            ),
            
            const Spacer(),
            
            // Footer Buttons
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  // MANUAL TRUTH OR DARE BUTTON (appears if player selected and in questions mode)
                  if (provider.currentPlayer != null && provider.mode == TruthDareMode.withQuestions)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              debugPrint('🎯 MANUAL: Choose Truth or Dare button clicked');
                              GameFeedbackService.tap();
                              _showQuestionSelection(provider);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.accentGold,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 12,
                            ),
                            icon: const Icon(Icons.psychology, size: 28),
                            label: const Text(
                              "CHOOSE TRUTH OR DARE",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  
                   if (!_showQuestion)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              debugPrint('🎰 SPIN button clicked');
                              GameFeedbackService.tap();
                              _wheelKey.currentState?.spin();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppConstants.backgroundColor,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 10,
                            ),
                            icon: const Icon(Icons.motion_photos_on, size: 28),
                            label: const Text(
                              "SPIN WHEEL",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () { setState(() { _started = false; }); },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text("EDIT PLAYERS"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                   
                   const SizedBox(height: 20),
                   
                   GestureDetector(
                     onTap: () => _showHistory(),
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       decoration: BoxDecoration(
                         color: Colors.white.withValues(alpha: 0.05),
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(color: Colors.white12),
                       ),
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Icon(Icons.history, color: Colors.white.withValues(alpha: 0.5), size: 16),
                           const SizedBox(width: 8),
                           Text(
                             "VIEW HISTORY",
                             style: TextStyle(
                               color: Colors.white.withValues(alpha: 0.5),
                               fontSize: 12,
                               letterSpacing: 1,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
        
        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),
      ],
    );
  }

  void _showQuestionSelection(TruthDareProvider provider) {
    debugPrint('🎭 _showQuestionSelection called for player: ${provider.currentPlayer?.name}');
    
    if (provider.currentPlayer == null) {
      debugPrint('❌ ERROR: currentPlayer is null, cannot show question selection!');
      return;
    }
    
    // Using showDialog instead of showModalBottomSheet for better web compatibility
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        debugPrint('✅ Building question selection dialog');
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars,
                  color: AppConstants.accentGold,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  "${provider.currentPlayer?.name}, Choose your fate:",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _buildChoiceButton(
                        title: "TRUTH",
                        color: AppConstants.cardBlue,
                        onTap: () async {
                          debugPrint('🔵 TRUTH selected');
                          Navigator.pop(context);
                          await provider.fetchQuestion(TdType.truth);
                          _showQuestionOverlay(provider);
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildChoiceButton(
                        title: "DARE",
                        color: AppConstants.cardPink,
                        onTap: () async {
                          debugPrint('🔴 DARE selected');
                          Navigator.pop(context);
                          await provider.fetchQuestion(TdType.dare);
                          _showQuestionOverlay(provider);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChoiceButton({required String title, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        debugPrint('🎯 Choice button tapped: $title');
        GameFeedbackService.tap();
        SoundManager().playUiSound(SoundManager.sfxUiSelect);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showQuestionOverlay(TruthDareProvider provider) {
    setState(() => _showQuestion = true);
    final isTruth = provider.currentQuestion?.type == TdType.truth;
    final themeColor = isTruth ? AppConstants.cardBlue : AppConstants.cardPink;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: 500,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeColor,
                themeColor.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: Column(
              // Header with Player Name
              children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: Colors.black.withValues(alpha: 0.2),
                       borderRadius: BorderRadius.circular(50),
                     ),
                     child: Text(
                       provider.currentPlayer?.name.toUpperCase() ?? "PLAYER",
                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                     ),
                   ),
                   const SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(
                         isTruth ? Icons.psychology : Icons.local_fire_department,
                         size: 48,
                         color: Colors.white.withValues(alpha: 0.8),
                       ),
                       const SizedBox(width: 12),
                       Text(
                         isTruth ? "TRUTH" : "DARE",
                         style: const TextStyle(
                           color: Colors.white,
                           fontSize: 32,
                           fontWeight: FontWeight.w900,
                           letterSpacing: 2,
                         ),
                       ),
                     ],
                   ),
              // The Question
              Expanded(
                child: Center(
                  child: provider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : provider.errorMessage != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white70, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  provider.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                          : SingleChildScrollView(
                              child: Text(
                                provider.currentQuestion?.text ?? "No question available",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(1, 1),
                                      blurRadius: 3,
                                    )
                                  ],
                                ),
                              ),
                            ),
                ),
              ),

              // Difficulty & Category Badge
              if (!provider.isLoading && provider.currentQuestion != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        provider.currentQuestion!.difficulty == TdDifficulty.easy 
                            ? Icons.sentiment_satisfied 
                            : provider.currentQuestion!.difficulty == TdDifficulty.medium
                                ? Icons.sentiment_neutral
                                : Icons.whatshot,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${provider.currentQuestion!.difficulty.name.toUpperCase()}  •  ${provider.currentQuestion!.category.name.toUpperCase()}",
                        style: const TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _showQuestion = false);
                        // Skip - no XP
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        "SKIP",
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        provider.completeTurn();
                        int xp = 15; // Define xp here
                        context.read<ProgressProvider>().recordGameResult(
                          gameId: 'game-truth-dare',
                          won: true,
                          xpAward: xp,
                          analytics: context.read<AnalyticsProvider>(),
                        );
                        GameFeedbackService.success();
                        _confettiController.play();
                        setState(() => _showQuestion = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: themeColor,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 10,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("COMPLETED", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          SizedBox(width: 8),
                          Icon(Icons.check_circle_rounded)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings(TruthDareProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstants.surfaceColor,
                AppConstants.surfaceColor.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white12, width: 2),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune, color: AppConstants.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "GAME SETTINGS",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Safe Mode Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: provider.safeMode 
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: provider.safeMode ? Colors.green : Colors.white12,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            provider.safeMode ? Icons.shield : Icons.shield_outlined,
                            color: provider.safeMode ? Colors.green : Colors.white70,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Safe Mode",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Kids-friendly content only (Ages 10-15)",
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: provider.safeMode,
                            activeThumbColor: Colors.green,
                            onChanged: (v) {
                              provider.setSafeMode(v);
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Age Group Section
                _buildSettingSection(
                  title: "Age Group",
                  icon: Icons.people,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TdAgeGroup.values.map((group) {
                      final isSelected = provider.selectedAgeGroup == group;
                      final isDisabled = provider.safeMode && group != TdAgeGroup.kids;
                      
                      return _buildChoiceChip(
                        label: _getAgeGroupLabel(group),
                        selected: isSelected,
                        disabled: isDisabled,
                        onSelected: isDisabled ? null : (s) {
                          provider.setAgeGroup(group);
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Category Section
                _buildSettingSection(
                  title: "Category",
                  icon: Icons.category,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCategoryChip('🔥 Trending', TdCategory.trending, provider, setModalState),
                      _buildCategoryChip('⭐ Most Asked', TdCategory.mostAsked, provider, setModalState),
                      _buildCategoryChip('✨ Clean', TdCategory.clean, provider, setModalState),
                      _buildCategoryChip('🌶️ Spicy', TdCategory.spicy, provider, setModalState),
                      _buildCategoryChip('💑 Couples', TdCategory.couples, provider, setModalState),
                      _buildCategoryChip('👥 Friends', TdCategory.friends, provider, setModalState),
                      _buildCategoryChip('🎭 Deep', TdCategory.deep, provider, setModalState),
                      _buildCategoryChip('📱 Social', TdCategory.social, provider, setModalState),
                      _buildCategoryChip('🎉 Party', TdCategory.party, provider, setModalState),
                      _buildCategoryChip('😜 Fun', TdCategory.fun, provider, setModalState),
                      _buildCategoryChip('🤪 Crazy', TdCategory.crazy, provider, setModalState),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                
                // Difficulty Section
                _buildSettingSection(
                  title: "Difficulty",
                  icon: Icons.speed,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TdDifficulty.values.map((diff) {
                      final isSelected = provider.selectedDifficulty == diff;
                      return _buildChoiceChip(
                        label: _getDifficultyLabel(diff),
                        selected: isSelected,
                        onSelected: (s) {
                          provider.setDifficulty(diff);
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // AI Fallback Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppConstants.accentGold),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AI Fallback",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Generate questions when database is empty",
                              style: TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: provider.useAIFallback,
                        activeThumbColor: AppConstants.accentGold,
                        onChanged: (v) {
                          provider.setUseAIFallback(v);
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    bool disabled = false,
    required Function(bool)? onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: disabled ? null : onSelected,
      selectedColor: AppConstants.primaryColor.withValues(alpha: 0.7),
      backgroundColor: disabled 
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.1),
      disabledColor: Colors.white.withValues(alpha: 0.02),
      labelStyle: TextStyle(
        color: disabled 
            ? Colors.white30
            : selected 
                ? Colors.white 
                : Colors.white70,
        fontWeight: selected ? FontWeight.bold : FontWeight.w600,
        fontSize: 13,
      ),
      side: BorderSide(
        color: selected 
            ? AppConstants.primaryColor 
            : disabled
                ? Colors.white10
                : Colors.white.withValues(alpha: 0.2),
        width: selected ? 2 : 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildCategoryChip(
    String label,
    TdCategory category,
    TruthDareProvider provider,
    StateSetter setModalState,
  ) {
    final isSelected = provider.selectedCategory == category;
    final isSpicyCategory = category == TdCategory.spicy || category == TdCategory.crazy;
    final isDisabled = provider.safeMode && isSpicyCategory;
    
    return _buildChoiceChip(
      label: label,
      selected: isSelected,
      disabled: isDisabled,
      onSelected: isDisabled ? null : (s) {
        provider.setCategory(category);
        setModalState(() {});
      },
    );
  }

  String _getAgeGroupLabel(TdAgeGroup group) {
    switch (group) {
      case TdAgeGroup.kids:
        return '👶 Kids (10-15)';
      case TdAgeGroup.teens:
        return '🧑 Teens (13-18)';
      case TdAgeGroup.adults:
        return '👨 Adults (18+)';
      case TdAgeGroup.mature:
        return '🔞 Mature (21+)';
    }
  }

  String _getDifficultyLabel(TdDifficulty diff) {
    switch (diff) {
      case TdDifficulty.easy:
        return '😊 Easy';
      case TdDifficulty.medium:
        return '😐 Medium';
      case TdDifficulty.hard:
        return '😅 Hard';
      case TdDifficulty.extreme:
        return '🔥 Extreme';
    }
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: const Text("Turn History", style: TextStyle(color: Colors.white)),
        content: Text(_history.isEmpty ? "No turns yet." : _history, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))
        ],
      ),
    );
  }

  Widget _buildSessionSettings(TruthDareProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Session Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Turns', style: TextStyle(color: AppConstants.textSecondary)),
              const SizedBox(width: 12),
              ...[5, 10, 15, 0].map((turns) {
                final label = turns == 0 ? '∞' : turns.toString();
                final selected = _targetTurns == turns;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    selectedColor: AppConstants.primaryColor.withValues(alpha: 0.6),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                    onSelected: (_) => setState(() => _targetTurns = turns),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI fallback', style: TextStyle(color: AppConstants.textSecondary)),
              Switch(
                value: _useAiFill,
                activeThumbColor: AppConstants.primaryColor,
                onChanged: (val) => setState(() => _useAiFill = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _ensureAiPlayers(TruthDareProvider provider) {
    if (!_useAiFill) return;
    final existingNames = provider.players.map((p) => p.name.toLowerCase()).toSet();
    while (provider.players.length < 2) {
      final name = _aiNames.firstWhere((n) => !existingNames.contains(n.toLowerCase()), orElse: () => 'AI-${provider.players.length + 1}');
      existingNames.add(name.toLowerCase());
      provider.addPlayerObject(Player(id: 'ai_${DateTime.now().microsecondsSinceEpoch}', name: name));
    }
  }

  void _showSessionComplete(TruthDareProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: const Text('Session Complete', style: TextStyle(color: Colors.white)),
        content: Text('$_turnCount turns played.', style: const TextStyle(color: Colors.white70)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GameOutcomeActions(
              gameId: 'game-truth-dare',
              onReplay: () {
                Navigator.pop(context);
                provider.resetGame();
                setState(() {
                  _started = false;
                  _turnCount = 0;
                });
              },
              onTryAnother: () {
                Navigator.pop(context);
                provider.resetGame();
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
