import 'package:flutter/material.dart';
import 'package:facecode/models/cosmetic_item.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/services/sound_manager.dart';

class ShopProvider extends ChangeNotifier {
  final ProgressProvider _progressProvider;

  ShopProvider(this._progressProvider);

  /// Check if user owns an item
  bool ownsItem(String id) {
    return _progressProvider.progress.inventory.contains(id);
  }

  /// Check if an item is currently equipped
  bool isEquipped(String id) {
    final item = CosmeticItem.allItems.firstWhere((i) => i.id == id, orElse: () => throw Exception('Item not found'));
    final equippedId = _progressProvider.progress.equippedItems[item.type.name];
    return equippedId == id;
  }

  /// Purchase an item
  Future<bool> purchaseItem(CosmeticItem item) async {
    if (ownsItem(item.id)) return true;
    
    // Check Elite requirement
    if (item.isEliteOnly && !_progressProvider.progress.isElite) {
      return false;
    }

    if (_progressProvider.progress.coins < item.price) return false;

    // Deduct coins and add to inventory
    final newInventory = [..._progressProvider.progress.inventory, item.id];
    final newProgress = _progressProvider.progress.copyWith(
      coins: _progressProvider.progress.coins - item.price,
      inventory: newInventory,
    );

    // Note: ProgressProvider doesn't have an external setter for progress 
    // unless we add one or implement the logic there.
    // For now, I'll rely on a new method in ProgressProvider I'm about to add.
    await _progressProvider.updateShopProgress(newProgress);
    
    SoundManager().playUiSound(SoundManager.sfxUiTap); // Success sound
    notifyListeners();
    return true;
  }

  /// Equip an item
  Future<void> equipItem(CosmeticItem item) async {
    if (!ownsItem(item.id)) return;

    final newEquipped = Map<String, String>.from(_progressProvider.progress.equippedItems);
    newEquipped[item.type.name] = item.id;

    final newProgress = _progressProvider.progress.copyWith(
      equippedItems: newEquipped,
    );

    await _progressProvider.updateShopProgress(newProgress);
    notifyListeners();
  }

  /// Get currently equipped item of a certain type
  CosmeticItem? getEquippedItem(CosmeticType type) {
    final id = _progressProvider.progress.equippedItems[type.name];
    if (id == null) return null;
    return CosmeticItem.allItems.firstWhere((i) => i.id == id);
  }
}
