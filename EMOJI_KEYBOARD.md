# 😎 FaceCode Emoji Keyboard

A comprehensive WhatsApp-style emoji picker for FaceCode with all standard Unicode emojis.

## ✨ Features

### 🎯 Complete Emoji Coverage
- **1000+ emojis** organized into 10 categories
- All standard Unicode emojis included
- No text keyboard - emoji-only input

### 📂 Categories
- 🕐 **Recent** - Recently used emojis (auto-tracked)
- 😀 **Smileys** - 110+ facial expressions
- 🐶 **Animals** - 90+ animals and nature
- 🍔 **Food** - 120+ food and drinks
- ⚽ **Sports** - 90+ sports and activities
- 🚗 **Travel** - 110+ places and transportation
- 🎉 **Activities** - 70+ activities and events
- 💡 **Objects** - 200+ objects and tools
- ❤️ **Symbols** - 250+ symbols and signs
- 🏳️ **Flags** - 250+ country flags

### 🎨 User Experience
- **Category tabs** - Easy navigation with emoji icons
- **Search bar** - Quick emoji search (placeholder for future keyword search)
- **Recently used** - Auto-tracks last 30 emojis used
- **Emoji preview** - Long press to preview large emoji
- **Haptic feedback** - Satisfying tactile response
- **Smooth scrolling** - Optimized grid performance

## 📦 Usage

### Basic Implementation

```dart
import 'package:facecode/widgets/emoji_picker.dart';

EmojiPicker(
  onEmojiSelected: (emoji) {
    print('Selected: $emoji');
  },
  height: 350, // Optional: default is 350
)
```

### Full Example with TextField

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final TextEditingController _controller = TextEditingController();

  void _onEmojiSelected(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;
    
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          readOnly: true, // Disable text keyboard
        ),
        EmojiPicker(
          onEmojiSelected: _onEmojiSelected,
        ),
      ],
    );
  }
}
```

### Demo Screen

Navigate to the demo screen to see it in action:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const EmojiKeyboardDemo(),
  ),
);
```

## 🏗️ Architecture

### Files Structure
```
lib/
├── widgets/
│   └── emoji_picker.dart      # Main emoji picker widget
├── utils/
│   └── emoji_catalog.dart     # Emoji data and categories
├── screens/
│   └── emoji_keyboard_demo.dart  # Demo screen
└── models/
    └── emoji_data.dart        # Legacy (can be removed)
```

### Key Components

#### EmojiPicker Widget
- **State management**: Recently used emojis via SharedPreferences
- **Search**: Real-time filtering (expandable for keyword search)
- **Preview**: Long-press gesture for emoji preview
- **Haptics**: Light impact on tap, medium on long-press

#### EmojiCatalog
- **10 categories** with icons and emojis
- **categoryIcons**: Map of category names to emoji icons
- **emojisByCategory**: Map of categories to emoji lists
- **Helper methods**: `getEmojis()`, `getCategoryIcon()`, `allEmojis`

## 🎯 Design Decisions

### Why Emoji-Only?
- **Faster gameplay** in FaceCode
- **Universal communication** across languages
- **Visual clarity** - no typing confusion
- **Fun factor** - emojis are more engaging

### Why WhatsApp-Style?
- **Familiar UX** - users know the pattern
- **Proven design** - battle-tested interface
- **Efficient** - category tabs + grid layout
- **Accessible** - easy to find what you need

### Performance Optimizations
- **Lazy loading** via GridView.builder
- **Const constructors** where possible
- **Efficient state updates** with mounted checks
- **Limited recent emojis** to 30 items

## ⚡ Advanced Features

### Recently Used Tracking
Automatically saves last 30 used emojis to SharedPreferences:

```dart
// Saved per-device across app sessions
await prefs.setStringList('recent_emojis', recentList);
```

### Search (Future Enhancement)
Currently shows subset when searching. To add keyword search:

1. Create emoji keyword map:
```dart
static const Map<String, List<String>> keywords = {
  '😀': ['smile', 'happy', 'grin'],
  '❤️': ['heart', 'love', 'red'],
  // ... more mappings
};
```

2. Update search logic:
```dart
_filteredEmojis = EmojiCatalog.allEmojis.where((emoji) {
  final words = EmojiCatalog.keywords[emoji] ?? [];
  return words.any((word) => word.contains(query));
}).toList();
```

### Emoji Preview Positioning
Preview automatically centers above grid with glow effect:

```dart
BoxShadow(
  color: AppConstants.primaryColor.withAlpha(100),
  blurRadius: 20,
  spreadRadius: 2,
)
```

## 🚀 Integration with FaceCode

### Game Screen Integration
```dart
// In game_screen.dart or similar
EmojiPicker(
  onEmojiSelected: (emoji) {
    // Submit emoji as answer
    gameProvider.submitAnswer(emoji);
  },
)
```

### Chat/Messaging Integration
```dart
// In chat screen
EmojiPicker(
  onEmojiSelected: (emoji) {
    // Add to chat message
    messageController.text += emoji;
  },
)
```

## 🎨 Customization

### Adjust Grid Size
Change `crossAxisCount` in `_buildEmojiGrid()`:

```dart
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 10, // More emojis per row
  // ...
),
```

### Change Colors
Uses AppConstants from `lib/utils/constants.dart`:
- `primaryColor` - Category indicator, borders
- `surfaceColor` - Background
- `textMuted` - Hints and disabled states

### Adjust Height
```dart
EmojiPicker(
  height: 450, // Taller picker
  // ...
)
```

## ✅ Testing

Run analysis:
```bash
flutter analyze lib/widgets/emoji_picker.dart
```

No errors expected! ✨

## 📱 Platform Support
- ✅ iOS
- ✅ Android
- ✅ Web
- ✅ Desktop (macOS, Windows, Linux)

## 🔧 Dependencies
- `shared_preferences: ^2.2.0` - Recent emojis persistence
- `flutter/services.dart` - Haptic feedback

## 💡 Tips

1. **Performance**: Grid renders efficiently with 1000+ emojis
2. **Persistence**: Recent emojis auto-save across sessions
3. **Accessibility**: Large touch targets (48dp emoji cells)
4. **Smooth scrolling**: BouncingScrollPhysics for native feel
5. **Haptics**: Different feedback for tap vs long-press

## 🎉 Try It Out!

1. Navigate to demo:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => EmojiKeyboardDemo()),
);
```

2. Tap emojis to add them
3. Long-press to preview
4. Use search bar to filter
5. Switch categories with tabs
6. Check "Recent" tab for history

---

**Built with ❤️ for FaceCode** 🎮😎🎉
