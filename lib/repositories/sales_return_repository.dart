import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/sales_return.dart';
import '../models/sales_return_item.dart';

class SalesReturnRepository {
  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  // =========================================================
  // CREATE SALES RETURN
  // =========================================================

  Future<int> createReturn(
      SalesReturn salesReturn,
      List<SalesReturnItem> items,
      ) async {
    final Database db =
    await _databaseHelper.database;

    if (items.isEmpty) {
      throw Exception(
        'Return cannot be created without items.',
      );
    }

    return await db.transaction<int>(
          (txn) async {
        // =====================================================
        // CHECK ORIGINAL SALE
        // =====================================================

        final saleResult = await txn.query(
          'sales',
          where: 'id = ?',
          whereArgs: [salesReturn.saleId],
          limit: 1,
        );

        if (saleResult.isEmpty) {
          throw Exception(
            'Original sale not found.',
          );
        }

        final Sale sale =
        Sale.fromMap(saleResult.first);

        // =====================================================
        // TOTAL SALE GROSS
        // =====================================================

        final double totalSaleGross =
            sale.subtotal.toDouble() +
                sale.gst.toDouble();

        if (totalSaleGross <= 0) {
          throw Exception(
            'Invalid original sale total.',
          );
        }

        // =====================================================
        // RETURN CALCULATIONS
        // =====================================================

        double calculatedTotal = 0.0;

        final List<_ReturnCalculation>
        calculations = [];

        // =====================================================
        // CHECK EACH ITEM
        // =====================================================

        for (final item in items) {
          // ---------------------------------------------------
          // BASIC VALIDATION
          // ---------------------------------------------------

          if (item.saleItemId <= 0) {
            throw Exception(
              'Invalid sale item.',
            );
          }

          if (item.variantId <= 0) {
            throw Exception(
              'Invalid product variant.',
            );
          }

          if (item.quantity <= 0) {
            throw Exception(
              'Invalid return quantity for '
                  '${item.productName}.',
            );
          }

          // ---------------------------------------------------
          // GET ORIGINAL SALE ITEM
          // ---------------------------------------------------

          final saleItemResult =
          await txn.query(
            'sale_items',
            where:
            'id = ? AND saleId = ?',
            whereArgs: [
              item.saleItemId,
              salesReturn.saleId,
            ],
            limit: 1,
          );

          if (saleItemResult.isEmpty) {
            throw Exception(
              'Original sale item not found: '
                  '${item.productName}.',
            );
          }

          final SaleItem saleItem =
          SaleItem.fromMap(
            saleItemResult.first,
          );

          // ---------------------------------------------------
          // CHECK SALE ITEM QUANTITY
          // ---------------------------------------------------

          if (saleItem.quantity <= 0) {
            throw Exception(
              'Invalid original quantity for '
                  '${item.productName}.',
            );
          }

          // ---------------------------------------------------
          // TOTAL ALREADY RETURNED
          // ---------------------------------------------------

          final returnedResult =
          await txn.rawQuery(
            '''
            SELECT COALESCE(
              SUM(quantity),
              0
            ) AS returnedQuantity
            FROM sales_return_items sri
            INNER JOIN sales_returns sr
              ON sr.id = sri.returnId
            WHERE sri.saleItemId = ?
              AND sr.saleId = ?
            ''',
            [
              item.saleItemId,
              salesReturn.saleId,
            ],
          );

          final int alreadyReturned =
          _toInt(
            returnedResult.first[
            'returnedQuantity'],
          );

          // ---------------------------------------------------
          // AVAILABLE QUANTITY
          // ---------------------------------------------------

          final int availableQuantity =
              saleItem.quantity -
                  alreadyReturned;

          if (availableQuantity <= 0) {
            throw Exception(
              '${item.productName} is already '
                  'fully returned.',
            );
          }

          if (item.quantity >
              availableQuantity) {
            throw Exception(
              'Cannot return ${item.quantity} '
                  'of ${item.productName}. '
                  'Available return quantity: '
                  '$availableQuantity',
            );
          }

          // ---------------------------------------------------
          // VERIFY VARIANT
          // ---------------------------------------------------

          final variantResult =
          await txn.query(
            'product_variants',
            columns: [
              'id',
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

          // ---------------------------------------------------
          // VERIFY SALE ITEM VARIANT
          // ---------------------------------------------------

          if (saleItem.variantId !=
              item.variantId) {
            throw Exception(
              'Invalid variant selected for '
                  '${item.productName}.',
            );
          }

          // ===================================================
          // RETURN AMOUNT
          // ===================================================

          // saleItem.total already contains:
          // selling price + GST amount.
          final double lineGross =
          saleItem.total.toDouble();

          if (lineGross < 0) {
            throw Exception(
              'Invalid sale item amount for '
                  '${item.productName}.',
            );
          }

          // ---------------------------------------------------
          // PROPORTIONAL BILL DISCOUNT
          // ---------------------------------------------------

          final double saleDiscount =
          sale.discount.toDouble();

          double discountShare = 0.0;

          if (saleDiscount > 0 &&
              totalSaleGross > 0 &&
              lineGross > 0) {
            discountShare =
                saleDiscount *
                    (lineGross /
                        totalSaleGross);
          }

          // ---------------------------------------------------
          // NET LINE AMOUNT
          // ---------------------------------------------------

          double lineNet =
              lineGross -
                  discountShare;

          if (lineNet < 0) {
            lineNet = 0.0;
          }

          // ---------------------------------------------------
          // PER UNIT REFUND
          // ---------------------------------------------------

          final double perUnitNet =
              lineNet /
                  saleItem.quantity.toDouble();

          // ---------------------------------------------------
          // RETURN REFUND
          // ---------------------------------------------------

          final double returnTotal =
              perUnitNet *
                  item.quantity.toDouble();

          final double safeReturnTotal =
          _roundMoney(returnTotal);

          final double returnedDiscount =
          _roundMoney(
            discountShare *
                (
                    item.quantity.toDouble() /
                        saleItem.quantity.toDouble()
                ),
          );

          calculatedTotal +=
              safeReturnTotal;

          calculations.add(
            _ReturnCalculation(
              item: item,
              saleItem: saleItem,
              discountShare:
              returnedDiscount,
              returnTotal:
              safeReturnTotal,
            ),
          );
        }

        // =====================================================
        // SAVE RETURN HEADER
        // =====================================================

        final Map<String, dynamic> returnMap =
        salesReturn.toMap();

        returnMap['totalAmount'] =
            _roundMoney(calculatedTotal);

        final int returnId =
        await txn.insert(
          'sales_returns',
          returnMap,
          conflictAlgorithm:
          ConflictAlgorithm.abort,
        );

        // =====================================================
        // SAVE RETURN ITEMS
        // + RESTORE STOCK
        // =====================================================

        for (final calculation
        in calculations) {
          final SalesReturnItem item =
              calculation.item;

          final SaleItem saleItem =
              calculation.saleItem;

          final Map<String, dynamic>
          itemMap = item.toMap();

          itemMap['returnId'] =
              returnId;

          // ---------------------------------------------------
          // ORIGINAL SELLING PRICE
          // ---------------------------------------------------

          itemMap['sellingPrice'] =
              saleItem.sellingPrice
                  .toDouble();

          // ---------------------------------------------------
          // RETURN GST
          // ---------------------------------------------------

          itemMap['gst'] =
              _calculateReturnGst(
                saleItem: saleItem,
                returnQuantity:
                item.quantity,
              );

          // ---------------------------------------------------
          // PROPORTIONAL DISCOUNT
          // ---------------------------------------------------

          itemMap['discount'] =
              calculation.discountShare;

          // ---------------------------------------------------
          // ACTUAL REFUND
          // ---------------------------------------------------

          itemMap['total'] =
              calculation.returnTotal;

          // ---------------------------------------------------
          // INSERT RETURN ITEM
          // ---------------------------------------------------

          await txn.insert(
            'sales_return_items',
            itemMap,
            conflictAlgorithm:
            ConflictAlgorithm.abort,
          );

          // ---------------------------------------------------
          // RESTORE STOCK
          // ---------------------------------------------------

          final int updatedRows =
          await txn.rawUpdate(
            '''
            UPDATE product_variants
            SET stock = stock + ?
            WHERE id = ?
            ''',
            [
              item.quantity,
              item.variantId,
            ],
          );

          if (updatedRows != 1) {
            throw Exception(
              'Stock restore failed for '
                  '${item.productName}.',
            );
          }
        }

        return returnId;
      },
    );
  }

  // =========================================================
  // GET ALL RETURNS
  // =========================================================

  Future<List<SalesReturn>>
  getAllReturns() async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.query(
      'sales_returns',
      orderBy: 'id DESC',
    );

    return result
        .map(
          (e) => SalesReturn.fromMap(e),
    )
        .toList();
  }

  // =========================================================
  // GET RETURN BY ID
  // =========================================================

  Future<SalesReturn?> getReturnById(
      int id,
      ) async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.query(
      'sales_returns',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return SalesReturn.fromMap(
      result.first,
    );
  }

  // =========================================================
  // GET RETURN ITEMS
  // =========================================================

  Future<List<SalesReturnItem>>
  getReturnItems(
      int returnId,
      ) async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.query(
      'sales_return_items',
      where: 'returnId = ?',
      whereArgs: [returnId],
      orderBy: 'id ASC',
    );

    return result
        .map(
          (e) =>
          SalesReturnItem.fromMap(e),
    )
        .toList();
  }

