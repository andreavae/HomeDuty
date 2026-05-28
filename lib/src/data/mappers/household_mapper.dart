import '../../domain/entities/household.dart';

Household householdFromMap(Map<String, dynamic> map) {
  return Household(
    id: map['id'] as String,
    name: map['name'] as String,
    ownerId: map['owner_id'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
