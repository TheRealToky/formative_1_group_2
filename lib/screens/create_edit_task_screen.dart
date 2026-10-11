import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/storage_service.dart';
 
class CreateEditTaskScreen extends StatefulWidget {
  final Task? task; // null = creating, not null = editing
 
  const CreateEditTaskScreen({super.key, this.task});
 
  @override
  State<CreateEditTaskScreen> createState() => _CreateEditTaskScreenState();
}
 
class _CreateEditTaskScreenState extends State<CreateEditTaskScreen> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final storage = StorageService();
 
  // Colors taken from the design
  static const blue = Color(0xFF1D4ED8);
  static const navy = Color(0xFF14213D);
  static const border = Color(0xFFD0D5DD);
  static const background = Color(0xFFF5F6F8);
 
  List<TeamMember> members = [];
  String? assigneeId;
  Priority priority = Priority.medium;
  DateTime? deadline;
  bool loading = true;
 
  @override
  void initState() {
    super.initState();
    // When editing, fill the form with the existing task
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
      // If the saved assignee no longer exists, pick the first member
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
 
  // One style shared by every input box
  InputDecoration fieldStyle() {
    OutlineInputBorder outline(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
    }
 
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: outline(border, 1),
      enabledBorder: outline(border, 1),
      focusedBorder: outline(blue, 1.5),
    );
  }
 
  // Small grey label above each field
  Widget fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF5B6475), fontSize: 14),
      ),
    );
  }
 
  Future<void> chooseDeadline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
 
    final selected = await showDatePicker(
      context: context,
      initialDate:
          deadline != null && !deadline!.isBefore(today) ? deadline! : today,
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
        const SnackBar(content: Text('Please select an assignee and deadline.')),
      );
      return;
    }
 
    final task = Task(
      id: widget.task?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      assigneeId: assigneeId!,
      priority: priority,
      deadline: deadline!,
      isCompleted: widget.task?.isCompleted ?? false,
    );
 
    // Send the task back to the screen that opened this one
    Navigator.pop(context, task);
  }
 
  // One priority button (Low / Medium / High)
  Widget priorityButton(Priority level) {
    final selected = priority == level;
    final label = level.name[0].toUpperCase() + level.name.substring(1);
 
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: level == Priority.high ? 0 : 8),
        child: OutlinedButton(
          onPressed: () => setState(() => priority = level),
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? const Color(0xFFDBE8FF) : Colors.white,
            foregroundColor: selected ? const Color(0xFF1E3A8A) : navy,
            side: BorderSide(color: selected ? blue : border),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
 
  String formatDeadline(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: navy,
        elevation: 0,
        title: Text(
          widget.task == null ? 'New Task' : 'Edit Task',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: formKey,
              child: Column(
                children: [
                  // The fields scroll; the buttons below stay at the bottom
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                          decoration: fieldStyle(),
                          maxLines: 5,
                        ),
                        const SizedBox(height: 18),
 
                        fieldLabel('Assign to'),
                        DropdownButtonFormField<String>(
                          initialValue: assigneeId,
                          decoration: fieldStyle(),
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
                            decoration: fieldStyle(),
                            child: Text(
                              deadline == null
                                  ? 'Select a date'
                                  : formatDeadline(deadline!),
                              style: TextStyle(
                                color: deadline == null ? Colors.grey : navy,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
 
                        fieldLabel('Priority'),
                        Row(
                          children: Priority.values.map(priorityButton).toList(),
                        ),
                      ],
                    ),
                  ),
 
                  // Buttons pinned at the bottom
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: members.isEmpty ? null : saveTask,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Save task',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: navy,
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}