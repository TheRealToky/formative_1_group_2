import 'package:sqflite/sqflite.dart';

import '../models/enums.dart';
import '../models/models.dart';

/// Screens: Task List, Task Details, Create / Edit Task, Dashboard ("Needs attention").
class TaskRepository {
  TaskRepository(this._db);
  final Database _db;

  static int _ms(DateTime d) => d.toUtc().millisecondsSinceEpoch;

  /// Task List: filter chips (status), search, optional assignee ("My tasks").
  /// Open tasks first, soonest deadline first, done tasks last.
  Future<List<Task>> list({int? projectId, TaskStatus? status, int? assigneeId, String? search}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (projectId != null) { where.add('project_id = ?'); args.add(projectId); }
    if (status != null) { where.add('status = ?'); args.add(status.db); }
    if (assigneeId != null) { where.add('assignee_id = ?'); args.add(assigneeId); }
    if (search != null && search.trim().isNotEmpty) { where.add('title LIKE ?'); args.add('%${search.trim()}%'); }
    final rows = await _db.rawQuery(
      'SELECT * FROM v_tasks_detailed${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'} '
      "ORDER BY (status = 'done'), due_at IS NULL, due_at ASC",
      args,
    );
    return rows.map(Task.fromMap).toList();
  }

  /// Task Details.
  Future<Task?> getById(int id) => _getIn(_db, id);

  Future<Task?> _getIn(DatabaseExecutor ex, int id) async {
    final rows = await ex.rawQuery('SELECT * FROM v_tasks_detailed WHERE id = ?', [id]);
    return rows.isEmpty ? null : Task.fromMap(rows.first);
  }

  /// Dashboard "Needs attention": open tasks that are overdue or have a breached / near SLA.
  Future<List<Task>> needsAttention(int projectId, {DateTime? now, Duration atRiskWindow = const Duration(hours: 24)}) async {
    final n = (now ?? DateTime.now()).toUtc();
    final rows = await _db.rawQuery('''
      SELECT * FROM v_tasks_detailed
      WHERE project_id = ? AND status != 'done'
        AND ((due_at IS NOT NULL AND due_at < ?) OR (sla_due_at IS NOT NULL AND sla_due_at <= ?))
      ORDER BY MIN(COALESCE(due_at, 9e15), COALESCE(sla_due_at, 9e15)) ASC
    ''', [projectId, _ms(n), _ms(n.add(atRiskWindow))]);
    return rows.map(Task.fromMap).toList();
  }

  /// Create Task screen. Returns the new id.
  Future<int> create(Task t, {int? changedBy}) => _db.transaction((txn) async {
        final now = _ms(DateTime.now());
        final done = t.status == TaskStatus.done;
        final id = await txn.insert('tasks', t.toMap()
          ..remove('id')
          ..['created_by'] = t.createdBy ?? changedBy
          ..['created_at'] = now
          ..['updated_at'] = now
          ..['completed_at'] = done ? now : null);
        await _log(txn, id, changedBy, 'created', null, t.title, now);
        return id;
      });

  /// Edit Task screen. Logs status / priority / assignee / deadline changes.
  Future<void> update(Task t, {int? changedBy}) => _db.transaction((txn) async {
        final old = await _getIn(txn, t.id!);
        if (old == null) return;
        final now = _ms(DateTime.now());
        final done = t.status == TaskStatus.done;
        await txn.update(
          'tasks',
          t.toMap()
            ..remove('id')
            ..remove('created_at')
            ..remove('created_by')
            ..['updated_at'] = now
            ..['completed_at'] = done ? (old.completedAt != null ? _ms(old.completedAt!) : now) : null,
          where: 'id = ?',
          whereArgs: [t.id],
        );
        final changes = <List<Object?>>[
          ['status', old.status.db, t.status.db],
          ['priority', old.priority.db, t.priority.db],
          ['assignee_id', old.assigneeId, t.assigneeId],
          ['due_at', old.dueAt?.millisecondsSinceEpoch, t.dueAt?.millisecondsSinceEpoch],
        ];
        for (final c in changes) {
          if (c[1] != c[2]) await _log(txn, t.id!, changedBy, c[0] as String, c[1]?.toString(), c[2]?.toString(), now);
        }
      });

  /// Task Details status buttons (To do / Doing / Done).
  Future<void> setStatus(int taskId, TaskStatus status, {int? changedBy}) async {
    final t = await getById(taskId);
    if (t != null) await update(t.copyWith(status: status), changedBy: changedBy);
  }

  /// Task Details "Delete task".
  Future<void> delete(int id) => _db.delete('tasks', where: 'id = ?', whereArgs: [id]);

  Future<List<TaskHistoryEntry>> history(int taskId) async =>
      (await _db.query('task_history', where: 'task_id = ?', whereArgs: [taskId], orderBy: 'changed_at DESC, id DESC'))
          .map(TaskHistoryEntry.fromMap)
          .toList();

  Future<void> _log(DatabaseExecutor ex, int taskId, int? by, String field, String? o, String? n, int at) =>
      ex.insert('task_history', {'task_id': taskId, 'changed_by': by, 'field': field, 'old_value': o, 'new_value': n, 'changed_at': at});
}
