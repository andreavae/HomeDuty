import 'package:flutter_test/flutter_test.dart';
import 'package:home_duty/src/data/repositories/household_repository_impl.dart';
import 'package:home_duty/src/domain/entities/household.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockPostgrestQueryBuilder extends Mock implements PostgrestQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder {}

void main() {
  group('HouseholdRepositoryImpl', () {
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;
    late MockUser mockUser;
    late HouseholdRepositoryImpl householdRepository;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockUser = MockUser();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-123');

      householdRepository = HouseholdRepositoryImpl(mockClient);
    });

    test('getCurrentHousehold returns null when user has no household',
        () async {
      final mockQueryBuilder = MockPostgrestQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(() => mockClient.from('household_members'))
          .thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq('user_id', 'user-123'))
          .thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

      final result = await householdRepository.getCurrentHousehold();

      expect(result, isNull);
    });

    test('getCurrentHousehold returns household when user is member', () async {
      final membersQueryBuilder = MockPostgrestQueryBuilder();
      final membersFilterBuilder = MockPostgrestFilterBuilder();
      final householdsQueryBuilder = MockPostgrestQueryBuilder();
      final householdsFilterBuilder = MockPostgrestFilterBuilder();

      when(() => mockClient.from('household_members'))
          .thenReturn(membersQueryBuilder);
      when(() => membersQueryBuilder.select()).thenReturn(membersFilterBuilder);
      when(() => membersFilterBuilder.eq('user_id', 'user-123'))
          .thenReturn(membersFilterBuilder);
      when(() => membersFilterBuilder.maybeSingle()).thenAnswer(
        (_) async => {
          'household_id': 'household-123',
          'user_id': 'user-123',
          'role': 'member',
        },
      );

      when(() => mockClient.from('households'))
          .thenReturn(householdsQueryBuilder);
      when(() => householdsQueryBuilder.select())
          .thenReturn(householdsFilterBuilder);
      when(() => householdsFilterBuilder.eq('id', 'household-123'))
          .thenReturn(householdsFilterBuilder);
      when(() => householdsFilterBuilder.maybeSingle()).thenAnswer(
        (_) async => {
          'id': 'household-123',
          'name': 'My Home',
          'owner_id': 'user-456',
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      final result = await householdRepository.getCurrentHousehold();

      expect(result, isA<Household>());
      expect(result?.id, 'household-123');
      expect(result?.name, 'My Home');
    });

    test('createHousehold creates household and adds user as owner', () async {
      final mockQueryBuilder = MockPostgrestQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(() => mockClient.from('households')).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.insert({
            'name': 'New Home',
            'owner_id': 'user-123',
          })).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.single()).thenAnswer(
        (_) async => {
          'id': 'household-123',
          'name': 'New Home',
          'owner_id': 'user-123',
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      when(() => mockClient.from('household_members'))
          .thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.insert({
            'household_id': 'household-123',
            'user_id': 'user-123',
            'role': 'owner',
          })).thenReturn(mockFilterBuilder);

      await householdRepository.createHousehold('New Home');

      verify(
        () => mockClient.from('household_members').insert({
          'household_id': 'household-123',
          'user_id': 'user-123',
          'role': 'owner',
        }),
      ).called(1);
    });

    test('joinHousehold adds user as member', () async {
      final mockQueryBuilder = MockPostgrestQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(() => mockClient.from('household_members'))
          .thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.insert({
            'household_id': 'household-456',
            'user_id': 'user-123',
            'role': 'member',
          })).thenReturn(mockFilterBuilder);

      await householdRepository.joinHousehold('household-456');

      verify(
        () => mockClient.from('household_members').insert({
          'household_id': 'household-456',
          'user_id': 'user-123',
          'role': 'member',
        }),
      ).called(1);
    });

    test('joinHousehold throws when user is not authenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () => householdRepository.joinHousehold('household-123'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
