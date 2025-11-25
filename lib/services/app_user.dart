class AppUser {
  final String id;
  final String name;
  final String email;
  final String emoji;
  final String? avatarUrl;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.emoji,
    required this.avatarUrl,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      emoji: map['emoji'] ?? '🙂',
      avatarUrl: map['avatarUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'emoji': emoji,
    'avatarUrl': avatarUrl,
  };

  AppUser copyWith({
    String? name,
    String? email,
    String? emoji,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      emoji: emoji ?? this.emoji,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
