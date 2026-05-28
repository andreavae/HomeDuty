enum TaskRecurrence {
  none,
  daily,
  weekly,
}

extension TaskRecurrenceX on TaskRecurrence {
  String get dbValue {
    switch (this) {
      case TaskRecurrence.none:
        return 'none';
      case TaskRecurrence.daily:
        return 'daily';
      case TaskRecurrence.weekly:
        return 'weekly';
    }
  }

  static TaskRecurrence fromDb(String value) {
    switch (value) {
      case 'daily':
        return TaskRecurrence.daily;
      case 'weekly':
        return TaskRecurrence.weekly;
      case 'none':
      default:
        return TaskRecurrence.none;
    }
  }
}
