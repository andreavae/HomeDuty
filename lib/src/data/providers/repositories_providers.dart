import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_client_provider.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/household_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../repositories/auth_repository_impl.dart';
import '../repositories/household_repository_impl.dart';
import '../repositories/household_repository_rest_eval.dart';
import '../repositories/task_repository_impl.dart';
import '../repositories/task_repository_rest_eval.dart';
import '../rest/supabase_rest_client.dart';

const _useRestEval = bool.fromEnvironment('USE_REST_EVAL', defaultValue: false);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(supabaseClientProvider));
});

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final fallback = HouseholdRepositoryImpl(client);

  if (!_useRestEval) return fallback;

  return HouseholdRepositoryRestEval(
    restClient: SupabaseRestClient(client),
    fallback: fallback,
  );
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final fallback = TaskRepositoryImpl(client);

  if (!_useRestEval) return fallback;

  return TaskRepositoryRestEval(
    restClient: SupabaseRestClient(client),
    fallback: fallback,
  );
});
