import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/storage_service.dart';
import 'sign_in_screen.dart';
 
class TeamProfileScreen extends StatefulWidget {
  final TeamMember? currentUser; // passed in by MainShell
 
  const TeamProfileScreen({super.key, this.currentUser});
 
  @override
  State<TeamProfileScreen> createState() => _TeamProfileScreenState();
}
 
class _TeamProfileScreenState extends State<TeamProfileScreen> {
  final storage = StorageService();
 
  static const blue = Color(0xFF1D4ED8);
  static const navy = Color(0xFF14213D);
 
  // Avatar colors, reused in order for each member
  static const avatarColors = [
    Color(0xFF9A3412),
    Color(0xFF1E3A8A),
    Color(0xFF374151),
    Color(0xFF166534),
  ];
 
  List<TeamMember> members = [];
  List<Task> tasks = [];
  TeamMember? me; // the signed-in user
 
  @override
  void initState() {
    super.initState();
    load();
  }
 
  Future<void> load() async {
    final loadedMembers = await storage.loadMembers();
    final loadedTasks = await storage.loadTasks();
    final myId = await storage.getCurrentUserId();
 
    // Find the signed-in user in the member list
    TeamMember? current;
    for (final member in loadedMembers) {
      if (member.id == myId) current = member;
    }
 
    if (!mounted) return;
    setState(() {
      members = loadedMembers;
      tasks = loadedTasks;
      // Prefer the user MainShell gave us; fall back to the saved id
      me = widget.currentUser ?? current;
    });
  }
 
  // How many unfinished tasks does this person have?
  int openTasks(String memberId) {
    return tasks.where((t) => t.assigneeId == memberId && !t.isCompleted).length;
  }
 
  void signOut() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }
 
  // Round avatar with the first letter of the name
  Widget avatar(String name, Color color, double size) {
    return CircleAvatar(
      radius: size,
      backgroundColor: color,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }
 
  // The dark card at the top showing the current user
  Widget profileCard() {
    final name = me?.name ?? 'Guest';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          avatar(name, blue, 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // TeamMember has no role field, so we show a general label
              const Text('Team member · You',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
 
  // One white card per team member
  Widget memberCard(TeamMember member, int index) {
    final open = openTasks(member.id);
 
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          avatar(member.name, avatarColors[index % avatarColors.length], 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // TeamMember has no role field, so we show a general label
                const Text('Team member',
                    style: TextStyle(color: Color(0xFF5B6475))),
                const SizedBox(height: 8),
                // Bar grows with open tasks (10 open tasks = full bar)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (open / 10).clamp(0.0, 1.0),
                    minHeight: 6,
                    color: blue,
                    backgroundColor: const Color(0xFFE5E7EB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$open open',
            style: const TextStyle(color: navy, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    // Show everyone except the signed-in user
    final others = members.where((m) => m.id != me?.id).toList();
 
    return Container(
      color: const Color(0xFFF5F6F8),
      child: Column(
        children: [
          Expanded(
            // Pull down to refresh the task counts
            child: RefreshIndicator(
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  const Text(
                    'Team & Profile',
                    style: TextStyle(
                      color: navy,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  profileCard(),
                  const SizedBox(height: 24),
                  const Text(
                    'Team members',
                    style: TextStyle(
                      color: navy,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (int i = 0; i < others.length; i++)
                    memberCard(others[i], i),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: signOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: navy,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFD0D5DD)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Sign out', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}