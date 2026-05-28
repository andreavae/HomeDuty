import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/task_completion.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/enums/task_recurrence.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/repositories/task_repository.dart';
import '../mappers/task_mapper.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Utente non autenticato.');
    return id;
  }

  @override
  Stream<List<TaskItem>> watchTasks(String householdId) {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('household_id', householdId)
        .order('due_date', ascending: true)
        .map((rows) => rows.map(taskFromMap).toList());
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
  }) async {
    await _client.from('tasks').insert({
      'household_id': householdId,
      'title': title,
      'description': description,
      'xp': xp,
      'assigned_user_id': assignedUserId,
      'due_date': dueDate?.toIso8601String(),
      'status': TaskStatus.todo.dbValue,
      'recurrence': recurrence.dbValue,
      'created_by': _userId,
    });
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
  }) async {
    await _client.from('tasks').update({
      'title': title,
      'description': description,
      'xp': xp,
      'assigned_user_id': assignedUserId,
      'due_date': dueDate?.toIso8601String(),
      'status': status.dbValue,
      'recurrence': recurrence.dbValue,
    }).eq('id', taskId);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  @override
  Future<void> completeTask(TaskItem task) async {
    if (task.status == TaskStatus.completed) return;

    await _client.rpc('complete_task', params: {
      'p_task_id': task.id,
      'p_completed_by': _userId,
    });
  }

  @override
  Future<List<TaskCompletion>> getCompletionsHistory(String householdId) async {
    final rows = await _client
        .from('task_completions')
        .select('''
          id,
          task_id,
          completed_by,
          gained_xp,
          completed_at,
          task:tasks!inner(household_id)
        ''')
        .eq('task.household_id', householdId)
        .order('completed_at', ascending: false);

    return rows.map((e) {
      final map = Map<String, dynamic>.from(e);
      map.remove('task');
      return completionFromMap(map);
    }).toList();
  }
}
