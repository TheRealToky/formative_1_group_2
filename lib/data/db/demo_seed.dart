import 'package:sqflite/sqflite.dart';

import '../auth/password_hasher.dart';

/// Sample data that matches the design mockups. Times are relative to "now"
/// so the overdue / SLA badges always have something to show.
class DemoSeed {
  /// Every demo account signs in with this password.
  static const demoPassword = 'password123';

  static Future<void> insert(Database db) async {
    final now = DateTime.now().toUtc();
    int at(Duration d) => now.add(d).millisecondsSinceEpoch;
    final t0 = now.millisecondsSinceEpoch;

    final batch = db.batch();
    for (final m in [
      ['Amina', 'Project lead', 'amina@example.com', '#1D4ED8'],
      ['Jonas', 'Developer', 'jonas@example.com', '#9A3412'],
      ['Priya', 'Developer', 'priya@example.com', '#1E3A8A'],
      ['Leo', 'QA tester', 'leo@example.com', '#374151'],
    ]) {
      final salt = PasswordHasher.newSalt();
      batch.insert('team_members', {
        'name': m[0], 'role': m[1], 'email': m[2], 'avatar_color': m[3],
        'password_salt': salt, 'password_hash': PasswordHasher.hash(demoPassword, salt), 'created_at': t0,
      });
    }
    batch.insert('projects', {'name': 'Mobile App v2', 'description': 'Second release of the mobile app', 'archived': 0, 'created_at': t0});

    // title, assignee, priority, status, due, sla, completed
    final tasks = <List<Object?>>[
      ['Build login API', 2, 'high', 'in_progress', at(const Duration(days: 2)), at(const Duration(hours: 6)), null],
      ['Design dashboard UI', 3, 'medium', 'in_progress', at(const Duration(days: 5)), null, null],
      ['Write test plan', 4, 'low', 'todo', at(const Duration(days: 7)), null, null],
      ['Fix sync bug', 1, 'high', 'todo', at(const Duration(days: -2)), at(const Duration(hours: -1)), null],
      ['Set up CI pipeline', 2, 'medium', 'todo', at(const Duration(days: 4)), at(const Duration(hours: 20)), null],
      ['Create onboarding screens', 3, 'medium', 'done', at(const Duration(days: -3)), null, at(const Duration(days: -4))],
      ['Define data model', 1, 'high', 'done', at(const Duration(days: -6)), null, at(const Duration(days: -7))],
      ['Draft requirements', 1, 'low', 'done', at(const Duration(days: -9)), null, at(const Duration(days: -10))],
    ];
    for (final t in tasks) {
      batch.insert('tasks', {
        'project_id': 1, 'title': t[0], 'assignee_id': t[1], 'created_by': 1,
        'priority': t[2], 'status': t[3], 'due_at': t[4], 'sla_due_at': t[5],
        'created_at': t0, 'updated_at': t0, 'completed_at': t[6],
      });
    }
    await batch.commit(noResult: true);
  }
}
