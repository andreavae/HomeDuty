import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/repositories_providers.dart';
import '../../domain/entities/app_user.dart';

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUserProfile();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authRepositoryProvider).isAuthenticated;
});
