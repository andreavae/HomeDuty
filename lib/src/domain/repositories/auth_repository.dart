import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUserProfile();
  Stream<AppUser?> watchCurrentUserProfile();
  Future<void> register({
    required String username,
    required String password,
    required String displayName,
  });
  Future<void> login({
    required String username,
    required String password,
  });
  Future<void> logout();
  bool get isAuthenticated;
}
