import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted, iterated SHA-256. Passwords are never stored in plain text.
/// This is fine for a local, offline app. If you add a server later, hash
/// there with bcrypt / Argon2 instead.
class PasswordHasher {
  static const int iterations = 10000;

  static String newSalt([int bytes = 16]) {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(bytes, (_) => r.nextInt(256)));
  }

  static String hash(String password, String salt) {
    final saltBytes = utf8.encode(salt);
    var digest = sha256.convert([...saltBytes, ...utf8.encode(password)]).bytes;
    for (var i = 1; i < iterations; i++) {
      digest = sha256.convert([...digest, ...saltBytes]).bytes;
    }
    return base64Url.encode(digest);
  }

  /// Constant-time comparison.
  static bool verify(String password, String salt, String expectedHash) {
    final actual = hash(password, salt);
    if (actual.length != expectedHash.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return diff == 0;
  }
}
