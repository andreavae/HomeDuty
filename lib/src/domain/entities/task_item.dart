import '../enums/task_recurrence.dart';
import '../enums/task_status.dart';

class TaskItem {
  const TaskItem({
    required this.id,
    required this.householdId,
    required this.title,
    required this.description,
    required this.xp,
    required this.assignedUserId,
    required this.dueDate,
    required this.status,
    required this.recurrence,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String householdId;
  final String title;
  final String description;
  final int xp;
  final String? assignedUserId;
  final DateTime? dueDate;
  final TaskStatus status;
  final TaskRecurrence recurrence;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
}
