import '../entities/task_completion.dart';
import '../entities/task_item.dart';
import '../enums/task_recurrence.dart';
import '../enums/task_status.dart';

abstract class TaskRepository {
  Stream<List<TaskItem>> watchTasks(String householdId);
  Future<void> createTask({
    required String householdId,
    required String title,
    required String description,
    required int xp,
    required String? assignedUserId,
    required DateTime? dueDate,
    required TaskRecurrence recurrence,
  });
  Future<void> updateTask({
    required String taskId,
    required String title,
    required String description,
    required int xp,
    required String? assignedUserId,
    required DateTime? dueDate,
    required TaskStatus status,
    required TaskRecurrence recurrence,
  });
  Future<void> deleteTask(String taskId);
  Future<void> completeTask(TaskItem task);
  Future<List<TaskCompletion>> getCompletionsHistory(String householdId);
}
