import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/size.dart';

class SizeRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> insert(SizeModel size) async {
    final Database db = await _databaseHelper.database;

    return await db.insert(
      'sizes',
      size.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SizeModel>> getAll() async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'sizes',
      orderBy: 'name ASC',
    );

    return result.map((e) => SizeModel.fromMap(e)).toList();
  }

  Future<int> update(SizeModel size) async {
    final Database db = await _databaseHelper.database;

    return await db.update(
      'sizes',
      size.toMap(),
      where: 'id = ?',
      whereArgs: [size.id],
    );
  }

  Future<int> delete(int id) async {
    final Database db = await _databaseHelper.database;

    return await db.delete(
      'sizes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}