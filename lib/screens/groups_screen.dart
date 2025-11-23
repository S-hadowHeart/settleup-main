import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_shell.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final groupsRef = FirebaseFirestore.instance
        .collection('groups')
        .orderBy('updatedAt', descending: true);

    final groupsCollection = FirebaseFirestore.instance.collection('groups');

    return AppShell(
      currentIndex: 1,
      title: 'Groups',
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: groupsCollection
              .where('members', arrayContains: uid)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError)
              return Center(child: Text('Error: ${snap.error}'));
            if (!snap.hasData)
              return const Center(child: CircularProgressIndicator());
            final docs = List<QueryDocumentSnapshot>.from(snap.data!.docs);

            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTs = aData['updatedAt'] as Timestamp?;
              final bTs = bData['updatedAt'] as Timestamp?;
              final aDate =
                  aTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bDate =
                  bTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });

            if (docs.isEmpty) return const Center(child: Text('No groups yet'));
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final d = docs[idx];
                final g = d.data() as Map<String, dynamic>;
                final members = (g['members'] as List?) ?? [];
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
                      child: Text(
                        g['emoji'] ?? '👥',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Text(
                      g['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${members.length} members'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/group-details',
                      arguments: {'id': d.id},
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
