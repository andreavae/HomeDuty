import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/repositories_providers.dart';
import '../../domain/entities/task_completion.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/enums/task_status.dart';
import 'household_state.dart';

enum TaskFilter { all, todo, inProgress, completed }

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

final tasksProvider = StreamProvider<List<TaskItem>>((ref) async* {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    yield [];
    return;
  }

  yield* ref.watch(taskRepositoryProvider).watchTasks(household.id);
});

final filteredTasksProvider = Provider<AsyncValue<List<TaskItem>>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  final filter = ref.watch(taskFilterProvider);

  return tasksAsync.whenData((tasks) {
    switch (filter) {
      case TaskFilter.todo:
        return tasks.where((t) => t.status == TaskStatus.todo).toList();
      case TaskFilter.inProgress:
        return tasks.where((t) => t.status == TaskStatus.inProgress).toList();
      case TaskFilter.completed:
        return tasks.where((t) => t.status == TaskStatus.completed).toList();
      case TaskFilter.all:
        return tasks;
    }
  });
});

final completionHistoryProvider = FutureProvider<List<TaskCompletion>>((ref) async {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) return [];

  return ref.watch(taskRepositoryProvider).getCompletionsHistory(household.id);
});
