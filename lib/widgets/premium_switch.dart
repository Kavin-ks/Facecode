import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/services/sound_manager.dart';

/// A premium toggle switch with "distinct click" sound
class PremiumSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const PremiumSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        SoundManager().playUiSound(SoundManager.sfxUiSwitch);
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: 200.ms,
        width: 50,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? AppConstants.primaryColor : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (value ? AppConstants.primaryColor : Colors.black).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: 200.ms,
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
