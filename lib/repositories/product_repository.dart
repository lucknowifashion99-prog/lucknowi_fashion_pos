import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/product_variant.dart';

class ProductRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // =========================================================
  // PRODUCT
  // =========================================================

  Future<int> insertProduct(Product product) async {
    final Database db = await _databaseHelper.database;

    return db.insert(
      'products',
      product.toMap(),
    );
  }

  Future<List<Product>> getAllProducts() async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'products',
      orderBy: 'name ASC',
    );

    return result
        .map((e) => Product.fromMap(e))
        .toList();
  }

  Future<Product?> getProductById(int id) async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Product.fromMap(result.first);
  }

  Future<int> updateProduct(Product product) async {
    final Database db = await _databaseHelper.database;

    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final Database db = await _databaseHelper.database;

    return db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================================================
  // PRODUCT VARIANTS
  // =========================================================

  Future<int> insertVariant(ProductVariant variant) async {
    final Database db = await _databaseHelper.database;

    return db.insert(
      'product_variants',
      variant.toMap(),
    );
  }

  Future<List<ProductVariant>> getVariants(
      int productId,
      ) async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'product_variants',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'id DESC',
    );

    return result
        .map((e) => ProductVariant.fromMap(e))
        .toList();
  }

  Future<ProductVariant?> getVariantById(
      int id,
      ) async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'product_variants',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return ProductVariant.fromMap(result.first);
  }

  // =========================================================
  // SEARCH SKU / BARCODE
  // =========================================================

  Future<ProductVariant?> searchVariantBySkuOrBarcode(
      String query,
      ) async {
    final Database db = await _databaseHelper.database;

    final search = query.trim().toLowerCase();

    if (search.isEmpty) {
      return null;
    }

    final result = await db.query(
      'product_variants',
      where: '''
        isActive = 1
        AND (
          LOWER(TRIM(sku)) = ?
          OR LOWER(TRIM(barcode)) = ?
        )
      ''',
      whereArgs: [
        search,
        search,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return ProductVariant.fromMap(
      result.first,
    );
  }

  // =========================================================
  // UPDATE VARIANT
  // =========================================================

  Future<int> updateVariant(
      ProductVariant variant,
      ) async {
    final Database db = await _databaseHelper.database;

    if (variant.id == null) {
      throw Exception(
        'Variant ID is missing. Cannot update variant.',
      );
    }

    final Map<String, dynamic> values = {
      'productId': variant.productId,
      'sku': variant.sku.trim(),
      'barcode': variant.barcode.trim(),
      'color': variant.color.trim(),
      'size': variant.size.trim(),
      'purchasePrice': variant.purchasePrice,
      'sellingPrice': variant.sellingPrice,
      'stock': variant.stock,
      'image': variant.image,
      'isActive': variant.isActive ? 1 : 0,
    };

    final int updatedRows = await db.update(
      'product_variants',
      values,
      where: 'id = ?',
      whereArgs: [variant.id],
    );

    return updatedRows;
  }

  // =========================================================
  // DELETE VARIANT
  // =========================================================

  Future<int> deleteVariant(
      int id,
      ) async {
    final Database db = await _databaseHelper.database;

    return db.delete(
      'product_variants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteVariantsByProductId(
      int productId,
      ) async {
    final Database db = await _databaseHelper.database;

    await db.delete(
      'product_variants',
      where: 'productId = ?',
      whereArgs: [productId],
    );
  }

  // =========================================================
  // STOCK
  // =========================================================

  Future<int> updateVariantStock(
      int variantId,
      int stock,
      ) async {
    final Database db = await _databaseHelper.database;

    return db.update(
      'product_variants',
      {
        'stock': stock,
      },
      where: 'id = ?',
      whereArgs: [variantId],
    );
  }
}