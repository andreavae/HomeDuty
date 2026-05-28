import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/household.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/household_repository.dart';
import '../mappers/household_mapper.dart';
import '../mappers/user_mapper.dart';

class HouseholdRepositoryImpl implements HouseholdRepository {
  HouseholdRepositoryImpl(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Utente non autenticato.');
    return id;
  }

  @override
  Future<Household?> getCurrentHousehold() async {
    final relation = await _client
        .from('household_members')
        .select('household_id')
        .eq('user_id', _userId)
        .maybeSingle();

    if (relation == null) return null;

    final household = await _client
        .from('households')
        .select()
        .eq('id', relation['household_id'])
        .maybeSingle();

    if (household == null) return null;
    return householdFromMap(household);
  }

  @override
  Stream<Household?> watchCurrentHousehold() {
    return _client
        .from('household_members')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .asyncMap((rows) async {
          if (rows.isEmpty) return null;
          final householdId = rows.first['household_id'] as String;
          final household = await _client
              .from('households')
              .select()
              .eq('id', householdId)
              .maybeSingle();
          if (household == null) return null;
          return householdFromMap(household);
        });
  }

  @override
  Future<void> createHousehold(String name) async {
    final map = await _client
        .from('households')
        .insert({'name': name, 'owner_id': _userId})
        .select()
        .single();

    await _client.from('household_members').insert({
      'household_id': map['id'],
      'user_id': _userId,
      'role': 'owner',
    });
  }

  @override
  Future<void> joinHousehold(String householdId) async {
    await _client.from('household_members').insert({
      'household_id': householdId,
      'user_id': _userId,
      'role': 'member',
    });
  }

  @override
  Future<List<AppUser>> getHouseholdMembers(String householdId) async {
    final rows = await _client.from('household_members').select('''
          user:users (
            id,
            username,
            display_name,
            total_xp,
            created_at
          )
        ''').eq('household_id', householdId);

    return rows
        .map((e) => appUserFromMap((e['user'] as Map<String, dynamic>)))
        .toList();
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard(String householdId) async {
    final members = await getHouseholdMembers(householdId);
    members.sort((a, b) => b.totalXp.compareTo(a.totalXp));

    return members
        .map(
          (u) => LeaderboardEntry(
            userId: u.id,
            username: u.username,
            totalXp: u.totalXp,
          ),
        )
        .toList();
  }
}
