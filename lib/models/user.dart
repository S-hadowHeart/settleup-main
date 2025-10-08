class AppUser {
  final String id;
  String name;
  final String email;
  String emoji;
  String? avatarPath; // optional local file path for profile image

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.emoji,
    this.avatarPath,
  });
}
