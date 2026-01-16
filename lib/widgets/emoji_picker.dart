import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/utils/emoji_catalog.dart';

/// Emoji picker widget for the emoji player
class EmojiPicker extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const EmojiPicker({
    super.key,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: EmojiCatalog.categories.length,
      child: Container(
        height: 320,
        decoration: const BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.borderRadius),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_emotions,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Text(
                      'Emoji Keyboard',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: EmojiCatalog.faces),
                Tab(text: EmojiCatalog.objects),
                Tab(text: EmojiCatalog.places),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: EmojiCatalog.categories.map((category) {
                  final emojis = EmojiCatalog.getEmojis(category);
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount =
                          (constraints.maxWidth / 56).floor().clamp(4, 10);

                      return GridView.builder(
                        padding: const EdgeInsets.all(AppConstants.defaultPadding),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 1,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: emojis.length,
                        itemBuilder: (context, index) {
                          final emoji = emojis[index];
                          return InkWell(
                            onTap: () => onEmojiSelected(emoji),
                            borderRadius: BorderRadius.circular(14),
                            child: Ink(
                              decoration: BoxDecoration(
                                color: AppConstants.backgroundColor,
                                borderRadius: BorderRadius.circular(14),
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
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
