import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:facecode/utils/app_dialogs.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final List<String> _avatars = ['🙂', '😀', '😎', '🤖', '👾', '🐱', '🐶', '🦊', '🐻', '🐼', '🐨', '🦄', '🐲', '👻', '🤡', '👽'];
  String _selectedAvatar = '🙂';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?.name.isNotEmpty == true
        ? user!.name
        : user?.displayName ?? '';
    _selectedAvatar = user?.avatarEmoji ?? '🙂';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppDialogs.showSnack(context, 'Please enter a name');
      return;
    }

    final auth = context.read<AuthProvider>();
    await auth.updateDisplayName(name);
    await auth.updateAvatar(_selectedAvatar);

    if (!mounted) return;
    Navigator.of(context).pop();
    AppDialogs.showSnack(context, 'Profile updated');
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
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Choose Avatar', style: TextStyle(color: AppConstants.textSecondary)),
                     const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _avatars.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final avatar = _avatars[index];
                          final isSelected = avatar == _selectedAvatar;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedAvatar = avatar),
                            child: Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppConstants.primaryColor : Colors.white10,
                                shape: BoxShape.circle,
                                border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                              ),
                              child: Text(avatar, style: const TextStyle(fontSize: 24)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Display Name', style: TextStyle(color: AppConstants.textSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.borderColor),
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GradientButton(text: 'Save Changes', onPressed: _save, icon: Icons.check_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
