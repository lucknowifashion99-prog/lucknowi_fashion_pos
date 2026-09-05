import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class ReportRepository {
  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  // =========================================================
  // TODAY SALES - NET AFTER RETURNS
  // =========================================================

  Future<double> getTodaySales() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT
        (
          COALESCE(
            (
              SELECT SUM(grandTotal)
              FROM sales
              WHERE date(createdAt) =
                    date('now', 'localtime')
            ),
            0
          )
          -
          COALESCE(
            (
              SELECT SUM(totalAmount)
              FROM sales_returns
              WHERE date(createdAt) =
                    date('now', 'localtime')
            ),
            0
          )
        ) AS total
    ''');

    return _toDouble(result.first['total']);
  }

  // =========================================================
  // TODAY PURCHASE
  // =========================================================

  Future<double> getTodayPurchase() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(
        SUM(grandTotal),
        0
      ) AS total
      FROM purchases
      WHERE date(createdAt) =
            date('now', 'localtime')
    ''');

    return _toDouble(result.first['total']);
  }

  // =========================================================
  // TODAY RETURNS
  // =========================================================

  Future<double> getTodayReturns() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(
        SUM(totalAmount),
        0
      ) AS total
      FROM sales_returns
      WHERE date(createdAt) =
            date('now', 'localtime')
    ''');

    return _toDouble(result.first['total']);
  }

  // =========================================================
  // MONTHLY RETURNS
  // =========================================================

  Future<double> getMonthlyReturns() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(
        SUM(totalAmount),
        0
      ) AS total
      FROM sales_returns
      WHERE strftime(
        '%Y-%m',
        createdAt
      ) = strftime(
        '%Y-%m',
        'now',
        'localtime'
      )
    ''');

    return _toDouble(result.first['total']);
  }

  // =========================================================
  // MONTHLY SALES - NET AFTER RETURNS
  // =========================================================

  Future<double> getMonthlySales() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT
        (
          COALESCE(
            (
              SELECT SUM(grandTotal)
              FROM sales
              WHERE strftime(
                '%Y-%m',
                createdAt
              ) = strftime(
                '%Y-%m',
                'now',
                'localtime'
              )
            ),
            0
          )
          -
          COALESCE(
            (
              SELECT SUM(totalAmount)
              FROM sales_returns
              WHERE strftime(
                '%Y-%m',
                createdAt
              ) = strftime(
                '%Y-%m',
                'now',
                'localtime'
              )
            ),
            0
          )
        ) AS total
    ''');

    return _toDouble(result.first['total']);
  }

  // =========================================================
  // MONTHLY PURCHASE
  // =========================================================

  Future<double> getMonthlyPurchase() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(
        SUM(grandTotal),
        0
      ) AS total
      FROM purchases
      WHERE strftime(
        '%Y-%m',
        createdAt
      ) = strftime(
        '%Y-%m',
        'now',
        'localtime'
      )
    ''');

    return _toDouble(result.first['total']);
  }

  // =========================================================
  // TODAY PROFIT - RETURN ADJUSTED
  // =========================================================

  Future<double> getTodayProfit() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
    SELECT
      (
        -- ================================================
        -- TODAY GROSS PROFIT FROM SOLD ITEMS
        -- ================================================
        COALESCE(
          (
            SELECT SUM(
              (
                si.sellingPrice
                -
                CASE
                  WHEN si.purchasePrice > 0
                    THEN si.purchasePrice
                  ELSE COALESCE(
                    pv.purchasePrice,
                    0
                  )
                END
              ) * si.quantity
            )
            FROM sale_items si

            INNER JOIN sales s
              ON s.id = si.saleId

            LEFT JOIN product_variants pv
              ON pv.id = si.variantId

            WHERE date(s.createdAt) =
                  date('now', 'localtime')
          ),
          0
        )

        -

        -- ================================================
        -- RETURNED ITEM PROFIT
        -- ================================================
        COALESCE(
          (
            SELECT SUM(
              (
                sri.sellingPrice
                -
                CASE
                  WHEN si.purchasePrice > 0
                    THEN si.purchasePrice
                  ELSE COALESCE(
                    pv.purchasePrice,
                    0
                  )
                END
              ) * sri.quantity
            )
            FROM sales_return_items sri

            INNER JOIN sales_returns sr
              ON sr.id = sri.returnId

            INNER JOIN sale_items si
              ON si.id = sri.saleItemId

            LEFT JOIN product_variants pv
              ON pv.id = si.variantId

            WHERE date(sr.createdAt) =
                  date('now', 'localtime')
          ),
          0
        )

        -

        -- ================================================
        -- ORIGINAL BILL DISCOUNT
        -- ================================================
        COALESCE(
          (
            SELECT SUM(discount)
            FROM sales
            WHERE date(createdAt) =
                  date('now', 'localtime')
          ),
          0
        )

        +

        -- ================================================
        -- RETURNED SHARE OF BILL DISCOUNT
        --
        -- Return refund already includes proportional
        -- discount, therefore that discount portion should
        -- be added back when calculating remaining profit.
        -- ================================================
        COALESCE(
          (
            SELECT SUM(
              CASE
                WHEN (
                  originalSale.subtotal
                  + originalSale.gst
                ) > 0
                THEN
                  originalSale.discount
                  *
                  (
                    saleItem.total
                    /
                    (
                      originalSale.subtotal
                      + originalSale.gst
                    )
                  )
                  *
                  (
                    sri.quantity
                    /
                    CAST(
                      saleItem.quantity
                      AS REAL
                    )
                  )
                ELSE 0
              END
            )
            FROM sales_return_items sri

            INNER JOIN sales_returns sr
              ON sr.id = sri.returnId

            INNER JOIN sales originalSale
              ON originalSale.id = sr.saleId

            INNER JOIN sale_items saleItem
              ON saleItem.id = sri.saleItemId

            WHERE date(sr.createdAt) =
                  date('now', 'localtime')
          ),
          0
        )
      ) AS profit
  ''');

    return _toDouble(
      result.first['profit'],
    );
  }

  // =========================================================
  // MONTHLY PROFIT - RETURN ADJUSTED
  // =========================================================

  Future<double> getMonthlyProfit() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
    SELECT
      (
        -- ================================================
        -- MONTHLY GROSS PROFIT FROM SOLD ITEMS
        -- ================================================
        COALESCE(
          (
            SELECT SUM(
              (
                si.sellingPrice
                -
                CASE
                  WHEN si.purchasePrice > 0
                    THEN si.purchasePrice
                  ELSE COALESCE(
                    pv.purchasePrice,
                    0
                  )
                END
              ) * si.quantity
            )
            FROM sale_items si

            INNER JOIN sales s
              ON s.id = si.saleId

            LEFT JOIN product_variants pv
              ON pv.id = si.variantId

            WHERE strftime(
              '%Y-%m',
              s.createdAt
            ) = strftime(
              '%Y-%m',
              'now',
              'localtime'
            )
          ),
          0
        )

        -

        -- ================================================
        -- RETURNED ITEM PROFIT
        -- ================================================
        COALESCE(
          (
            SELECT SUM(
              (
                sri.sellingPrice
                -
                CASE
                  WHEN si.purchasePrice > 0
                    THEN si.purchasePrice
                  ELSE COALESCE(
                    pv.purchasePrice,
                    0
                  )
                END
              ) * sri.quantity
            )
            FROM sales_return_items sri

            INNER JOIN sales_returns sr
              ON sr.id = sri.returnId

            INNER JOIN sale_items si
              ON si.id = sri.saleItemId

            LEFT JOIN product_variants pv
              ON pv.id = si.variantId

            WHERE strftime(
              '%Y-%m',
              sr.createdAt
            ) = strftime(
              '%Y-%m',
              'now',
              'localtime'
            )
          ),
          0
        )

        -

        -- ================================================
        -- ORIGINAL BILL DISCOUNT
        -- ================================================
        COALESCE(
          (
            SELECT SUM(discount)
            FROM sales
            WHERE strftime(
              '%Y-%m',
              createdAt
            ) = strftime(
              '%Y-%m',
              'now',
              'localtime'
            )
          ),
          0
        )

        +

        -- ================================================
        -- RETURNED SHARE OF BILL DISCOUNT
        -- ================================================
        COALESCE(
          (
            SELECT SUM(
              CASE
                WHEN (
                  originalSale.subtotal
                  + originalSale.gst
                ) > 0
                THEN
                  originalSale.discount
                  *
                  (
                    saleItem.total
                    /
                    (
                      originalSale.subtotal
                      + originalSale.gst
                    )
                  )
                  *
                  (
                    sri.quantity
                    /
                    CAST(
                      saleItem.quantity
                      AS REAL
                    )
                  )
                ELSE 0
              END
            )
            FROM sales_return_items sri

            INNER JOIN sales_returns sr
              ON sr.id = sri.returnId

            INNER JOIN sales originalSale
              ON originalSale.id = sr.saleId

            INNER JOIN sale_items saleItem
              ON saleItem.id = sri.saleItemId

            WHERE strftime(
              '%Y-%m',
              sr.createdAt
            ) = strftime(
              '%Y-%m',
              'now',
              'localtime'
            )
          ),
          0
        )
      ) AS profit
  ''');

    return _toDouble(
      result.first['profit'],
    );
  }

  // =========================================================
  // CURRENT STOCK
  // =========================================================

  Future<int> getCurrentStock() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(
        SUM(stock),
        0
      ) AS total
      FROM product_variants
      WHERE isActive = 1
    ''');

    return _toInt(result.first['total']);
  }

  // =========================================================
  // LOW STOCK COUNT
  // =========================================================

  Future<int> getLowStockCount({
    int threshold = 5,
  }) async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM product_variants
      WHERE isActive = 1
      AND stock <= ?
      ''',
      [threshold],
    );

    return _toInt(result.first['total']);
  }

  // =========================================================
  // TOTAL PRODUCTS
  // =========================================================

  Future<int> getTotalProducts() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM products
    ''');

    return _toInt(result.first['total']);
  }

  // =========================================================
  // TOTAL VARIANTS
  // =========================================================

  Future<int> getTotalVariants() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM product_variants
      WHERE isActive = 1
    ''');

    return _toInt(result.first['total']);
  }

  // =========================================================
  // TOTAL SUPPLIERS
  // =========================================================

  Future<int> getTotalSuppliers() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM suppliers
    ''');

    return _toInt(result.first['total']);
  }

  // =========================================================
  // TOTAL CUSTOMERS
  // =========================================================

  Future<int> getTotalCustomers() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM customers
    ''');

    return _toInt(result.first['total']);
  }

  // =========================================================
  // TOP SELLING PRODUCTS - RETURN ADJUSTED
  // =========================================================

  Future<List<Map<String, dynamic>>>
  getTopSellingProducts({
    int limit = 5,
  }) async {
    final db = await _databaseHelper.database;

    return await db.rawQuery(
      '''
      SELECT
        base.productName,

        base.soldQuantity,

        COALESCE(
          (
            SELECT SUM(sri.quantity)
            FROM sales_return_items sri
            WHERE sri.productName =
                  base.productName
          ),
          0
        ) AS returnedQuantity,

        (
          base.soldQuantity
          -
          COALESCE(
            (
              SELECT SUM(sri.quantity)
              FROM sales_return_items sri
              WHERE sri.productName =
                    base.productName
            ),
            0
          )
        ) AS quantity,

        (
          base.soldAmount
          -
          COALESCE(
            (
              SELECT SUM(sri.total)
              FROM sales_return_items sri
              WHERE sri.productName =
                    base.productName
            ),
            0
          )
        ) AS total

      FROM
        (
          SELECT
            productName,
            COALESCE(
              SUM(quantity),
              0
            ) AS soldQuantity,
            COALESCE(
              SUM(total),
              0
            ) AS soldAmount
          FROM sale_items
          GROUP BY productName
        ) base

      WHERE
        (
          base.soldQuantity
          -
          COALESCE(
            (
              SELECT SUM(sri.quantity)
              FROM sales_return_items sri
              WHERE sri.productName =
                    base.productName
            ),
            0
          )
        ) > 0

      ORDER BY quantity DESC

      LIMIT ?
      ''',
      [limit],
    );
  }

  // =========================================================
  // LOW STOCK PRODUCTS
  // =========================================================

  Future<List<Map<String, dynamic>>>
  getLowStockProducts({
    int threshold = 5,
  }) async {
    final db = await _databaseHelper.database;

    return await db.rawQuery(
      '''
      SELECT
        pv.id,
        p.name AS productName,
        pv.color,
        pv.size,
        pv.sku,
        pv.stock

      FROM product_variants pv

      INNER JOIN products p
        ON p.id = pv.productId

      WHERE pv.isActive = 1
      AND pv.stock <= ?

      ORDER BY pv.stock ASC
      ''',
      [threshold],
    );
  }

  // =========================================================
  // STAFF-WISE SALES - NET AFTER RETURNS
  // RETURN IS ATTRIBUTED TO ORIGINAL SALE STAFF
  // =========================================================

  Future<List<Map<String, dynamic>>>
  getStaffWiseSales() async {
    final db = await _databaseHelper.database;

    return await db.rawQuery('''
      SELECT
        s.staffId AS staffId,

        COALESCE(
          st.name,
          'Unknown Staff'
        ) AS staffName,

        COALESCE(
          st.username,
          '-'
        ) AS username,

        COUNT(DISTINCT s.id) AS billCount,

        (
          COALESCE(
            SUM(s.grandTotal),
            0
          )
          -
          COALESCE(
            (
              SELECT SUM(sr.totalAmount)
              FROM sales_returns sr

              INNER JOIN sales originalSale
                ON originalSale.id = sr.saleId

              WHERE originalSale.staffId =
                    s.staffId
            ),
            0
          )
        ) AS sales,

        (
          COALESCE(
            SUM(s.grandTotal),
            0
          )
          -
          COALESCE(
            (
              SELECT SUM(sr.totalAmount)
              FROM sales_returns sr

              INNER JOIN sales originalSale
                ON originalSale.id = sr.saleId

              WHERE originalSale.staffId =
                    s.staffId
            ),
            0
          )
        ) AS totalSales,

        (
          COALESCE(
            (
              SELECT SUM(si2.quantity)
              FROM sale_items si2

              INNER JOIN sales s2
                ON s2.id = si2.saleId

              WHERE s2.staffId =
                    s.staffId
            ),
            0
          )
          -
          COALESCE(
            (
              SELECT SUM(sri.quantity)
              FROM sales_return_items sri

              INNER JOIN sales_returns sr
                ON sr.id = sri.returnId

              INNER JOIN sales originalSale
                ON originalSale.id = sr.saleId

              WHERE originalSale.staffId =
                    s.staffId
            ),
            0
          )
        ) AS itemsSold,

        (
          COALESCE(
            (
              SELECT SUM(
                (
                  si3.sellingPrice
                  -
                  CASE
                    WHEN si3.purchasePrice > 0
                      THEN si3.purchasePrice
                    ELSE COALESCE(
                      pv3.purchasePrice,
                      0
                    )
                  END
                ) * si3.quantity
              )
              FROM sale_items si3

              INNER JOIN sales s3
                ON s3.id = si3.saleId

              LEFT JOIN product_variants pv3
                ON pv3.id = si3.variantId

              WHERE s3.staffId =
                    s.staffId
            ),
            0
          )

          -

          COALESCE(
            (
              SELECT SUM(
                (
                  sri.sellingPrice
                  -
                  CASE
                    WHEN originalItem.purchasePrice > 0
                      THEN originalItem.purchasePrice
                    ELSE COALESCE(
                      originalVariant.purchasePrice,
                      0
                    )
                  END
                ) * sri.quantity
              )
              FROM sales_return_items sri

              INNER JOIN sales_returns sr
                ON sr.id = sri.returnId

              INNER JOIN sales originalSale
                ON originalSale.id = sr.saleId

              INNER JOIN sale_items originalItem
                ON originalItem.id =
                   sri.saleItemId

              LEFT JOIN product_variants originalVariant
                ON originalVariant.id =
                   originalItem.variantId

              WHERE originalSale.staffId =
                    s.staffId
            ),
            0
          )

          -

          COALESCE(
            (
              SELECT SUM(s4.discount)
              FROM sales s4
              WHERE s4.staffId =
                    s.staffId
            ),
            0
          )
        ) AS profit

      FROM sales s

      LEFT JOIN staff st
        ON st.id = s.staffId

      GROUP BY
        s.staffId,
        st.name,
        st.username

      ORDER BY sales DESC
    ''');
  }

  // =========================================================
  // TODAY STAFF-WISE SALES
  // =========================================================

  Future<List<Map<String, dynamic>>>
  getTodayStaffWiseSales() async {
    final db = await _databaseHelper.database;

    return await db.rawQuery('''
      SELECT
        s.staffId AS staffId,

        COALESCE(
          st.name,
          'Unknown Staff'
        ) AS staffName,

        COALESCE(
          st.username,
          '-'
        ) AS username,

        COUNT(DISTINCT s.id) AS billCount,

        (
          COALESCE(
            SUM(s.grandTotal),
            0
          )
          -
          COALESCE(
            (
              SELECT SUM(sr.totalAmount)
              FROM sales_returns sr

              INNER JOIN sales originalSale
                ON originalSale.id = sr.saleId

              WHERE originalSale.staffId =
                    s.staffId

              AND date(sr.createdAt) =
                  date('now', 'localtime')
            ),
            0
          )
        ) AS sales,

        (
          COALESCE(
            SUM(s.grandTotal),
            0
          )
          -
          COALESCE(
            (
              SELECT SUM(sr.totalAmount)
              FROM sales_returns sr

              INNER JOIN sales originalSale
                ON originalSale.id = sr.saleId

              WHERE originalSale.staffId =
                    s.staffId

              AND date(sr.createdAt) =
                  date('now', 'localtime')
            ),
            0
          )
        ) AS totalSales,

        (
          COALESCE(
            (
              SELECT SUM(si2.quantity)
              FROM sale_items si2

              INNER JOIN sales s2
                ON s2.id = si2.saleId

              WHERE s2.staffId =
                    s.staffId

              AND date(s2.createdAt) =
                  date('now', 'localtime')
            ),
            0
          )

          -

          COALESCE(
            (
              SELECT SUM(sri.quantity)
              FROM sales_return_items sri

              INNER JOIN sales_returns sr
                ON sr.id = sri.returnId

              INNER JOIN sales originalSale
                ON originalSale.id = sr.saleId

              WHERE originalSale.staffId =
                    s.staffId

              AND date(sr.createdAt) =
                  date('now', 'localtime')
            ),
            0
          )
        ) AS itemsSold,

        (
          COALESCE(
            (
              SELECT SUM(
                (
                  si3.sellingPrice
                  -
                  CASE
                    WHEN si3.purchasePrice > 0
                      THEN si3.purchasePrice
                    ELSE COALESCE(
                      pv3.purchasePrice,
                      0
                    )
                  END
                ) * si3.quantity
              )
              FROM sale_items si3

              INNER JOIN sales s3
                ON s3.id = si3.saleId

              LEFT JOIN product_variants pv3
                ON pv3.id = si3.variantId

              WHERE s3.staffId =
                    s.staffId

              AND date(s3.createdAt) =
                  date('now', 'localtime')
            ),
            0
          )

          -

          COALESCE(
            (
              SELECT SUM(
                (
                  sri.sellingPrice
                  -
                  CASE
                    WHEN originalItem.purchasePrice > 0
                      THEN originalItem.purchasePrice
                    ELSE COALESCE(
                      originalVariant.purchasePrice,
                      0
                    )
                  END
                ) * sri.quantity
              )
              FROM sales_return_items sri

              INNER JOIN sales_returns sr
                ON sr.id = sri.returnId

              INNER JOIN sales originalSale
                ON originalSale.id = sr.saleId

              INNER JOIN sale_items originalItem
                ON originalItem.id =
                   sri.saleItemId

              LEFT JOIN product_variants originalVariant
                ON originalVariant.id =
                   originalItem.variantId

              WHERE originalSale.staffId =
                    s.staffId

              AND date(sr.createdAt) =
                  date('now', 'localtime')
            ),
            0
          )

          -

          COALESCE(
            (
              SELECT SUM(s4.discount)
              FROM sales s4
              WHERE s4.staffId =
                    s.staffId

              AND date(s4.createdAt) =
                  date('now', 'localtime')
            ),
            0
          )
        ) AS profit

      FROM sales s

      LEFT JOIN staff st
        ON st.id = s.staffId

      WHERE date(s.createdAt) =
            date('now', 'localtime')

      GROUP BY
        s.staffId,
        st.name,
        st.username

      ORDER BY sales DESC
    ''');
  }

  // =========================================================
  // MONTHLY STAFF-WISE SALES
  // =========================================================

  Future<List<Map<String, dynamic>>>
  getMonthlyStaffWiseSales() async {
    final db = await _databaseHelper.database;

    return await db.rawQuery('''
      SELECT
        s.staffId AS staffId,

        COALESCE(
          st.name,
          'Unknown Staff'
        ) AS staffName,

        COALESCE(
          st.username,
          '-'
        ) AS username,

        COUNT(DISTINCT s.id) AS billCount,

        (
          COALESCE(
            SUM(s.grandTotal),
            0
          )
          -
          COALESCE(
            (
              SELECT SUM(sr.totalAmount)
              FROM sales_returns sr

              INNER JOIN sales originalSale
                ON originalSale.id = sr.saleId

              WHERE originalSale.staffId =
                    s.staffId

              AND strftime(
                '%Y-%m',
                sr.createdAt
              ) = strftime(
                '%Y-%m',
                'now',
                'localtime'
              )
            ),
            0
          )
        ) AS sales,

        (
          COALESCE(
            SUM(s.grandTotal),
            0
          )
          -
          COALESCE(
            (
              SELECT SUM(sr.totalAmount)
              FROM sales_returns sr

              INNER JOIN sales originalSale
                ON originalSale.id = sr.saleId

              WHERE originalSale.staffId =
                    s.staffId

              AND strftime(
                '%Y-%m',
                sr.createdAt
              ) = strftime(
                '%Y-%m',
                'now',
                'localtime'
              )
            ),
            0
          )
        ) AS totalSales,

        (
          COALESCE(
            (
              SELECT SUM(si2.quantity)
              FROM sale_items si2

              INNER JOIN sales s2
                ON s2.id = si2.saleId

              WHERE s2.staffId =
                    s.staffId

              AND strftime(
                '%Y-%m',
                s2.createdAt
              ) = strftime(
                '%Y-%m',
                'now',
                'localtime'
              )
            ),
            0
          )

          -

          COALESCE(
            (
              SELECT SUM(sri.quantity)
              FROM sales_return_items sri

              INNER JOIN sales_returns sr
                ON sr.id = sri.returnId

              INNER JOIN sales originalSale
                ON originalSale.id = sr.saleId

              WHERE originalSale.staffId =
                    s.staffId

              AND strftime(
                '%Y-%m',
                sr.createdAt
              ) = strftime(
                '%Y-%m',
                'now',
                'localtime'
              )
            ),
            0
          )
        ) AS itemsSold,

        (
          COALESCE(
            (
              SELECT SUM(
                (
                  si3.sellingPrice
                  -
                  CASE
                    WHEN si3.purchasePrice > 0
                      THEN si3.purchasePrice
                    ELSE COALESCE(
                      pv3.purchasePrice,
                      0
                    )
                  END
                ) * si3.quantity
              )
              FROM sale_items si3

              INNER JOIN sales s3
                ON s3.id = si3.saleId

              LEFT JOIN product_variants pv3
                ON pv3.id = si3.variantId

              WHERE s3.staffId =
                    s.staffId

              AND strftime(
                '%Y-%m',
                s3.createdAt
              ) = strftime(
                '%Y-%m',
                'now',
                'localtime'
              )
            ),
            0
          )

          -

          COALESCE(
            (
              SELECT SUM(
                (
                  sri.sellingPrice
                  -
                  CASE
                    WHEN originalItem.purchasePrice > 0
                      THEN originalItem.purchasePrice
                    ELSE COALESCE(
                      originalVariant.purchasePrice,
                      0
                    )
                  END
                ) * sri.quantity
              )
              FROM sales_return_items sri

              INNER JOIN sales_returns sr
                ON sr.id = sri.returnId

              INNER JOIN sales originalSale
                ON originalSale.id = sr.saleId

              INNER JOIN sale_items originalItem
                ON originalItem.id =
                   sri.saleItemId

              LEFT JOIN product_variants originalVariant
                ON originalVariant.id =
                   originalItem.variantId

              WHERE originalSale.staffId =
                    s.staffId

              AND strftime(
                '%Y-%m',
                sr.createdAt
              ) = strftime(
                '%Y-%m',
                'now',
                'localtime'
              )
            ),
            0
          )

          -

          COALESCE(
            (
              SELECT SUM(s4.discount)
              FROM sales s4
              WHERE s4.staffId =
                    s.staffId

              AND strftime(
                '%Y-%m',
                s4.createdAt
              ) = strftime(
                '%Y-%m',
                'now',
                'localtime'
              )
            ),
            0
          )
        ) AS profit

      FROM sales s

      LEFT JOIN staff st
        ON st.id = s.staffId

      WHERE strftime(
        '%Y-%m',
        s.createdAt
      ) = strftime(
        '%Y-%m',
        'now',
        'localtime'
      )

      GROUP BY
        s.staffId,
        st.name,
        st.username

      ORDER BY sales DESC
    ''');
  }

  // =========================================================
  // TOTAL STAFF SALES - NET AFTER RETURNS
  // =========================================================

  Future<double> getStaffTotalSales(
      int staffId,
      ) async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT
        (
          COALESCE(
            (
              SELECT SUM(grandTotal)
              FROM sales
              WHERE staffId = ?
            ),
            0
          )
          -
          COALESCE(
            (
              SELECT SUM(sr.totalAmount)
              FROM sales_returns sr

              INNER JOIN sales s
                ON s.id = sr.saleId

              WHERE s.staffId = ?
            ),
            0
          )
        ) AS total
      ''',
      [
        staffId,
        staffId,
      ],
    );

    return _toDouble(
      result.first['total'],
    );
  }

  // =========================================================
  // STAFF BILL COUNT
  // =========================================================

  Future<int> getStaffBillCount(
      int staffId,
      ) async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM sales
      WHERE staffId = ?
      ''',
      [staffId],
    );

    return _toInt(
      result.first['total'],
    );
  }

  // =========================================================
  // TODAY STAFF SALES - NET AFTER RETURNS
  // =========================================================

  Future<double> getTodayStaffSales(
      int staffId,
      ) async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT
        (
          COALESCE(
            (
              SELECT SUM(grandTotal)
              FROM sales
              WHERE staffId = ?
              AND date(createdAt) =
                  date('now', 'localtime')
            ),
            0
          )
          -
          COALESCE(
            (
              SELECT SUM(sr.totalAmount)
              FROM sales_returns sr

              INNER JOIN sales s
                ON s.id = sr.saleId

              WHERE s.staffId = ?

              AND date(sr.createdAt) =
                  date('now', 'localtime')
            ),
            0
          )
        ) AS total
      ''',
      [
        staffId,
        staffId,
      ],
    );

    return _toDouble(
      result.first['total'],
    );
  }

  // =========================================================
  // TODAY STAFF BILL COUNT
  // =========================================================

  Future<int> getTodayStaffBillCount(
      int staffId,
      ) async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM sales
      WHERE staffId = ?
      AND date(createdAt) =
          date('now', 'localtime')
      ''',
      [staffId],
    );

    return _toInt(
      result.first['total'],
    );
  }

  // =========================================================
  // TOTAL SALES - NET AFTER RETURNS
  // =========================================================

  Future<double> getTotalSales() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT
        (
          COALESCE(
            (
              SELECT SUM(grandTotal)
              FROM sales
            ),
            0
          )
          -
          COALESCE(
            (
              SELECT SUM(totalAmount)
              FROM sales_returns
            ),
            0
          )
        ) AS total
    ''');

    return _toDouble(
      result.first['total'],
    );
  }

  // =========================================================
  // TODAY SALES COUNT
  // =========================================================

  Future<int> getTodaySalesCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM sales
      WHERE date(createdAt) =
            date('now', 'localtime')
    ''');

    return _toInt(
      result.first['total'],
    );
  }

  // =========================================================
  // TOTAL SALES COUNT
  // =========================================================

  Future<int> getTotalSalesCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM sales
    ''');

    return _toInt(
      result.first['total'],
    );
  }

  // =========================================================
  // TODAY TOTAL
  // =========================================================

  Future<double> getTodayTotal() async {
    return await getTodaySales();
  }

  // =========================================================
  // HELPERS
  // =========================================================

  double _toDouble(dynamic value) {
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