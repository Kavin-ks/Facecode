import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:facecode/models/game_metadata.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/utils/game_catalog.dart';
import 'package:facecode/widgets/premium_ui.dart';

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
    return Consumer<ProgressProvider>(
      builder: (context, progress, _) {
        final challengeGameId = progress.progress.dailyChallengeGameId;
        final isCompleted = progress.progress.dailyChallengeCompleted;
        
        if (challengeGameId == null) return const SizedBox.shrink();
        
        final game = GameCatalog.getById(challengeGameId);
        if (game == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
          child: NeonCard(
            onTap: isCompleted ? null : () {
              HapticFeedback.mediumImpact();
              Navigator.pushNamed(context, game.route);
            },
            gradientColors: isCompleted 
                ? [Colors.grey.shade700, Colors.grey.shade800]
                : const [Color(0xFFFFD700), Color(0xFFFFA000)],
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [Colors.grey.shade600, Colors.grey.shade700]
                          : AppConstants.goldGradient,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.stars,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '⭐ DAILY CHALLENGE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.accentGold,
                              letterSpacing: 1,
                            ),
                          ),
                          if (isCompleted) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppConstants.successColor,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCompleted ? 'Completed! Come back tomorrow' : game.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      if (!isCompleted)
                        Text(
                          '+100 XP Bonus',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isCompleted)
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppConstants.textPrimary,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
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
      child: GestureDetector(
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
        return _buildGameCard(games[index]);
      },
    );
  }

  Widget _buildGameCard(GameMetadata game) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.pushNamed(context, game.route);
      },
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
      ),
    );
  }
}
