import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:facecode/services/settings_service.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
        title: const Text('Privacy'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            _PrivacyTile(
              icon: Icons.public_outlined,
              title: 'Public Profile',
              subtitle: 'Allow others to view your profile and badges',
              settingKey: 'privacy_public_profile',
            ),
            SizedBox(height: 10),
            _PrivacyTile(
              icon: Icons.circle_outlined,
              title: 'Show Online Status',
              subtitle: 'Let friends know when you are online',
              settingKey: 'privacy_show_online',
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String settingKey;

  const _PrivacyTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.settingKey,
  });

  @override
  State<_PrivacyTile> createState() => _PrivacyTileState();
}

class _PrivacyTileState extends State<_PrivacyTile> {
  bool _value = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final map = await SettingsService.loadAll();
    setState(() {
      _value = map[widget.settingKey] ?? true;
    });
  }

  Future<void> _toggle(bool v) async {
    setState(() => _value = v);
    if (widget.settingKey == 'privacy_public_profile') {
      await SettingsService.setPublicProfile(v);
    } else if (widget.settingKey == 'privacy_show_online') {
      await SettingsService.setShowOnline(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Icon(widget.icon, color: AppConstants.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(widget.subtitle, style: TextStyle(color: AppConstants.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: _value, onChanged: _toggle, activeThumbColor: AppConstants.primaryColor),
        ],
      ),
    );
  }
}
