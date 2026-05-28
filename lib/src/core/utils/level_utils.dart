int levelFromXp(int xp) {
  if (xp <= 0) return 1;
  return (xp ~/ 100) + 1;
}

int xpToNextLevel(int xp) {
  final nextLevelXp = levelFromXp(xp) * 100;
  return nextLevelXp - xp;
}
