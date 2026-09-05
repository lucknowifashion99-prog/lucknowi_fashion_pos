import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class PurchaseRepository {
  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  // =========================================================
  // SAVE PURCHASE
  // =========================================================

  Future<int> savePurchase({
    required String invoiceNumber,
    required int? supplierId,
    required double subtotal,
    required double discount,
    required double gst,
    required double grandTotal,
    required String paymentMethod,
    required String paymentStatus,
    required String createdAt,
    required List<PurchaseItemData> items,
  }) async {
    final db = await _databaseHelper.database;

    // -------------------------------------------------------
    // BASIC VALIDATION
    // -------------------------------------------------------

    if (invoiceNumber.trim().isEmpty) {
      throw Exception(
        'Invoice number is required.',
      );
    }

    if (items.isEmpty) {
      throw Exception(
        'Purchase cannot be created without items.',
      );
    }

    if (subtotal < 0 ||
        discount < 0 ||
        gst < 0 ||
        grandTotal < 0) {
      throw Exception(
        'Invalid purchase amount.',
      );
    }

    return await db.transaction<int>(
          (txn) async {
        // =====================================================
        // VALIDATE ALL ITEMS FIRST
        // =====================================================

        for (final item in items) {
          if (item.variantId <= 0) {
            throw Exception(
              'Invalid product variant.',
            );
          }

          if (item.quantity <= 0) {
            throw Exception(
              'Invalid quantity for ${item.productName}.',
            );
          }

          if (item.purchasePrice <= 0) {
            throw Exception(
              'Invalid purchase price for '
                  '${item.productName}.',
            );
          }

          // ---------------------------------------------------
          // CHECK VARIANT
          // ---------------------------------------------------

          final variantResult = await txn.query(
            'product_variants',
            columns: [
              'id',
              'stock',
              'isActive',
            ],
            where: 'id = ?',
            whereArgs: [
              item.variantId,
            ],
            limit: 1,
          );

          if (variantResult.isEmpty) {
            throw Exception(
              'Product variant not found: '
                  '${item.productName}.',
            );
          }

          final variant =
              variantResult.first;

          final isActive =
              (variant['isActive'] as num?)
                  ?.toInt() ??
                  1;

          if (isActive != 1) {
            throw Exception(
              'Product variant is inactive: '
                  '${item.productName}.',
            );
          }
        }

        // =====================================================
        // CREATE PURCHASE HEADER
        // =====================================================

        final purchaseId = await txn.insert(
          'purchases',
          {
            'invoiceNumber':
            invoiceNumber.trim(),
            'supplierId': supplierId,
            'subtotal': subtotal,
            'discount': discount,
            'gst': gst,
            'grandTotal': grandTotal,
            'paymentMethod':
            paymentMethod.trim().isEmpty
                ? 'Cash'
                : paymentMethod.trim(),
            'paymentStatus':
            paymentStatus.trim().isEmpty
                ? 'Paid'
                : paymentStatus.trim(),
            'createdAt': createdAt,
          },
          conflictAlgorithm:
          ConflictAlgorithm.abort,
        );

        // =====================================================
        // SAVE ITEMS + INCREASE STOCK
        // =====================================================

        for (final item in items) {
          // ---------------------------------------------------
          // SAVE PURCHASE ITEM
          // ---------------------------------------------------

          await txn.insert(
            'purchase_items',
            {
              'purchaseId': purchaseId,
              'variantId': item.variantId,
              'productName': item.productName,
              'color': item.color,
              'size': item.size,
              'sku': item.sku,
              'barcode': item.barcode,
              'quantity': item.quantity,
              'purchasePrice':
              item.purchasePrice,
              'gst': item.gst,
              'discount': item.discount,
              'total': item.total,
            },
            conflictAlgorithm:
            ConflictAlgorithm.abort,
          );

          // ---------------------------------------------------
          // INCREASE STOCK + UPDATE PURCHASE PRICE
          // ---------------------------------------------------

          final updatedRows =
          await txn.rawUpdate(
            '''
            UPDATE product_variants
            SET
              stock = stock + ?,
              purchasePrice = ?
            WHERE id = ?
            AND isActive = 1
            ''',
            [
              item.quantity,
              item.purchasePrice,
              item.variantId,
            ],
          );

          if (updatedRows != 1) {
            throw Exception(
              'Stock update failed for '
                  '${item.productName}.',
            );
          }
        }

        return purchaseId;
      },
    );
  }

  // =========================================================
  // GET ALL PURCHASES
  // =========================================================

  Future<List<Map<String, dynamic>>>
  getAllPurchases() async {
    final db =
    await _databaseHelper.database;

    return await db.query(
      'purchases',
      orderBy: 'id DESC',
    );
  }

  // =========================================================
  // GET PURCHASE ITEMS
  // =========================================================

  Future<List<Map<String, dynamic>>>
  getPurchaseItems(
      int purchaseId,
      ) async {
    final db =
    await _databaseHelper.database;

    return await db.query(
      'purchase_items',
      where: 'purchaseId = ?',
      whereArgs: [
        purchaseId,
      ],
      orderBy: 'id ASC',
    );
  }

  // =========================================================
  // GET PURCHASE BY ID
  // =========================================================

  Future<Map<String, dynamic>?>
  getPurchaseById(
      int purchaseId,
      ) async {
    final db =
    await _databaseHelper.database;

    final result = await db.query(
      'purchases',
      where: 'id = ?',
      whereArgs: [
        purchaseId,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // =========================================================
  // DELETE PURCHASE + RESTORE/REVERSE STOCK
  // =========================================================

  Future<void> deletePurchase(
      int purchaseId,
      ) async {
    final db =
    await _databaseHelper.database;

    await db.transaction(
          (txn) async {
        // ===================================================
        // CHECK PURCHASE EXISTS
        // ===================================================

        final purchaseResult =
        await txn.query(
          'purchases',
          columns: [
            'id',
            'invoiceNumber',
          ],
          where: 'id = ?',
          whereArgs: [
            purchaseId,
          ],
          limit: 1,
        );

        if (purchaseResult.isEmpty) {
          throw Exception(
            'Purchase not found.',
          );
        }

        final invoiceNumber =
            purchaseResult.first[
            'invoiceNumber']
                ?.toString() ??
                '-';

        // ===================================================
        // GET PURCHASE ITEMS
        // ===================================================

        final items = await txn.query(
          'purchase_items',
          columns: [
            'variantId',
            'productName',
            'quantity',
          ],
          where: 'purchaseId = ?',
          whereArgs: [
            purchaseId,
          ],
        );

        if (items.isEmpty) {
          throw Exception(
            'No items found for purchase '
                '$invoiceNumber.',
          );
        }

        // ===================================================
        // CHECK STOCK BEFORE REVERSING
        // ===================================================

        for (final item in items) {
          final variantId =
              (item['variantId'] as num?)
                  ?.toInt() ??
                  0;

          final quantity =
              (item['quantity'] as num?)
                  ?.toInt() ??
                  0;

          final productName =
              item['productName']
                  ?.toString() ??
                  'Product';

          if (variantId <= 0) {
            throw Exception(
              'Invalid variant for '
                  '$productName.',
            );
          }

          if (quantity <= 0) {
            throw Exception(
              'Invalid quantity for '
                  '$productName.',
            );
          }

          final variantResult =
          await txn.query(
            'product_variants',
            columns: [
              'stock',
              'isActive',
            ],
            where: 'id = ?',
            whereArgs: [
              variantId,
            ],
            limit: 1,
          );

          if (variantResult.isEmpty) {
            throw Exception(
              'Variant not found for '
                  '$productName.',
            );
          }

          final currentStock =
              (variantResult.first[
              'stock']
              as num?)
                  ?.toInt() ??
                  0;

          // -------------------------------------------------
          // IMPORTANT:
          // Purchase delete cannot make stock negative.
          // -------------------------------------------------

          if (currentStock < quantity) {
            throw Exception(
              'Cannot delete purchase '
                  '$invoiceNumber.\n\n'
                  '$productName stock is '
                  '$currentStock, but this purchase '
                  'added $quantity.\n\n'
                  'Some stock from this purchase '
                  'has already been sold or removed.',
            );
          }
        }

        // ===================================================
        // REVERSE STOCK
        // ===================================================

        for (final item in items) {
          final variantId =
              (item['variantId'] as num?)
                  ?.toInt() ??
                  0;

          final quantity =
              (item['quantity'] as num?)
                  ?.toInt() ??
                  0;

          final productName =
              item['productName']
                  ?.toString() ??
                  'Product';

          final updatedRows =
          await txn.rawUpdate(
            '''
            UPDATE product_variants
            SET stock = stock - ?
            WHERE id = ?
            AND stock >= ?
            ''',
            [
              quantity,
              variantId,
              quantity,
            ],
          );

          if (updatedRows != 1) {
            throw Exception(
              'Stock reversal failed for '
                  '$productName.',
            );
          }
        }

        // ===================================================
        // DELETE PURCHASE
        // ===================================================

        final deletedRows =
        await txn.delete(
          'purchases',
          where: 'id = ?',
          whereArgs: [
            purchaseId,
          ],
        );

        if (deletedRows != 1) {
          throw Exception(
            'Purchase deletion failed.',
          );
        }
      },
    );
  }
}

// =============================================================
// PURCHASE ITEM DATA
// =============================================================

class PurchaseItemData {
  final int variantId;

  final String productName;

  final String? color;

  final String? size;

  final String? sku;

  final String? barcode;

  final int quantity;

  final double purchasePrice;

  final double gst;

  final double discount;

  final double total;

  const PurchaseItemData({
    required this.variantId,
    required this.productName,
    this.color,
    this.size,
    this.sku,
    this.barcode,
    required this.quantity,
    required this.purchasePrice,
    required this.gst,
    required this.discount,
    required this.total,
  });
}