import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

class SaleRepository {
  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  // =========================================================
  // CREATE SALE
  // =========================================================

  Future<int> createSale(
      Sale sale,
      List<SaleItem> items,
      ) async {
    final Database db =
    await _databaseHelper.database;

    if (items.isEmpty) {
      throw Exception(
        'Sale cannot be created without items.',
      );
    }

    return await db.transaction<int>(
          (txn) async {
        // =====================================================
        // CHECK STOCK FIRST
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

          final result = await txn.query(
            'product_variants',
            columns: [
              'stock',
              'isActive',
            ],
            where: 'id = ?',
            whereArgs: [
              item.variantId,
            ],
            limit: 1,
          );

          if (result.isEmpty) {
            throw Exception(
              'Product variant not found: '
                  '${item.productName}.',
            );
          }

          final isActive =
              (result.first['isActive'] as num?)
                  ?.toInt() ??
                  1;

          if (isActive != 1) {
            throw Exception(
              'Product variant is inactive: '
                  '${item.productName}.',
            );
          }

          final stock =
              (result.first['stock'] as num?)
                  ?.toInt() ??
                  0;

          if (stock < item.quantity) {
            throw Exception(
              'Insufficient stock for '
                  '${item.productName}. '
                  'Available stock: $stock',
            );
          }
        }

        // =====================================================
        // SAVE SALE
        // =====================================================

        final saleId = await txn.insert(
          'sales',
          sale.toMap(),
          conflictAlgorithm:
          ConflictAlgorithm.abort,
        );

        // =====================================================
        // SAVE ITEMS + REDUCE STOCK
        // =====================================================

        for (final item in items) {
          final itemMap =
          item.toMap();

          itemMap['saleId'] =
              saleId;

          await txn.insert(
            'sale_items',
            itemMap,
            conflictAlgorithm:
            ConflictAlgorithm.abort,
          );

          final updatedRows =
          await txn.rawUpdate(
            '''
            UPDATE product_variants
            SET stock = stock - ?
            WHERE id = ?
            AND isActive = 1
            AND stock >= ?
            ''',
            [
              item.quantity,
              item.variantId,
              item.quantity,
            ],
          );

          if (updatedRows != 1) {
            throw Exception(
              'Stock update failed for '
                  '${item.productName}.',
            );
          }
        }

        return saleId;
      },
    );
  }

  // =========================================================
  // GET ALL SALES
  // =========================================================

  Future<List<Sale>> getAllSales() async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.query(
      'sales',
      orderBy: 'id DESC',
    );

    return result
        .map(
          (e) => Sale.fromMap(e),
    )
        .toList();
  }

  // =========================================================
  // GET SALE BY ID
  // =========================================================

  Future<Sale?> getSaleById(
      int id,
      ) async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Sale.fromMap(
      result.first,
    );
  }

  // =========================================================
  // GET SALE ITEMS
  // =========================================================

  Future<List<SaleItem>> getSaleItems(
      int saleId,
      ) async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.query(
      'sale_items',
      where: 'saleId = ?',
      whereArgs: [saleId],
      orderBy: 'id ASC',
    );

    return result
        .map(
          (e) => SaleItem.fromMap(e),
    )
        .toList();
  }

  // =========================================================
  // GET RETURNED QUANTITY FOR SALE ITEM
  // =========================================================

  Future<int> getReturnedQuantity(
      int saleItemId,
      ) async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(
        SUM(quantity),
        0
      ) AS total
      FROM sales_return_items
      WHERE saleItemId = ?
      ''',
      [saleItemId],
    );

    return _toInt(
      result.first['total'],
    );
  }

  // =========================================================
  // GET ALL RETURNED QUANTITIES
  // =========================================================

  Future<Map<int, int>> getReturnedQuantities(
      int saleId,
      ) async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT
        sri.saleItemId,
        COALESCE(
          SUM(sri.quantity),
          0
        ) AS returnedQuantity
      FROM sales_return_items sri
      INNER JOIN sale_items si
        ON si.id = sri.saleItemId
      WHERE si.saleId = ?
      GROUP BY sri.saleItemId
      ''',
      [saleId],
    );

    final Map<int, int> returned =
    {};

    for (final row in result) {
      final saleItemId =
      _toInt(row['saleItemId']);

      final quantity =
      _toInt(row['returnedQuantity']);

      returned[saleItemId] =
          quantity;
    }

    return returned;
  }

  // =========================================================
  // CREATE PARTIAL SALES RETURN
  // =========================================================

  // =========================================================
