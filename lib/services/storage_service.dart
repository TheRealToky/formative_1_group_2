import 'package:sqflite/sqflite.dart';

import '../data/db/app_database.dart';
import '../models/task.dart';
import '../models/team_member.dart';

class StorageService {
  StorageService([this._testDb]);
  final Database? _testDb;

  Future<Database> get _db =>
      _testDb != null ? Future.value(_testDb) : AppDatabase.instance.database;

  Future<List<TeamMember>> loadMembers() async {
    final db = await _db;
    final rows = await db.query('team_members', orderBy: 'id ASC');
    return rows.map((r) => TeamMember(
      id: r['id'].toString(),
      name: r['name'] as String,
    )).toList();
  }

  Future<void> saveMembers(List<TeamMember> members) async {
    final db = await _db;
    for (final m in members) {
      final intId = int.tryParse(m.id);
      final existing = intId != null
          ? await db.query('team_members', where: 'id = ?', whereArgs: [intId])
          : await db.query('team_members', where: 'LOWER(name) = ?', whereArgs: [m.name.toLowerCase()]);

      if (existing.isEmpty) {
        await db.insert(
          'team_members',
          {
            'id': ?intId,
            'name': m.name,
            'role': 'Developer',
            'avatar_color': '#1D4ED8',
            'created_at': DateTime.now().toUtc().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  Future<List<Task>> loadTasks() async {
    final db = await _db;
    final rows = await db.query('tasks', orderBy: 'id ASC');
    return rows.map((r) {
      final status = r['status'] as String? ?? 'todo';
      final completedAt = r['completed_at'] as int?;
      final isDone = status == 'done' || completedAt != null;

      final dueAt = r['due_at'] as int?;
      final slaDueAt = r['sla_due_at'] as int?;
      final createdAt = r['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch;
      final deadlineMs = dueAt ?? slaDueAt ?? createdAt;

      final priorityStr = (r['priority'] as String?)?.toLowerCase();
      final priority = Priority.values.firstWhere(
        (p) => p.name == priorityStr,
        orElse: () => Priority.medium,
      );

      return Task(
        id: r['id'].toString(),
        title: r['title'] as String,
        description: (r['description'] as String?) ?? '',
        assigneeId: r['assignee_id']?.toString() ?? '',
        priority: priority,
        deadline: DateTime.fromMillisecondsSinceEpoch(deadlineMs),
        isCompleted: isDone,
      );
    }).toList();
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final db = await _db;

    // Ensure default project exists if needed
    final projectRows = await db.query('projects', limit: 1);
    final projectId = projectRows.isNotEmpty ? (projectRows.first['id'] as int) : 1;
    if (projectRows.isEmpty) {
      await db.insert(
        'projects',
        {
          'id': 1,
          'name': 'Mobile App v2',
          'description': 'Main project',
          'archived': 0,
          'created_at': DateTime.now().toUtc().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // Get current member IDs to validate foreign key constraint
    final memberRows = await db.query('team_members', columns: ['id']);
    final validMemberIds = memberRows.map((r) => r['id'] as int).toSet();

    // Query existing task IDs
    final existingRows = await db.query('tasks', columns: ['id']);
    final existingDbIds = existingRows.map((r) => r['id'] as int).toSet();

    final preservedDbIds = <int>{};

    for (final t in tasks) {
      final intId = int.tryParse(t.id);
      final rawAssignee = int.tryParse(t.assigneeId);
      final validAssignee = (rawAssignee != null && validMemberIds.contains(rawAssignee))
          ? rawAssignee
          : null;

      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final values = <String, Object?>{
        'project_id': projectId,
        'title': t.title,
        'description': t.description,
        'assignee_id': validAssignee,
        'priority': t.priority.name,
        'status': t.isCompleted ? 'done' : 'todo',
        'due_at': t.deadline.millisecondsSinceEpoch,
        'updated_at': now,
        'completed_at': t.isCompleted ? now : null,
      };

      if (intId != null && existingDbIds.contains(intId)) {
        await db.update('tasks', values, where: 'id = ?', whereArgs: [intId]);
        preservedDbIds.add(intId);
      } else {
        final newId = await db.insert(
          'tasks',
          {
            'id': ?intId,
            ...values,
            'created_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        preservedDbIds.add(intId ?? newId);
      }
    }

    // Delete tasks that were removed from the list
    for (final id in existingDbIds) {
      if (!preservedDbIds.contains(id)) {
        await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
      }
    }
  }

  Future<String?> getCurrentUserId() async {
    final db = await _db;
    final rows = await db.query('session', where: 'id = 1');
    if (rows.isEmpty) return null;
    return rows.first['member_id']?.toString();
  }

  Future<void> setCurrentUserId(String? id) async {
    final db = await _db;
    if (id == null) {
      await db.delete('session');
      return;
    }

    final memberId = int.tryParse(id);
    if (memberId == null) return;

    final member = await db.query('team_members', where: 'id = ?', whereArgs: [memberId]);
    if (member.isEmpty) return;

    await db.insert(
      'session',
      {
        'id': 1,
        'member_id': memberId,
        'signed_in_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearSession() async {
    final db = await _db;
    await db.delete('session');
  }
}
