import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/models/cosmetic_item.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/providers/shop_provider.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/utils/app_dialogs.dart';

class CosmeticShopScreen extends StatefulWidget {
  const CosmeticShopScreen({super.key});

  @override
  State<CosmeticShopScreen> createState() => _CosmeticShopScreenState();
}

class _CosmeticShopScreenState extends State<CosmeticShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: CosmeticType.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>().progress;
    
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
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
                color: AppConstants.primaryColor.withValues(alpha: 0.15),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(duration: 5.seconds, begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, progress.coins),
                _buildCategoryTabs(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: CosmeticType.values.map((type) {
                      return _buildItemGrid(type);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int coins) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text(
            'COSMETIC SHOP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppConstants.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  coins.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppConstants.primaryColor,
        unselectedLabelColor: AppConstants.textMuted,
        indicatorColor: AppConstants.primaryColor,
        dividerColor: Colors.transparent,
        tabs: CosmeticType.values.map((type) {
          return Tab(
            text: type.name.toUpperCase(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemGrid(CosmeticType type) {
    final items = CosmeticItem.allItems.where((i) => i.type == type).toList();
    
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Coming Soon...',
          style: TextStyle(color: AppConstants.textMuted),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildCosmeticCard(context, items[index], index);
      },
    );
  }

  Widget _buildCosmeticCard(BuildContext context, CosmeticItem item, int index) {
    final shop = context.watch<ShopProvider>();
    final progress = context.watch<ProgressProvider>().progress;
    final isOwned = shop.ownsItem(item.id);
    final isEquipped = shop.isEquipped(item.id);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEquipped 
                  ? AppConstants.primaryColor 
                  : Colors.white.withValues(alpha: 0.1),
              width: isEquipped ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: _buildItemPreview(item),
                      ),
                      if (item.isEliteOnly)
                         Positioned(
                           top: 8,
                           right: 8,
                           child: Container(
                             padding: const EdgeInsets.all(4),
                             decoration: const BoxDecoration(
                               color: Color(0xFFFFD700),
                               shape: BoxShape.circle,
                             ),
                             child: const Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.black),
                           ).animate(onPlay: (c) => c.repeat())
                            .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.5)),
                         ),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: AppConstants.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(context, shop, item, isOwned, isEquipped, progress.isElite),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildItemPreview(CosmeticItem item) {
    IconData icon;
    switch (item.type) {
      case CosmeticType.theme:
        icon = Icons.palette_outlined;
        break;
      case CosmeticType.wheelSkin:
        icon = Icons.refresh_outlined;
        break;
      case CosmeticType.soundPack:
        icon = Icons.audiotrack_outlined;
        break;
      case CosmeticType.badgeFrame:
        icon = Icons.verified_user_outlined;
        break;
    }

    return Hero(
      tag: 'cosmetic_${item.id}',
      child: Icon(
        icon,
        size: 48,
        color: item.rarity == CosmeticRarity.legendary 
            ? AppConstants.accentGold 
            : AppConstants.primaryColor.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, ShopProvider shop, CosmeticItem item, bool isOwned, bool isEquipped, bool isUserElite) {
    if (isEquipped) {
      return Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppConstants.primaryColor),
        ),
        child: const Center(
          child: Text(
            'EQUIPPED',
            style: TextStyle(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    if (isOwned) {
      return AddictivePrimaryButton(
        label: 'EQUIP',
        height: 36,
        fontSize: 12,
        onPressed: () => shop.equipItem(item),
      );
    }

    final showsEliteLocked = item.isEliteOnly && !isUserElite;

    return PremiumTap(
      onTap: () async {
        if (showsEliteLocked) {
          Navigator.of(context).pushNamed('/elite');
          return;
        }
        final success = await shop.purchaseItem(item);
        if (!success && context.mounted) {
           AppDialogs.showSnack(context, 'Not enough coins!', isError: true);
        }
      },
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: showsEliteLocked 
              ? const Color(0xFFFFD700).withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: showsEliteLocked 
                ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: showsEliteLocked 
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 14),
                SizedBox(width: 4),
                Text(
                  'ELITE ONLY',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded, color: AppConstants.primaryColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  item.price.toString(),
                  style: const TextStyle(
                    color: Colors.white,
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
