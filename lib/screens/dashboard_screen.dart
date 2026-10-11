import 'package:flutter/material.dart';
import 'package:sla_tracker/data/data.dart';
import 'package:sla_tracker/screens/task_details_screen.dart';
import 'package:sla_tracker/utils/date_format.dart';
import 'package:sla_tracker/widgets/priority_chip.dart';
import 'package:sla_tracker/widgets/status_chip.dart';

class DashboardScreen extends StatefulWidget {
  final TeamMember currentUser;
  const DashboardScreen({super.key, required this.currentUser});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  Project? _project;
  DashboardStats? _stats;
  List<Task> _attentionTasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final db = await AppDatabase.instance.database;
    final projectRepo = ProjectRepository(db);
    final taskRepo = TaskRepository(db);

    final projects = await projectRepo.all();
    if (projects.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final project = projects.first;
    final stats = await projectRepo.stats(project.id!);
    final attention = await taskRepo.needsAttention(project.id!);

    if (!mounted) return;
    setState(() {
      _project = project;
      _stats = stats;
      _attentionTasks = attention;
      _loading = false;
    });
  }

  Future<void> _openTaskDetails(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailsScreen(
          taskId: task.id!,
          currentUser: widget.currentUser,
        ),
      ),
    );
    refresh();
  }

  String _formatAttentionSubtitle(Task task) {
    final assignee = task.assigneeName ?? 'Unassigned';
    final due = formatDateShort(task.dueAt);
    final now = DateTime.now();

    final parts = <String>[assignee, 'Due $due'];

    if (task.isOverdue(now) && task.dueAt != null) {
      parts.add(formatOverdue(task.dueAt!, now));
    } else if (task.slaDueAt != null) {
      parts.add(formatSlaRemaining(task.slaDueAt!, now));
    }

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final stats = _stats;
    final projectName = _project?.name ?? 'Project';
    final progressPct = stats == null || stats.total == 0
        ? 0
        : ((stats.done / stats.total) * 100).round();
    final progressVal = stats == null || stats.total == 0
        ? 0.0
        : (stats.done / stats.total).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Project Dashboard',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Project Progress Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projectName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$progressPct%',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            '${stats?.done ?? 0} of ${stats?.total ?? 0} tasks done',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progressVal,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Status Count Cards (To do, In progress, Done)
                Row(
                  children: [
                    Expanded(
                      child: _buildCountCard(
                        count: stats?.todo ?? 0,
                        label: 'To do',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCountCard(
                        count: stats?.inProgress ?? 0,
                        label: 'In progress',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCountCard(
                        count: stats?.done ?? 0,
                        label: 'Done',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Needs Attention Section
                const Text(
                  'Needs attention',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                // Needs Attention Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFC2410C),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        '${stats?.overdue ?? 0} overdue',
                        style: const TextStyle(
                          color: Color(0xFF9A3412),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        height: 16,
                        width: 1,
                        color: const Color(0xFFEA580C).withValues(alpha: 0.4),
                      ),
                      Text(
                        '${stats?.slaAtRisk ?? 0} SLA at risk',
                        style: const TextStyle(
                          color: Color(0xFF9A3412),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Attention Tasks List
                if (_attentionTasks.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        'All tasks on track! 🎉',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  ..._attentionTasks.map((task) => _buildAttentionCard(task)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountCard({required int count, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openTaskDetails(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PriorityChip(priority: task.priority),
                      const SizedBox(width: 6),
                      SlaStatusChip(status: task.getSlaStatus()),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatAttentionSubtitle(task),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
