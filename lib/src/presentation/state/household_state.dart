import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/repositories_providers.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/household.dart';
import '../../domain/entities/leaderboard_entry.dart';

final currentHouseholdProvider = StreamProvider<Household?>((ref) {
  return ref.watch(householdRepositoryProvider).watchCurrentHousehold();
});

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) return [];
  return ref.watch(householdRepositoryProvider).getLeaderboard(household.id);
});

final householdMembersProvider = FutureProvider<List<AppUser>>((ref) async {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) return [];
  return ref.watch(householdRepositoryProvider).getHouseholdMembers(household.id);
});
