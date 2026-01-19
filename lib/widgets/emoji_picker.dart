import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/utils/emoji_catalog.dart';

/// WhatsApp-style emoji picker with categories, search, and recently used emojis
class EmojiPicker extends StatefulWidget {
  final Function(String) onEmojiSelected;
  final double height;

  const EmojiPicker({
    super.key,
    required this.onEmojiSelected,
    this.height = 350,
  });

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<String> _recentEmojis = [];
  List<String> _filteredEmojis = [];
  bool _isSearching = false;
  String? _previewEmoji;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: EmojiCatalog.categories.length, vsync: this);
    _loadRecentEmojis();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentEmojis() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList('recent_emojis') ?? [];
    if (mounted) {
      setState(() {
        _recentEmojis = recent;
      });
    }
  }

  Future<void> _saveRecentEmoji(String emoji) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove if already exists
    _recentEmojis.remove(emoji);
    
    // Add to front
    _recentEmojis.insert(0, emoji);
    
    // Keep only last 30
    if (_recentEmojis.length > 30) {
      _recentEmojis = _recentEmojis.sublist(0, 30);
    }
    
    await prefs.setStringList('recent_emojis', _recentEmojis);
    if (mounted) {
      setState(() {});
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredEmojis = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      // Show all emojis when searching (in a real app, you'd filter by keywords)
      _filteredEmojis = EmojiCatalog.allEmojis.take(100).toList();
    });
  }

  void _onEmojiTap(String emoji) {
    HapticFeedback.lightImpact();
    _saveRecentEmoji(emoji);
    widget.onEmojiSelected(emoji);
    
    if (mounted) {
      setState(() {
        _previewEmoji = null;
      });
    }
  }

  void _onEmojiLongPress(String emoji) {
    HapticFeedback.mediumImpact();
    setState(() {
      _previewEmoji = emoji;
    });
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.smallPadding),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: AppConstants.borderColor.withAlpha(50),
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppConstants.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search emojis...',
          hintStyle: const TextStyle(color: AppConstants.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppConstants.secondaryColor, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppConstants.textMuted, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    HapticFeedback.lightImpact();
                  },
                )
              : null,
          filled: true,
          fillColor: AppConstants.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: AppConstants.borderColor.withAlpha(50),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppConstants.primaryColor,
        indicatorWeight: 3,
        labelColor: AppConstants.primaryColor,
        unselectedLabelColor: AppConstants.textMuted,
        tabAlignment: TabAlignment.start,
        tabs: EmojiCatalog.categories.map((category) {
          final icon = EmojiCatalog.getCategoryIcon(category);
          return Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmojiGrid(List<String> emojis) {
    if (emojis.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_emotions_outlined,
              size: 64,
              color: AppConstants.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'No emojis found' : 'No recent emojis',
              style: const TextStyle(
                color: AppConstants.textMuted,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        return GestureDetector(
          onTap: () => _onEmojiTap(emoji),
          onLongPress: () => _onEmojiLongPress(emoji),
          onLongPressEnd: (_) {
            if (mounted) {
              setState(() => _previewEmoji = null);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: _previewEmoji == emoji
                  ? AppConstants.primaryColor.withAlpha(40)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmojiPreview() {
    if (_previewEmoji == null) return const SizedBox.shrink();

    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(
              color: AppConstants.primaryColor.withAlpha(80),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withAlpha(100),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            _previewEmoji!,
            style: const TextStyle(fontSize: 64),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLarge),
        ),
        border: Border.all(
          color: AppConstants.primaryColor.withAlpha(30),
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildSearchBar(),
              if (!_isSearching) _buildCategoryTabs(),
              Expanded(
                child: _isSearching
                    ? _buildEmojiGrid(_filteredEmojis)
                    : TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(),
                        children: EmojiCatalog.categories.map((category) {
                          final emojis = category == EmojiCatalog.recent
                              ? _recentEmojis
                              : EmojiCatalog.getEmojis(category);
                          return _buildEmojiGrid(emojis);
                        }).toList(),
                      ),
              ),
            ],
          ),
          _buildEmojiPreview(),
        ],
      ),
    );
  }
}
