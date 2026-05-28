import '../../domain/entities/app_user.dart';

AppUser appUserFromMap(Map<String, dynamic> map) {
  return AppUser(
    id: map['id'] as String,
    username: map['username'] as String,
    displayName: (map['display_name'] as String?) ?? map['username'] as String,
    totalXp: (map['total_xp'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
