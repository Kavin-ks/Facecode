import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facecode/providers/settings_provider.dart';
import 'package:facecode/utils/theme.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          _buildSectionHeader(context, "THEME"),
          _buildThemeSelector(context),
          const SizedBox(height: 16),
          _buildSwitch(
            context,
            "Reduce Motion",
            "Disable animations for faster UI",
            context.select((SettingsProvider s) => s.reduceMotion),
            (val) => context.read<SettingsProvider>().toggleReduceMotion(val),
          ),
          
          const SizedBox(height: 32),
          _buildSectionHeader(context, "SOUND & AUDIO"),
          _buildSoundControls(context),

          const SizedBox(height: 32),
          _buildSectionHeader(context, "HAPTICS"),
           _buildSwitch(
            context,
            "Vibration Feedback",
            "Feel buttons and interactions",
            context.select((SettingsProvider s) => s.hapticsEnabled),
            (val) => context.read<SettingsProvider>().toggleHaptics(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final current = context.watch<SettingsProvider>().themeMode;
    return Row(
      children: [
        Expanded(
          child: _ThemeCard(
            label: "Dark",
            icon: Icons.dark_mode,
            isSelected: current == AppThemeMode.dark,
            onTap: () => context.read<SettingsProvider>().setThemeMode(AppThemeMode.dark),
            color: const Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ThemeCard(
            label: "Light",
            icon: Icons.light_mode,
            isSelected: current == AppThemeMode.light,
            onTap: () => context.read<SettingsProvider>().setThemeMode(AppThemeMode.light),
            color: const Color(0xFFF5F7FA),
            textColor: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ThemeCard(
            label: "Party",
            icon: Icons.celebration,
            isSelected: current == AppThemeMode.party,
            onTap: () => context.read<SettingsProvider>().setThemeMode(AppThemeMode.party),
            color: const Color(0xFF2A0E45),
          ),
        ),
      ],
    );
  }

  Widget _buildSoundControls(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Column(
      children: [
        _buildSwitch(
          context,
          "UI Sounds",
          "Clicks and ticks",
          settings.uiSounds,
          (val) => settings.setUiSounds(val),
        ),
        const SizedBox(height: 8),
        _buildSwitch(
          context,
          "Game Sounds",
          "Effects during gameplay",
          settings.gameSounds,
          (val) => settings.setGameSounds(val),
        ),
        const SizedBox(height: 8),
        _buildSwitch(
          context,
          "Celebration Sounds",
          "Level up & badge unlocks",
          settings.celebrationSounds,
          (val) => settings.setCelebrationSounds(val),
        ),
        const SizedBox(height: 8),
        _buildSwitch(
          context,
          "Background Music",
          "Ambient menu loop",
          settings.bgMusic,
          (val) => settings.setBgMusic(val),
        ),
        
        if (settings.uiSounds || settings.gameSounds || settings.bgMusic || settings.celebrationSounds) ...[
          const Divider(height: 32),
          _buildVolumeSlider(context, "Master Volume", settings.masterVolume, (val) => settings.setMasterVolume(val)),
          if (settings.uiSounds || settings.gameSounds || settings.celebrationSounds)
            _buildVolumeSlider(context, "SFX Volume", settings.sfxVolume, (val) => settings.setSfxVolume(val)),
          if (settings.bgMusic)
            _buildVolumeSlider(context, "Music Volume", settings.musicVolume, (val) => settings.setMusicVolume(val)),
        ],
      ],
    );
  }

  Widget _buildSwitch(BuildContext context, String title, String subtitle, bool value, Function(bool) onChanged) {
    return Card(
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeTrackColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildVolumeSlider(BuildContext context, String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text("${(value * 100).toInt()}%", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;

  const _ThemeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumTap(
      onTap: onTap,
      scaleMin: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: isSelected 
              ? Border.all(color: AppConstants.primaryColor, width: 3)
              : Border.all(color: Colors.white10),
          boxShadow: isSelected 
              ? [BoxShadow(color: AppConstants.primaryColor.withValues(alpha: 0.4), blurRadius: 8)] 
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(
                color: textColor, 
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
