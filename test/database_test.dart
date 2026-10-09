import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Adjust to your package name, e.g. package:sla_tracker/data/data.dart
import 'package:sla_tracker/data/data.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late TaskRepository tasks;
  late ProjectRepository projects;
  late MemberRepository members;
  late AuthRepository auth;

  setUp(() async {
    final db = await AppDatabase.open(path: inMemoryDatabasePath);
    tasks = TaskRepository(db);
    projects = ProjectRepository(db);
    members = MemberRepository(db);
    auth = AuthRepository(db);
  });

  test('seed data loads', () async {
    expect((await members.all()).length, 4);
    expect((await tasks.list()).length, 8);
  });

  test('dashboard stats and needs-attention', () async {
    final s = await projects.stats(1);
    expect(s.total, 8);
    expect(s.done, 3);
    expect(s.overdue, 1);
    expect((await tasks.needsAttention(1)).isNotEmpty, true);
  });

  test('create, complete, delete a task', () async {
    final id = await tasks.create(Task.draft(projectId: 1, title: 'New task', assigneeId: 2, priority: TaskPriority.high), changedBy: 1);
    await tasks.setStatus(id, TaskStatus.done, changedBy: 1);
    final t = (await tasks.getById(id))!;
    expect(t.status, TaskStatus.done);
    expect(t.completedAt, isNotNull);
    expect((await tasks.history(id)).length, 2); // created + status
    await tasks.delete(id);
    expect(await tasks.getById(id), isNull);
  });

  test('sign in with a seeded account, then sign out', () async {
    expect(await auth.currentMember(), isNull);
    final m = await auth.signIn('Amina@Example.com', DemoSeed.demoPassword);
    expect(m.name, 'Amina');
    expect((await auth.currentMember())!.id, m.id);
    await auth.signOut();
    expect(await auth.currentMember(), isNull);
  });

  test('wrong password is rejected', () async {
    expect(() => auth.signIn('amina@example.com', 'nope'), throwsA(isA<AuthException>()));
  });

  test('sign up creates an account, signs in, and blocks duplicate emails', () async {
    final m = await auth.signUp(name: 'Sam', role: 'Developer', email: 'sam@example.com', password: 'secret123');
    expect((await auth.currentMember())!.id, m.id);
    await auth.signOut();
    expect((await auth.signIn('sam@example.com', 'secret123')).name, 'Sam');
    expect(() => auth.signUp(name: 'Sam 2', role: 'Developer', email: 'SAM@example.com', password: 'secret123'), throwsA(isA<AuthException>()));
  });
}
