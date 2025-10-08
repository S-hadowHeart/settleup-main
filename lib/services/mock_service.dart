import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/expense.dart';

class MockService {
  static final MockService _instance = MockService._internal();
  factory MockService() => _instance;
  MockService._internal() {
    _init();
  }

  final _uuid = const Uuid();

  late AppUser currentUser;
  final List<AppUser> users = [];
  final List<Group> groups = [];
  final List<Expense> expenses = [];

  void _init() {
    // create some mock users
    currentUser = AppUser(
      id: _uuid.v4(),
      name: 'Mico',
      email: 'Mico@galaxy.com',
      emoji: '😁',
    );
    // load persisted avatar/emoji if present
    _loadUserPrefs();
    users.add(currentUser);
    users.add(
      AppUser(
        id: _uuid.v4(),
        name: 'Alice',
        email: 'alice@example.com',
        emoji: '🧑‍🍳',
      ),
    );
    users.add(
      AppUser(
        id: _uuid.v4(),
        name: 'Bob',
        email: 'bob@example.com',
        emoji: '🧑‍🔧',
      ),
    );

    // create a mock group
    final g1 = Group(
      id: _uuid.v4(),
      name: 'Dinner',
      emoji: '🍽️',
      members: [
        GroupMember(user: currentUser),
        GroupMember(user: users[1]),
      ],
    );
    groups.add(g1);

    final g2 = Group(
      id: _uuid.v4(),
      name: 'Trip',
      emoji: '🧳',
      members: [
        GroupMember(user: currentUser),
        GroupMember(user: users[2]),
      ],
    );
    groups.add(g2);

    // add some example expenses
    addExpense(g1.id, 'Pizza and drinks', 1200.0, 'Food', currentUser.id, {
      currentUser.id: 600.0,
      users[1].id: 600.0,
    });
    addExpense(g1.id, 'Dessert', 300.0, 'Food', users[1].id, {
      currentUser.id: 150.0,
      users[1].id: 150.0,
    });

    addExpense(g2.id, 'Fuel', 800.0, 'Travel', currentUser.id, {
      currentUser.id: 400.0,
      users[2].id: 400.0,
    });
  }

  Future<void> _loadUserPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emoji = prefs.getString('currentUser_emoji');
      final path = prefs.getString('currentUser_avatarPath');
      if (emoji != null) currentUser.emoji = emoji;
      if (path != null && path.isNotEmpty) currentUser.avatarPath = path;
    } catch (_) {
      // ignore errors in prototype
    }
  }

  Future<void> setAvatarPath(String? path) async {
    currentUser.avatarPath = path;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (path == null) {
        await prefs.remove('currentUser_avatarPath');
      } else {
        await prefs.setString('currentUser_avatarPath', path);
      }
    } catch (_) {}
  }

  Future<void> setEmoji(String emoji) async {
    currentUser.emoji = emoji;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser_emoji', emoji);
    } catch (_) {}
  }

  List<Group> recentGroups({int limit = 4}) {
    return groups.take(limit).toList();
  }

  int totalGroups() => groups.length;

  double totalExpensesByUser(String userId) {
    return expenses
        .where((e) => e.paidByUserId == userId)
        .fold(0.0, (p, n) => p + n.amount);
  }

  double totalOwedByUser(String userId) {
    // sum splits where user owes positive amount
    double sum = 0;
    for (final e in expenses) {
      final v = e.splits[userId] ?? 0.0;
      sum += v;
    }
    return sum;
  }

  AppUser? findUserByEmail(String email) {
    final idx = users.indexWhere((u) => u.email == email);
    if (idx >= 0) return users[idx];
    // do not auto-create users in the service; return null if not found
    return null;
  }

  Group createGroup(String name, String emoji, List<String> memberEmails) {
    final members = memberEmails
        .map((m) => findUserByEmail(m))
        .where((u) => u != null)
        .map((u) => GroupMember(user: u!))
        .toList();
    final g = Group(
      id: _uuid.v4(),
      name: name,
      emoji: emoji,
      members: [
        GroupMember(user: currentUser),
        ...members,
      ],
    );
    groups.add(g);
    return g;
  }

  Expense addExpense(
    String groupId,
    String title,
    double amount,
    String category,
    String paidBy,
    Map<String, double> splits, [
    String? attachmentPath,
  ]) {
    final e = Expense(
      id: _uuid.v4(),
      groupId: groupId,
      title: title,
      amount: amount,
      category: category,
      paidByUserId: paidBy,
      date: DateTime.now(),
      splits: splits,
      attachmentPath: attachmentPath,
    );
    expenses.add(e);
    final g = groups.firstWhere((g) => g.id == groupId);
    g.expenseIds.add(e.id);
    return e;
  }
}
