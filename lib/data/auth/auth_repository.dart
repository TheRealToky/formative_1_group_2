import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import 'password_hasher.dart';

enum AuthError { nameRequired, invalidEmail, weakPassword, emailTaken, wrongCredentials }

class AuthException implements Exception {
  const AuthException(this.error, this.message);
  final AuthError error;
  final String message; // safe to show in the UI
  @override
  String toString() => message;
}

/// Screens: Sign In and Sign Up. Owns the persisted session (who is signed in).
class AuthRepository {
  AuthRepository(this._db);
  final Database _db;

  /// Options for the Sign Up "Role" dropdown.
  static const roles = ['Project lead', 'Developer', 'QA tester', 'Designer'];
  static const minPasswordLength = 8;

  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static String normalizeEmail(String e) => e.trim().toLowerCase();

  // Use these in form validators for instant feedback (return null when valid).
  static String? validateEmail(String? v) => _emailRe.hasMatch(normalizeEmail(v ?? '')) ? null : 'Enter a valid email address';
  static String? validatePassword(String? v) => (v ?? '').length >= minPasswordLength ? null : 'Use at least $minPasswordLength characters';

  /// Creates the account and signs the new member in.
  Future<TeamMember> signUp({required String name, required String role, required String email, required String password}) async {
    if (name.trim().isEmpty) throw const AuthException(AuthError.nameRequired, 'Enter your name');
    if (validateEmail(email) != null) throw const AuthException(AuthError.invalidEmail, 'Enter a valid email address');
    if (validatePassword(password) != null) throw AuthException(AuthError.weakPassword, 'Use at least $minPasswordLength characters');

    final mail = normalizeEmail(email);
    return _db.transaction((txn) async {
      final taken = await txn.rawQuery('SELECT 1 FROM team_members WHERE lower(email) = ?', [mail]);
      if (taken.isNotEmpty) throw const AuthException(AuthError.emailTaken, 'An account with this email already exists');
      final salt = PasswordHasher.newSalt();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final id = await txn.insert('team_members', {
        'name': name.trim(),
        'role': role,
        'email': mail,
        'avatar_color': '#1D4ED8',
        'password_salt': salt,
        'password_hash': PasswordHasher.hash(password, salt),
        'created_at': now,
      });
      await _startSession(txn, id, now);
      return (await _memberIn(txn, id))!;
    });
  }

  /// Throws [AuthException] (wrongCredentials) for an unknown email or a wrong
  /// password; the message is the same for both on purpose.
  Future<TeamMember> signIn(String email, String password) async {
    const fail = AuthException(AuthError.wrongCredentials, 'Incorrect email or password');
    final rows = await _db.rawQuery('SELECT * FROM team_members WHERE lower(email) = ?', [normalizeEmail(email)]);
    if (rows.isEmpty) throw fail;
    final r = rows.first;
    final salt = r['password_salt'] as String?;
    final hash = r['password_hash'] as String?;
    if (salt == null || hash == null || !PasswordHasher.verify(password, salt, hash)) throw fail;
    await _startSession(_db, r['id'] as int, DateTime.now().toUtc().millisecondsSinceEpoch);
    return TeamMember.fromMap(r);
  }

  Future<void> signOut() => _db.delete('session');

  /// null => show the Sign In screen on app start.
  Future<TeamMember?> currentMember() async {
    final rows = await _db.rawQuery('SELECT m.* FROM session s JOIN team_members m ON m.id = s.member_id WHERE s.id = 1');
    return rows.isEmpty ? null : TeamMember.fromMap(rows.first);
  }

  /// Returns false if [oldPassword] is wrong.
  Future<bool> changePassword(int memberId, String oldPassword, String newPassword) async {
    if (validatePassword(newPassword) != null) throw AuthException(AuthError.weakPassword, 'Use at least $minPasswordLength characters');
    final rows = await _db.query('team_members', columns: ['password_salt', 'password_hash'], where: 'id = ?', whereArgs: [memberId]);
    if (rows.isEmpty) return false;
    final salt = rows.first['password_salt'] as String?;
    final hash = rows.first['password_hash'] as String?;
    if (salt == null || hash == null || !PasswordHasher.verify(oldPassword, salt, hash)) return false;
    final newSalt = PasswordHasher.newSalt();
    await _db.update('team_members', {'password_salt': newSalt, 'password_hash': PasswordHasher.hash(newPassword, newSalt)}, where: 'id = ?', whereArgs: [memberId]);
    return true;
  }

  Future<void> _startSession(DatabaseExecutor ex, int memberId, int at) =>
      ex.insert('session', {'id': 1, 'member_id': memberId, 'signed_in_at': at}, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<TeamMember?> _memberIn(DatabaseExecutor ex, int id) async {
    final rows = await ex.query('team_members', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : TeamMember.fromMap(rows.first);
  }
}
