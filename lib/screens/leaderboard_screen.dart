import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/providers/leaderboard_provider.dart';
import 'package:facecode/models/leaderboard_entry.dart';
import 'package:facecode/screens/public_profile_screen.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LeaderboardProvider(),
      child: const _LeaderboardContent(),
    );
  }
}

class _LeaderboardContent extends StatefulWidget {
  const _LeaderboardContent();

  @override
  State<_LeaderboardContent> createState() => _LeaderboardContentState();
}

class _LeaderboardContentState extends State<_LeaderboardContent> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final progress = context.read<ProgressProvider>().progress;
    final auth = context.read<AuthProvider>();
    final userName = auth.user?.displayName ?? "Player";
    
    // Default load
    context.read<LeaderboardProvider>().loadLeaderboard(
      LeaderboardType.weekly,
      progress,
      userName: userName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeaderboardProvider>();
    final progress = context.watch<ProgressProvider>().progress;
    final auth = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildTabs(provider, progress, auth.user?.displayName ?? "Player"),
            ),

            // Content
            Expanded(
              child: provider.isLoading 
                  ? _buildSkeletonLoader()
                  : _buildLeaderboardList(provider.entries),
            ),
            
            // Sticky User Footer
            if (!provider.isLoading && provider.entries.any((e) => e.isUser))
              _buildStickyFooter(provider.entries.firstWhere((e) => e.isUser)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              PremiumIconButton(
                icon: Icons.arrow_back,
                color: Colors.white,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 4),
              Text(
                'Leaderboard',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: AppConstants.accentGold, size: 16),
                const SizedBox(width: 4),
                Text(
                  "Season 1",
                  style: TextStyle(
                    color: AppConstants.accentGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(LeaderboardProvider provider, dynamic progress, String userName) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buidTabItem(provider, "Daily", LeaderboardType.daily, progress, userName),
          _buidTabItem(provider, "Weekly", LeaderboardType.weekly, progress, userName),
          _buidTabItem(provider, "All Time", LeaderboardType.allTime, progress, userName),
        ],
      ),
    );
  }

  Widget _buidTabItem(LeaderboardProvider provider, String label, LeaderboardType type, dynamic progress, String userName) {
    final isSelected = provider.currentType == type;
    return Expanded(
      child: PremiumTap(
        onTap: () => provider.loadLeaderboard(type, progress, userName: userName),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppConstants.textMuted,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> entries) {
    if (entries.isEmpty) return const SizedBox();

    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Podium
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (top3.length > 1) _buildPodiumPlace(top3[1], 2), // 2nd
                if (top3.isNotEmpty) _buildPodiumPlace(top3[0], 1), // 1st
                if (top3.length > 2) _buildPodiumPlace(top3[2], 3), // 3rd
              ],
            ),
          ),
        ),

        // List
        Container(
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, -5)),
            ],
          ),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rest.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildRankItem(rest[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumPlace(LeaderboardEntry entry, int place) {
    // 1st place is bigger
    final isFirst = place == 1;
    final size = isFirst ? 100.0 : 80.0;
    final heightDifference = isFirst ? 40.0 : 0.0;
    final color = place == 1 ? AppConstants.accentGold : (place == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

    return Expanded(
      child: PremiumTap(
        onTap: () {
          Navigator.of(context).push(
            AppRoute.fadeSlide(PublicProfileScreen(entry: entry)),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
          // Crown for 1st
          if (isFirst) 
             const Icon(Icons.star, color: AppConstants.accentGold, size: 24)
                 .animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -5, duration: 1.seconds),
          
          const SizedBox(height: 8),

          // Avatar
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 15),
              ],
              color: AppConstants.surfaceLight,
            ),
            child: Center(
              child: Text(entry.avatar, style: TextStyle(fontSize: size * 0.4)),
            ),
          ).animate().scale(delay: (place * 200).ms, duration: 600.ms, curve: Curves.elasticOut),

          const SizedBox(height: 12),

          Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: entry.isUser ? AppConstants.primaryColor : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isFirst ? 14 : 12,
            ),
          ),
          
          Text(
            "${entry.score}",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: isFirst ? 16 : 14,
            ),
          ),

          const SizedBox(height: 12),
          
          // Podium Bar
          Container(
            height: 60 + heightDifference,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(top: BorderSide(color: color, width: 1)),
            ),
            alignment: Alignment.center,
            child: Text(
              "$place",
              style: TextStyle(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().slideY(begin: 1, end: 0, delay: (place * 100).ms, duration: 500.ms, curve: Curves.easeOutBack),
        ],
      ),
      ),
    );
  }

  Widget _buildRankItem(LeaderboardEntry entry) {
    return PremiumTap(
      onTap: () {
        Navigator.of(context).push(
          AppRoute.fadeSlide(PublicProfileScreen(entry: entry)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isUser ? AppConstants.primaryColor.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.isUser ? AppConstants.primaryColor.withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 30,
            child: Text(
              "#${entry.rank}",
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          
          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppConstants.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(entry.avatar, style: const TextStyle(fontSize: 20))),
          ),

          const SizedBox(width: 16),

          // Name and Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    color: entry.isUser ? Colors.white : AppConstants.textPrimary,
                    fontWeight: entry.isUser ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                if (entry.rankTitle != null)
                  Row(
                    children: [
                      Text(
                        entry.rankTitle!.toUpperCase(),
                        style: TextStyle(
                          color: entry.rankColor ?? AppConstants.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      // Today's Best Icon
                      if (entry.isDailyBest)
                         const Padding(
                           padding: EdgeInsets.only(left: 4.0),
                           child: Icon(Icons.emoji_events_rounded, color: AppConstants.accentGold, size: 10),
                         ),
                    ],
                  ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${entry.score}",
                style: const TextStyle(
                  color: AppConstants.accentGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                "XP",
                style: TextStyle(
                  color: AppConstants.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildSkeletonLoader() {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Podium Skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [ const SkeletonBase(width: 80, height: 80, radius: 40), const SizedBox(height: 12), const SkeletonBase(width: 60, height: 12), const SizedBox(height: 12), Container(height: 60, color: Colors.white.withValues(alpha: 0.05)) ])),
                Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [ const SkeletonBase(width: 100, height: 100, radius: 50), const SizedBox(height: 12), const SkeletonBase(width: 80, height: 14), const SizedBox(height: 12), Container(height: 100, color: Colors.white.withValues(alpha: 0.05)) ])),
                Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [ const SkeletonBase(width: 80, height: 80, radius: 40), const SizedBox(height: 12), const SkeletonBase(width: 60, height: 12), const SizedBox(height: 12), Container(height: 60, color: Colors.white.withValues(alpha: 0.05)) ])),
              ],
            ),
          ),
        ),

        // List Skeleton
        Container(
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => const SkeletonListItem(),
          ),
        ),
      ],
    );
  }

  Widget _buildStickyFooter(LeaderboardEntry userEntry) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // User Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  userEntry.avatar,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "You",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (userEntry.rankTitle != null)
                    Text(
                      userEntry.rankTitle!.toUpperCase(),
                      style: TextStyle(
                        color: userEntry.rankColor ?? AppConstants.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                   Text(
                    "#${userEntry.rank} in leaderboard",
                    style: const TextStyle(
                      color: AppConstants.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${userEntry.score}",
                  style: const TextStyle(
                    color: AppConstants.accentGold,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const Text(
                  "XP",
                  style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutBack);
  }
}
