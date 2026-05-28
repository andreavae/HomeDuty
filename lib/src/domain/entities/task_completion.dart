class TaskCompletion {
  const TaskCompletion({
    required this.id,
    required this.taskId,
    required this.completedBy,
    required this.gainedXp,
    required this.completedAt,
  });

  final String id;
  final String taskId;
  final String completedBy;
  final int gainedXp;
  final DateTime completedAt;
}
