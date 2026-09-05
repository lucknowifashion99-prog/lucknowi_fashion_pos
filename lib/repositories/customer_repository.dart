import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/customer.dart';

class CustomerRepository {
  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  // =========================================================
  // INSERT CUSTOMER
  // =========================================================

  Future<int> insert(Customer customer) async {
    final Database db =
    await _databaseHelper.database;

    return await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm:
      ConflictAlgorithm.replace,
    );
  }

  // =========================================================
  // GET ALL CUSTOMERS
  // =========================================================

  Future<List<Customer>> getAll() async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.query(
      'customers',
      orderBy: 'name ASC',
    );

    return result
        .map(
          (e) => Customer.fromMap(e),
    )
        .toList();
  }

  // =========================================================
  // GET CUSTOMER BY ID
  // =========================================================

  Future<Customer?> getById(int id) async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Customer.fromMap(
      result.first,
    );
  }

  // =========================================================
  // UPDATE CUSTOMER
  // =========================================================

  Future<int> update(
      Customer customer,
      ) async {
    final Database db =
    await _databaseHelper.database;

    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  // =========================================================
  // DELETE CUSTOMER
  // =========================================================

  Future<int> delete(int id) async {
    final Database db =
    await _databaseHelper.database;

    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}