import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// Screen: Team Members / Profile. (Sign in / sign up live in AuthRepository.)
class MemberRepository {
  MemberRepository(this._db);
  final Database _db;

  Future<List<TeamMember>> all() async =>
      (await _db.query('team_members', orderBy: 'name')).map(TeamMember.fromMap).toList();

  /// Team screen: each member with open-task count.
  Future<List<MemberWorkload>> workload({int? projectId}) async {
    final rows = await _db.rawQuery('''
      SELECT m.*,
             COALESCE(SUM(CASE WHEN t.status IS NOT NULL AND t.status != 'done' THEN 1 ELSE 0 END), 0) AS open_tasks,
             COUNT(t.id) AS total_tasks
      FROM team_members m
      LEFT JOIN tasks t ON t.assignee_id = m.id ${projectId == null ? '' : 'AND t.project_id = ?'}
      GROUP BY m.id
      ORDER BY open_tasks DESC, m.name
    ''', projectId == null ? [] : [projectId]);
    return rows
        .map((r) => MemberWorkload(member: TeamMember.fromMap(r), openTasks: r['open_tasks'] as int, totalTasks: r['total_tasks'] as int))
        .toList();
  }
}
