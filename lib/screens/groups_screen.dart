import 'package:flutter/material.dart';
import '../services/mock_service.dart';
import '../widgets/app_shell.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = MockService();
    final groups = svc.groups;
    return AppShell(
      currentIndex: 1,
      title: 'Groups',
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.separated(
          itemCount: groups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final g = groups[idx];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.deepPurple.shade50,
                  child: Text(g.emoji, style: const TextStyle(fontSize: 20)),
                ),
                title: Text(
                  g.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${g.members.length} members'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/group-details',
                  arguments: g,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
