import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:facecode/providers/elite_provider.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/utils/app_dialogs.dart';

class EliteLandingScreen extends StatelessWidget {
  const EliteLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final elite = context.watch<EliteProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0221), // Midnight Obsidian
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD700).withValues(alpha: 0.1), // Gold Glow
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(duration: 5.seconds, begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildHeroSection(),
                        const SizedBox(height: 32),
                        _buildBenefitsList(),
                        const SizedBox(height: 48),
                        _buildCTA(context, elite),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white70),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: const Text(
        'FACECODE ELITE',
        style: TextStyle(
          color: Color(0xFFFFD700),
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: const Center(
            child: Icon(Icons.workspace_premium_rounded, size: 64, color: Colors.white),
          ),
        ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        const Text(
          'Elevate Your Game',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        const Text(
          'The ultimate experience for dedicated players.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      {'icon': Icons.block_rounded, 'title': 'Ad-Free Experience', 'desc': 'No interruptions, just gameplay.'},
      {'icon': Icons.palette_rounded, 'title': 'Exclusive Cosmetics', 'desc': 'Access to Neon Obsidian themes and skins.'},
      {'icon': Icons.flash_on_rounded, 'title': 'Priority Matchmaking', 'desc': 'Jump to the front of the queue.'},
      {'icon': Icons.rocket_launch_rounded, 'title': 'Early Feature Access', 'desc': 'Try new games before general release.'},
    ];

    return Column(
      children: benefits.asMap().entries.map((entry) {
        final b = entry.value;
        return _buildBenefitCard(b['icon'] as IconData, b['title'] as String, b['desc'] as String, entry.key);
      }).toList(),
    );
  }

  Widget _buildBenefitCard(IconData icon, String title, String desc, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFFFFD700), size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (600 + index * 100).ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildCTA(BuildContext context, EliteProvider elite) {
    if (elite.isElite) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
        ),
        child: const Center(
          child: Text(
            'YOU ARE AN ELITE MEMBER',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        AddictivePrimaryButton(
          label: 'JOIN FACECODE ELITE',
          onPressed: () async {
            await elite.joinElite();
            if (context.mounted) {
              AppDialogs.showSnack(context, 'Welcome to Facecode Elite!');
            }
          },
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        const Text(
          'Cancel anytime from your account settings.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }
}
