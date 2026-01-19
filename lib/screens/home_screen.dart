import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:facecode/screens/mode_selection_screen.dart';
import 'package:facecode/screens/profile_screen.dart';
import 'package:facecode/routing/app_route.dart';

/// Premium home screen with game mode selection
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0D12),
              Color(0xFF1A1A2E),
              Color(0xFF0D0D12),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Profile button in top right
                Align(
                  alignment: Alignment.topRight,
                  child: _buildProfileButton(),
                ),
                
                const SizedBox(height: 20),
                
                // Logo with glow
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withAlpha(60),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Text(
                      '😎',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 90),
                    ),
                  ),
                )
                    .animate()
                    .scale(curve: Curves.elasticOut, duration: 800.ms)
                    .then()
                    .shimmer(duration: 2000.ms, color: Colors.white24),
                
                const SizedBox(height: AppConstants.largePadding),
                
                // Title with gradient
                Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: AppConstants.neonGradient,
                    ).createShader(bounds),
                    child: const Text(
                      'FaceCode',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: AppConstants.smallPadding),
                
                Text(
                  '✨ Express yourself with emojis! ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppConstants.textMuted,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                
                const SizedBox(height: AppConstants.xlPadding),

                // Main action buttons
                _buildPremiumButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      AppRoute.fadeSlide(const ModeSelectionScreen(isCreating: true)),
                    );
                  },
                  icon: Icons.add_circle_outline,
                  label: 'CREATE ROOM',
                  gradient: AppConstants.premiumGradient,
                  isPrimary: true,
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: AppConstants.defaultPadding),

                _buildPremiumButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      AppRoute.fadeSlide(const ModeSelectionScreen(isCreating: false)),
                    );
                  },
                  icon: Icons.login_rounded,
                  label: 'JOIN ROOM',
                  gradient: AppConstants.neonGradient,
                  isPrimary: false,
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: AppConstants.xlPadding),
                
                // How to Play section
                _buildHowToPlaySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(AppRoute.fadeSlide(const ProfileScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor.withAlpha(150),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppConstants.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: AppConstants.premiumGradient),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withAlpha(60),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildPremiumButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required bool isPrimary,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isPrimary ? LinearGradient(colors: gradient) : null,
        color: isPrimary ? null : AppConstants.surfaceColor,
        border: isPrimary ? null : Border.all(
          color: gradient.first.withAlpha(100),
          width: 1.5,
        ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: gradient.first.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : gradient.first,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHowToPlaySection() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppConstants.goldAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'HOW TO PLAY',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.goldAccent,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.largePadding),
          
          _buildHowToPlayItem('1️⃣', 'One player gets a secret word', 0),
          _buildHowToPlayItem('😎', 'They can ONLY use emojis to describe it', 1),
          _buildHowToPlayItem('🤔', 'Other players try to guess the word', 2),
          _buildHowToPlayItem('⏱️', 'Race against the clock - 60 seconds!', 3),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHowToPlayItem(String emoji, String text, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor.withAlpha(150),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 800 + (index * 100))).slideX(begin: -0.1, end: 0);
  }
}
