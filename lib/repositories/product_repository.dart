import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/product.dart';

class ProductRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> insertProduct(Product product) async {
    final Database db = await _databaseHelper.database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'products',
      orderBy: 'name ASC',
    );

    return result.map((e) => Product.fromMap(e)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final Database db = await _databaseHelper.database;

    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final Database db = await _databaseHelper.database;

    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}