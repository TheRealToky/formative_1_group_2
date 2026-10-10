import 'enums.dart';

DateTime _dt(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
DateTime? _dtN(Object? ms) => ms == null ? null : _dt(ms as int);
int? _ms(DateTime? d) => d?.toUtc().millisecondsSinceEpoch;

class TeamMember {
  const TeamMember({this.id, required this.name, required this.role, this.email, this.avatarColor = '#1D4ED8', required this.createdAt});
  final int? id;
  final String name, role, avatarColor;
  final String? email;
  final DateTime createdAt;

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  factory TeamMember.fromMap(Map<String, Object?> m) => TeamMember(
        id: m['id'] as int?,
        name: m['name'] as String,
        role: m['role'] as String,
        email: m['email'] as String?,
        avatarColor: m['avatar_color'] as String,
        createdAt: _dt(m['created_at'] as int),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'role': role,
        'email': email,
        'avatar_color': avatarColor,
        'created_at': _ms(createdAt),
      };
}

class Project {
  const Project({this.id, required this.name, this.description, this.archived = false, required this.createdAt});
  final int? id;
  final String name;
  final String? description;
  final bool archived;
  final DateTime createdAt;

  factory Project.fromMap(Map<String, Object?> m) => Project(
        id: m['id'] as int?,
        name: m['name'] as String,
        description: m['description'] as String?,
        archived: (m['archived'] as int) == 1,
        createdAt: _dt(m['created_at'] as int),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
        'archived': archived ? 1 : 0,
        'created_at': _ms(createdAt),
      };
}

class Task {
  const Task({
    this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.assigneeId,
    this.createdBy,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    this.dueAt,
    this.slaDueAt,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.assigneeName,
    this.assigneeColor,
  });

  /// Use this on the Create Task screen; the repository sets the final timestamps.
  factory Task.draft({
    required int projectId,
    required String title,
    String? description,
    int? assigneeId,
    int? createdBy,
    TaskPriority priority = TaskPriority.medium,
    TaskStatus status = TaskStatus.todo,
    DateTime? dueAt,
    DateTime? slaDueAt,
  }) {
    final now = DateTime.now().toUtc();
    return Task(projectId: projectId, title: title, description: description, assigneeId: assigneeId, createdBy: createdBy, priority: priority, status: status, dueAt: dueAt, slaDueAt: slaDueAt, createdAt: now, updatedAt: now);
  }

  final int? id;
  final int projectId;
  final String title;
  final String? description;
  final int? assigneeId, createdBy;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueAt, slaDueAt, completedAt;
  final DateTime createdAt, updatedAt;
  final String? assigneeName, assigneeColor; // read-only, from v_tasks_detailed

  bool isOverdue(DateTime now) => status != TaskStatus.done && dueAt != null && dueAt!.isBefore(now);

  SlaState slaState(DateTime now, {Duration atRiskWindow = const Duration(hours: 24)}) {
    if (status == TaskStatus.done || slaDueAt == null) return SlaState.none;
    if (slaDueAt!.isBefore(now)) return SlaState.breached;
    return slaDueAt!.difference(now) <= atRiskWindow ? SlaState.atRisk : SlaState.onTrack;
  }

  Duration? slaRemaining(DateTime now) => slaDueAt?.difference(now);

  Task copyWith({String? title, String? description, int? assigneeId, TaskPriority? priority, TaskStatus? status, DateTime? dueAt, DateTime? slaDueAt}) => Task(
        id: id, projectId: projectId, createdBy: createdBy, createdAt: createdAt, updatedAt: updatedAt, completedAt: completedAt,
        title: title ?? this.title,
        description: description ?? this.description,
        assigneeId: assigneeId ?? this.assigneeId,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        dueAt: dueAt ?? this.dueAt,
        slaDueAt: slaDueAt ?? this.slaDueAt,
        assigneeName: assigneeName, assigneeColor: assigneeColor,
      );

  factory Task.fromMap(Map<String, Object?> m) => Task(
        id: m['id'] as int?,
        projectId: m['project_id'] as int,
        title: m['title'] as String,
        description: m['description'] as String?,
        assigneeId: m['assignee_id'] as int?,
        createdBy: m['created_by'] as int?,
        priority: TaskPriority.fromDb(m['priority'] as String),
        status: TaskStatus.fromDb(m['status'] as String),
        dueAt: _dtN(m['due_at']),
        slaDueAt: _dtN(m['sla_due_at']),
        createdAt: _dt(m['created_at'] as int),
        updatedAt: _dt(m['updated_at'] as int),
        completedAt: _dtN(m['completed_at']),
        assigneeName: m['assignee_name'] as String?,
        assigneeColor: m['assignee_color'] as String?,
      );

  /// Columns of the `tasks` table only (joined fields are not written).
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'project_id': projectId,
        'title': title,
        'description': description,
        'assignee_id': assigneeId,
        'created_by': createdBy,
        'priority': priority.db,
        'status': status.db,
        'due_at': _ms(dueAt),
        'sla_due_at': _ms(slaDueAt),
        'created_at': _ms(createdAt),
        'updated_at': _ms(updatedAt),
        'completed_at': _ms(completedAt),
      };
}

class TaskHistoryEntry {
  const TaskHistoryEntry({required this.field, this.oldValue, this.newValue, this.changedBy, required this.changedAt});
  final String field;
  final String? oldValue, newValue;
  final int? changedBy;
  final DateTime changedAt;

  factory TaskHistoryEntry.fromMap(Map<String, Object?> m) => TaskHistoryEntry(
        field: m['field'] as String,
        oldValue: m['old_value'] as String?,
        newValue: m['new_value'] as String?,
        changedBy: m['changed_by'] as int?,
        changedAt: _dt(m['changed_at'] as int),
      );
}

/// Dashboard screen numbers.
class DashboardStats {
  const DashboardStats({required this.total, required this.todo, required this.inProgress, required this.done, required this.overdue, required this.slaAtRisk});
  final int total, todo, inProgress, done, overdue, slaAtRisk;
  double get progress => total == 0 ? 0 : done / total;
}

/// Team screen row.
class MemberWorkload {
  const MemberWorkload({required this.member, required this.openTasks, required this.totalTasks});
  final TeamMember member;
  final int openTasks, totalTasks;
}
