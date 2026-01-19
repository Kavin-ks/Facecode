import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:facecode/models/game_difficulty.dart';
import 'package:facecode/utils/color_ext.dart';

/// Premium search bar with glassmorphism
class PremiumSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;

  const PremiumSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacitySafe(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacitySafe(0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search games...',
                hintStyle: TextStyle(color: Colors.white.withOpacitySafe(0.5)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00E5FF)),
                suffixIcon: onFilterTap != null
                    ? IconButton(
                        icon: const Icon(Icons.tune, color: Color(0xFF00E5FF)),
                        onPressed: onFilterTap,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter bottom sheet
class FilterBottomSheet extends StatefulWidget {
  final GameDifficulty? selectedDifficulty;
  final Function(GameDifficulty?) onDifficultyChanged;

  const FilterBottomSheet({
    super.key,
    this.selectedDifficulty,
    required this.onDifficultyChanged,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  GameDifficulty? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.selectedDifficulty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Games',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Difficulty',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              _buildDifficultyChip('All', null),
              ...GameDifficulty.values.map((difficulty) {
                return _buildDifficultyChip(
                  difficulty.name,
                  difficulty,
                );
              }),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onDifficultyChanged(_selectedDifficulty);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String label, GameDifficulty? difficulty) {
    final isSelected = _selectedDifficulty == difficulty;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDifficulty = selected ? difficulty : null;
        });
      },
      selectedColor: const Color(0xFF00E5FF),
      backgroundColor: Colors.white.withOpacitySafe(0.1),
      checkmarkColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF00E5FF)
              : Colors.white.withOpacitySafe(0.2),
        ),
      ),
    );
  }
}
