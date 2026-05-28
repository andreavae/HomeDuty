import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../profile/profile_screen.dart';
import '../tasks/task_list_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    TaskListScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Leaderboard'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profilo'),
        ],
      ),
    );
  }
}
