import '../../domain/entities/task_completion.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/enums/task_recurrence.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/repositories/task_repository.dart';
import '../mappers/task_mapper.dart';
import '../repositories/task_repository_impl.dart';
import '../rest/supabase_rest_client.dart';

class TaskRepositoryRestEval implements TaskRepository {
  TaskRepositoryRestEval({
    required SupabaseRestClient restClient,
    required TaskRepositoryImpl fallback,
  })  : _restClient = restClient,
        _fallback = fallback;

  final SupabaseRestClient _restClient;
  final TaskRepositoryImpl _fallback;

  @override
  Stream<List<TaskItem>> watchTasks(String householdId) async* {
    while (true) {
      final rows = await _restClient.getList(
        'tasks',
        query: {
          'household_id': 'eq.$householdId',
          'select': '*',
          'order': 'due_date.asc',
        },
      );

      yield rows.map(taskFromMap).toList(growable: false);
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }

  @override
  Future<void> createTask({
    required String householdId,
    required String title,
    required String description,
    required int xp,
    required String? assignedUserId,
    required DateTime? dueDate,
    required TaskRecurrence recurrence,
  }) {
    return _fallback.createTask(
      householdId: householdId,
      title: title,
      description: description,
      xp: xp,
      assignedUserId: assignedUserId,
      dueDate: dueDate,
      recurrence: recurrence,
    );
  }

  @override
  Future<void> updateTask({
    required String taskId,
    required String title,
    required String description,
    required int xp,
    required String? assignedUserId,
    required DateTime? dueDate,
    required TaskStatus status,
    required TaskRecurrence recurrence,
  }) {
    return _fallback.updateTask(
      taskId: taskId,
      title: title,
      description: description,
      xp: xp,
      assignedUserId: assignedUserId,
      dueDate: dueDate,
      status: status,
      recurrence: recurrence,
    );
  }

  @override
  Future<void> deleteTask(String taskId) {
    return _fallback.deleteTask(taskId);
  }

  @override
  Future<void> completeTask(TaskItem task) {
    return _fallback.completeTask(task);
  }

  @override
  Future<List<TaskCompletion>> getCompletionsHistory(String householdId) {
    return _fallback.getCompletionsHistory(householdId);
  }
}
