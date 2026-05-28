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
      appBar: AppBar(title: const Text('Profilo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          userAsync.when(
            data: (user) {
              if (user == null) return const Text('Profilo non disponibile.');
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
                      Text('XP totali: ${user.totalXp}'),
                      Text('Livello: $level'),
                      Text('XP al prossimo livello: $xpLeft'),
                    ],
                  ),
                ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Errore profilo: $e'),
          ),
          const SizedBox(height: 12),
          const Text('Tema'),
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
          const Text('Storico completamenti'),
          historyAsync.when(
            data: (rows) {
              if (rows.isEmpty) return const Text('Nessun completamento.');
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
                      child: Text('Completamenti: $totalCompleted | XP guadagnati: $totalGainedXp'),
                    ),
                  ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Errore storico: $e'),
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