  // =========================================================
  // GET RETURNS FOR SALE
  // =========================================================

  Future<List<SalesReturn>>
  getReturnsForSale(
      int saleId,
      ) async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.query(
      'sales_returns',
      where: 'saleId = ?',
      whereArgs: [saleId],
      orderBy: 'id DESC',
    );

    return result
        .map(
          (e) => SalesReturn.fromMap(e),
    )
        .toList();
  }

  // =========================================================
  // GET RETURNED QUANTITY
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
      ) AS returnedQuantity
      FROM sales_return_items
      WHERE saleItemId = ?
      ''',
      [saleItemId],
    );

    return _toInt(
      result.first[
      'returnedQuantity'],
    );
  }

  // =========================================================
  // GET AVAILABLE RETURN QUANTITY
  // =========================================================

  Future<int> getAvailableReturnQuantity(
      SaleItem saleItem,
      ) async {
    final int returned =
    await getReturnedQuantity(
      saleItem.id ?? 0,
    );

    final int available =
        saleItem.quantity -
            returned;

    if (available < 0) {
      return 0;
    }

    return available;
  }

  // =========================================================
  // TOTAL RETURN AMOUNT
  // =========================================================

  Future<double>
  getTotalReturnAmount() async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.rawQuery(
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
  // TODAY RETURN AMOUNT
  // =========================================================

  Future<double>
  getTodayReturnAmount() async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.rawQuery(
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
  // TOTAL RETURN COUNT
  // =========================================================

  Future<int>
  getTotalReturnCount() async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM sales_returns
      ''',
    );

    return _toInt(
      result.first['total'],
    );
  }

  // =========================================================
  // TODAY RETURN COUNT
  // =========================================================

  Future<int>
  getTodayReturnCount() async {
    final Database db =
    await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM sales_returns
      WHERE date(createdAt) =
            date('now', 'localtime')
      ''',
    );

    return _toInt(
      result.first['total'],
    );
  }

  // =========================================================
  // CALCULATE RETURN GST
  // =========================================================

  double _calculateReturnGst({
    required SaleItem saleItem,
    required int returnQuantity,
  }) {
    if (saleItem.quantity <= 0) {
      return 0.0;
    }

    final double originalGst =
    saleItem.gst.toDouble();

    final double perUnitGst =
        originalGst /
            saleItem.quantity.toDouble();

    final double returnGst =
        perUnitGst *
            returnQuantity.toDouble();

    return _roundMoney(returnGst);
  }

  // =========================================================
  // ROUND MONEY
  // =========================================================

  double _roundMoney(num value) {
    final double doubleValue =
    value.toDouble();

    final double rounded =
        (doubleValue * 100).round() /
            100;

    return rounded.toDouble();
  }

  // =========================================================
  // SAFE DOUBLE
  // =========================================================

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    ) ??
        0.0;
  }

  // =========================================================
  // SAFE INT
  // =========================================================

  int _toInt(dynamic value) {
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

// ===========================================================
// INTERNAL RETURN CALCULATION
// ===========================================================

class _ReturnCalculation {
  final SalesReturnItem item;
  final SaleItem saleItem;
  final double discountShare;
  final double returnTotal;

  _ReturnCalculation({
    required this.item,
    required this.saleItem,
    required this.discountShare,
    required this.returnTotal,
  });
}