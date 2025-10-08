class Expense {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String category;
  final String paidByUserId;
  final DateTime date;
  final Map<String, double> splits; // userId -> amount
  final String? attachmentPath;

  Expense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.category,
    required this.paidByUserId,
    required this.date,
    required this.splits,
    this.attachmentPath,
  });
}
