import 'package:sla_tracker/models/task.dart';

/// Builds 10 sample tasks with deadlines relative to "now",
/// so every SLA status is represented.
List<Task> buildDummyTasks(List<String> assigneeIds) {
  final now = DateTime.now();
  var counter = 0;

  Task make(
    String title,
    String description,
    Priority priority,
    Duration fromNow, {
    bool completed = false,
  }) {
    final assignee = assigneeIds[counter % assigneeIds.length];
    counter++;
    return Task(
      id: 'dummy_$counter',
      title: title,
      description: description,
      assigneeId: assignee,
      priority: priority,
      deadline: now.add(fromNow),
      isCompleted: completed,
    );
  }

  return [
    // At Risk
    make(
      'Fix login bug',
      'Users cannot sign in with a short password.',
      Priority.high,
      const Duration(hours: 24),
    ),
    make(
      'Implement local storage',
      'Save tasks with SharedPreferences. High priority, so the 72h window applies.',
      Priority.high,
      const Duration(hours: 60),
    ),
    make(
      'Update README',
      'Add setup steps and screenshots.',
      Priority.low,
      const Duration(hours: 30),
    ),

    // Overdue
    make(
      'Design login screen',
      'Clean sign in layout with validation.',
      Priority.medium,
      const Duration(days: -2),
    ),
    make(
      'Review pull requests',
      'Review the team branches before merging.',
      Priority.medium,
      const Duration(days: -1),
    ),

    // On Track
    make(
      'Design database schema',
      'Same time left as the storage task, but medium priority so it is On Track.',
      Priority.medium,
      const Duration(hours: 60),
    ),
    make(
      'Write unit tests',
      'Cover the SLA status rules.',
      Priority.low,
      const Duration(days: 6),
    ),
    make(
      'Prepare demo script',
      'Plan who explains which screen.',
      Priority.high,
      const Duration(days: 4),
    ),

    // Completed
    make(
      'Create task model',
      'Task class with toJson and fromJson.',
      Priority.medium,
      const Duration(days: -3),
      completed: true,
    ),
    make(
      'Set up GitHub branches',
      'One branch per team member.',
      Priority.low,
      const Duration(days: 2),
      completed: true,
    ),
  ];
}
