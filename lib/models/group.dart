import 'user.dart';

class GroupMember {
  final AppUser user;
  double balance;

  GroupMember({required this.user, this.balance = 0});
}

class Group {
  final String id;
  String name;
  String emoji;
  final List<GroupMember> members;
  final List<String> expenseIds;

  Group({
    required this.id,
    required this.name,
    required this.emoji,
    required this.members,
  }) : expenseIds = [];
}
