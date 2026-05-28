import 'package:flutter_test/flutter_test.dart';
import 'package:home_duty/src/data/repositories/auth_repository_impl.dart';
import 'package:home_duty/src/domain/entities/app_user.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseAuth extends Mock implements GoTrueClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class MockUser extends Mock implements User {
  MockUser({required this.id, this.userMetadata});

  @override
  final String id;

  @override
  final Map<String, dynamic>? userMetadata;
}

class MockSession extends Mock implements Session {}

class MockPostgrestQueryBuilder extends Mock implements PostgrestQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder {}

void main() {
  group('AuthRepositoryImpl', () {
    late MockSupabaseClient mockClient;
    late MockSupabaseAuth mockAuth;
    late AuthRepositoryImpl authRepository;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockSupabaseAuth();
      when(() => mockClient.auth).thenReturn(mockAuth);
      authRepository = AuthRepositoryImpl(mockClient);
    });

    test('isAuthenticated returns true when session exists', () {
      final mockSession = MockSession();
      when(() => mockAuth.currentSession).thenReturn(mockSession);

      expect(authRepository.isAuthenticated, isTrue);
    });

    test('isAuthenticated returns false when no session', () {
      when(() => mockAuth.currentSession).thenReturn(null);

      expect(authRepository.isAuthenticated, isFalse);
    });

    test('getCurrentUserProfile returns null when user not authenticated',
        () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await authRepository.getCurrentUserProfile();

      expect(result, isNull);
    });

    test(
        'getCurrentUserProfile returns user when authenticated and profile exists',
        () async {
      final createdAt = DateTime(2026, 1, 1).toIso8601String();
      final mockUser = MockUser(
        id: 'user-123',
        userMetadata: {'username': 'testuser', 'display_name': 'Test User'},
      );
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final mockQueryBuilder = MockPostgrestQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(() => mockClient.from('users')).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq('id', 'user-123'))
          .thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.maybeSingle()).thenAnswer(
        (_) async => {
          'id': 'user-123',
          'username': 'testuser',
          'display_name': 'Test User',
          'total_xp': 100,
          'created_at': createdAt,
        },
      );

      final result = await authRepository.getCurrentUserProfile();

      expect(result, isA<AppUser>());
      expect(result?.id, 'user-123');
      expect(result?.username, 'testuser');
    });

    test('watchCurrentUserProfile emits null when not authenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final stream = authRepository.watchCurrentUserProfile();

      await expectLater(stream, emits(null));
    });

    test('logout delegates to Supabase auth signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await authRepository.logout();

      verify(() => mockAuth.signOut()).called(1);
    });
  });
}
