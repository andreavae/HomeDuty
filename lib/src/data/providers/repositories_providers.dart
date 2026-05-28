import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_client_provider.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/household_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../repositories/auth_repository_impl.dart';
import '../repositories/household_repository_impl.dart';
import '../repositories/task_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(supabaseClientProvider));
});

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepositoryImpl(ref.watch(supabaseClientProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(ref.watch(supabaseClientProvider));
});
