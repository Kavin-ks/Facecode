import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:facecode/services/settings_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _enabled = true;
  bool _sound = true;
  bool _vibrate = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await SettingsService.loadAll();
    setState(() {
      _enabled = all['notif_enabled'] ?? true;
      _sound = all['notif_sound'] ?? true;
      _vibrate = all['notif_vibrate'] ?? true;
      _loading = false;
    });
  }

  Future<void> _toggleEnabled(bool v) async {
    setState(() => _enabled = v);
    await SettingsService.setNotificationsEnabled(v);
  }

  Future<void> _toggleSound(bool v) async {
    setState(() => _sound = v);
    await SettingsService.setNotificationSound(v);
  }

  Future<void> _toggleVibrate(bool v) async {
    setState(() => _vibrate = v);
    await SettingsService.setNotificationVibrate(v);
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
        title: const Text('Notifications'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _SwitchTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Enable Notifications',
                    subtitle: 'Receive updates, rewards and reminders',
                    value: _enabled,
                    onChanged: _toggleEnabled,
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: _enabled ? 1 : 0.5,
                    child: Column(
                      children: [
                        _SwitchTile(
                          icon: Icons.volume_up_outlined,
                          title: 'Sound',
                          subtitle: 'Play a sound for alerts',
                          value: _sound,
                          onChanged: _enabled ? _toggleSound : null,
                        ),
                        const SizedBox(height: 10),
                        _SwitchTile(
                          icon: Icons.vibration_outlined,
                          title: 'Vibration',
                          subtitle: 'Vibrate on important events',
                          value: _vibrate,
                          onChanged: _enabled ? _toggleVibrate : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Icon(icon, color: AppConstants.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: AppConstants.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }
}
