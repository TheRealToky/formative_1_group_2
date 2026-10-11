import 'package:flutter/material.dart';
import 'package:sla_tracker/data/data.dart';
import 'package:sla_tracker/screens/task_edit_screen.dart';
import 'package:sla_tracker/utils/date_format.dart';
import 'package:sla_tracker/widgets/priority_chip.dart';
import 'package:sla_tracker/widgets/status_chip.dart';

class TaskDetailsScreen extends StatefulWidget {
  final int taskId;
  final TeamMember currentUser;

  const TaskDetailsScreen({
    super.key,
    required this.taskId,
    required this.currentUser,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  Task? _task;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    final db = await AppDatabase.instance.database;
    final taskRepo = TaskRepository(db);
    final task = await taskRepo.getById(widget.taskId);

    if (!mounted) return;
    setState(() {
      _task = task;
      _loading = false;
    });
  }

  Future<void> _updateStatus(TaskStatus newStatus) async {
    if (_task == null || _task!.status == newStatus) return;

    final db = await AppDatabase.instance.database;
    final taskRepo = TaskRepository(db);
    await taskRepo.setStatus(widget.taskId, newStatus, changedBy: widget.currentUser.id);
    await _loadTask();
  }

  Future<void> _editTask() async {
    if (_task == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskEditScreen(
          task: _task,
          currentUser: widget.currentUser,
        ),
      ),
    );
    _loadTask();
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final db = await AppDatabase.instance.database;
    final taskRepo = TaskRepository(db);
    await taskRepo.delete(widget.taskId);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final task = _task;
    if (task == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(backgroundColor: const Color(0xFFF8FAFC)),
        body: const Center(child: Text('Task not found')),
      );
    }

    final now = DateTime.now();
    String? slaString;
    if (task.slaDueAt != null) {
      slaString = formatSlaRemaining(task.slaDueAt!, now).replaceFirst('SLA ', '');
    } else if (task.isOverdue(now) && task.dueAt != null) {
      slaString = formatOverdue(task.dueAt!, now);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Task Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Task Card
              Container(
                width: double.infinity,
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
                      task.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        PriorityChip(priority: task.priority),
                        const SizedBox(width: 8),
                        StatusChip(status: task.status),
                        const SizedBox(width: 8),
                        SlaStatusChip(status: task.getSlaStatus()),
                      ],
                    ),
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        task.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    const SizedBox(height: 14),

                    // Assignee Row
                    _buildMetaRow(
                      label: 'Assignee',
                      value: task.assigneeName ?? 'Unassigned',
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    const SizedBox(height: 14),

                    // Due Row
                    _buildMetaRow(
                      label: 'Due',
                      value: formatDateShort(task.dueAt),
                    ),

                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    const SizedBox(height: 14),

                    // SLA Row
                    _buildMetaRow(
                      label: 'SLA',
                      value: slaString ?? task.getSlaStatus().label,
                      valueColor: task.getSlaStatus() == SlaStatus.overdue
                          ? const Color(0xFFB91C1C)
                          : task.getSlaStatus() == SlaStatus.atRisk
                              ? const Color(0xFFC2410C)
                              : const Color(0xFF15803D),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Update status section
              const Text(
                'Update status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildStatusButton('To do', TaskStatus.todo, task.status),
                  const SizedBox(width: 10),
                  _buildStatusButton('Doing', TaskStatus.inProgress, task.status),
                  const SizedBox(width: 10),
                  _buildStatusButton('Done', TaskStatus.done, task.status),
                ],
              ),
              const SizedBox(height: 32),

              // Edit task button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _editTask,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Edit task',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Delete task button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _deleteTask,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Delete task',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow({
    required String label,
    required String value,
    Color valueColor = const Color(0xFF0F172A),
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton(String label, TaskStatus status, TaskStatus current) {
    final isSelected = status == current;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _updateStatus(status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1D4ED8) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}
