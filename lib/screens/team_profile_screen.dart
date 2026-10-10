import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/team_member.dart';
import '../services/storage_service.dart';

class TeamProfileScreen extends StatefulWidget {
  const TeamProfileScreen({super.key});

  @override
  State<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends State<TeamProfileScreen> {
  final storage = StorageService();

  List<TeamMember> members = [];
  List<Task> tasks = [];

  final colors = [
    Colors.blue,
    Colors.teal,
    Colors.deepOrange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final loadedMembers = await storage.loadMembers();
    final loadedTasks = await storage.loadTasks();

    if (!mounted) return;

    setState(() {
      members = loadedMembers;
      tasks = loadedTasks;
    });
  }

  List<Task> memberTasks(TeamMember member) {
    return tasks.where((task) => task.assigneeId == member.id).toList();
  }

  int openCount(TeamMember member) {
    return memberTasks(member).where((task) => !task.isCompleted).length;
  }

  double progress(TeamMember member) {
    final assigned = memberTasks(member);

    if (assigned.isEmpty) return 0;

    final completed = assigned.where((task) => task.isCompleted).length;
    return completed / assigned.length;
  }

  Widget avatar(TeamMember member) {
    final index = members.indexOf(member);

    return CircleAvatar(
      backgroundColor: colors[index % colors.length],
      child: Text(
        member.name.isEmpty ? '?' : member.name[0].toUpperCase(),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  void showTasks(TeamMember member) {
    final assigned = memberTasks(member);

    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "${member.name}'s tasks",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (assigned.isEmpty) const Text('No tasks assigned yet.'),
          ...assigned.map(
            (task) => ListTile(
              title: Text(task.title),
              subtitle: Text(
                task.isCompleted ? 'Completed' : 'Open',
              ),
              trailing: Text(task.priority.name),
            ),
          ),
        ],
      ),
    );
  }

  void signOut() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign-out is not connected yet.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team & Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final me = members.first;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Team & Profile'),
        backgroundColor: const Color(0xFFF5F7FA),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFF14213D),
            child: ListTile(
              leading: avatar(me),
              title: Text(
                me.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Team member',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Team members',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...members.skip(1).map(
            (member) => Card(
              child: ListTile(
                onTap: () => showTasks(member),
                leading: avatar(member),
                title: Text(member.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${openCount(member)} open tasks'),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: progress(member)),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),

          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}