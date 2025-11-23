import 'package:cloud_firestore/cloud_firestore.dart';

class GroupService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> watchGroups(String uid) {
    return _db
        .collection('groups')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<String> createGroup({
    required String name,
    required String emoji,
    required String createdBy,
  }) async {
    final ref = _db.collection('groups').doc();
    await ref.set({
      'name': name,
      'emoji': emoji,
      'createdBy': createdBy,
      'members': [createdBy],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
