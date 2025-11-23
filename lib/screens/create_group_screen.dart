import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/emoji_picker.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _memberController = TextEditingController();
  String _emoji = '😀';
  final List<String> _members = [];

  @override
  void dispose() {
    _nameController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  void _pickEmoji() async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => EmojiPicker(
        selected: _emoji,
        onSelected: (e) => Navigator.of(context).pop(e),
      ),
    );
    if (emoji != null) setState(() => _emoji = emoji);
  }

  void _addMember() {
    final email = _memberController.text.trim();
    if (email.isEmpty) return;
    final emailReg = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    if (!emailReg.hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid email')));
      return;
    }
    if (_members.contains(email)) {
      _memberController.clear();
      return;
    }
    setState(() {
      _members.add(email);
      _memberController.clear();
    });
  }

  bool _isLoading = false;

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be signed in to create a group'),
          ),
        );
        return;
      }
      final uid = currentUser.uid;
      final name = _nameController.text.trim();

      final usersRef = FirebaseFirestore.instance.collection('users');
      final membersResolved = <String>[];

      for (final email in _members) {
        try {
          final q = await usersRef
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          if (q.docs.isNotEmpty) {
            membersResolved.add(q.docs.first.id);
          } else {
            final doc = usersRef.doc();
            await doc.set({
              'name': email.split('@')[0],
              'email': email,
              'emoji': '🙂',
              'avatarUrl': null,
              'createdAt': FieldValue.serverTimestamp(),
            });
            membersResolved.add(doc.id);
          }
        } catch (e, st) {
          debugPrint('Error resolving/creating user for $email: $e\n$st');
        }
      }

      if (!membersResolved.contains(uid)) membersResolved.insert(0, uid);

      final ref = FirebaseFirestore.instance.collection('groups').doc();
      await ref.set({
        'name': name,
        'emoji': _emoji,
        'createdBy': uid,
        'members': membersResolved,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Group created')));
      Navigator.of(context).pop();
    } catch (e, st) {
      debugPrint('Failed to create group: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickEmoji,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.deepPurple.shade50,
                  child: Text(_emoji, style: const TextStyle(fontSize: 32)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Group name',
                      hintText: 'e.g. Weekend Trip',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _memberController,
                          decoration: const InputDecoration(
                            labelText: 'Add member by email',
                            hintText: 'alice@example.com',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _addMember,
                        icon: const Icon(
                          Icons.add_circle,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _members
                        .map(
                          (m) => Chip(
                            label: Text(m),
                            backgroundColor: Colors.grey.shade100,
                            onDeleted: () => setState(() => _members.remove(m)),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _create,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.group_add),
                    label: Text(_isLoading ? 'Creating…' : 'Create group'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
