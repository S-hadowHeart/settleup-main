import 'package:flutter/material.dart';
import '../services/mock_service.dart';
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
  final svc = MockService();
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
    if (_memberController.text.trim().isEmpty) return;
    setState(() {
      _members.add(_memberController.text.trim());
      _memberController.clear();
    });
  }

  void _create() {
    if (_formKey.currentState?.validate() ?? false) {
      svc.createGroup(_nameController.text.trim(), _emoji, _members);
      Navigator.of(context).pop();
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
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _create,
                    icon: const Icon(Icons.group_add),
                    label: const Text('Create group'),
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
