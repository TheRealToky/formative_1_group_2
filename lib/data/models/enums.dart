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

/// Explicit 4-state SLA status required by project rubrics:
/// On Track, At Risk, Overdue, Completed.
enum SlaStatus {
  onTrack('On Track'),
  atRisk('At Risk'),
  overdue('Overdue'),
  completed('Completed');

  const SlaStatus(this.label);
  final String label;
}

