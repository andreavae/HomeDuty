import '../../domain/entities/task_completion.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/enums/task_recurrence.dart';
import '../../domain/enums/task_status.dart';

TaskItem taskFromMap(Map<String, dynamic> map) {
  return TaskItem(
    id: map['id'] as String,
    householdId: map['household_id'] as String,
    title: map['title'] as String,
    description: (map['description'] as String?) ?? '',
    xp: (map['xp'] as num).toInt(),
    assignedUserId: map['assigned_user_id'] as String?,
    dueDate: map['due_date'] == null
        ? null
        : DateTime.parse(map['due_date'] as String),
    status: TaskStatusX.fromDb(map['status'] as String),
    recurrence: TaskRecurrenceX.fromDb(map['recurrence'] as String),
    createdBy: map['created_by'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );
}

TaskCompletion completionFromMap(Map<String, dynamic> map) {
  return TaskCompletion(
    id: map['id'] as String,
    taskId: map['task_id'] as String,
    completedBy: map['completed_by'] as String,
    gainedXp: (map['gained_xp'] as num).toInt(),
    completedAt: DateTime.parse(map['completed_at'] as String),
  );
}
