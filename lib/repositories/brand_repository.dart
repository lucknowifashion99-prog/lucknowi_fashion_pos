import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/brand.dart';

class BrandRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> insert(Brand brand) async {
    final Database db = await _databaseHelper.database;

    return await db.insert(
      'brands',
      brand.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Brand>> getAll() async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'brands',
      orderBy: 'name ASC',
    );

    return result.map((e) => Brand.fromMap(e)).toList();
  }

  Future<int> update(Brand brand) async {
    final Database db = await _databaseHelper.database;

    return await db.update(
      'brands',
      brand.toMap(),
      where: 'id = ?',
      whereArgs: [brand.id],
    );
  }

  Future<int> delete(int id) async {
    final Database db = await _databaseHelper.database;

    return await db.delete(
      'brands',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}