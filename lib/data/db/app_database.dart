import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'demo_seed.dart';
import 'schema.dart';

/// Single access point to the SQLite database.
///
///   final db = await AppDatabase.instance.database;
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  Future<Database> get database async => _db ??= await open();

  /// [path] defaults to the app's databases folder. Pass `inMemoryDatabasePath`
  /// in tests. Set [seed] to false for a clean production database.
  static Future<Database> open({String? path, bool seed = true}) async {
    final dbPath = path ?? p.join(await getDatabasesPath(), 'task_tracker.db');
    return openDatabase(
      dbPath,
      version: kDbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        for (final sql in kSchemaStatements) {
          await db.execute(sql);
        }
        if (seed) await DemoSeed.insert(db);
      },
      onUpgrade: (db, from, to) async {
        if (from < 2) {
          // v2: sign in / sign up. Accounts created in v1 have no password
          // (they cannot sign in); use AuthRepository.signUp for new ones.
          await db.execute('ALTER TABLE team_members ADD COLUMN password_hash TEXT');
          await db.execute('ALTER TABLE team_members ADD COLUMN password_salt TEXT');
          await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_members_email ON team_members(lower(email))');
        }
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Deletes the file and recreates it (handy during development).
  Future<void> reset() async {
    await close();
    await deleteDatabase(p.join(await getDatabasesPath(), 'task_tracker.db'));
    await database;
  }
}
