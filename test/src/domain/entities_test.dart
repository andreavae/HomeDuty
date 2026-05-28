import 'package:flutter_test/flutter_test.dart';
import 'package:home_duty/src/domain/entities/app_user.dart';
import 'package:home_duty/src/domain/entities/household.dart';
import 'package:home_duty/src/domain/entities/task_item.dart';
import 'package:home_duty/src/domain/enums/task_recurrence.dart';
import 'package:home_duty/src/domain/enums/task_status.dart';

void main() {
  group('AppUser', () {
    test('creates instance with all properties', () {
      final now = DateTime.now();
      final user = AppUser(
        id: 'user-123',
        username: 'john_doe',
        displayName: 'John Doe',
        totalXp: 500,
        createdAt: now,
      );

      expect(user.id, 'user-123');
      expect(user.username, 'john_doe');
      expect(user.displayName, 'John Doe');
      expect(user.totalXp, 500);
      expect(user.createdAt, now);
    });
  });

  group('Household', () {
    test('Household creates instance with properties', () {
      final now = DateTime.now();
      final household = Household(
        id: 'household-123',
        name: 'My Home',
        ownerId: 'user-123',
        createdAt: now,
      );

      expect(household.id, 'household-123');
      expect(household.name, 'My Home');
      expect(household.ownerId, 'user-123');
      expect(household.createdAt, now);
    });
  });

  group('TaskItem', () {
    test('creates instance with all properties', () {
      final dueDate = DateTime(2026, 12, 31);
      final createdAt = DateTime.now();
      final updatedAt = DateTime.now();
      final task = TaskItem(
        id: 'task-123',
        householdId: 'household-123',
        title: 'Clean kitchen',
        description: 'Clean and organize',
        xp: 50,
        status: TaskStatus.todo,
        assignedUserId: 'user-456',
        createdBy: 'user-123',
        dueDate: dueDate,
        recurrence: TaskRecurrence.weekly,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(task.id, 'task-123');
      expect(task.householdId, 'household-123');
      expect(task.title, 'Clean kitchen');
      expect(task.xp, 50);
      expect(task.status, TaskStatus.todo);
      expect(task.recurrence, TaskRecurrence.weekly);
      expect(task.updatedAt, updatedAt);
    });

    test('supports null optional fields', () {
      final now = DateTime.now();
      final task = TaskItem(
        id: 'task-456',
        householdId: 'household-123',
        title: 'Unassigned task',
        description: 'No assignment',
        xp: 25,
        status: TaskStatus.todo,
        assignedUserId: null,
        createdBy: 'user-123',
        dueDate: null,
        recurrence: TaskRecurrence.none,
        createdAt: now,
        updatedAt: now,
      );

      expect(task.assignedUserId, isNull);
      expect(task.dueDate, isNull);
    });
  });

  group('TaskStatusX', () {
    test('dbValue maps correctly', () {
      expect(TaskStatus.todo.dbValue, 'todo');
      expect(TaskStatus.inProgress.dbValue, 'in_progress');
      expect(TaskStatus.completed.dbValue, 'completed');
    });

    test('fromDb maps correctly and falls back to todo', () {
      expect(TaskStatusX.fromDb('todo'), TaskStatus.todo);
      expect(TaskStatusX.fromDb('in_progress'), TaskStatus.inProgress);
      expect(TaskStatusX.fromDb('completed'), TaskStatus.completed);
      expect(TaskStatusX.fromDb('unknown'), TaskStatus.todo);
    });
  });

  group('TaskRecurrenceX', () {
    test('dbValue maps correctly', () {
      expect(TaskRecurrence.none.dbValue, 'none');
      expect(TaskRecurrence.daily.dbValue, 'daily');
      expect(TaskRecurrence.weekly.dbValue, 'weekly');
    });

    test('fromDb maps correctly and falls back to none', () {
      expect(TaskRecurrenceX.fromDb('none'), TaskRecurrence.none);
      expect(TaskRecurrenceX.fromDb('daily'), TaskRecurrence.daily);
      expect(TaskRecurrenceX.fromDb('weekly'), TaskRecurrence.weekly);
      expect(TaskRecurrenceX.fromDb('unknown'), TaskRecurrence.none);
    });
  });
}
