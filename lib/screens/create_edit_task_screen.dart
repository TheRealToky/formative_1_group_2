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

  final blue = const Color(0xFF2453D4);
  final navy = const Color(0xFF14213D);

  List<TeamMember> members = [];
  String? assigneeId;
  Priority priority = Priority.medium;
  DateTime? deadline;
  bool loading = true;

  @override
  void initState() {
    super.initState();

    final task = widget.task;
    if (task != null) {
      titleController.text = task.title;
      descriptionController.text = task.description;
      assigneeId = task.assigneeId;
      priority = task.priority;
      deadline = task.deadline;
    }

    loadMembers();
  }

  Future<void> loadMembers() async {
    final result = await storage.loadMembers();
    if (!mounted) return;

    setState(() {
      members = result;
      if (!members.any((m) => m.id == assigneeId)) {
        assigneeId = members.isEmpty ? null : members.first.id;
      }
      loading = false;
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  InputDecoration fieldStyle() => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9DDE5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9DDE5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: blue, width: 1.5),
        ),
      );

  Widget fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF404B5D),
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Future<void> chooseDeadline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final selected = await showDatePicker(
      context: context,
      initialDate:
          deadline != null && !deadline!.isBefore(today)
              ? deadline!
              : today,
      firstDate: today,
      lastDate: DateTime(now.year + 2),
    );

    if (selected != null) {
      setState(() => deadline = selected);
    }
  }

  void saveTask() {
    if (!formKey.currentState!.validate()) return;

    if (assigneeId == null || deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an assignee and deadline.'),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        foregroundColor: navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.task == null ? 'New Task' : 'Edit Task',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  fieldLabel('Title'),
                  TextFormField(
                    controller: titleController,
                    decoration: fieldStyle(),
                    validator: (value) =>
                        value == null || value.trim().length < 3
                            ? 'Enter at least 3 characters'
                            : null,
                  ),
                  const SizedBox(height: 18),

                  fieldLabel('Description'),
                  TextFormField(
                    controller: descriptionController,
                    decoration: fieldStyle().copyWith(
                      hintText: 'Enter task details',
                    ),
                    maxLines: 4,
                    maxLength: 200,
                  ),
                  const SizedBox(height: 12),

                  fieldLabel('Assign to'),
                  DropdownButtonFormField<String>(
                    initialValue: assigneeId,
                    decoration: fieldStyle(),
                    hint: const Text('Choose a team member'),
                    items: members.map((member) {
                      return DropdownMenuItem(
                        value: member.id,
                        child: Text(member.name),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => assigneeId = value),
                    validator: (value) =>
                        value == null ? 'Choose a team member' : null,
                  ),
                  const SizedBox(height: 18),

                  fieldLabel('Deadline'),
                  InkWell(
                    onTap: chooseDeadline,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: fieldStyle().copyWith(
                        suffixIcon: Icon(
                          Icons.calendar_month_outlined,
                          color: blue,
                        ),
                      ),
                      child: Text(
                        deadline == null
                            ? 'Select a date'
                            : '${deadline!.day} ${_month(deadline!.month)} ${deadline!.year}',
                        style: TextStyle(
                          color: deadline == null
                              ? Colors.grey[600]
                              : navy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  fieldLabel('Priority'),
                  Row(
                    children: Priority.values.map((level) {
                      final selected = priority == level;
                      final label = level.name[0].toUpperCase() +
                          level.name.substring(1);

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => priority = level),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: selected
                                  ? const Color(0xFFE4ECFF)
                                  : Colors.white,
                              foregroundColor: navy,
                              side: BorderSide(
                                color: selected
                                    ? blue
                                    : const Color(0xFFD9DDE5),
                                width: selected ? 1.5 : 1,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(label),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: members.isEmpty ? null : saveTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text(
                        'Save task',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: navy,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFD9DDE5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _month(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}


