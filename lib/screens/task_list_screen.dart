import 'package:flutter/material.dart';
import 'package:sla_tracker/models/task.dart';
import 'package:sla_tracker/models/team_member.dart';
import 'package:sla_tracker/screens/task_details_screen.dart';
import 'package:sla_tracker/services/sla_service.dart';
import 'package:sla_tracker/services/storage_service.dart';
import 'package:sla_tracker/utils/date_format.dart';
import 'package:sla_tracker/widgets/status_chip.dart';
import 'package:sla_tracker/utils/dummy_data.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _storage = StorageService();
  List<Task> _tasks = [];
  List<TeamMember> _members = [];
  SlaStatus? _filter; // null means "All"
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tasks = await _storage.loadTasks();
    final members = await _storage.loadMembers();
    tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _members = members;
      _loading = false;
    });
  }

  String _assigneeName(String id) {
    for (final m in _members) {
      if (m.id == id) return m.name;
    }
    return 'Unassigned';
  }

  Future<void> _openDetails(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailsScreen(
          task: task,
          assigneeName: _assigneeName(task.assigneeId),
        ),
      ),
    );
    _load(); // refresh in case the task was changed or deleted
  }

  // TEMPORARY: loads 10 dummy tasks for testing.
  // Replace with Navigator.push to the Create Task screen later.
  Future<void> _loadDummyTasks() async {
    final tasks = await _storage.loadTasks();
    tasks.removeWhere((t) => t.id.startsWith('dummy_')); // avoid duplicates
    final ids = _members.isEmpty
        ? [await _storage.getCurrentUserId() ?? '1']
        : _members.map((m) => m.id).toList();
    tasks.addAll(buildDummyTasks(ids));
    await _storage.saveTasks(tasks);
    await _load();
  }

  Widget _filterChips() {
    final filters = <(String, SlaStatus?)>[
      ('All', null),
      ('On Track', SlaStatus.onTrack),
      ('At Risk', SlaStatus.atRisk),
      ('Overdue', SlaStatus.overdue),
      ('Completed', SlaStatus.completed),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (final f in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f.$1),
                selected: _filter == f.$2,
                onSelected: (_) => setState(() => _filter = f.$2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _taskCard(Task task) {
    final status = getSlaStatus(task);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_assigneeName(task.assigneeId)} • ${formatDate(task.deadline)}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: status),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _tasks
        .where((t) => _filter == null || getSlaStatus(t) == _filter)
        .toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _loadDummyTasks,
        tooltip: 'Load dummy tasks',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _filterChips(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                ? const Center(child: Text('No tasks here yet'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: visible.length,
                    itemBuilder: (context, i) => _taskCard(visible[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
