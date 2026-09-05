import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/staff.dart';

class StaffRepository {
  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  // =========================================================
  // GET ALL STAFF
  // =========================================================

  Future<List<Staff>> getAll() async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.query(
      'staff',
      orderBy: 'id DESC',
    );

    return result
        .map((e) => Staff.fromMap(e))
        .toList();
  }

  // =========================================================
  // GET BY USERNAME
  // =========================================================

  Future<Staff?> getByUsername(
      String username,
      ) async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.query(
      'staff',
      where: 'username = ?',
      whereArgs: [username.trim()],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Staff.fromMap(result.first);
  }

  // =========================================================
  // ENSURE DEFAULT ADMIN
  // =========================================================

  Future<void> ensureDefaultAdmin() async {
    final Database db =
    await _databaseHelper.database;

    final existing = await db.query(
      'staff',
      where: 'username = ?',
      whereArgs: ['admin'],
      limit: 1,
    );

    // =======================================================
    // ADMIN ALREADY EXISTS
    // =======================================================

    if (existing.isNotEmpty) {
      final existingAdmin = existing.first;

      final adminId =
      (existingAdmin['id'] as num?)?.toInt();

      if (adminId != null) {
        // Make absolutely sure admin account
        // has Admin role and is active.
        await db.update(
          'staff',
          {
            'role': 'Admin',
            'isActive': 1,
          },
          where: 'id = ?',
          whereArgs: [adminId],
        );
      }

      return;
    }

    // =======================================================
    // CREATE DEFAULT ADMIN
    // =======================================================

    await db.insert(
      'staff',
      {
        'name': 'Administrator',
        'username': 'admin',
        'password': 'admin123',
        'role': 'Admin',
        'isActive': 1,
        'createdAt':
        DateTime.now().toIso8601String(),
      },
    );
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<Staff?> login(
      String username,
      String password,
      ) async {
    final cleanUsername =
    username.trim();

    final cleanPassword =
    password.trim();

    // Make sure default admin exists
    // and has Admin role.
    await ensureDefaultAdmin();

    final Database db =
    await _databaseHelper.database;

    final result = await db.query(
      'staff',
      where: '''
        username = ?
        AND password = ?
        AND isActive = 1
      ''',
      whereArgs: [
        cleanUsername,
        cleanPassword,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Staff.fromMap(result.first);
  }

  // =========================================================
  // ADD STAFF
  // =========================================================

  Future<int> insert(
      Staff staff,
      ) async {
    final Database db =
    await _databaseHelper.database;

    return await db.insert(
      'staff',
      staff.toMap(),
    );
  }

  // =========================================================
  // UPDATE STAFF
  // =========================================================

  Future<int> update(
      Staff staff,
      ) async {
    final Database db =
    await _databaseHelper.database;

    return await db.update(
      'staff',
      staff.toMap(),
      where: 'id = ?',
      whereArgs: [staff.id],
    );
  }

  // =========================================================
  // DELETE STAFF
  // =========================================================

  Future<int> delete(
      int id,
      ) async {
    final Database db =
    await _databaseHelper.database;

    return await db.delete(
      'staff',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================================================
  // ACTIVE / INACTIVE
  // =========================================================

  Future<int> setActive(
      int id,
      bool active,
      ) async {
    final Database db =
    await _databaseHelper.database;

    return await db.update(
      'staff',
      {
        'isActive': active ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}