import 'package:flutter/material.dart';
import 'package:sla_tracker/models/team_member.dart';
import 'package:sla_tracker/screens/sign_in_screen.dart';
import 'package:sla_tracker/screens/task_list_screen.dart';

class MainShell extends StatefulWidget {
  final TeamMember currentUser;
  const MainShell({super.key, required this.currentUser});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 1; // start on the Tasks tab
  static const _titles = ['Home', 'Tasks', 'Team', 'Profile'];

  void _signOut() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _PlaceholderTab(label: 'Home tab\nWelcome, ${widget.currentUser.name}'),
      const TaskListScreen(),
      const _PlaceholderTab(label: 'Team tab'),
      _PlaceholderTab(
        label: 'Profile tab\nSigned in as ${widget.currentUser.name}',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.group), label: 'Team'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String label;
  const _PlaceholderTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}
