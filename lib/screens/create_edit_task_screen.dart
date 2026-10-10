import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/team_member.dart';
import '../services/storage_service.dart';

class CreateEditTaskScreen extends StatefulWidget {
  final Task? task;

  const CreateEditTaskScreen({super.key, this.task});

  @override
  State<CreateEditTaskScreen> createState() =>
      _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends State<CreateEditTaskScreen> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final storage = StorageService();

  List<TeamMember> members = [];
  String? assigneeId;
  Priority priority = Priority.medium;
  DateTime? deadline;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    if (widget.task != null) {
      titleController.text = widget.task!.title;
      descriptionController.text = widget.task!.description;
      assigneeId = widget.task!.assigneeId;
      priority = widget.task!.priority;
      deadline = widget.task!.deadline;
    }

    loadMembers();
  }

  Future<void> loadMembers() async {
    members = await storage.loadMembers();

    if (!mounted) return;

    setState(() {
      if (!members.any((member) => member.id == assigneeId)) {
        assigneeId = members.isEmpty ? null : members.first.id;
      }
      isLoading = false;
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> chooseDeadline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final date = await showDatePicker(
      context: context,
      initialDate: deadline != null && !deadline!.isBefore(today)
          ? deadline!
          : today,
      firstDate: today,
      lastDate: DateTime(now.year + 2),
    );

    if (date != null) {
      setState(() => deadline = date);
    }
  }

  void saveTask() {
    if (!formKey.currentState!.validate()) return;

    if (deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a deadline')),
      );
      return;
    }

    final task = Task(
      id: widget.task?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      assigneeId: assigneeId!,
      priority: priority,
      deadline: deadline!,
      isCompleted: widget.task?.isCompleted ?? false,
    );

    Navigator.pop(context, task);
  }

  InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
        backgroundColor: const Color(0xFFF5F7FA),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: decoration('Title'),
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Enter at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: descriptionController,
                    decoration: decoration('Description (optional)'),
                    maxLines: 3,
                    maxLength: 200,
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    initialValue: assigneeId,
                    decoration: decoration('Assign to'),
                    items: members.map((member) {
                      return DropdownMenuItem(
                        value: member.id,
                        child: Text(member.name),
                      );
                    }).toList(),
                    validator: (value) =>
                        value == null ? 'Select a team member' : null,
                    onChanged: (value) {
                      setState(() => assigneeId = value);
                    },
                  ),
                  const SizedBox(height: 14),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      deadline == null
                          ? 'Choose deadline'
                          : 'Deadline: ${deadline!.day}/${deadline!.month}/${deadline!.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: chooseDeadline,
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Priority',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children: Priority.values.map((level) {
                      return ChoiceChip(
                        label: Text(
                          level.name[0].toUpperCase() +
                              level.name.substring(1),
                        ),
                        selected: priority == level,
                        onSelected: (_) {
                          setState(() => priority = level);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: members.isEmpty ? null : saveTask,
                    child: const Text('Save task'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
    );
  }
}