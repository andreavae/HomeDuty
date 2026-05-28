class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.totalXp,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String displayName;
  final int totalXp;
  final DateTime createdAt;
}
