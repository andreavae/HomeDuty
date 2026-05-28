import '../../domain/entities/app_user.dart';
import '../../domain/entities/household.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/household_repository.dart';
import '../mappers/household_mapper.dart';
import '../repositories/household_repository_impl.dart';
import '../rest/supabase_rest_client.dart';

class HouseholdRepositoryRestEval implements HouseholdRepository {
  HouseholdRepositoryRestEval({
    required SupabaseRestClient restClient,
    required HouseholdRepositoryImpl fallback,
  })  : _restClient = restClient,
        _fallback = fallback;

  final SupabaseRestClient _restClient;
  final HouseholdRepositoryImpl _fallback;

  @override
  Future<Household?> getCurrentHousehold() async {
    final userId = _restClient.userId;

    final links = await _restClient.getList(
      'household_members',
      query: {
        'user_id': 'eq.$userId',
        'select': 'household_id',
        'limit': '1',
      },
    );

    if (links.isEmpty) return null;
    final householdId = links.first['household_id'] as String?;
    if (householdId == null) return null;

    final households = await _restClient.getList(
      'households',
      query: {
        'id': 'eq.$householdId',
        'select': '*',
        'limit': '1',
      },
    );

    if (households.isEmpty) return null;
    return householdFromMap(households.first);
  }

  @override
  Stream<Household?> watchCurrentHousehold() {
    return _fallback.watchCurrentHousehold();
  }

  @override
  Future<void> createHousehold(String name) async {
    final userId = _restClient.userId;

    final created = await _restClient.postReturningList('households', {
      'name': name,
      'owner_id': userId,
    });

    if (created.isEmpty || created.first['id'] == null) {
      throw Exception('Household creation returned no id.');
    }

    final householdId = created.first['id'] as String;

    await _restClient.postReturningList('household_members', {
      'household_id': householdId,
      'user_id': userId,
      'role': 'owner',
    });
  }

  @override
  Future<void> joinHousehold(String householdId) {
    return _fallback.joinHousehold(householdId);
  }

  @override
  Future<List<AppUser>> getHouseholdMembers(String householdId) {
    return _fallback.getHouseholdMembers(householdId);
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard(String householdId) {
    return _fallback.getLeaderboard(householdId);
  }
}
