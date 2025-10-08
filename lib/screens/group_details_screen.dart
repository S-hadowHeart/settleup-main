import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:io';
import '../models/group.dart';
import '../services/mock_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/emoji_picker.dart';
import '../models/expense.dart';

class GroupDetailsScreen extends StatefulWidget {
  const GroupDetailsScreen({super.key});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  final svc = MockService();
  final Set<String> _appliedSettlementKeys = {};
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  @override
  Widget build(BuildContext context) {
    final g = ModalRoute.of(context)!.settings.arguments as Group;
    final expenses = svc.expenses.where((e) => e.groupId == g.id).toList();

    return AppShell(
      currentIndex: 1,
      title: '${g.emoji} ${g.name}',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${g.members.length} members',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _editGroup(g),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Summary'),
                Tab(text: 'Expenses'),
                Tab(text: 'Balance'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildSummary(g, expenses),
                  ),
                  Column(
                    children: [
                      Expanded(child: _buildExpensesList(expenses)),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/add-expense',
                            arguments: g.id,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add expense'),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildBalanceSettleInteractive(g, expenses),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // helper to safely get a user's name by id; returns a fallback if not found
  String _userNameById(String id) {
    final idx = svc.users.indexWhere((u) => u.id == id);
    if (idx >= 0) return svc.users[idx].name;
    return 'Unknown';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildSummary(Group g, List<Expense> expenses) {
    final total = expenses.fold<double>(0.0, (p, e) => p + e.amount);
    final yourShare = expenses.fold<double>(
      0.0,
      (p, e) => p + (e.splits[svc.currentUser.id] ?? 0.0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: g.members
              .map((m) => Chip(label: Text('${m.user.emoji} ${m.user.name}')))
              .toList(),
        ),
        const SizedBox(height: 12),

        // Summary cards
        Row(
          children: [
            Expanded(
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total spent',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your share',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${yourShare.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'What is balance?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 6),
                Text(
                  'Example: If you paid ₹300 for dinner split equally between 3 people, each owes ₹100. Your balance shows how much you have paid minus what you owe.',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/add-expense',
                  arguments: g.id,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add expense'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _tabController.animateTo(2),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Balance / Settle'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpensesList(List<Expense> expenses) {
    if (expenses.isEmpty) return const Center(child: Text('No expenses yet'));
    return ListView.separated(
      itemCount: expenses.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, idx) {
        final e = expenses[idx];
        return ListTile(
          title: Text(e.title),
          subtitle: Text('₹${e.amount.toStringAsFixed(2)} • ${e.category}'),
          trailing: Text(e.date.toLocal().toString().split(' ').first),
          onTap: () => _showExpenseDetails(e),
        );
      },
    );
  }

  void _showExpenseDetails(Expense e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(e.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₹${e.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Paid by: ${_userNameById(e.paidByUserId)}'),
            const SizedBox(height: 8),
            Text('Splits:'),
            ...e.splits.entries.map(
              (s) => Text(
                '${_userNameById(s.key)}: ₹${s.value.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(height: 8),
            if (e.attachmentPath != null) ...[
              const SizedBox(height: 8),
              const Text('Attachment:'),
              const SizedBox(height: 6),
              SizedBox(
                height: 160,
                child: Image.file(File(e.attachmentPath!), fit: BoxFit.contain),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSettleInteractive(Group g, List<Expense> expenses) {
    // build suggestions but keep selection local using StatefulBuilder
    // calculate net per user
    final Map<String, double> net = {};
    for (var m in g.members) net[m.user.id] = 0.0;
    for (var e in expenses) {
      for (var entry in e.splits.entries) {
        net[entry.key] = (net[entry.key] ?? 0) - entry.value;
      }
      net[e.paidByUserId] = (net[e.paidByUserId] ?? 0) + e.amount;
    }

    final creditors = net.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final debtors = net.entries.where((e) => e.value < 0).toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final suggestions =
        <
          MapEntry<String, MapEntry<String, double>>
        >[]; // creditorId -> (debtorId, amount)
    int i = 0, j = 0;
    while (i < creditors.length && j < debtors.length) {
      final c = creditors[i];
      final d = debtors[j];
      final amount = math.min(c.value, -d.value);
      suggestions.add(MapEntry(c.key, MapEntry(d.key, amount)));
      creditors[i] = MapEntry(c.key, c.value - amount);
      debtors[j] = MapEntry(d.key, d.value + amount);
      if (creditors[i].value <= 0) i++;
      if (debtors[j].value >= 0) j++;
    }

    // compute visible suggestions and keys once
    final visible = <MapEntry<String, MapEntry<String, double>>>[];
    final keys = <String>[];
    for (var s in suggestions) {
      final key = '${s.key}-${s.value.key}-${s.value.value}';
      if (!_appliedSettlementKeys.contains(key)) {
        visible.add(s);
        keys.add(key);
      }
    }

    // keep selection persistent while this widget is active
    final selected = <int>{};

    return StatefulBuilder(
      builder: (context, setSt) {
        return Column(
          children: [
            if (suggestions.isEmpty) const Text('All settled'),
            if (visible.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, idx) {
                    final s = visible[idx];
                    final creditor = _userNameById(s.key);
                    final debtor = _userNameById(s.value.key);
                    final amount = s.value.value;
                    return CheckboxListTile(
                      title: Text(
                        '$debtor pays ₹${amount.toStringAsFixed(2)} to $creditor',
                      ),
                      value: selected.contains(idx),
                      onChanged: (v) => setSt(() {
                        if (v == true)
                          selected.add(idx);
                        else
                          selected.remove(idx);
                      }),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () {
                              // map selected indices to keys and suggestions in `visible`
                              final chosen = selected
                                  .map((i) => visible[i])
                                  .toList();
                              final chosenKeys = selected
                                  .map((i) => keys[i])
                                  .toList();
                              _applySettlementSuggestions(
                                chosen,
                                chosenKeys,
                                g,
                              );
                            },
                      child: const Text('Settle selected'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _applySettlementSuggestions(
    List<MapEntry<String, MapEntry<String, double>>> chosen,
    List<String> chosenKeys,
    Group g,
  ) {
    // mark chosen suggestions as applied
    setState(() {
      _appliedSettlementKeys.addAll(chosenKeys);
    });
    final msg = chosen
        .map((s) {
          final creditor = _userNameById(s.key);
          final debtor = _userNameById(s.value.key);
          final amount = s.value.value;
          return '$debtor → $creditor: ₹${amount.toStringAsFixed(2)}';
        })
        .join('\n');
    final summary = msg.isEmpty ? 'No items selected' : msg;
    // show a transient snackbar instead of modal prototype dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(summary), duration: const Duration(seconds: 3)),
    );
  }

  void _editGroup(Group g) {
    final nameC = TextEditingController(text: g.name);
    String selectedEmoji = g.emoji;
    final emailC = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSt) {
          return AlertDialog(
            title: const Text('Edit group'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        child: Text(
                          selectedEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () async {
                          // open emoji picker modal
                          final picked = await showModalBottomSheet<String>(
                            context: context,
                            builder: (_) => EmojiPicker(
                              selected: selectedEmoji,
                              onSelected: (e) => Navigator.of(context).pop(e),
                            ),
                          );
                          if (picked != null)
                            setSt(() => selectedEmoji = picked);
                        },
                        icon: const Icon(Icons.emoji_emotions_outlined),
                        label: const Text('Change icon'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameC,
                    decoration: const InputDecoration(labelText: 'Group name'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Members',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (var m in g.members)
                        Chip(
                          label: Text('${m.user.emoji} ${m.user.name}'),
                          onDeleted: m.user.id == svc.currentUser.id
                              ? null
                              : () {
                                  setSt(
                                    () => g.members.removeWhere(
                                      (mm) => mm.user.id == m.user.id,
                                    ),
                                  );
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emailC,
                          decoration: const InputDecoration(
                            hintText: 'add member by email',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final email = emailC.text.trim();
                          if (email.isEmpty) return;
                          final user = svc.findUserByEmail(email)!;
                          // avoid duplicates
                          if (g.members.any((mm) => mm.user.id == user.id))
                            return;
                          setSt(() => g.members.add(GroupMember(user: user)));
                          emailC.clear();
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    g.name = nameC.text.trim();
                    g.emoji = selectedEmoji;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
