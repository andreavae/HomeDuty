import 'package:flutter_test/flutter_test.dart';
import 'package:home_duty/src/data/rest/supabase_rest_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}

void main() {
  group('SupabaseRestClient', () {
    late MockSupabaseClient mockSupabase;
    late MockGoTrueClient mockAuth;
    late SupabaseRestClient restClient;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      when(() => mockSupabase.auth).thenReturn(mockAuth);
      restClient = SupabaseRestClient(mockSupabase);
    });

    test('userId returns current user id', () {
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-123');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      expect(restClient.userId, 'user-123');
    });

    test('userId throws exception when user not authenticated', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () => restClient.userId,
        throwsException,
      );
    });

    test('getList throws when SUPABASE_URL is missing', () async {
      final mockUser = MockUser();
      final mockSession = MockSession();

      when(() => mockUser.id).thenReturn('user-123');
      when(() => mockSession.accessToken).thenReturn('token-123');
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockAuth.currentSession).thenReturn(mockSession);

      await expectLater(
        () => restClient.getList('users'),
        throwsA(isA<Exception>()),
      );
    });

    test('postReturningList throws when SUPABASE_URL is missing', () async {
      final mockUser = MockUser();
      final mockSession = MockSession();

      when(() => mockUser.id).thenReturn('user-123');
      when(() => mockSession.accessToken).thenReturn('token-123');
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockAuth.currentSession).thenReturn(mockSession);

      await expectLater(
        () => restClient.postReturningList('users', {'id': 'user-123'}),
        throwsA(isA<Exception>()),
      );
    });
  });
}
