import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_shell.dart';
import '../widgets/emoji_picker.dart';

class GroupDetailsScreen extends StatefulWidget {
  const GroupDetailsScreen({super.key});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadGroupAndMembers(String groupId) async {
    final fire = FirebaseFirestore.instance;
    final gdoc = await fire.collection('groups').doc(groupId).get();
    final gdata = gdoc.data() ?? <String, dynamic>{};
    final List members = (gdata['members'] as List<dynamic>?) ?? [];

    final users = <String, Map<String, dynamic>>{};
    if (members.isNotEmpty) {
      final chunks = <List>[];
      const chunkSize = 10;
      for (var i = 0; i < members.length; i += chunkSize) {
        chunks.add(members.sublist(i, math.min(i + chunkSize, members.length)));
      }
      for (final chunk in chunks) {
        final q = await fire
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final ud in q.docs) {
          users[ud.id] = ud.data();
        }
      }
    }
    return {'group': gdata, 'users': users};
  }

  @override
  Widget build(BuildContext context) {
    final arg =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final groupId = arg['id'] as String;
    final fire = FirebaseFirestore.instance;

    return StreamBuilder<DocumentSnapshot>(
      stream: fire.collection('groups').doc(groupId).snapshots(),
      builder: (context, gsnap) {
        if (gsnap.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${gsnap.error}')));
        }
        if (!gsnap.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        final gmap = gsnap.data!.data() as Map<String, dynamic>;
        final members = (gmap['members'] as List<dynamic>?) ?? [];

        return AppShell(
          currentIndex: 1,
          title: '${gmap['emoji'] ?? ''} ${gmap['name'] ?? 'Group'}',
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
                            gmap['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${members.length} members',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _editGroupDialog(context, groupId, gmap),
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
                      FutureBuilder<Map<String, dynamic>>(
                        future: _loadGroupAndMembers(groupId),
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return Center(child: Text('Error: ${snap.error}'));
                          }
                          if (!snap.hasData)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          final users =
                              snap.data!['users'] as Map<String, dynamic>;
                          return _buildSummaryUI(groupId, users);
                        },
                      ),

                      StreamBuilder<QuerySnapshot>(
                        stream: fire
                            .collection('groups')
                            .doc(groupId)
                            .collection('expenses')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return Center(child: Text('Error: ${snap.error}'));
                          }
                          if (!snap.hasData)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          final docs = snap.data!.docs;
                          if (docs.isEmpty)
                            return const Center(child: Text('No expenses yet'));
                          return Column(
                            children: [
                              Expanded(
                                child: ListView.separated(
                                  itemCount: docs.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (context, idx) {
                                    final e =
                                        docs[idx].data()
                                            as Map<String, dynamic>;
                                    final title = e['title'] ?? '';
                                    final amount = (e['amount'] ?? 0)
                                        .toDouble();
                                    final createdAt = e['createdAt'] != null
                                        ? (e['createdAt'] as Timestamp).toDate()
                                        : DateTime.now();
                                    return ListTile(
                                      title: Text(title),
                                      subtitle: Text(
                                        '₹${amount.toStringAsFixed(2)} • ${createdAt.toLocal().toString().split(' ').first}',
                                      ),
                                      onTap: () =>
                                          _showExpenseDetails(context, e),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    '/add-expense',
                                    arguments: groupId,
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add expense'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      FutureBuilder<Map<String, dynamic>>(
                        future: _loadGroupAndMembers(groupId),
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return Center(child: Text('Error: ${snap.error}'));
                          }
                          if (!snap.hasData)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          final users =
                              snap.data!['users'] as Map<String, dynamic>;
                          return _buildBalanceUI(groupId, users);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryUI(String groupId, Map<String, dynamic> usersById) {
    final fire = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot>(
      stream: fire
          .collection('groups')
          .doc(groupId)
          .collection('expenses')
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final expenses = snap.data!.docs
            .map((d) => d.data() as Map<String, dynamic>)
            .toList();
        final total = expenses.fold<double>(
          0.0,
          (p, e) => p + ((e['amount'] ?? 0).toDouble()),
        );
        final currentUser = FirebaseAuth.instance.currentUser;
        final uid = currentUser?.uid ?? '';
        double yourShare = 0.0;
        for (final e in expenses) {
          final splits = (e['splits'] as Map<String, dynamic>?) ?? {};
          yourShare += (splits[uid] ?? 0).toDouble();
        }

        final memberWidgets = usersById.entries.map((en) {
          final u = en.value as Map<String, dynamic>;
          final emoji = u['emoji'] ?? '🙂';
          final name = u['name'] ?? u['email'] ?? '';
          return Chip(label: Text('$emoji $name'));
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 8, runSpacing: 6, children: memberWidgets),
              const SizedBox(height: 12),
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
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
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
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
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
                        arguments: groupId,
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
          ),
        );
      },
    );
  }

  Widget _buildBalanceUI(String groupId, Map<String, dynamic> usersById) {
    final fire = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot>(
      stream: fire
          .collection('groups')
          .doc(groupId)
          .collection('expenses')
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        final Map<String, double> net = {};
        usersById.keys.forEach((k) => net[k] = 0.0);

        for (final d in docs) {
          final e = d.data() as Map<String, dynamic>;
          final amount = (e['amount'] ?? 0).toDouble();
          final paidBy = e['paidBy'] as String? ?? '';
          final splits = (e['splits'] as Map<String, dynamic>?) ?? {};

          splits.forEach((uid, val) {
            net[uid] = (net[uid] ?? 0) - (val.toDouble());
          });
          net[paidBy] = (net[paidBy] ?? 0) + amount;
        }

        final creditors = net.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final debtors = net.entries.where((e) => e.value < 0).toList()
          ..sort((a, b) => a.value.compareTo(b.value));

        final suggestions = <MapEntry<String, MapEntry<String, double>>>[];
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

        if (suggestions.isEmpty)
          return const Center(child: Text('All settled'));

        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, idx) {
            final s = suggestions[idx];
            final creditorId = s.key;
            final debtorId = s.value.key;
            final amount = s.value.value;
            final creditorName = (usersById[creditorId]?['name']) ?? 'Unknown';
            final debtorName = (usersById[debtorId]?['name']) ?? 'Unknown';
            return CheckboxListTile(
              title: Text(
                '$debtorName pays ₹${amount.toStringAsFixed(2)} to $creditorName',
              ),
              value: false,
              onChanged: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Marked: $debtorName → $creditorName ₹${amount.toStringAsFixed(2)}',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showExpenseDetails(BuildContext context, Map<String, dynamic> e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(e['title'] ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: ₹${((e['amount'] ?? 0).toDouble()).toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            Text('Paid by: ${e['paidBy'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Splits:'),
            const SizedBox(height: 6),
            ...((e['splits'] as Map<String, dynamic>? ?? {}).entries.map(
              (s) => Text('${s.key}: ₹${(s.value).toString()}'),
            )),
            if (e['attachmentUrl'] != null) ...[
              const SizedBox(height: 8),
              const Text('Attachment:'),
              const SizedBox(height: 6),
              SizedBox(
                height: 160,
                child: Image.network(e['attachmentUrl'], fit: BoxFit.contain),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editGroupDialog(
    BuildContext context,
    String groupId,
    Map<String, dynamic> group,
  ) {
    final nameC = TextEditingController(text: group['name']);
    String selectedEmoji = group['emoji'] ?? '😀';
    final emailC = TextEditingController();
    var isSaving = false;

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

                  FutureBuilder<Map<String, dynamic>>(
                    future: _loadGroupAndMembers(groupId),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Text('Error loading members: ${snap.error}');
                      }
                      if (!snap.hasData) {
                        return const SizedBox(
                          height: 48,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final currentGroup =
                          snap.data!['group'] as Map<String, dynamic>;
                      final membersList =
                          (currentGroup['members'] as List<dynamic>?) ?? [];
                      final usersById =
                          (snap.data!['users'] as Map<String, dynamic>) ?? {};

                      if (membersList.isEmpty) return const Text('No members');

                      return Wrap(
                        spacing: 6,
                        children: membersList.map<Widget>((mid) {
                          final id = mid.toString();
                          final u = usersById[id] as Map<String, dynamic>?;
                          final display = u != null
                              ? '${u['emoji'] ?? '🙂'} ${u['name'] ?? u['email'] ?? id}'
                              : id;
                          return Chip(
                            label: Text(display),
                            onDeleted: () async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('groups')
                                    .doc(groupId)
                                    .update({
                                      'members': FieldValue.arrayRemove([id]),
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    });
                                setSt(() {});
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to remove member: $e',
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        }).toList(),
                      );
                    },
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
                        onPressed: () async {
                          final email = emailC.text.trim();
                          if (email.isEmpty) return;
                          final emailReg = RegExp(
                            r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
                          );
                          if (!emailReg.hasMatch(email)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enter a valid email'),
                              ),
                            );
                            return;
                          }

                          setSt(() => isSaving = true);

                          try {
                            // find or create user doc
                            final usersRef = FirebaseFirestore.instance
                                .collection('users');
                            final q = await usersRef
                                .where('email', isEqualTo: email)
                                .limit(1)
                                .get();
                            String uid;
                            if (q.docs.isNotEmpty) {
                              uid = q.docs.first.id;
                            } else {
                              final doc = usersRef.doc();
                              await doc.set({
                                'name': email.split('@')[0],
                                'email': email,
                                'emoji': '🙂',
                                'avatarUrl': null,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                              uid = doc.id;
                            }
                            await FirebaseFirestore.instance
                                .collection('groups')
                                .doc(groupId)
                                .update({
                                  'members': FieldValue.arrayUnion([uid]),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });
                            emailC.clear();
                            setSt(() {});
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to add member: $e'),
                              ),
                            );
                          } finally {
                            setSt(() => isSaving = false);
                          }
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
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('groups')
                        .doc(groupId)
                        .update({
                          'name': nameC.text.trim(),
                          'emoji': selectedEmoji,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save: $e')),
                    );
                  }
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
