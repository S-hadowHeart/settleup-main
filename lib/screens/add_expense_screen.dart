import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/mock_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'Other';
  String? _selectedGroupId;
  String? _paidBy;
  bool _equalSplit = true;
  final Set<String> _selectedMembers = {};
  final svc = MockService();
  bool _didHandleRouteArg = false;

  @override
  void initState() {
    super.initState();
    if (svc.groups.isNotEmpty) {
      _selectedGroupId = svc.groups.first.id;
      _selectedMembers.addAll(svc.groups.first.members.map((m) => m.user.id));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didHandleRouteArg) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String) {
        final exists = svc.groups.any((g) => g.id == arg);
        if (exists) {
          setState(() {
            _selectedGroupId = arg;
            final grp = svc.groups.firstWhere((g) => g.id == arg);
            _selectedMembers
              ..clear()
              ..addAll(grp.members.map((m) => m.user.id));
          });
        }
      }
      _didHandleRouteArg = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final groupId = _selectedGroupId ?? svc.groups.first.id;
      final amount = double.tryParse(_amountController.text) ?? 0;
      final splits = <String, double>{};
      final members = svc.groups.firstWhere((g) => g.id == groupId).members;
      if (_equalSplit) {
        final per = amount / members.length;
        for (final m in members) {
          splits[m.user.id] = per;
        }
      } else {
        final selected = members
            .where((m) => _selectedMembers.contains(m.user.id))
            .toList();
        final per = selected.isEmpty ? 0.0 : amount / selected.length;
        for (final m in members) {
          splits[m.user.id] = selected.any((s) => s.user.id == m.user.id)
              ? per
              : 0.0;
        }
      }
      svc.addExpense(
        groupId,
        _titleController.text.trim(),
        amount,
        _category,
        _paidBy ?? svc.currentUser.id,
        splits,
        _attachmentPath,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = svc.groups;
    final grp = _selectedGroupId != null
        ? svc.groups.firstWhere((g) => g.id == _selectedGroupId)
        : (groups.isNotEmpty ? groups.first : null);
    return Scaffold(
      appBar: AppBar(title: const Text('Add expense')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // (dev banner removed)
              const SizedBox(height: 8),
              const Text(
                'Choose group',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final g = groups[idx];
                    final sel = _selectedGroupId == g.id;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedGroupId = g.id;
                        _selectedMembers.clear();
                        _selectedMembers.addAll(
                          g.members.map((m) => m.user.id),
                        );
                      }),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 120,
                          maxWidth: 160,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sel
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: sel
                                ? Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(child: Text(g.emoji)),
                              const SizedBox(height: 8),
                              Text(
                                g.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${g.members.length} members',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Paid by selector
              if (grp != null) ...[
                const Text('Paid by'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: grp.members.map((m) {
                    final isSel = (_paidBy ?? svc.currentUser.id) == m.user.id;
                    return ChoiceChip(
                      label: Text('${m.user.emoji} ${m.user.name}'),
                      selected: isSel,
                      onSelected: (_) => setState(() => _paidBy = m.user.id),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter amount' : null,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['Food', 'Travel', 'Shopping', 'Other']
                    .map(
                      (c) => ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Equal split'),
                value: _equalSplit,
                onChanged: (v) => setState(() => _equalSplit = v),
              ),
              if (!_equalSplit) ...[
                const SizedBox(height: 8),
                const Text('Split between'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      (_selectedGroupId != null
                              ? svc.groups
                                    .firstWhere((g) => g.id == _selectedGroupId)
                                    .members
                              : svc.groups.first.members)
                          .map((m) {
                            final selected = _selectedMembers.contains(
                              m.user.id,
                            );
                            return FilterChip(
                              selected: selected,
                              label: Text('${m.user.emoji} ${m.user.name}'),
                              onSelected: (sel) => setState(() {
                                if (sel) {
                                  _selectedMembers.add(m.user.id);
                                } else {
                                  _selectedMembers.remove(m.user.id);
                                }
                              }),
                            );
                          })
                          .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickAttachment,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Attach bill'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save expense'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_attachmentPath != null)
                Text(
                  'Attached: Added successfully',
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _attachmentPath;

  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final res = await picker.pickImage(source: ImageSource.gallery);
    if (res != null) setState(() => _attachmentPath = res.path);
  }
}
