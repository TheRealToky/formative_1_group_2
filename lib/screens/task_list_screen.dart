import 'package:flutter/material.dart';
import 'package:sla_tracker/data/data.dart';
import 'package:sla_tracker/screens/task_details_screen.dart';
import 'package:sla_tracker/screens/task_edit_screen.dart';
import 'package:sla_tracker/utils/date_format.dart';
import 'package:sla_tracker/widgets/priority_chip.dart';
import 'package:sla_tracker/widgets/status_chip.dart';

class TaskListScreen extends StatefulWidget {
  final TeamMember currentUser;
  const TaskListScreen({super.key, required this.currentUser});

  @override
  State<TaskListScreen> createState() => TaskListScreenState();
}

class TaskListScreenState extends State<TaskListScreen> {
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  TaskStatus? _selectedStatus; // null means 'All'
  SlaStatus? _selectedSla; // null means 'All'
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final db = await AppDatabase.instance.database;
    final taskRepo = TaskRepository(db);
    final tasks = await taskRepo.list(status: _selectedStatus);

    if (!mounted) return;
    setState(() {
      _allTasks = tasks;
      _applyFilters();
      _loading = false;
    });
  }

  void _applyFilters() {
    if (_selectedSla == null) {
      _filteredTasks = _allTasks;
    } else {
      _filteredTasks = _allTasks.where((t) => t.getSlaStatus() == _selectedSla).toList();
    }
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

  Future<void> _createNewTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskEditScreen(
          currentUser: widget.currentUser,
        ),
      ),
    );
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    final statusFilters = <(String, TaskStatus?)>[
      ('All', null),
      ('To do', TaskStatus.todo),
      ('Doing', TaskStatus.inProgress),
      ('Done', TaskStatus.done),
    ];

    final slaFilters = <(String, SlaStatus?)>[
      ('All SLAs', null),
      ('On Track', SlaStatus.onTrack),
      ('At Risk', SlaStatus.atRisk),
      ('Overdue', SlaStatus.overdue),
      ('Completed', SlaStatus.completed),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Primary Status Filter Chips (To do / Doing / Done)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: statusFilters.map((opt) {
                  final isSelected = _selectedStatus == opt.$2;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          _selectedStatus = opt.$2;
                          _loading = true;
                        });
                        refresh();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1D4ED8) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          opt.$1,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // SLA Feedback Filter Chips (On Track / At Risk / Overdue / Completed)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: slaFilters.map((opt) {
                  final isSelected = _selectedSla == opt.$2;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _selectedSla = opt.$2;
                          _applyFilters();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          opt.$1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Task List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: refresh,
                      child: _filteredTasks.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 120),
                                Center(
                                  child: Text(
                                    'No tasks match the selected filters',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _filteredTasks.length,
                              itemBuilder: (context, index) {
                                final task = _filteredTasks[index];
                                final assignee = task.assigneeName ?? 'Unassigned';
                                final dueText = task.dueAt != null
                                    ? 'Due ${formatDateShort(task.dueAt)}'
                                    : 'No deadline';
                                final sla = task.getSlaStatus();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.015),
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
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
                                                  PriorityChip(
                                                    priority: task.priority,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  SlaStatusChip(
                                                    status: sla,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '$assignee · $dueText',
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
                              },
                            ),
                    ),
            ),

            // Bottom Action Button "+ New task"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _createNewTask,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '+ New task',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
