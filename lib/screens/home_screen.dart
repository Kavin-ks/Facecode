import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:facecode/screens/mode_selection_screen.dart';
import 'package:facecode/screens/profile_screen.dart';
import 'package:facecode/routing/app_route.dart';

/// Home screen with create/join room options
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo and Title
              const Text(
                '😎',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 80),
              ).animate().scale(curve: Curves.easeOutBack),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              Text(
                'FaceCode',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppConstants.primaryColor,
                    ),
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: AppConstants.smallPadding),
              
              Text(
                'Express yourself with emojis!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppConstants.textSecondary,
                    ),
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: AppConstants.largePadding * 2),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    AppRoute.fadeSlide(const ModeSelectionScreen(isCreating: true)),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Room'),
              ).animate().fadeIn(delay: 400.ms).scale(),

              const SizedBox(height: AppConstants.defaultPadding),

              // Profile / Auth
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(AppRoute.fadeSlide(const ProfileScreen()));
                },
                icon: const Icon(Icons.person),
                label: const Text('Profile'),
              ).animate().fadeIn(delay: 520.ms).scale(),

              const SizedBox(height: AppConstants.defaultPadding),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    AppRoute.fadeSlide(const ModeSelectionScreen(isCreating: false)),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Join Room'),
              ).animate().fadeIn(delay: 550.ms).scale(),
              
              const SizedBox(height: AppConstants.largePadding * 2),
              
              // How to Play
              Text(
                'How to Play',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppConstants.primaryColor,
                    ),
              ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              _buildHowToPlayItem('1️⃣', 'One player gets a secret word'),
              _buildHowToPlayItem('😎', 'They can ONLY use emojis to describe it'),
              _buildHowToPlayItem('🤔', 'Other players try to guess'),
              _buildHowToPlayItem('⏱️', 'You have 60 seconds per round!'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowToPlayItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.smallPadding),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.1, end: 0);
  }
}
