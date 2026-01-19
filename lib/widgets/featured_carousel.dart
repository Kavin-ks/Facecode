import 'dart:async';
import 'package:flutter/material.dart';
import 'package:facecode/models/game_metadata.dart';
import 'package:facecode/widgets/premium_game_card.dart';
import 'package:facecode/utils/color_ext.dart';
import 'package:facecode/widgets/shimmer.dart';

/// Auto-scrolling featured games carousel
class FeaturedGamesCarousel extends StatefulWidget {
  final List<GameMetadata> games;
  final Function(GameMetadata) onGameTap;
  final bool isFavorite;
  final Function(GameMetadata)? onFavoriteToggle;

  const FeaturedGamesCarousel({
    super.key,
    required this.games,
    required this.onGameTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  State<FeaturedGamesCarousel> createState() => _FeaturedGamesCarouselState();
}

class _FeaturedGamesCarouselState extends State<FeaturedGamesCarousel> {
  late PageController _pageController;
  late Timer _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && widget.games.isNotEmpty) {
        _currentPage = (_currentPage + 1) % widget.games.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.games.isEmpty) {
      // Show shimmer placeholders when no games are available (loading)
      return SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemBuilder: (context, index) {
            return Shimmer(width: 280, height: 200, borderRadius: BorderRadius.circular(20));
          },
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemCount: 3,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.star, color: Color(0xFFFFD700), size: 24),
              SizedBox(width: 8),
              Text(
                'Featured Games',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: widget.games.length,
            itemBuilder: (context, index) {
              final game = widget.games[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeInOut.transform(value) * 220,
                      child: child,
                    ),
                  );
                },
                child: PremiumGameCard(
                  game: game,
                  onTap: () => widget.onGameTap(game),
                  isLarge: true,
                  isFavorite: widget.isFavorite,
                  onFavoriteToggle: widget.onFavoriteToggle != null
                      ? () => widget.onFavoriteToggle!(game)
                      : null,
                ),
              );
            },
          ),
        ),
        // Page indicators
        const SizedBox(height: 12),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.games.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? const Color(0xFF00E5FF)
                      : Colors.white.withOpacitySafe(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
