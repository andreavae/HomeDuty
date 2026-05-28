import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../mappers/user_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  String _emailFromUsername(String username) {
    final normalized = username.trim().toLowerCase();
    return '$normalized@homeduty.local';
  }

  @override
  bool get isAuthenticated => _client.auth.currentSession != null;

  @override
  Future<AppUser?> getCurrentUserProfile() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    final map = await _client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (map == null) return null;
    return appUserFromMap(map);
  }

  @override
  Stream<AppUser?> watchCurrentUserProfile() {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return Stream.value(null);

    final stream = _client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', authUser.id)
        .map((rows) {
          if (rows.isEmpty) return null;
          return appUserFromMap(rows.first);
        });

    return stream;
  }

  @override
  Future<void> register({
    required String username,
    required String password,
    required String displayName,
  }) async {
    final email = _emailFromUsername(username);
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'display_name': displayName,
      },
    );

    final user = res.user;
    if (user == null) {
      throw Exception('Registrazione fallita: utente non creato.');
    }

    await _client.from('users').upsert({
      'id': user.id,
      'username': username,
      'display_name': displayName,
      'total_xp': 0,
    });
  }

  @override
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final email = _emailFromUsername(username);
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
