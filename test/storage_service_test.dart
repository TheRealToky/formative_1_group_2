import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sla_tracker/data/db/app_database.dart';
import 'package:sla_tracker/models/task.dart';
import 'package:sla_tracker/models/team_member.dart';
import 'package:sla_tracker/services/storage_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late StorageService storage;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, seed: true);
    storage = StorageService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('loadMembers loads seeded members from SQLite', () async {
    final members = await storage.loadMembers();
    expect(members.length, 4);
    expect(members.map((m) => m.name), containsAll(['Amina', 'Jonas', 'Priya', 'Leo']));
  });

  test('saveMembers adds new members to SQLite', () async {
    final members = await storage.loadMembers();
    final newMember = TeamMember(id: '99', name: 'Zack');
    members.add(newMember);
    await storage.saveMembers(members);

    final updated = await storage.loadMembers();
    expect(updated.length, 5);
    expect(updated.any((m) => m.name == 'Zack'), isTrue);
  });

  test('loadTasks loads seeded tasks from SQLite', () async {
    final tasks = await storage.loadTasks();
    expect(tasks.length, 8);
    expect(tasks.first.title, 'Build login API');
  });

  test('saveTasks updates, adds, and removes tasks in SQLite', () async {
    final tasks = await storage.loadTasks();
    expect(tasks.isNotEmpty, true);

    // Toggle complete
    tasks.first.isCompleted = true;

    // Add a new task
    final newTask = Task(
      id: '100',
      title: 'New Unit Test Task',
      description: 'Test description',
      assigneeId: '1',
      priority: Priority.high,
      deadline: DateTime.now().add(const Duration(days: 3)),
      isCompleted: false,
    );
    tasks.add(newTask);

    // Remove one task
    tasks.removeAt(1);

    await storage.saveTasks(tasks);

    final reloaded = await storage.loadTasks();
    expect(reloaded.length, 8); // 8 - 1 + 1 = 8
    expect(reloaded.first.isCompleted, true);
    expect(reloaded.any((t) => t.title == 'New Unit Test Task'), isTrue);
  });

  test('current user session management works via SQLite session table', () async {
    expect(await storage.getCurrentUserId(), isNull);

    await storage.setCurrentUserId('1');
    expect(await storage.getCurrentUserId(), '1');

    await storage.clearSession();
    expect(await storage.getCurrentUserId(), isNull);
  });
}
