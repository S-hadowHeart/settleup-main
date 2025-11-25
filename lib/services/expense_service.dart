import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> watchExpenses(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<void> addExpense({
    required String groupId,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> participants,
  }) {
    final ref = _db
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc();

    return ref.set({
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'participants': participants,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
