import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/category.dart';

class CategoryRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> insert(Category category) async {
    final Database db = await _databaseHelper.database;

    return await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Category>> getAll() async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'categories',
      orderBy: 'name ASC',
    );

    return result.map((e) => Category.fromMap(e)).toList();
  }

  Future<int> update(Category category) async {
    final Database db = await _databaseHelper.database;

    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> delete(int id) async {
    final Database db = await _databaseHelper.database;

    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}