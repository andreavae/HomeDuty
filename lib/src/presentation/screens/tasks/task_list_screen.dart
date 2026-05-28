import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/repositories_providers.dart';
import '../../../domain/entities/task_item.dart';
import '../../../domain/enums/task_status.dart';
import '../../state/task_state.dart';
import 'task_form_screen.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  Future<void> _openForm(BuildContext context, {TaskItem? task}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(initialTask: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(filteredTasksProvider);
    final filter = ref.watch(taskFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<TaskFilter>(
              value: filter,
              onChanged: (value) {
                if (value != null) {
                  ref.read(taskFilterProvider.notifier).state = value;
                }
              },
              items: const [
                DropdownMenuItem(value: TaskFilter.all, child: Text('All')),
                DropdownMenuItem(value: TaskFilter.todo, child: Text('Todo')),
                DropdownMenuItem(value: TaskFilter.inProgress, child: Text('In Progress')),
                DropdownMenuItem(value: TaskFilter.completed, child: Text('Completed')),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) return const Center(child: Text('No tasks found.'));

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(task.title),
                  subtitle: Text('${task.description}\n${task.xp} XP'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          await _openForm(context, task: task);
                          break;
                        case 'delete':
                          await ref.read(taskRepositoryProvider).deleteTask(task.id);
                          break;
                        case 'complete':
                          await ref.read(taskRepositoryProvider).completeTask(task);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      if (task.status != TaskStatus.completed)
                        const PopupMenuItem(value: 'complete', child: Text('Complete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading tasks: $e')),
      ),
    );
  }
}
