import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:facecode/widgets/emoji_picker.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:facecode/utils/constants.dart';

/// Demo screen showing the emoji picker in action
class EmojiKeyboardDemo extends StatefulWidget {
  const EmojiKeyboardDemo({super.key});

  @override
  State<EmojiKeyboardDemo> createState() => _EmojiKeyboardDemoState();
}

class _EmojiKeyboardDemoState extends State<EmojiKeyboardDemo> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Emoji Keyboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(title: 'Your Emoji Message'),
                      const SizedBox(height: 16),
                      
                      // Emoji display area
                      NeonCard(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 150),
                          child: _controller.text.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Tap emojis below to start',
                                    style: TextStyle(
                                      color: AppConstants.textMuted,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : Text(
                                  _controller.text,
                                  style: const TextStyle(
                                    fontSize: 48,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: GradientButton(
                              text: 'Clear',
                              icon: Icons.clear,
                              onPressed: _controller.text.isNotEmpty
                                  ? () {
                                      setState(() {
                                        _controller.clear();
                                      });
                                    }
                                  : null,
                              gradientColors: const [
                                AppConstants.errorColor,
                                Color(0xFFFF6B6B),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GradientButton(
                              text: 'Copy',
                              icon: Icons.copy,
                              onPressed: _controller.text.isNotEmpty
                                  ? () {
                                      Clipboard.setData(
                                        ClipboardData(text: _controller.text),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Copied to clipboard!'),
                                          duration: Duration(seconds: 2),
                                          backgroundColor: AppConstants.successColor,
                                        ),
                                      );
                                    }
                                  : null,
                              gradientColors: const [
                                AppConstants.successColor,
                                Color(0xFF00C853),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Info cards
                      NeonCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppConstants.secondaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Long press any emoji to preview it',
                                style: TextStyle(
                                  color: AppConstants.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Emoji Picker
              EmojiPicker(
                onEmojiSelected: (emoji) {
                  setState(() {
                    _onEmojiSelected(emoji);
                  });
                },
                height: MediaQuery.of(context).size.height * 0.4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
