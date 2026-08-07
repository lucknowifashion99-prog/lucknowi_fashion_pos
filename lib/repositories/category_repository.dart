import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/category.dart';

class CategoryRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> insert(Category category) async {
    final Database db = await _databaseHelper.database;

    try {
      print("========== INSERT CATEGORY ==========");
      print("Name : ${category.name}");

      final id = await db.insert(
        'categories',
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print("Inserted ID : $id");

      final result = await db.query('categories');

      print("Current Categories :");
      print(result);

      print("=====================================");

      return id;
    } catch (e) {
      print("INSERT ERROR : $e");
      rethrow;
    }
  }

  Future<List<Category>> getAll() async {
    final Database db = await _databaseHelper.database;

    try {
      final result = await db.query(
        'categories',
        orderBy: 'name ASC',
      );

      print("LOAD CATEGORY : $result");

      return result.map((e) => Category.fromMap(e)).toList();
    } catch (e) {
      print("LOAD ERROR : $e");
      return [];
    }
  }

  Future<int> update(Category category) async {
    final Database db = await _databaseHelper.database;

    try {
      final rows = await db.update(
        'categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );

      print("UPDATED ROWS : $rows");

      return rows;
    } catch (e) {
      print("UPDATE ERROR : $e");
      rethrow;
    }
  }

  Future<int> delete(int id) async {
    final Database db = await _databaseHelper.database;

    try {
      final rows = await db.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );

      print("DELETED ROWS : $rows");

      return rows;
    } catch (e) {
      print("DELETE ERROR : $e");
      rethrow;
    }
  }
}