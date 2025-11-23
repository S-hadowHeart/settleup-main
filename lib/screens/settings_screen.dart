import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/emoji_picker.dart';
import '../services/firebase_user_service.dart';
import '../models/app_user.dart';
import '../widgets/app_shell.dart';
import '../app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseUserService userService = FirebaseUserService();

  AppUser? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    user = await userService.loadUser();
    setState(() => loading = false);
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final dynamic img = await picker.pickImage(source: ImageSource.gallery);

    if (img == null) return;

    final file = File(img.path);

    final url = await userService.uploadAvatar(file);

    setState(() {
      user = user!.copyWith(avatarUrl: url);
    });
  }

  Future<void> _chooseEmoji() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => EmojiPicker(
        selected: user!.emoji,
        onSelected: (e) => Navigator.pop(context, e),
      ),
    );

    if (selected != null) {
      await userService.updateEmoji(selected);
      setState(() => user = user!.copyWith(emoji: selected));
    }
  }

  Future<void> _changeName() async {
    final controller = TextEditingController(text: user!.name);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit profile"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Full name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              await userService.updateName(newName);
              setState(() => user = user!.copyWith(name: newName));
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email found for this account')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _signOut() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sign out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Sign out"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (yes == true) {
      await userService.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return AppShell(
      currentIndex: 2,
      title: "Settings",
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
                      final action = await showModalBottomSheet<String>(
                        context: context,
                        builder: (_) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.emoji_emotions),
                              title: const Text("Choose emoji"),
                              onTap: () => Navigator.pop(context, "emoji"),
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text("Pick image"),
                              onTap: () => Navigator.pop(context, "gallery"),
                            ),
                          ],
                        ),
                      );
                      if (action == "emoji") _chooseEmoji();
                      if (action == "gallery") await _pickFromGallery();
                    },
                    child: CircleAvatar(
                      radius: 44,
                      backgroundImage: user!.avatarUrl != null
                          ? NetworkImage(user!.avatarUrl!)
                          : null,
                      backgroundColor: Colors.deepPurple.shade50,
                      child: user!.avatarUrl == null
                          ? Text(
                              user!.emoji,
                              style: const TextStyle(fontSize: 28),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user!.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user!.email,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit profile"),
              onTap: _changeName,
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text("Theme"),
              subtitle: Text(
                appThemeMode.value == ThemeMode.system
                    ? "System"
                    : appThemeMode.value == ThemeMode.dark
                    ? "Dark"
                    : "Light",
              ),
              onTap: () async {
                final mode = await showDialog<ThemeMode>(
                  context: context,
                  builder: (_) => SimpleDialog(
                    title: const Text("Select theme"),
                    children: [
                      SimpleDialogOption(
                        child: const Text("System"),
                        onPressed: () =>
                            Navigator.pop(context, ThemeMode.system),
                      ),
                      SimpleDialogOption(
                        child: const Text("Light"),
                        onPressed: () =>
                            Navigator.pop(context, ThemeMode.light),
                      ),
                      SimpleDialogOption(
                        child: const Text("Dark"),
                        onPressed: () => Navigator.pop(context, ThemeMode.dark),
                      ),
                    ],
                  ),
                );

                if (mode != null) appThemeMode.value = mode;
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("About"),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: "SettleUp",
                applicationVersion: "0.1",
                children: const [Text("A simple bill splitting prototype")],
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text("Change password"),
              onTap: _changePassword,
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text("Sign out"),
            ),
          ],
        ),
      ),
    );
  }
}
