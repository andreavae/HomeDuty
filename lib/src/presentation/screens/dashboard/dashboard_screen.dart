import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums/task_status.dart';
import '../../state/household_state.dart';
import '../../state/task_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final householdAsync = ref.watch(currentHouseholdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          householdAsync.when(
            data: (household) => Text(
              household == null
                  ? 'No household selected'
                  : 'Household: ${household.name} (${household.id})',
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Household error: $e'),
          ),
          const SizedBox(height: 16),
          const Text('Today\'s tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          tasksAsync.when(
            data: (tasks) {
              final today = DateTime.now();
              final daily = tasks.where((t) {
                if (t.status == TaskStatus.completed) return false;
                if (t.dueDate == null) return false;
                return t.dueDate!.year == today.year &&
                    t.dueDate!.month == today.month &&
                    t.dueDate!.day == today.day;
              }).toList();

              if (daily.isEmpty) return const Text('No tasks due today.');

              return Column(
                children: daily
                    .map(
                      (t) => Card(
                        child: ListTile(
                          title: Text(t.title),
                          subtitle: Text('${t.xp} XP'),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Task error: $e'),
          ),
          const SizedBox(height: 24),
          const Text('Top leaderboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          leaderboardAsync.when(
            data: (rows) {
              if (rows.isEmpty) return const Text('No members found.');
              return Column(
                children: rows.take(3).toList().asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final row = entry.value;
                  return ListTile(
                    leading: CircleAvatar(child: Text('$i')),
                    title: Text(row.username),
                    trailing: Text('${row.totalXp} XP'),
                  );
                }).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Leaderboard error: $e'),
          ),
        ],
      ),
    );
  }
}
