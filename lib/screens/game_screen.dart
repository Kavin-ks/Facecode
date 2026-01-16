import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:facecode/models/game_room.dart';
import 'package:facecode/providers/game_provider.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/result_screen.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/emoji_picker.dart';
import 'package:facecode/widgets/error_listener.dart';

/// Main gameplay screen.
///
/// - Emoji player can only communicate using emojis.
/// - Guessers can type guesses.
/// - 60s round timer.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _guessController = TextEditingController();
  bool _wrongGuessPulse = false;

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  Future<void> _selectActivePlayer(BuildContext context) async {
    final provider = context.read<GameProvider>();
    final room = provider.currentRoom;
    if (room == null) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppConstants.surfaceColor,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Text(
                  'Who is holding the phone?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ...room.players.map((p) {
                final isActive = provider.currentPlayer?.id == p.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppConstants.primaryColor,
                    child: Text(
                      p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(p.name),
                  subtitle: Text(room.isEmojiPlayer(p.id) ? 'Emoji player' : 'Guesser'),
                  trailing: isActive
                      ? const Icon(Icons.check, color: AppConstants.secondaryColor)
                      : null,
                  onTap: () {
                    provider.setActivePlayer(p.id);
                    Navigator.of(context).pop();
                  },
                );
              }),
              const SizedBox(height: AppConstants.defaultPadding),
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
      _guessController.clear();
      return;
    }

    // Wrong guess micro-interaction.
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

          return Scaffold(
            appBar: AppBar(
              title: const Text('FaceCode'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: AppConstants.smallPadding),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor,
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(
                          color: AppConstants.primaryColor.withAlpha(102),
                        ),
                      ),
                      child: Text(
                        '⏱️ ${room.roundTimeRemaining}s',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ).animate().fadeIn().slideX(begin: 0.1, end: 0),
                  ),
                ),
              ],
            ),
            body: Stack(
              children: [
                // Background gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppConstants.softBackgroundGradient,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Active player selector
                        InkWell(
                          onTap: () => _selectActivePlayer(context),
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConstants.surfaceColor,
                              borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Active: ${activePlayer.name}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontSize: 16),
                                  ),
                                ),
                                Text(
                                  isEmojiPlayer ? '😎 Emoji Player' : '⌨️ Guesser',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: isEmojiPlayer
                                            ? AppConstants.secondaryColor
                                            : AppConstants.textSecondary,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.swap_horiz),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(),

                        const SizedBox(height: AppConstants.defaultPadding),

                        // Prompt (emoji player only)
                        if (isEmojiPlayer)
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
                                  'Your Secret Prompt',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(color: AppConstants.textPrimary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${prompt?.category ?? ''} • ${prompt?.difficulty.name ?? ''}'.toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppConstants.textSecondary),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  prompt?.text ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: 0.06, end: 0)
                        else
                          Container(
                            padding: const EdgeInsets.all(AppConstants.defaultPadding),
                            decoration: BoxDecoration(
                              color: AppConstants.surfaceColor,
                              borderRadius:
                                  BorderRadius.circular(AppConstants.borderRadius),
                            ),
                            child: Row(
                              children: [
                                const Text('🔒', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Prompt is hidden. Watch the emojis and guess!',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: 0.06, end: 0),

                        const SizedBox(height: AppConstants.defaultPadding),

                        // Emoji trail
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(AppConstants.defaultPadding),
                            decoration: BoxDecoration(
                              color: AppConstants.surfaceColor,
                              borderRadius:
                                  BorderRadius.circular(AppConstants.borderRadius),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Emoji Trail',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const Spacer(),
                                    if (isEmojiPlayer)
                                      TextButton.icon(
                                        onPressed: () => provider.clearEmojiMessages(),
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text('Clear'),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppConstants.smallPadding),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Wrap(
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
                                              color: AppConstants.backgroundColor,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color:
                                                    AppConstants.primaryColor.withAlpha(64),
                                              ),
                                            ),
                                            child: Text(
                                              e,
                                              style: const TextStyle(fontSize: 30),
                                            ),
                                          ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppConstants.defaultPadding),

                        // Guess input (guessers only)
                        if (!isEmojiPlayer)
                          AnimatedContainer(
                            duration: 250.ms,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConstants.surfaceColor,
                              borderRadius:
                                  BorderRadius.circular(AppConstants.borderRadius),
                              border: Border.all(
                                color: _wrongGuessPulse
                                    ? AppConstants.errorColor
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _guessController,
                                    decoration: const InputDecoration(
                                      hintText: 'Type your guess…',
                                      prefixIcon: Icon(Icons.help_outline),
                                    ),
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _submitGuess(context),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () => _submitGuess(context),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(120, 56),
                                  ),
                                  child: const Text('Guess'),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: 0.08, end: 0)
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConstants.surfaceColor,
                              borderRadius:
                                  BorderRadius.circular(AppConstants.borderRadius),
                              border: Border.all(
                                color: AppConstants.secondaryColor.withAlpha(89),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text('🚫', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Text input is disabled for the emoji player.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(color: AppConstants.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(),
                      ],
                    ),
                  ),
                ),

                // Loading overlay
                if (provider.isBusy)
                  Container(
                    color: Colors.black.withAlpha(102),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
            bottomSheet: isEmojiPlayer
                ? EmojiPicker(
                    onEmojiSelected: (emoji) => provider.sendEmoji(emoji),
                  )
                : null,
          );
        },
      ),
    );
  }
}
