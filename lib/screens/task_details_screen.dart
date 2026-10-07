import 'package:flutter/material.dart';
import 'package:sla_tracker/models/task.dart';
import 'package:sla_tracker/services/sla_service.dart';
import 'package:sla_tracker/services/storage_service.dart';
import 'package:sla_tracker/utils/date_format.dart';
import 'package:sla_tracker/widgets/status_chip.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Task task;
  final String assigneeName;

  const TaskDetailsScreen({
    super.key,
    required this.task,
    required this.assigneeName,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final _storage = StorageService();
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  // Replace this task in the saved list, then save the whole list
  Future<void> _saveTask() async {
    final tasks = await _storage.loadTasks();
    final index = tasks.indexWhere((t) => t.id == _task.id);
    if (index != -1) tasks[index] = _task;
    await _storage.saveTasks(tasks);
  }

  Future<void> _toggleComplete(bool value) async {
    setState(() => _task.isCompleted = value);
    await _saveTask();
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final tasks = await _storage.loadTasks();
    tasks.removeWhere((t) => t.id == _task.id);
    await _storage.saveTasks(tasks);
    if (mounted) Navigator.pop(context);
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = getSlaStatus(_task);
    final priorityName = _task.priority.name;
    final priorityText =
        priorityName[0].toUpperCase() + priorityName.substring(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () {
              // TODO: Navigator.push to the Create/Edit screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit screen coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: _deleteTask,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _task.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StatusChip(status: status),
            const SizedBox(height: 16),
            Text(_task.description),
            const Divider(height: 32),
            _infoRow(Icons.person, 'Assignee', widget.assigneeName),
            _infoRow(Icons.flag, 'Priority', priorityText),
            _infoRow(
              Icons.calendar_today,
              'Deadline',
              formatDate(_task.deadline),
            ),
            const Divider(height: 32),
            SwitchListTile(
              title: const Text('Mark as completed'),
              value: _task.isCompleted,
              onChanged: _toggleComplete,
            ),
          ],
        ),
      ),
    );
  }
}