// CREATE PARTIAL SALES RETURN
// DISCOUNT-AWARE + GST-AMOUNT-AWARE REFUND
// =========================================================

  Future<int> createSalesReturn({
    required Sale sale,
    required List<SaleItem> items,
    required Map<int, int> returnQuantities,
    required String refundMethod,
    String? reason,
    int? staffId,
  }) async {
    final Database db =
    await _databaseHelper.database;

    if (sale.id == null) {
      throw Exception('Invalid sale ID.');
    }

    if (items.isEmpty) {
      throw Exception('No sale items found.');
    }

    return await db.transaction<int>(
          (txn) async {
        double totalAmount = 0;

        final List<Map<String, dynamic>> returnItems = [];

        // =====================================================
        // BILL GROSS TOTAL
        //
        // SaleItem.gst is already GST AMOUNT,
        // NOT GST percentage.
        // =====================================================

        double billGrossTotal = 0;

        for (final item in items) {
          final itemGross =
              (item.sellingPrice * item.quantity) +
                  item.gst;

          billGrossTotal += itemGross;
        }

        if (billGrossTotal <= 0) {
          throw Exception('Invalid bill total.');
        }

        // =====================================================
        // PROCESS RETURN ITEMS
        // =====================================================

        for (final item in items) {
          final itemId = item.id;

          if (itemId == null) {
            throw Exception('Invalid sale item.');
          }

          final requestedQuantity =
              returnQuantities[itemId] ?? 0;

          if (requestedQuantity <= 0) {
            continue;
          }

          // ===================================================
          // ALREADY RETURNED
          // ===================================================

          final returnedResult =
          await txn.rawQuery(
            '''
          SELECT COALESCE(
            SUM(quantity),
            0
          ) AS total
          FROM sales_return_items
          WHERE saleItemId = ?
          ''',
            [itemId],
          );

          final alreadyReturned =
          _toInt(
            returnedResult.first['total'],
          );

          final remainingQuantity =
              item.quantity - alreadyReturned;

          if (remainingQuantity <= 0) {
            throw Exception(
              '${item.productName} has already been fully returned.',
            );
          }

          if (requestedQuantity > remainingQuantity) {
            throw Exception(
              'Cannot return $requestedQuantity '
                  'of ${item.productName}. '
                  'Only $remainingQuantity item(s) remaining for return.',
            );
          }

          // ===================================================
          // ITEM GROSS
          //
          // selling price + ACTUAL GST AMOUNT
          // ===================================================

          final itemBaseTotal =
              item.sellingPrice * item.quantity;

          final itemGstTotal =
              item.gst;

          final itemGrossTotal =
              itemBaseTotal + itemGstTotal;

          // ===================================================
          // PROPORTIONAL BILL DISCOUNT
          // ===================================================

          double itemDiscount = 0;

          if (sale.discount > 0 &&
              billGrossTotal > 0) {
            itemDiscount =
                sale.discount *
                    (itemGrossTotal /
                        billGrossTotal);
          }

          // ===================================================
          // ITEM NET AFTER DISCOUNT
          // =====================================================

          final itemNetTotal =
              itemGrossTotal - itemDiscount;

          // ===================================================
          // EFFECTIVE UNIT PAID PRICE
          // =====================================================

          final unitRefund =
              itemNetTotal / item.quantity;

          // ===================================================
          // RETURN TOTAL
          // ===================================================

          final itemReturnTotal =
              unitRefund * requestedQuantity;

          totalAmount += itemReturnTotal;

          // ===================================================
          // RETURN ITEM
          // ===================================================

          returnItems.add({
            'saleItemId': itemId,
            'variantId': item.variantId,
            'productName': item.productName,
            'color': item.color,
            'size': item.size,
            'sku': item.sku,
            'barcode': item.barcode,
            'quantity': requestedQuantity,

            // Actual amount customer paid per unit
            // AFTER proportional bill discount.
            'sellingPrice': unitRefund,

            // GST amount belonging to returned quantity.
            'gst':
            itemGstTotal /
                item.quantity *
                requestedQuantity,

            // Discount belonging to returned quantity.
            'discount':
            itemDiscount /
                item.quantity *
                requestedQuantity,

            'total': itemReturnTotal,
          });
        }

        // =====================================================
        // VALIDATION
        // =====================================================

        if (returnItems.isEmpty) {
          throw Exception(
            'Please select at least one item to return.',
          );
        }

        // =====================================================
        // ROUND TOTAL
        // =====================================================

        totalAmount = double.parse(
          totalAmount.toStringAsFixed(2),
        );

        // =====================================================
        // GENERATE RETURN NUMBER
        // =====================================================

        final now = DateTime.now();

        final returnNumber =
        _generateReturnNumber(now);

        // =====================================================
        // SAVE RETURN HEADER
        // =====================================================

        final returnId =
        await txn.insert(
          'sales_returns',
          {
            'returnNumber': returnNumber,
            'saleId': sale.id,
            'customerId': sale.customerId,
            'staffId': staffId ?? sale.staffId,
            'totalAmount': totalAmount,
            'refundMethod': refundMethod,
            'reason': reason,
            'createdAt':
            now.toIso8601String(),
          },
          conflictAlgorithm:
          ConflictAlgorithm.abort,
        );

        // =====================================================
        // SAVE RETURN ITEMS + RESTORE STOCK
        // =====================================================

        for (final returnItem in returnItems) {
          final variantId =
          _toInt(
            returnItem['variantId'],
          );

          final quantity =
          _toInt(
            returnItem['quantity'],
          );

          await txn.insert(
            'sales_return_items',
            {
              'returnId': returnId,
              ...returnItem,
            },
            conflictAlgorithm:
            ConflictAlgorithm.abort,
          );

          // ===================================================
          // RESTORE STOCK
          // ===================================================

          final updatedRows =
          await txn.rawUpdate(
            '''
          UPDATE product_variants
          SET stock = stock + ?
          WHERE id = ?
          ''',
            [
              quantity,
              variantId,
            ],
          );

          if (updatedRows != 1) {
            throw Exception(
              'Failed to restore stock for '
                  '${returnItem['productName']}.',
            );
          }
        }

        return returnId;
      },
    );
  }

  // =========================================================
  // GET RETURN BY ID
  // =========================================================

  Future<Map<String, dynamic>?>
  getSalesReturnById(
      int returnId,
      ) async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.query(
      'sales_returns',
      where: 'id = ?',
      whereArgs: [returnId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // =========================================================
  // GET RETURN ITEMS
  // =========================================================

  Future<List<Map<String, dynamic>>>
  getSalesReturnItems(
      int returnId,
      ) async {
    final Database db =
    await _databaseHelper.database;

    return await db.query(
      'sales_return_items',
      where: 'returnId = ?',
      whereArgs: [returnId],
      orderBy: 'id ASC',
    );
  }

  // =========================================================
  // GET ALL RETURNS
  // =========================================================

  Future<List<Map<String, dynamic>>>
  getAllSalesReturns() async {
    final Database db =
    await _databaseHelper.database;

    return await db.query(
      'sales_returns',
      orderBy: 'id DESC',
    );
  }

  // =========================================================
  // GET TODAY RETURNS
  // =========================================================

  Future<List<Map<String, dynamic>>>
  getTodaySalesReturns() async {
    final Database db =
    await _databaseHelper.database;

    return await db.query(
      'sales_returns',
      where:
      "date(createdAt) = date('now', 'localtime')",
      orderBy: 'id DESC',
    );
  }

  // =========================================================
  // GET TOTAL RETURN AMOUNT
  // =========================================================

  Future<double>
  getTotalReturnAmount() async {
    final Database db =
    await _databaseHelper.database;

    final result =
    await db.rawQuery(
      '''
      SELECT COALESCE(
        SUM(totalAmount),
        0
      ) AS total
      FROM sales_returns
      ''',
    );

    return _toDouble(
      result.first['total'],
    );
  }

  // =========================================================
  // GET TODAY RETURN AMOUNT
  // =========================================================

  Future<double>
  getTodayReturnAmount() async {
    final Database db =
    await _databaseHelper.database;

    final result =
    await db.rawQuery(
      '''
      SELECT COALESCE(
        SUM(totalAmount),
        0
      ) AS total
      FROM sales_returns
      WHERE date(createdAt) =
            date('now', 'localtime')
      ''',
    );

    return _toDouble(
      result.first['total'],
    );
  }

  // =========================================================
  // DELETE SALE + RESTORE COMPLETE STOCK
  // =========================================================

  Future<int> deleteSale(
      int saleId,
      ) async {
    final Database db =
    await _databaseHelper.database;

    return await db.transaction<int>(
          (txn) async {
        // ===================================================
        // GET SALE ITEMS
        // ===================================================

        final items =
        await txn.query(
          'sale_items',
          columns: [
            'variantId',
            'quantity',
          ],
          where: 'saleId = ?',
          whereArgs: [saleId],
        );

        // ===================================================
        // RESTORE STOCK
        // ===================================================

        for (final item in items) {
          final variantId =
          _toInt(
            item['variantId'],
          );

          final quantity =
          _toInt(
            item['quantity'],
          );

          if (variantId <= 0 ||
              quantity <= 0) {
            continue;
          }

          await txn.rawUpdate(
            '''
            UPDATE product_variants
            SET stock = stock + ?
            WHERE id = ?
            ''',
            [
              quantity,
              variantId,
            ],
          );
        }

        // ===================================================
        // DELETE SALE
        // ===================================================

        final deletedRows =
        await txn.delete(
          'sales',
          where: 'id = ?',
          whereArgs: [saleId],
        );

        return deletedRows;
      },
    );
  }

  // =========================================================
  // TODAY'S SALES
  // =========================================================

  Future<List<Sale>>
  getTodaySales() async {
    final Database db =
    await _databaseHelper.database;

    final result =
    await db.query(
      'sales',
      where:
      "date(createdAt) = date('now', 'localtime')",
      orderBy: 'id DESC',
    );

    return result
        .map(
          (e) => Sale.fromMap(e),
    )
        .toList();
  }

  // =========================================================
  // TOTAL SALES
  // =========================================================

  Future<double>
  getTotalSales() async {
    final Database db =
    await _databaseHelper.database;

    final result =
    await db.rawQuery(
      '''
      SELECT COALESCE(
        SUM(grandTotal),
        0
      ) AS total
      FROM sales
      ''',
    );

    return _toDouble(
      result.first['total'],
    );
  }

  // =========================================================
  // TODAY TOTAL
  // =========================================================

  Future<double>
  getTodayTotal() async {
    final Database db =
    await _databaseHelper.database;

    final result =
    await db.rawQuery(
      '''
      SELECT COALESCE(
        SUM(grandTotal),
        0
      ) AS total
      FROM sales
      WHERE date(createdAt) =
            date('now', 'localtime')
      ''',
    );

    return _toDouble(
      result.first['total'],
    );
  }

  // =========================================================
  // TOTAL SALES COUNT
  // =========================================================

  Future<int>
  getTotalSalesCount() async {
    final Database db =
    await _databaseHelper.database;

    final result =
    await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM sales
      ''',
    );

    return _toInt(
      result.first['total'],
    );
  }

  // =========================================================
  // TODAY SALES COUNT
  // =========================================================

  Future<int>
  getTodaySalesCount() async {
    final Database db =
    await _databaseHelper.database;

    final result =
    await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM sales
      WHERE date(createdAt) =
            date('now', 'localtime')
      ''',
    );

    return _toInt(
      result.first['total'],
    );
  }

  // =========================================================
  // GENERATE RETURN NUMBER
  // =========================================================

  String _generateReturnNumber(
      DateTime date,
      ) {
    final year =
    date.year.toString();

    final month =
    date.month.toString().padLeft(
      2,
      '0',
    );

    final day =
    date.day.toString().padLeft(
      2,
      '0',
    );

    final hour =
    date.hour.toString().padLeft(
      2,
      '0',
    );

    final minute =
    date.minute.toString().padLeft(
      2,
      '0',
    );

    final second =
    date.second.toString().padLeft(
      2,
      '0',
    );

    final millisecond =
    date.millisecond
        .toString()
        .padLeft(
      3,
      '0',
    );

    return 'RET-$year$month$day-$hour$minute$second$millisecond';
  }

  // =========================================================
  // DOUBLE HELPER
  // =========================================================

  double _toDouble(
      dynamic value,
      ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    ) ??
        0;
  }

  // =========================================================
  // INT HELPER
  // =========================================================

  int _toInt(
      dynamic value,
      ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    ) ??
        0;
  }
}