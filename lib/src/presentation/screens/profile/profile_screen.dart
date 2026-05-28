import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/level_utils.dart';
import '../../../data/providers/repositories_providers.dart';
import '../../state/auth_state.dart';
import '../../state/task_state.dart';
import '../../theme/theme_mode_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final historyAsync = ref.watch(completionHistoryProvider);
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          userAsync.when(
            data: (user) {
              if (user == null) return const Text('Profile not available.');
              final level = levelFromXp(user.totalXp);
              final xpLeft = xpToNextLevel(user.totalXp);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName, style: Theme.of(context).textTheme.titleLarge),
                      Text('@${user.username}'),
                      const SizedBox(height: 8),
                      Text('Total XP: ${user.totalXp}'),
                      Text('Level: $level'),
                      Text('XP to next level: $xpLeft'),
                    ],
                  ),
                ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Profile error: $e'),
          ),
          const SizedBox(height: 12),
          const Text('Theme'),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {mode},
            onSelectionChanged: (value) {
              ref.read(themeModeProvider.notifier).setMode(value.first);
            },
          ),
          const SizedBox(height: 16),
          const Text('Completion history'),
          historyAsync.when(
            data: (rows) {
              if (rows.isEmpty) return const Text('No completions yet.');
              final totalCompleted = rows.length;
              final totalGainedXp = rows.fold<int>(0, (sum, row) => sum + row.gainedXp);
              final historyTiles = rows.take(10).map<Widget>((e) {
                return ListTile(
                  dense: true,
                  title: Text('Task ${e.taskId}'),
                  subtitle: Text(e.completedAt.toLocal().toString()),
                  trailing: Text('+${e.gainedXp} XP'),
                );
              }).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: historyTiles
                  ..insert(
                    0,
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Completions: $totalCompleted | XP earned: $totalGainedXp'),
                    ),
                  ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('History error: $e'),
          ),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
