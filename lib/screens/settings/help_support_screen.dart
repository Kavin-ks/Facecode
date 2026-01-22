import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:facecode/utils/app_dialogs.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _supportEmail = 'support@facecode.app';

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!context.mounted) return;
    AppDialogs.showSnack(context, 'Support email copied');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Help & Support'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, color: Colors.white70),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(_supportEmail, style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () => _copyEmail(context),
                        child: const Text('Copy', style: TextStyle(color: AppConstants.secondaryColor)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FAQ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _faq('How do I play?', 'Join a room or start one, then guess emojis and complete challenges to earn XP.'),
                  const SizedBox(height: 8),
                  _faq('Lost progress?', 'Make sure you are signed in. Guest progress is local to the device.'),
                  const SizedBox(height: 8),
                  _faq('Report a bug', 'Send us details and screenshots to the support email.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faq(String q, String a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(q, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(a, style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
      ],
    );
  }
}
