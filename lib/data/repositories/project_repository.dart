import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// Screen: Project Dashboard.
class ProjectRepository {
  ProjectRepository(this._db);
  final Database _db;

  Future<List<Project>> all({bool includeArchived = false}) async =>
      (await _db.query('projects', where: includeArchived ? null : 'archived = 0', orderBy: 'name')).map(Project.fromMap).toList();

  Future<int> create(String name, {String? description}) => _db.insert('projects', {
        'name': name,
        'description': description,
        'archived': 0,
        'created_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      });

  /// Progress bar, status tiles and the "Needs attention" counters.
  /// slaAtRisk counts open tasks whose SLA is breached or ends within [atRiskWindow].
  Future<DashboardStats> stats(int projectId, {DateTime? now, Duration atRiskWindow = const Duration(hours: 24)}) async {
    final n = (now ?? DateTime.now()).toUtc();
    final r = (await _db.rawQuery('''
      SELECT COUNT(*) AS total,
        COALESCE(SUM(status = 'todo'), 0) AS todo,
        COALESCE(SUM(status = 'in_progress'), 0) AS in_progress,
        COALESCE(SUM(status = 'done'), 0) AS done,
        COALESCE(SUM(status != 'done' AND due_at IS NOT NULL AND due_at < ?), 0) AS overdue,
        COALESCE(SUM(status != 'done' AND sla_due_at IS NOT NULL AND sla_due_at <= ?), 0) AS sla_at_risk
      FROM tasks WHERE project_id = ?
    ''', [n.millisecondsSinceEpoch, n.add(atRiskWindow).millisecondsSinceEpoch, projectId])).first;
    return DashboardStats(
      total: r['total'] as int,
      todo: r['todo'] as int,
      inProgress: r['in_progress'] as int,
      done: r['done'] as int,
      overdue: r['overdue'] as int,
      slaAtRisk: r['sla_at_risk'] as int,
    );
  }
}
