import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<Map<String, double>> _computeTotals(String uid) async {
    final fire = FirebaseFirestore.instance;
    double totalExpenses = 0.0;
    double youOwe = 0.0;

    final groupsSnap = await fire
        .collection('groups')
        .where('members', arrayContains: uid)
        .get();

    final groupDocs = groupsSnap.docs;

    for (final g in groupDocs) {
      final expensesSnap = await fire
          .collection('groups')
          .doc(g.id)
          .collection('expenses')
          .get();

      for (final ed in expensesSnap.docs) {
        final data = ed.data();
        final amount = (data['amount'] ?? 0).toDouble();
        totalExpenses += amount;

        final splits = (data['splits'] as Map<String, dynamic>?) ?? {};
        if (splits.containsKey(uid)) {
          final s = splits[uid];
          try {
            youOwe += (s ?? 0).toDouble();
          } catch (_) {}
        }
      }
    }

    return {'total': totalExpenses, 'youOwe': youOwe};
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final fire = FirebaseFirestore.instance;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: fire.collection("users").doc(uid).snapshots(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (userSnap.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${userSnap.error}')),
          );
        }

        final userMap = userSnap.data?.data();
        final name = userMap?["name"] ?? "User";
        final emoji = userMap?["emoji"] ?? "🙂";
        final avatarUrl = userMap?["avatarUrl"];

        return AppShell(
          currentIndex: 0,
          title: 'SettleUp',
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/settings'),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null ? Text(emoji) : null,
                ),
              ),
            ),
          ],
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    '${_greeting()}, $name',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Split bills, settle faster',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          context,
                          Icons.group_add,
                          'Create group',
                          Theme.of(context).colorScheme.primaryContainer,
                          () => Navigator.pushNamed(context, '/create-group'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionCard(
                          context,
                          Icons.add_shopping_cart,
                          'Add expense',
                          Theme.of(context).colorScheme.primaryContainer,
                          () => Navigator.pushNamed(context, '/add-expense'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  FutureBuilder<Map<String, double>>(
                    future: _computeTotals(uid),
                    builder: (context, totSnap) {
                      if (totSnap.connectionState == ConnectionState.waiting) {
                        return Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                'Expenses',
                                '...',
                                Icons.receipt_long,
                                context,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _statCard(
                                'You owe',
                                '...',
                                Icons.account_balance_wallet,
                                context,
                              ),
                            ),
                          ],
                        );
                      }
                      if (totSnap.hasError) {
                        return Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                'Expenses',
                                '—',
                                Icons.receipt_long,
                                context,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _statCard(
                                'You owe',
                                '—',
                                Icons.account_balance_wallet,
                                context,
                              ),
                            ),
                          ],
                        );
                      }

                      final totals =
                          totSnap.data ?? {'total': 0.0, 'youOwe': 0.0};
                      final totalExpenses = totals['total'] ?? 0.0;
                      final youOwe = totals['youOwe'] ?? 0.0;

                      return Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              'Expenses',
                              '₹${totalExpenses.toStringAsFixed(2)}',
                              Icons.receipt_long,
                              context,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _statCard(
                              'You owe',
                              '₹${youOwe.toStringAsFixed(2)}',
                              Icons.account_balance_wallet,
                              context,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent groups',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/groups'),
                        child: const Text('See all'),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: 120,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: fire
                          .collection('groups')
                          .where('members', arrayContains: uid)
                          .snapshots(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snap.hasError) {
                          return Center(child: Text('Error: ${snap.error}'));
                        }

                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'No groups yet',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      '/create-group',
                                    ),
                                    child: const Text(
                                      'Create your first group',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final groups = docs.map((d) {
                          final data = d.data() as Map<String, dynamic>?;
                          return {'id': d.id, ...(data ?? {})};
                        }).toList();

                        groups.sort((a, b) {
                          final aTs = a['createdAt'];
                          final bTs = b['createdAt'];
                          if (aTs is Timestamp && bTs is Timestamp) {
                            return bTs.compareTo(aTs);
                          }
                          return 0;
                        });

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: groups.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, idx) {
                            final g = groups[idx];
                            return GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/group-details',
                                arguments: g,
                              ),
                              child: Container(
                                width: 220,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(
                                        (0.04 * 255).round(),
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      child: Text(
                                        g['emoji'] ?? '👥',
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            g['name'] ?? 'Group',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${(g['members'] as List?)?.length ?? 0} members',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
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
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionCard(
    BuildContext context,
    IconData icon,
    String label,
    Color bg,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(height: 6),
          Text(label),
        ],
      ),
    ),
  );

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    BuildContext context,
  ) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha((0.03 * 255).round()),
          blurRadius: 6,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
