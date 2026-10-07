enum Priority { low, medium, high }

class Task {
  final String id;
  String title;
  String description;
  String assigneeId;
  Priority priority;
  DateTime deadline;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.priority,
    required this.deadline,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'assigneeId': assigneeId,
    'priority': priority.name,
    'deadline': deadline.toIso8601String(),
    'isCompleted': isCompleted,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    assigneeId: json['assigneeId'],
    priority: Priority.values.byName(json['priority']),
    deadline: DateTime.parse(json['deadline']),
    isCompleted: json['isCompleted'],
  );
}
