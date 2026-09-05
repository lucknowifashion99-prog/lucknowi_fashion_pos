import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/color_model.dart';

class ColorRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> insert(ColorModel color) async {
    final Database db = await _databaseHelper.database;

    return await db.insert(
      'colors',
      color.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ColorModel>> getAll() async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'colors',
      orderBy: 'name ASC',
    );

    return result
        .map((e) => ColorModel.fromMap(e))
        .toList();
  }

  Future<int> update(ColorModel color) async {
    final Database db = await _databaseHelper.database;

    return await db.update(
      'colors',
      color.toMap(),
      where: 'id = ?',
      whereArgs: [color.id],
    );
  }

  Future<int> delete(int id) async {
    final Database db = await _databaseHelper.database;

    return await db.delete(
      'colors',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}