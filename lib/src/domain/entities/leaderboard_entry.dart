class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.totalXp,
  });

  final String userId;
  final String username;
  final int totalXp;
}
