import '../entities/household.dart';
import '../entities/leaderboard_entry.dart';
import '../entities/app_user.dart';

abstract class HouseholdRepository {
  Future<Household?> getCurrentHousehold();
  Stream<Household?> watchCurrentHousehold();
  Future<void> createHousehold(String name);
  Future<void> joinHousehold(String householdId);
  Future<List<AppUser>> getHouseholdMembers(String householdId);
  Future<List<LeaderboardEntry>> getLeaderboard(String householdId);
}
