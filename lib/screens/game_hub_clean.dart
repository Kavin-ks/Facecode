import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facecode/utils/game_catalog.dart';
import 'package:facecode/widgets/clean_game_card.dart';
import 'package:facecode/providers/user_preferences_provider.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/models/game_metadata.dart';
import 'package:facecode/utils/color_ext.dart';

class GameHubClean extends StatefulWidget {
  const GameHubClean({super.key});

  @override
  State<GameHubClean> createState() => _GameHubCleanState();
}

class _GameHubCleanState extends State<GameHubClean> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: GameCategory.values.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>().progress;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 4),
            const Text('FaceCode', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openProfile,
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacitySafe(0.12),
              child: const Text('K', style: TextStyle(color: Colors.white)),
            ),
            tooltip: 'Profile',
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.white54,
        backgroundColor: Colors.transparent,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            Navigator.pushNamed(context, '/leaderboard');
          } else if (index == 2) {
            _openProfile();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_on), label: 'Games'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: 'Ranks'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hi ${context.watch<AuthProvider>().user?.name ?? 'Kavin'} 👋', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text('What do you want to play today?', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  // Daily challenge simple card
                  if (progress.dailyChallengeGameId != null)
                    Card(
                      elevation: 1,
                      child: ListTile(
                        leading: const Icon(Icons.emoji_events),
                        title: Text('Daily Challenge'),
                        subtitle: Text(GameCatalog.getById(progress.dailyChallengeGameId!)?.name ?? 'Daily challenge'),
                        trailing: TextButton(
                          onPressed: () async {
                            await context.read<ProgressProvider>().completeDailyChallenge();
                          },
                          child: const Text('Claim'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Categories
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
                    tabs: [
                      const Tab(text: 'All'),
                      ...GameCategory.values.map((c) => Tab(text: c.name)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGameList(GameCatalog.allGames),
                ...GameCategory.values.map((category) => _buildGameList(GameCatalog.getByCategory(category))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameList(List<GameMetadata> games) {
    if (games.isEmpty) {
      return Center(child: Text('No games yet', style: Theme.of(context).textTheme.bodySmall));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return CleanGameCard(
          game: game,
          onPlay: () {
            // Record recently played and navigate
            context.read<UserPreferencesProvider>().addToRecentlyPlayed(game.id);
            Navigator.pushNamed(context, game.route);
          },
          isFavorite: context.watch<UserPreferencesProvider>().isFavorite(game.id),
          onFavoriteToggle: () => context.read<UserPreferencesProvider>().toggleFavorite(game.id),
        );
      },
    );
  }
}
