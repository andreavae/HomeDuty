enum TaskStatus {
  todo,
  inProgress,
  completed,
}

extension TaskStatusX on TaskStatus {
  String get dbValue {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
    }
  }

  static TaskStatus fromDb(String value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'todo':
      default:
        return TaskStatus.todo;
    }
  }
}
