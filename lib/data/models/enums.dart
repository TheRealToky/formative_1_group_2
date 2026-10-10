enum TaskStatus {
  todo('todo', 'To do'),
  inProgress('in_progress', 'In progress'),
  done('done', 'Done');

  const TaskStatus(this.db, this.label);
  final String db;
  final String label;
  static TaskStatus fromDb(String v) => values.firstWhere((e) => e.db == v);
}

enum TaskPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High');

  const TaskPriority(this.db, this.label);
  final String db;
  final String label;
  static TaskPriority fromDb(String v) => values.firstWhere((e) => e.db == v);
}

/// Derived (never stored): drives the orange SLA badges in the UI.
enum SlaState { none, onTrack, atRisk, breached }
