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
  String? currentUserId;
  bool loading = true;

  final navy = const Color(0xFF14213D);
  final blue = const Color(0xFF2453D4);
  final colors = [
    const Color(0xFF2453D4),
    const Color(0xFF9B3518),
    const Color(0xFF243F91),
    const Color(0xFF374151),
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final loadedMembers = await storage.loadMembers();
    final loadedTasks = await storage.loadTasks();
    final userId = await storage.getCurrentUserId();

    if (!mounted) return;
    setState(() {
      members = loadedMembers;
      tasks = loadedTasks;
      currentUserId = loadedMembers.any((m) => m.id == userId)
          ? userId
          : (loadedMembers.isEmpty ? null : loadedMembers.first.id);
      loading = false;
    });
  }

  List<Task> memberTasks(TeamMember member) =>
      tasks.where((task) => task.assigneeId == member.id).toList();

  int openCount(TeamMember member) =>
      memberTasks(member).where((task) => !task.isCompleted).length;

  double progress(TeamMember member) {
    final assigned = memberTasks(member);
    if (assigned.isEmpty) return 0;
    final completed = assigned.where((task) => task.isCompleted).length;
    return completed / assigned.length;
  }

  Widget avatar(TeamMember member) {
    final index = members.indexOf(member);
    return CircleAvatar(
      radius: 24,
      backgroundColor: colors[index % colors.length],
      child: Text(
        member.name.isEmpty ? '?' : member.name[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void showTasks(TeamMember member) {
    final assigned = memberTasks(member);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${member.name}’s tasks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 12),
          if (assigned.isEmpty)
            const Text('No tasks assigned yet.'),
          ...assigned.map(
            (task) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(task.title),
              subtitle: Text(
                task.isCompleted ? 'Completed' : 'Open',
              ),
              trailing: Text(
                task.priority.name.toUpperCase(),
                style: TextStyle(
                  color: blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
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
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final me = members.where((m) => m.id == currentUserId).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: Text(
          'Team & Profile',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFFF7F8FC),
        foregroundColor: navy,
        elevation: 0,
      ),
      body: members.isEmpty
          ? const Center(child: Text('No team members yet.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: navy,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      if (me != null) avatar(me),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              me?.name ?? 'Your profile',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Team member · You',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'Team members',
                  style: TextStyle(
                    color: navy,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...members.where((m) => m.id != currentUserId).map((member) {
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE4E7ED)),
                    ),
                    child: InkWell(
                      onTap: () => showTasks(member),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            avatar(member),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: TextStyle(
                                      color: navy,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Team member',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: progress(member),
                                      minHeight: 6,
                                      backgroundColor:
                                          const Color(0xFFE5E7EB),
                                      color: blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${openCount(member)} open',
                              style: TextStyle(
                                color: navy,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: signOut,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: navy,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD9DDE5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Sign out',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}