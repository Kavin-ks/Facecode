import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/utils/game_catalog.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/providers/user_preferences_provider.dart';
import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/models/game_metadata.dart';
import 'package:facecode/widgets/game_card_modern.dart';
import 'package:facecode/widgets/premium_ui.dart';

/// Modern Home Screen matching Play Store game hub style
class HomeScreenNew extends StatefulWidget {
  const HomeScreenNew({super.key});

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew> {
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Party', 'Brain', 'Fast', 'Classic'];

  List<GameMetadata> get _filteredGames {
    if (_selectedCategory == 'All') {
      return GameCatalog.allGames;
    }
    return GameCatalog.allGames.where((game) {
      return game.category.name.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final progress = progressProvider.progress;

    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.displayName ?? 'Player';
    final userInitial = authProvider.user?.initial ?? 'P';

    final isDailyReady = progress.dailyChallengeGameId != null;
    final dailyGame = GameCatalog.allGames.firstWhere(
      (g) => g.id == progress.dailyChallengeGameId,
      orElse: () => GameCatalog.allGames.first,
    );

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildAppBar(context, userName, userInitial),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStatsCard(progress),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: isDailyReady
                    ? _buildDailyChallenge(context, progress, dailyGame)
                    : _buildDailyChallengeSkeleton(),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Games',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildCategoryChip(category),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: _filteredGames.length,
                  itemBuilder: (context, index) {
                    final game = _filteredGames[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GameCardModern(
                        game: game,
                        onTap: () {
                          context.read<UserPreferencesProvider>().addToRecentlyPlayed(game.id);
                          Navigator.pushNamed(context, game.route);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String userName, String userInitial) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const AnimatedLogo(size: 36, showGlow: true),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FaceCode',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Hi $userName',
                  style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            GlassCard(
              radius: 12,
              padding: const EdgeInsets.all(10),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon!')),
                );
              },
              child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Center(
                  child: Text(
                    userInitial,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStatsCard(dynamic progress) {
    return GlassCard(
      radius: 20,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppConstants.goldGradient),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppConstants.accentGold.withAlpha(50), blurRadius: 14),
              ],
            ),
            child: Center(
              child: Text(_levelBadge(progress.level), style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Level ${progress.level}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${progress.currentXP}/${progress.xpForNextLevel} XP', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.progressPercent,
                    backgroundColor: Colors.white.withAlpha(20),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatPill(Icons.videogame_asset, '${progress.totalGamesPlayed}', 'Played'),
                    const SizedBox(width: 8),
                    _buildStatPill(Icons.emoji_events, '${progress.totalWins}', 'Wins'),
                    const SizedBox(width: 8),
                    _buildStatPill(Icons.local_fire_department, '${progress.currentStreak}', 'Streak'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _levelBadge(int level) {
    if (level >= 50) return '👑';
    if (level >= 40) return '💎';
    if (level >= 30) return '⭐';
    if (level >= 20) return '🔥';
    if (level >= 10) return '🎯';
    return '🌟';
  }

  Widget _buildStatPill(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppConstants.secondaryColor),
          const SizedBox(width: 4),
          Text('$value $label', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDailyChallenge(BuildContext context, dynamic progress, GameMetadata dailyGame) {
    final completed = progress.dailyChallengeCompleted == true;
    return GlassCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('DAILY CHALLENGE', style: TextStyle(color: AppConstants.primaryColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.white.withAlpha(10), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(dailyGame.bannerImage, style: const TextStyle(fontSize: 20))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dailyGame.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            dailyGame.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: completed ? null : () => Navigator.pushNamed(context, dailyGame.route),
              style: ElevatedButton.styleFrom(
                backgroundColor: completed ? Colors.white24 : AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(completed ? 'Completed' : 'Play', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChallengeSkeleton() {
    return GlassCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonLine(width: 140),
          SizedBox(height: 12),
          SkeletonLine(width: 220, height: 16),
          SizedBox(height: 8),
          SkeletonLine(width: 260),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor.withAlpha(40) : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppConstants.primaryColor : Colors.white.withAlpha(20)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppConstants.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
