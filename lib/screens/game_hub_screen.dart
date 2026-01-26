import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:facecode/models/game_metadata.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/utils/game_catalog.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/widgets/daily_challenge_card.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:facecode/services/game_feedback_service.dart';

/// Main Game Hub - Home screen showing all available mini-games
class GameHubScreen extends StatefulWidget {
  const GameHubScreen({super.key});

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  GameCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildDailyChallenge(),
              _buildCategoryTabs(),
              Expanded(
                child: _buildGameGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ProgressProvider>(
      builder: (context, progress, _) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              // App Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AnimatedLogo(size: 50, showGlow: true),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FaceCode',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Party Game Hub',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppConstants.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Progress Card
              NeonCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Level Badge
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppConstants.goldGradient,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.accentGold.withAlpha(60),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              progress.getLevelBadge(),
                              style: const TextStyle(fontSize: 24),
                            ),
                            Text(
                              '${progress.progress.level}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Progress Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Level ${progress.progress.level}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.textPrimary,
                                ),
                              ),
                              Text(
                                '${progress.progress.currentXP}/${progress.progress.xpForNextLevel} XP',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppConstants.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress.progress.progressPercent,
                              backgroundColor: AppConstants.surfaceLight,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppConstants.primaryColor,
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatChip(
                                Icons.videogame_asset,
                                '${progress.progress.totalGamesPlayed}',
                                'Games',
                              ),
                              const SizedBox(width: 8),
                              _buildStatChip(
                                Icons.emoji_events,
                                '${progress.progress.totalWins}',
                                'Wins',
                              ),
                              const SizedBox(width: 8),
                              _buildStatChip(
                                Icons.local_fire_department,
                                '${progress.progress.currentStreak}',
                                'Streak',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppConstants.borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppConstants.secondaryColor),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppConstants.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChallenge() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: DailyChallengeCard(),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
        children: [
          _buildCategoryChip(null, 'All Games', Icons.apps),
          ...GameCatalog.categories.map((category) {
            return _buildCategoryChip(
              category,
              category.name,
              category.icon,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(GameCategory? category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: PremiumTap(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedCategory = category;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: category?.color != null
                        ? [category!.color, category.color.withAlpha(200)]
                        : AppConstants.primaryGradient,
                  )
                : null,
            color: isSelected ? null : AppConstants.surfaceLight,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppConstants.borderColor,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (category?.color ?? AppConstants.primaryColor)
                          .withAlpha(60),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppConstants.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameGrid() {
    final games = _selectedCategory == null
        ? GameCatalog.allGames
        : GameCatalog.getByCategory(_selectedCategory!);

    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        // Staggered entrance using flutter_animate
        return GameCard(game: games[index], index: index)
            .animate(delay: (80 * index).ms)
            .fadeIn(duration: 420.ms, curve: Curves.easeOut)
            .slide(begin: const Offset(0, 0.06), end: const Offset(0, 0), duration: 420.ms, curve: Curves.easeOutBack)
            .scaleXY(begin: 0.98, end: 1.0, duration: 420.ms, curve: Curves.elasticOut);
      },
    );
  }

}

// Individual animated game card widget
class GameCard extends StatefulWidget {
  final GameMetadata game;
  final int index;

  const GameCard({super.key, required this.game, required this.index});

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _hovered = false;
  bool _pressed = false;

  void _onTap() async {
    GameFeedbackService.tap();
    setState(() => _pressed = true);
    await Future.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    setState(() => _pressed = false);
    HapticFeedback.mediumImpact();

    // Navigate with a slight delay so the press animation is visible
    Navigator.pushNamed(context, widget.game.route);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final glowColor = game.category.color.withAlpha(100);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1.0, end: _hovered ? 1.02 : (_pressed ? 0.98 : 1.0)),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (context, double scale, child) {
          final translateY = _hovered ? -8.0 : (_pressed ? -4.0 : 0.0);
          return Transform.translate(
            offset: Offset(0, translateY),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: _hovered ? glowColor : Colors.black.withAlpha(40),
                    blurRadius: _hovered ? 28 : 12,
                    offset: Offset(0, _hovered ? 12 : 6),
                  ),
                ],
              ),
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            ),
          );
        },
        child: PremiumTap(
          onTap: _onTap,
          child: NeonCard(
            padding: EdgeInsets.zero,
            gradientColors: game.gradientColors,
            child: Column(
              children: [
                // Icon Header
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: game.gradientColors,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      game.icon,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Game Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: AppConstants.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${game.minPlayers}-${game.maxPlayers}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppConstants.textMuted,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: game.category.color.withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                game.category.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: game.category.color,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, duration: 500.ms),
        ),
      ),
    );
  }
}

