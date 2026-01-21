import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:facecode/models/game_metadata.dart';
import 'package:facecode/models/game_difficulty.dart';
import 'package:facecode/utils/color_ext.dart';
import 'package:facecode/widgets/shimmer.dart';

/// Premium glassmorphism game card with hover effects
class PremiumGameCard extends StatefulWidget {
  final GameMetadata game;
  final VoidCallback onTap;
  final bool isLarge;
  final bool isFavorite;
  final bool isLoading;
  final VoidCallback? onFavoriteToggle;

  const PremiumGameCard({
    super.key,
    required this.game,
    required this.onTap,
    this.isLarge = false,
    this.isFavorite = false,
    this.isLoading = false,
    this.onFavoriteToggle,
  });

  @override
  State<PremiumGameCard> createState() => _PremiumGameCardState();
}

class _PremiumGameCardState extends State<PremiumGameCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _handleTapDown(TapDownDetails details) {
    if (!mounted) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!mounted) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (!mounted) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.isLarge ? 280.0 : 160.0;
    final height = widget.isLarge ? 200.0 : 200.0;

    // Loading placeholder
    if (widget.isLoading) {
      return Container(
        width: width,
        height: height,
        margin: const EdgeInsets.all(8),
        child: Shimmer(width: width, height: height, borderRadius: BorderRadius.circular(20)),
      );
    }

    return MouseRegion(
      onEnter: (_) { if (!mounted) return; setState(() => _isHovered = true); },
      onExit: (_) { if (!mounted) return; setState(() => _isHovered = false); },
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : (_isHovered ? 1.03 : 1.0),
        duration: const Duration(milliseconds: 180),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: widget.game.gradientColors.first.withOpacitySafe(0.2),
            highlightColor: Colors.white.withOpacitySafe(0.04),
            onTap: widget.onTap,
            onTapDown: _handleTapDown,
            onTapCancel: _handleTapCancel,
            onTapUp: _handleTapUp,
            child: Container(
              width: width,
              height: height,
              margin: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  // Glassmorphism background
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: widget.game.gradientColors
                                .map((c) => c.withOpacitySafe(0.3))
                                .toList(),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.game.gradientColors.first.withOpacitySafe(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.game.gradientColors.first.withOpacitySafe(_isHovered ? 0.55 : 0.25),
                              blurRadius: _isHovered ? 30 : (_isPressed ? 12 : 20),
                              spreadRadius: _isHovered ? 2 : 0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Banner section
                            Container(
                              height: widget.isLarge ? 100 : 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: widget.game.gradientColors,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Banner emoji/image
                                  Center(
                                    child: Text(
                                      widget.game.bannerImage,
                                      style: TextStyle(
                                        fontSize: widget.isLarge ? 48 : 40,
                                      ),
                                    ),
                                  ),
                                  // Favorite button
                                  if (widget.onFavoriteToggle != null)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: widget.onFavoriteToggle,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacitySafe(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                                            color: widget.isFavorite ? Colors.red : Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Difficulty badge
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.game.difficulty.color,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            widget.game.difficulty.icon,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.game.difficulty.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
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
                            // Content section
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Game name
                                    Text(
                                      widget.game.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    // Description
                                    Text(
                                      widget.game.description,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacitySafe(0.7),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    // Player count
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people,
                                          size: 14,
                                          color: Colors.white.withOpacitySafe(0.7),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.game.minPlayers == widget.game.maxPlayers
                                              ? '${widget.game.minPlayers} player${widget.game.minPlayers > 1 ? 's' : ''}'
                                              : '${widget.game.minPlayers}-${widget.game.maxPlayers} players',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white.withOpacitySafe(0.7),
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
                    ),
                  ),

                  // Play button overlay
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.game.gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: widget.game.gradientColors.first.withOpacitySafe(0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onTap,
                          borderRadius: BorderRadius.circular(12),
                          splashColor: Colors.white.withOpacitySafe(0.12),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow, color: Colors.black),
                                SizedBox(width: 6),
                                Text(
                                  'Play',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
