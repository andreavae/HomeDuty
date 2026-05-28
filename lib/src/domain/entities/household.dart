class Household {
  const Household({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;
}
