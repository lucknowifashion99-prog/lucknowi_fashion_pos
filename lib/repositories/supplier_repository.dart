import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/supplier.dart';

class SupplierRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> insert(Supplier supplier) async {
    final Database db = await _databaseHelper.database;

    return await db.insert(
      'suppliers',
      supplier.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Supplier>> getAll() async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'suppliers',
      orderBy: 'name ASC',
    );

    return result.map((e) => Supplier.fromMap(e)).toList();
  }

  Future<int> update(Supplier supplier) async {
    final Database db = await _databaseHelper.database;

    return await db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> delete(int id) async {
    final Database db = await _databaseHelper.database;

    return await db.delete(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}