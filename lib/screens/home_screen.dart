import 'dart:io';
import 'package:flutter/material.dart';
import '../services/mock_service.dart';
import '../widgets/app_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

String _fmtRupee(double v) => '₹${v.toStringAsFixed(2)}';

class _HomeScreenState extends State<HomeScreen> {
  final svc = MockService();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = svc.currentUser;
    final recent = svc.recentGroups();

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
              backgroundImage: user.avatarPath != null
                  ? FileImage(File(user.avatarPath!))
                  : null,
              child: user.avatarPath == null ? Text(user.emoji) : null,
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
              // (dev banner removed)
              const SizedBox(height: 8),
              Text(
                '${_greeting()}, ${user.name}',
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
                      Icons.group_add,
                      'Create group',
                      Theme.of(context).colorScheme.primaryContainer,
                      () => Navigator.pushNamed(context, '/create-group'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionCard(
                      Icons.add_shopping_cart,
                      'Add expense',
                      Theme.of(context).colorScheme.primaryContainer,
                      () => Navigator.pushNamed(context, '/add-expense'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'Groups',
                      svc.totalGroups().toString(),
                      Icons.groups,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statCard(
                      'Expenses',
                      _fmtRupee(svc.totalExpensesByUser(svc.currentUser.id)),
                      Icons.receipt_long,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statCard(
                      'You owe',
                      _fmtRupee(svc.totalOwedByUser(svc.currentUser.id)),
                      Icons.account_balance_wallet,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent groups',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/groups'),
                    child: const Text('See all'),
                  ),
                ],
              ),

              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, idx) {
                    final g = recent[idx];
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
                                g.emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    g.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${g.members.length} members',
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
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard(
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

  Widget _statCard(String title, String value, IconData icon) => Container(
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
