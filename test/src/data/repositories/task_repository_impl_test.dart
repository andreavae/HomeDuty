import 'package:flutter_test/flutter_test.dart';
import 'package:home_duty/src/data/repositories/task_repository_impl.dart';
import 'package:home_duty/src/domain/entities/task_completion.dart';
import 'package:home_duty/src/domain/entities/task_item.dart';
import 'package:home_duty/src/domain/enums/task_recurrence.dart';
import 'package:home_duty/src/domain/enums/task_status.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockPostgrestQueryBuilder extends Mock implements PostgrestQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder {}

void main() {
  group('TaskRepositoryImpl', () {
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;
    late MockUser mockUser;
    late TaskRepositoryImpl taskRepository;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockUser = MockUser();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-123');

      taskRepository = TaskRepositoryImpl(mockClient);
    });

    test('createTask inserts task with correct parameters', () async {
      final mockQueryBuilder = MockPostgrestQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();
      final dueDate = DateTime(2026, 12, 31);

      when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);

      await taskRepository.createTask(
        householdId: 'household-123',
        title: 'Clean kitchen',
        description: 'Clean and organize kitchen',
        xp: 50,
        assignedUserId: 'user-456',
        dueDate: dueDate,
        recurrence: TaskRecurrence.weekly,
      );

      final captured = verify(
        () => mockClient.from('tasks').insert(captureAny()),
      ).captured.single as Map<String, dynamic>;

      expect(captured['household_id'], 'household-123');
      expect(captured['status'], 'todo');
      expect(captured['recurrence'], 'weekly');
      expect(captured['created_by'], 'user-123');
    });

    test('createTask with no assignment and due date', () async {
      final mockQueryBuilder = MockPostgrestQueryBuilder();

      when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.insert(any())).thenReturn(mockQueryBuilder);

      await taskRepository.createTask(
        householdId: 'household-123',
        title: 'Clean bathroom',
        description: 'Clean bathroom',
        xp: 30,
        assignedUserId: null,
        dueDate: null,
        recurrence: TaskRecurrence.none,
      );

      verify(() => mockClient.from('tasks').insert(any())).called(1);
    });

    test('updateTask updates task with new values', () async {
      final mockQueryBuilder = MockPostgrestQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq('id', 'task-123'))
          .thenReturn(mockFilterBuilder);

      await taskRepository.updateTask(
        taskId: 'task-123',
        title: 'Updated task',
        description: 'Updated description',
        xp: 100,
        assignedUserId: 'user-789',
        dueDate: DateTime(2026, 12, 25),
        status: TaskStatus.inProgress,
        recurrence: TaskRecurrence.daily,
      );

      final captured = verify(
        () => mockClient.from('tasks').update(captureAny()),
      ).captured.single as Map<String, dynamic>;

      expect(captured['status'], 'in_progress');
      expect(captured['recurrence'], 'daily');
    });

    test('deleteTask removes task from database', () async {
      final mockQueryBuilder = MockPostgrestQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq('id', 'task-123'))
          .thenReturn(mockFilterBuilder);

      await taskRepository.deleteTask('task-123');

      verify(() => mockClient.from('tasks').delete()).called(1);
    });

    test('completeTask calls RPC function with correct parameters', () async {
      final now = DateTime.now();
      final task = TaskItem(
        id: 'task-123',
        householdId: 'household-123',
        title: 'Test task',
        description: 'Test',
        xp: 50,
        status: TaskStatus.todo,
        assignedUserId: 'user-456',
        createdBy: 'user-789',
        dueDate: null,
        recurrence: TaskRecurrence.none,
        createdAt: now,
        updatedAt: now,
      );

      when(() => mockClient.rpc('complete_task', params: {
            'p_task_id': 'task-123',
            'p_completed_by': 'user-123',
          })).thenAnswer((_) async => null);

      await taskRepository.completeTask(task);

      verify(
        () => mockClient.rpc('complete_task', params: {
          'p_task_id': 'task-123',
          'p_completed_by': 'user-123',
        }),
      ).called(1);
    });

    test('completeTask skips if task already completed', () async {
      final now = DateTime.now();
      final task = TaskItem(
        id: 'task-123',
        householdId: 'household-123',
        title: 'Test task',
        description: 'Test',
        xp: 50,
        status: TaskStatus.completed,
        assignedUserId: 'user-456',
        createdBy: 'user-789',
        dueDate: null,
        recurrence: TaskRecurrence.none,
        createdAt: now,
        updatedAt: now,
      );

      await taskRepository.completeTask(task);

      verifyNever(() => mockClient.rpc(any(), params: any()));
    });

    test('getCompletionsHistory returns list of completions', () async {
      final mockQueryBuilder = MockPostgrestQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();

      final completions = [
        {
          'id': 'completion-1',
          'task_id': 'task-123',
          'completed_by': 'user-456',
          'gained_xp': 50,
          'completed_at': DateTime.now().toIso8601String(),
          'task': {
            'household_id': 'household-123',
          }
        },
        {
          'id': 'completion-2',
          'task_id': 'task-124',
          'completed_by': 'user-789',
          'gained_xp': 75,
          'completed_at': DateTime.now().toIso8601String(),
          'task': {
            'household_id': 'household-123',
          }
        },
      ];

      when(() => mockClient.from('task_completions'))
          .thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.select(any())).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq('task.household_id', 'household-123'))
          .thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.order('completed_at', ascending: false))
          .thenAnswer((_) async => completions);

      final result =
          await taskRepository.getCompletionsHistory('household-123');

      expect(result, isA<List<TaskCompletion>>());
      expect(result.length, 2);
      expect(result.first.id, 'completion-1');
    });

    test('getCompletionsHistory returns empty list when no completions',
        () async {
      final mockQueryBuilder = MockPostgrestQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(() => mockClient.from('task_completions'))
          .thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.select(any())).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq('task.household_id', 'household-123'))
          .thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.order('completed_at', ascending: false))
          .thenAnswer((_) async => []);

      final result =
          await taskRepository.getCompletionsHistory('household-123');

      expect(result, isEmpty);
    });
  });
}
