import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:facecode/models/game_room.dart';
import 'package:facecode/providers/game_provider.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/result_screen.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/emoji_picker.dart';
import 'package:facecode/widgets/error_listener.dart';

/// Premium main gameplay screen.
///
/// - Emoji player can only communicate using emojis.
/// - Guessers can type guesses.
/// - 60s round timer.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _guessController = TextEditingController();
  bool _wrongGuessPulse = false;
  late AnimationController _timerPulseController;

  @override
  void initState() {
    super.initState();
    _timerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _guessController.dispose();
    _timerPulseController.dispose();
    super.dispose();
  }

  Future<void> _selectActivePlayer(BuildContext context) async {
    final provider = context.read<GameProvider>();
    final room = provider.currentRoom;
    if (room == null) return;

    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swap_horiz, color: AppConstants.primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Switch Player',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ...room.players.map((p) {
                final isActive = provider.currentPlayer?.id == p.id;
                final isEmoji = room.isEmojiPlayer(p.id);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? AppConstants.primaryColor.withAlpha(20) 
                        : AppConstants.backgroundColor.withAlpha(100),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive 
                          ? AppConstants.primaryColor.withAlpha(100) 
                          : AppConstants.borderColor,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? const LinearGradient(colors: AppConstants.premiumGradient)
                            : null,
                        color: isActive ? null : AppConstants.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      isEmoji ? '😎 Emoji player' : '⌨️ Guesser',
                      style: TextStyle(
                        color: isEmoji ? AppConstants.neonPink : AppConstants.textMuted,
                      ),
                    ),
                    trailing: isActive
                        ? Icon(Icons.check_circle, color: AppConstants.successColor)
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      provider.setActivePlayer(p.id);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              }),
              const SizedBox(height: AppConstants.largePadding),
            ],
          ),
        );
      },
    );
  }

  void _submitGuess(BuildContext context) {
    final provider = context.read<GameProvider>();
    final room = provider.currentRoom;
    final player = provider.currentPlayer;

    if (room == null || player == null) return;

    final ok = provider.submitGuess(_guessController.text, player.id);
    if (ok) {
      HapticFeedback.heavyImpact();
      _guessController.clear();
      return;
    }

    // Wrong guess micro-interaction
    HapticFeedback.lightImpact();
    setState(() {
      _wrongGuessPulse = true;
    });
    Future.delayed(350.ms, () {
      if (!mounted) return;
      setState(() {
        _wrongGuessPulse = false;
      });
    });
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

          if (room.state == GameState.results) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                AppRoute.fadeSlide(const ResultScreen()),
              );
            });
          }

          final activePlayer = provider.currentPlayer ?? room.players.first;
          if (provider.currentPlayer == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.setActivePlayer(activePlayer.id);
            });
          }

          final isEmojiPlayer = room.isEmojiPlayer(activePlayer.id);
          final prompt = room.currentPrompt;
          final timeRemaining = room.roundTimeRemaining;
          final isLowTime = timeRemaining <= 10;

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
                  SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        // Custom App Bar
                        _buildGameAppBar(context, timeRemaining, isLowTime),
                        
                        // Main Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(AppConstants.defaultPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Active player selector
                                _buildPlayerSelector(activePlayer, isEmojiPlayer),

                                const SizedBox(height: AppConstants.defaultPadding),

                                // Prompt section
                                if (isEmojiPlayer)
                                  _buildSecretPrompt(prompt)
                                else
                                  _buildHiddenPrompt(),

                                const SizedBox(height: AppConstants.defaultPadding),

                                // Emoji trail
                                _buildEmojiTrail(room, isEmojiPlayer, provider),

                                const SizedBox(height: AppConstants.defaultPadding),

                                // Guess input (guessers only)
                                if (!isEmojiPlayer)
                                  _buildGuessInput()
                                else
                                  _buildEmojiOnlyNotice(),
                                
                                // Space for bottom sheet
                                if (isEmojiPlayer)
                                  const SizedBox(height: 280),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Loading overlay
                  if (provider.isBusy)
                    Container(
                      color: Colors.black.withAlpha(150),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            bottomSheet: isEmojiPlayer
                ? EmojiPicker(
                    onEmojiSelected: (emoji) {
                      HapticFeedback.selectionClick();
                      provider.sendEmoji(emoji);
                    },
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildGameAppBar(BuildContext context, int timeRemaining, bool isLowTime) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor.withAlpha(150),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Row(
              children: [
                const Text('😎', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: AppConstants.neonGradient,
                  ).createShader(bounds),
                  child: const Text(
                    'FaceCode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Timer
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isLowTime
                  ? const LinearGradient(
                      colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                    )
                  : null,
              color: isLowTime ? null : AppConstants.surfaceColor.withAlpha(150),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLowTime 
                    ? Colors.transparent 
                    : AppConstants.borderColor,
              ),
              boxShadow: isLowTime
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF416C).withAlpha(60),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: isLowTime ? Colors.white : AppConstants.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${timeRemaining}s',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
              .animate(
                target: isLowTime ? 1 : 0,
                onPlay: (controller) {
                  if (isLowTime) controller.repeat(reverse: true);
                },
              )
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 500.ms,
              ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildPlayerSelector(dynamic activePlayer, bool isEmojiPlayer) {
    return GestureDetector(
      onTap: () => _selectActivePlayer(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor.withAlpha(150),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConstants.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppConstants.premiumGradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  activePlayer.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activePlayer.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to switch player',
                    style: TextStyle(
                      color: AppConstants.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isEmojiPlayer 
                    ? AppConstants.neonPink.withAlpha(30) 
                    : AppConstants.neonBlue.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isEmojiPlayer ? '😎 Emoji' : '⌨️ Guesser',
                style: TextStyle(
                  color: isEmojiPlayer ? AppConstants.neonPink : AppConstants.neonBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.swap_horiz, color: AppConstants.textMuted, size: 22),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildSecretPrompt(dynamic prompt) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor.withAlpha(30),
            AppConstants.secondaryColor.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.primaryColor.withAlpha(80),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withAlpha(30),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🤫', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              const Text(
                'YOUR SECRET PROMPT',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor.withAlpha(100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${prompt?.category ?? ''} • ${prompt?.difficulty.name ?? ''}'.toUpperCase(),
              style: TextStyle(
                color: AppConstants.goldAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: AppConstants.neonGradient,
            ).createShader(bounds),
            child: Text(
              prompt?.text ?? '',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.06, end: 0);
  }

  Widget _buildHiddenPrompt() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.neonBlue.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🔒', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Secret Prompt Hidden',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Watch the emojis and guess the word!',
                  style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.06, end: 0);
  }

  Widget _buildEmojiTrail(GameRoom room, bool isEmojiPlayer, GameProvider provider) {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_emotions, color: AppConstants.goldAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'EMOJI TRAIL',
                style: TextStyle(
                  color: AppConstants.goldAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              if (isEmojiPlayer)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    provider.clearEmojiMessages();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppConstants.errorColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppConstants.errorColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Clear',
                          style: TextStyle(
                            color: AppConstants.errorColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          if (room.emojiMessages.isEmpty)
            Center(
              child: Column(
                children: [
                  Text(
                    '🎭',
                    style: TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No emojis yet...',
                    style: TextStyle(
                      color: AppConstants.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final e in room.emojiMessages)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.backgroundColor.withAlpha(150),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppConstants.primaryColor.withAlpha(50),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withAlpha(20),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      e,
                      style: const TextStyle(fontSize: 32),
                    ),
                  )
                      .animate()
                      .fadeIn()
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        curve: Curves.elasticOut,
                      ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGuessInput() {
    return AnimatedContainer(
      duration: 250.ms,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _wrongGuessPulse
              ? AppConstants.errorColor
              : AppConstants.borderColor,
          width: _wrongGuessPulse ? 2 : 1,
        ),
        boxShadow: _wrongGuessPulse
            ? [
                BoxShadow(
                  color: AppConstants.errorColor.withAlpha(40),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.backgroundColor.withAlpha(100),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _guessController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your guess…',
                  hintStyle: TextStyle(color: AppConstants.textMuted),
                  prefixIcon: Icon(Icons.lightbulb_outline, color: AppConstants.textMuted, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitGuess(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _submitGuess(context),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppConstants.premiumGradient),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withAlpha(60),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'GUESS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.08, end: 0);
  }

  Widget _buildEmojiOnlyNotice() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: AppConstants.neonPink.withAlpha(15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppConstants.neonPink.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.neonPink.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🚫', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emoji Only Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use the emoji picker below to communicate!',
                  style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}
