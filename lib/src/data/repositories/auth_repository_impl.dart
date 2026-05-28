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
    final encoded = normalized.codeUnits
        .map((unit) => unit.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'u$encoded@homeduty.app';
  }

  @override
  bool get isAuthenticated => _client.auth.currentSession != null;

  @override
  Future<AppUser?> getCurrentUserProfile() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    var map = await _client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (map == null) {
      await _ensureProfileForUser(authUser);
      map = await _client
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();
    }

    if (map == null) return null;
    return appUserFromMap(map);
  }

  Future<void> _ensureProfileForUser(
    User authUser, {
    String? fallbackUsername,
    String? fallbackDisplayName,
  }) async {
    final existing = await _client
        .from('users')
        .select('id')
        .eq('id', authUser.id)
        .maybeSingle();
    if (existing != null) return;

    final meta = authUser.userMetadata ?? <String, dynamic>{};
    final username = (meta['username'] as String?) ?? fallbackUsername;
    final displayName =
        (meta['display_name'] as String?) ?? fallbackDisplayName ?? username;

    if (username == null || username.trim().isEmpty) {
      throw Exception('Cannot create user profile: username is missing.');
    }

    await _client.from('users').upsert({
      'id': authUser.id,
      'username': username,
      'display_name': (displayName == null || displayName.trim().isEmpty)
          ? username
          : displayName,
      'total_xp': 0,
    });
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

    if (res.session == null) {
      throw Exception(
        'Registration completed but no active session was created. '
        'Confirm your email (if enabled) and then login, or disable email confirmation in Supabase Auth settings.',
      );
    }

    // With email confirmation enabled, Supabase may return no active session.
    // In that case RLS may block profile creation until first confirmed login.
    await _ensureProfileForUser(
      user,
      fallbackUsername: username,
      fallbackDisplayName: displayName,
    );
  }

  @override
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final email = _emailFromUsername(username);
    final res =
        await _client.auth.signInWithPassword(email: email, password: password);
    final user = res.user;
    if (user != null) {
      await _ensureProfileForUser(
        user,
        fallbackUsername: username,
        fallbackDisplayName: username,
      );
    }
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
