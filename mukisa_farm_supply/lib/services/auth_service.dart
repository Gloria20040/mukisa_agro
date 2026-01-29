import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../database/db_helper.dart';

class AuthService {
  static String hashPassword(String password) => sha256.convert(utf8.encode(password)).toString();

  // returns user map {id, username, role} or null
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    final db = await DBHelper.instance.database;
    final hash = hashPassword(password);
    final rows = await db.query(
      'users',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, hash],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return {'id': r['id'], 'username': r['username'], 'role': r['role']};
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await DBHelper.instance.database;
    final res = await db.query('users', columns: ['id', 'username', 'role']);
    return res;
  }

  // Admin-only: set password for any user (returns true on success)
  static Future<bool> setPasswordForUser(int userId, String newPassword) async {
    final db = await DBHelper.instance.database;
    final newHash = hashPassword(newPassword);
    final info = await db.update('users', {'password_hash': newHash}, where: 'id = ?', whereArgs: [userId]);
    return info > 0;
  }

  // change password for given user id; returns true if successful
  static Future<bool> changePassword(int userId, String currentPassword, String newPassword) async {
    final db = await DBHelper.instance.database;
    final currentHash = hashPassword(currentPassword);
    final row = await db.query('users', where: 'id = ? AND password_hash = ?', whereArgs: [userId, currentHash], limit: 1);
    if (row.isEmpty) return false;
    final newHash = hashPassword(newPassword);
    await db.update('users', {'password_hash': newHash}, where: 'id = ?', whereArgs: [userId]);
    return true;
  }
}
