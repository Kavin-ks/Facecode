import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facecode/models/game_metadata.dart';
import 'package:facecode/models/game_difficulty.dart';
import 'package:facecode/utils/game_catalog.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/utils/color_ext.dart';
import 'package:facecode/widgets/shimmer.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/providers/user_preferences_provider.dart';
import 'package:facecode/widgets/featured_carousel.dart';
import 'package:facecode/widgets/premium_game_card.dart';
import 'package:facecode/widgets/search_filter.dart';

/// Redesigned premium game hub with Netflix/Play Store style layout
class GameHubScreen extends StatefulWidget {
  const GameHubScreen({super.key});

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  GameDifficulty? _selectedDifficulty;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: GameCategory.values.length + 1, // +1 for "All"
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        selectedDifficulty: _selectedDifficulty,
        onDifficultyChanged: (difficulty) {
          setState(() => _selectedDifficulty = difficulty);
        },
      ),
    );
  }

  List<GameMetadata> _getFilteredGames() {
    List<GameMetadata> games = GameCatalog.allGames;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      games = GameCatalog.search(_searchQuery);
    }

    // Difficulty filter
    if (_selectedDifficulty != null) {
      games = games
          .where((game) => game.difficulty == _selectedDifficulty)
          .toList();
    }

    return games;
  }

  void _navigateToGame(GameMetadata game) {
    final prefsProvider = context.read<UserPreferencesProvider>();
    prefsProvider.addToRecentlyPlayed(game.id);
    Navigator.pushNamed(context, game.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar with User Info
              _buildAppBar(),

              // Search Bar
              SliverToBoxAdapter(
                child: PremiumSearchBar(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  onFilterTap: _showFilterSheet,
                ),
              ),

              // Hero Stats Section
              if (_searchQuery.isEmpty) _buildHeroSection(),

              // Featured Games Carousel
              if (_searchQuery.isEmpty)
                SliverToBoxAdapter(
                  child: Consumer<UserPreferencesProvider>(
                    builder: (context, prefsProvider, _) {
                      return FeaturedGamesCarousel(
                        games: GameCatalog.featuredGames,
                        onGameTap: _navigateToGame,
                        isFavorite: false,
                        onFavoriteToggle: (game) {
                          prefsProvider.toggleFavorite(game.id);
                        },
                      );
                    },
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Recently Played Section
              if (_searchQuery.isEmpty) _buildRecentlyPlayedSection(),

              // Category Tabs
              if (_searchQuery.isEmpty) _buildCategoryTabs(),

              // Games by Category
              if (_searchQuery.isEmpty)
                _buildCategoryGames()
              else
                _buildSearchResults(),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Logo
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppConstants.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacitySafe(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '🎮',
                  style: TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // App Name
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FaceCode',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Play Store',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Profile Button
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withOpacitySafe(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacitySafe(0.3),
                  width: 2,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.person, color: Color(0xFF00E5FF)),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return SliverToBoxAdapter(
      child: Consumer<ProgressProvider>(
        builder: (context, progressProvider, _) {
          final progress = progressProvider.progress;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacitySafe(0.15),
                        Colors.white.withOpacitySafe(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacitySafe(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome Back!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Level ${progress.level}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    progressProvider.getLevelBadge(),
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Streak Display
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF4081), Color(0xFFFF6E40)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '🔥',
                                  style: TextStyle(fontSize: 24),
                                ),
                                Text(
                                  '${progress.currentStreak}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'streak',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // XP Progress
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'XP Progress',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                '${progress.currentXP} / ${progress.xpForNextLevel} XP',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00E5FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress.currentXP / progress.xpForNextLevel,
                              backgroundColor: Colors.white.withOpacitySafe(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF00E5FF),
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                      // Daily Challenge
                      if (progress.dailyChallengeGameId != null) ...[
                        const SizedBox(height: 16),
                        Builder(builder: (context) {
                          final challengeGame = GameCatalog.getById(progress.dailyChallengeGameId!);
                          final challengeTitle = challengeGame?.name ?? progress.dailyChallengeGameId!;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withOpacitySafe(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFD700).withOpacitySafe(0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  color: Color(0xFFFFD700),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Daily Challenge',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        challengeTitle,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!progress.dailyChallengeCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD700),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      '+100 XP',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF4CAF50),
                                    size: 24,
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentlyPlayedSection() {
    return SliverToBoxAdapter(
      child: Consumer<UserPreferencesProvider>(
        builder: (context, prefsProvider, _) {
          if (prefsProvider.recentlyPlayedIds.isEmpty) {
            // Show shimmer placeholders
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history, color: Color(0xFF00E5FF), size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Recently Played',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          ' ',
                          style: TextStyle(color: Color(0xFF00E5FF)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      return Shimmer(width: 180, height: 220, borderRadius: BorderRadius.circular(20));
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: 3,
                  ),
                ),
              ],
            );
          }

          final recentGames = prefsProvider.recentlyPlayedIds
              .map((id) => GameCatalog.getById(id))
              .where((game) => game != null)
              .cast<GameMetadata>()
              .toList();

          if (recentGames.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history, color: Color(0xFF00E5FF), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Recently Played',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        prefsProvider.clearRecentlyPlayed();
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Color(0xFF00E5FF)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: recentGames.length,
                  itemBuilder: (context, index) {
                    final game = recentGames[index];
                    return PremiumGameCard(
                      game: game,
                      onTap: () => _navigateToGame(game),
                      isFavorite: prefsProvider.isFavorite(game.id),
                      onFavoriteToggle: () {
                        prefsProvider.toggleFavorite(game.id);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _CategoryTabsDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF00E5FF),
          labelColor: const Color(0xFF00E5FF),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          tabs: [
            const Tab(text: 'All Games'),
            ...GameCategory.values.map((category) {
              return Tab(
                child: Row(
                  children: [
                    Icon(category.icon, size: 18),
                    const SizedBox(width: 6),
                    Text(category.name),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGames() {
    return SliverToBoxAdapter(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildGameGrid(GameCatalog.allGames),
          ...GameCategory.values.map((category) {
            final games = GameCatalog.getByCategory(category);
            return _buildGameGrid(games);
          }),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final filteredGames = _getFilteredGames();
    
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              '${filteredGames.length} games found',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ),
          _buildGameGrid(filteredGames),
        ],
      ),
    );
  }

  Widget _buildGameGrid(List<GameMetadata> games) {
    if (games.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.sports_esports,
                size: 64,
                color: Colors.white30,
              ),
              SizedBox(height: 16),
              Text(
                'No games found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<UserPreferencesProvider>(
      builder: (context, prefsProvider, _) {
        return SizedBox(
          height: 220.0 * ((games.length / 2).ceil()),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
            ),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return PremiumGameCard(
                game: game,
                onTap: () => _navigateToGame(game),
                isFavorite: prefsProvider.isFavorite(game.id),
                onFavoriteToggle: () {
                  prefsProvider.toggleFavorite(game.id);
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// Custom delegate for sticky category tabs
class _CategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _CategoryTabsDelegate(this.tabBar);

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0F0C29).withOpacitySafe(0.95),
                const Color(0xFF0F0C29).withOpacitySafe(0.8),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacitySafe(0.1),
                width: 1,
              ),
            ),
          ),
          child: tabBar,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_CategoryTabsDelegate oldDelegate) => false;
}
