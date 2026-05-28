import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/household_state.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: leaderboardAsync.when(
        data: (rows) {
          if (rows.isEmpty) return const Center(child: Text('Nessun dato leaderboard.'));
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              final rank = index + 1;
              return ListTile(
                leading: CircleAvatar(child: Text('$rank')),
                title: Text(row.username),
                trailing: Text('${row.totalXp} XP'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore leaderboard: $e')),
      ),
    );
  }
}
