import 'dart:io';

import 'package:flutter/material.dart';
import '../widgets/emoji_picker.dart';
import '../services/mock_service.dart';
import '../widgets/app_shell.dart';
import 'package:image_picker/image_picker.dart';
import '../app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final svc = MockService();

  String _profileEmoji = '';
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _profileEmoji = svc.currentUser.emoji;
    // if user has a persisted avatar path, load it into the preview
    final p = svc.currentUser.avatarPath;
    if (p != null && p.isNotEmpty) {
      final f = File(p);
      if (f.existsSync()) _profileImage = f;
    }
  }

  Future<void> _pickFromGallery() async {
    final p = ImagePicker();
    final res = await p.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (res == null) return;
    final f = File(res.path);
    // persist avatar path
    await svc.setAvatarPath(f.path);
    setState(() => _profileImage = f);
  }

  void _chooseEmoji() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => EmojiPicker(
        selected: _profileEmoji,
        onSelected: (e) => Navigator.of(context).pop(e),
      ),
    );
    if (picked != null) {
      await svc.setEmoji(picked);
      setState(() => _profileEmoji = picked);
    }
  }

  void _signOut() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 2,
      title: 'Settings',
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final choice = await showModalBottomSheet<String>(
                        context: context,
                        builder: (_) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('Choose emoji'),
                              leading: const Icon(Icons.emoji_emotions),
                              onTap: () => Navigator.of(context).pop('emoji'),
                            ),
                            ListTile(
                              title: const Text('Pick image'),
                              leading: const Icon(Icons.photo_library),
                              onTap: () => Navigator.of(context).pop('gallery'),
                            ),
                          ],
                        ),
                      );
                      if (choice == 'emoji') _chooseEmoji();
                      if (choice == 'gallery') await _pickFromGallery();
                    },
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.deepPurple.shade50,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? Text(
                              _profileEmoji,
                              style: const TextStyle(fontSize: 28),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    svc.currentUser.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    svc.currentUser.email,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit profile'),
              onTap: () {
                // basic edit profile dialog
                final nameC = TextEditingController(text: svc.currentUser.name);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Edit profile'),
                    content: TextField(
                      controller: nameC,
                      decoration: const InputDecoration(labelText: 'Full name'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            svc.currentUser.name = nameC.text.trim();
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Theme'),
              subtitle: Text(
                appThemeMode.value == ThemeMode.system
                    ? 'System' // follow system
                    : appThemeMode.value == ThemeMode.dark
                    ? 'Dark'
                    : 'Light',
              ),
              onTap: () async {
                final choice = await showDialog<ThemeMode>(
                  context: context,
                  builder: (_) => SimpleDialog(
                    title: const Text('Select theme'),
                    children: [
                      SimpleDialogOption(
                        onPressed: () =>
                            Navigator.of(context).pop(ThemeMode.system),
                        child: const Text('System'),
                      ),
                      SimpleDialogOption(
                        onPressed: () =>
                            Navigator.of(context).pop(ThemeMode.light),
                        child: const Text('Light'),
                      ),
                      SimpleDialogOption(
                        onPressed: () =>
                            Navigator.of(context).pop(ThemeMode.dark),
                        child: const Text('Dark'),
                      ),
                    ],
                  ),
                );
                if (choice != null) appThemeMode.value = choice;
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'SettleUp (prototype)',
                applicationVersion: '0.1',
                children: [const Text('A simple bill splitting prototype')],
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 6),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change password'),
              onTap: () {
                final oldC = TextEditingController();
                final newC = TextEditingController();
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Change password'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: oldC,
                          decoration: const InputDecoration(
                            labelText: 'Current password',
                          ),
                          obscureText: true,
                        ),
                        TextField(
                          controller: newC,
                          decoration: const InputDecoration(
                            labelText: 'New password',
                          ),
                          obscureText: true,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password changed (prototype)'),
                            ),
                          );
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () async {
                final yes = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Sign out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                );
                if (yes == true) _signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
