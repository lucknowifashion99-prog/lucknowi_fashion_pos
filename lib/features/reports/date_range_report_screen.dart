import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database_helper.dart';
import '../../features/reports/report_excel_service.dart';
import 'report_pdf_service.dart';

class DateRangeReportScreen extends StatefulWidget {
  const DateRangeReportScreen({super.key});

  @override
  State<DateRangeReportScreen> createState() =>
      _DateRangeReportScreenState();
}

class _DateRangeReportScreenState
    extends State<DateRangeReportScreen> {
  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  bool _loading = false;

  double _sales = 0;
  double _returns = 0;
  double _netSales = 0;
  double _purchase = 0;
  double _profit = 0;

  final DateFormat _format = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReport();
    });
  }

  // =========================================================
  // DATE
  // =========================================================

  String _date(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // =========================================================
  // FROM DATE
  // =========================================================

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      _fromDate = picked;

      if (_toDate.isBefore(_fromDate)) {
        _toDate = _fromDate;
      }
    });

    await _loadReport();
  }

  // =========================================================
  // TO DATE
  // =========================================================

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      _toDate = picked;
    });

    await _loadReport();
  }

  // =========================================================
  // LOAD REPORT
  // =========================================================

  Future<void> _loadReport() async {
    if (_fromDate.isAfter(_toDate)) return;

    setState(() {
      _loading = true;
    });

    try {
      final db = await _databaseHelper.database;

      final from = _date(_fromDate);
      final to = _date(_toDate);

      // =====================================================
      // SALES
      // =====================================================

      final salesResult = await db.rawQuery(
        '''
        SELECT COALESCE(
          SUM(grandTotal),
          0
        ) AS total
        FROM sales
        WHERE date(createdAt)
          BETWEEN ? AND ?
        ''',
        [from, to],
      );

      // =====================================================
      // RETURNS
      // =====================================================

      final returnsResult = await db.rawQuery(
        '''
        SELECT COALESCE(
          SUM(totalAmount),
          0
        ) AS total
        FROM sales_returns
        WHERE date(createdAt)
          BETWEEN ? AND ?
        ''',
        [from, to],
      );

      // =====================================================
      // PURCHASE
      // =====================================================

      final purchaseResult = await db.rawQuery(
        '''
        SELECT COALESCE(
          SUM(grandTotal),
          0
        ) AS total
        FROM purchases
        WHERE date(createdAt)
          BETWEEN ? AND ?
        ''',
        [from, to],
      );

      // =====================================================
      // PROFIT
      // =====================================================

      final profitResult = await db.rawQuery(
        '''
        SELECT
          (
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

                WHERE date(s.createdAt)
                  BETWEEN ? AND ?
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
                  ON pv.id = sri.variantId

                WHERE date(sr.createdAt)
                  BETWEEN ? AND ?
              ),
              0
            )

            -

            COALESCE(
              (
                SELECT SUM(discount)
                FROM sales
                WHERE date(createdAt)
                  BETWEEN ? AND ?
              ),
              0
            )
          ) AS profit
        ''',
        [
          from,
          to,
          from,
          to,
          from,
          to,
        ],
      );

      final sales =
          (salesResult.first['total'] as num?)
              ?.toDouble() ??
              0;

      final returns =
          (returnsResult.first['total'] as num?)
              ?.toDouble() ??
              0;

      final purchase =
          (purchaseResult.first['total'] as num?)
              ?.toDouble() ??
              0;

      final profit =
          (profitResult.first['profit'] as num?)
              ?.toDouble() ??
              0;

      if (!mounted) return;

      setState(() {
        _sales = sales;
        _returns = returns;
        _netSales = sales - returns;
        _purchase = purchase;
        _profit = profit;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Report load failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // PDF EXPORT
  // =========================================================

  Future<void> _exportPdf() async {
    try {
      final db = await _databaseHelper.database;

      final from = _date(_fromDate);
      final to = _date(_toDate);

      // =====================================================
      // TOP SELLING PRODUCTS
      // =====================================================

      final topProducts = await db.rawQuery(
        '''
        SELECT
          si.productName AS productName,

          COALESCE(
            SUM(si.quantity),
            0
          ) AS soldQuantity,

          COALESCE(
            (
              SELECT SUM(sri.quantity)
              FROM sales_return_items sri

              INNER JOIN sales_returns sr
                ON sr.id = sri.returnId

              WHERE sri.saleItemId = si.id
                AND date(sr.createdAt)
                  BETWEEN ? AND ?
            ),
            0
          ) AS returnedQuantity

        FROM sale_items si

        INNER JOIN sales s
          ON s.id = si.saleId

        WHERE date(s.createdAt)
          BETWEEN ? AND ?

        GROUP BY si.productName

        ORDER BY soldQuantity DESC

        LIMIT 10
        ''',
        [
          from,
          to,
          from,
          to,
        ],
      );

      final List<Map<String, dynamic>>
      topProductList = [];

      for (final item in topProducts) {
        final sold =
            (item['soldQuantity'] as num?)
                ?.toInt() ??
                0;

        final returned =
            (item['returnedQuantity'] as num?)
                ?.toInt() ??
                0;

        topProductList.add({
          'productName':
          item['productName']?.toString() ?? '',
          'soldQuantity': sold,
          'returnedQuantity': returned,
          'netQuantity': sold - returned,
        });
      }

      // =====================================================
      // STAFF-WISE SALES
      // =====================================================

      final staffResult = await db.rawQuery(
        '''
        SELECT
          s.staffId AS staffId,

          COALESCE(
            st.name,
            'Admin / Unknown'
          ) AS staffName,

          COALESCE(
            SUM(s.grandTotal),
            0
          ) AS totalSales,

          COALESCE(
            (
              SELECT SUM(sr.totalAmount)
              FROM sales_returns sr

              INNER JOIN sales originalSale
                ON originalSale.id = sr.saleId

              WHERE originalSale.staffId = s.staffId
                AND date(sr.createdAt)
                  BETWEEN ? AND ?
            ),
            0
          ) AS returns

        FROM sales s

        LEFT JOIN staff st
          ON st.id = s.staffId

        WHERE date(s.createdAt)
          BETWEEN ? AND ?

        GROUP BY
          s.staffId,
          st.name

        ORDER BY totalSales DESC
        ''',
        [
          from,
          to,
          from,
          to,
        ],
      );

      await ReportPdfService.generateAndPrint(
        fromDate: _fromDate,
        toDate: _toDate,
        sales: _sales,
        returns: _returns,
        netSales: _netSales,
        purchase: _purchase,
        profit: _profit,
        topProducts: topProductList,
        staffSales: staffResult,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF export failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // EXCEL EXPORT
  // =========================================================

  Future<void> _exportExcel() async {
    try {
      final db = await _databaseHelper.database;

      final from = _date(_fromDate);
      final to = _date(_toDate);

      // =====================================================
      // TOP SELLING PRODUCTS
      // =====================================================

      final topProducts = await db.rawQuery(
        '''
      SELECT
        si.productName AS productName,

        COALESCE(
          SUM(si.quantity),
          0
        ) AS soldQuantity,

        COALESCE(
          (
            SELECT SUM(sri.quantity)
            FROM sales_return_items sri
            INNER JOIN sales_returns sr
              ON sr.id = sri.returnId
            WHERE sri.saleItemId = si.id
              AND date(sr.createdAt)
                BETWEEN ? AND ?
          ),
          0
        ) AS returnedQuantity

      FROM sale_items si

      INNER JOIN sales s
        ON s.id = si.saleId

      WHERE date(s.createdAt)
        BETWEEN ? AND ?

      GROUP BY si.productName

      ORDER BY soldQuantity DESC

      LIMIT 10
      ''',
        [
          from,
          to,
          from,
          to,
        ],
      );

      final List<Map<String, dynamic>> topProductList = [];

      for (final item in topProducts) {
        final sold =
            (item['soldQuantity'] as num?)
                ?.toInt() ??
                0;

        final returned =
            (item['returnedQuantity'] as num?)
                ?.toInt() ??
                0;

        topProductList.add({
          'productName':
          item['productName']?.toString() ?? '',
          'soldQuantity': sold,
          'returnedQuantity': returned,
          'netQuantity': sold - returned,
        });
      }

      // =====================================================
      // STAFF-WISE SALES
      // =====================================================

      final staffResult = await db.rawQuery(
        '''
      SELECT
        s.staffId AS staffId,

        COALESCE(
          st.name,
          'Admin / Unknown'
        ) AS staffName,

        COALESCE(
          SUM(s.grandTotal),
          0
        ) AS totalSales,

        COALESCE(
          (
            SELECT SUM(sr.totalAmount)
            FROM sales_returns sr

            INNER JOIN sales originalSale
              ON originalSale.id = sr.saleId

            WHERE originalSale.staffId = s.staffId
              AND date(sr.createdAt)
                BETWEEN ? AND ?
          ),
          0
        ) AS returns

      FROM sales s

      LEFT JOIN staff st
        ON st.id = s.staffId

      WHERE date(s.createdAt)
        BETWEEN ? AND ?

      GROUP BY
        s.staffId,
        st.name

      ORDER BY totalSales DESC
      ''',
        [
          from,
          to,
          from,
          to,
        ],
      );

      // =====================================================
      // EXPORT EXCEL
      // =====================================================

      final savedPath =
      await ReportExcelService.exportReport(
        fromDate: _fromDate,
        toDate: _toDate,
        sales: _sales,
        returns: _returns,
        netSales: _netSales,
        purchase: _purchase,
        profit: _profit,
        topProducts: topProductList,
        staffSales: staffResult,
      );

      if (!mounted) return;

      // =====================================================
      // USER CANCELLED
      // =====================================================

      if (savedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Excel save cancel kar diya gaya.',
            ),
          ),
        );

        return;
      }

      // =====================================================
      // SUCCESS
      // =====================================================

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Excel saved successfully:\n$savedPath',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Excel export failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // MONEY
  // =========================================================

  String _money(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  // =========================================================
  // REPORT CARD
  // =========================================================

  Widget _reportCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor:
              color.withValues(alpha: 0.12),
              child: Icon(
                icon,
                color: color,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _money(value),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DATE CARD
  // =========================================================

  Widget _dateCard({
    required String title,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      size: 20,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _format.format(date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Date-wise Report',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed:
            _loading ? null : _exportExcel,
            icon: const Icon(
              Icons.table_chart,
            ),
            tooltip: 'Export Excel',
          ),
          IconButton(
            onPressed:
            _loading ? null : _exportPdf,
            icon: const Icon(
              Icons.picture_as_pdf,
            ),
            tooltip: 'Export PDF',
          ),
          IconButton(
            onPressed:
            _loading ? null : _loadReport,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadReport,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(16),
          children: [
            // =================================================
            // DATE RANGE
            // =================================================

            const Text(
              'Select Date Range',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                _dateCard(
                  title: 'From Date',
                  date: _fromDate,
                  onTap: _selectFromDate,
                ),
                const SizedBox(width: 10),
                _dateCard(
                  title: 'To Date',
                  date: _toDate,
                  onTap: _selectToDate,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // =================================================
            // TOP SELLING PRODUCTS
            // =================================================

            const Text(
              'Top Selling Products',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            FutureBuilder<
                List<Map<String, dynamic>>>(
              future: () async {
                final db =
                await _databaseHelper.database;

                final from =
                _date(_fromDate);
                final to =
                _date(_toDate);

                return await db.rawQuery(
                  '''
                        SELECT
                          si.productName AS productName,

                          COALESCE(
                            SUM(si.quantity),
                            0
                          ) AS soldQuantity,

                          COALESCE(
                            (
                              SELECT SUM(sri.quantity)
                              FROM sales_return_items sri

                              INNER JOIN sales_returns sr
                                ON sr.id = sri.returnId

                              WHERE sri.saleItemId = si.id
                                AND date(sr.createdAt)
                                  BETWEEN ? AND ?
                            ),
                            0
                          ) AS returnedQuantity,

                          COALESCE(
                            SUM(si.quantity),
                            0
                          )
                          -
                          COALESCE(
                            (
                              SELECT SUM(sri.quantity)
                              FROM sales_return_items sri

                              INNER JOIN sales_returns sr
                                ON sr.id = sri.returnId

                              WHERE sri.saleItemId = si.id
                                AND date(sr.createdAt)
                                  BETWEEN ? AND ?
                            ),
                            0
                          ) AS netQuantity

                        FROM sale_items si

                        INNER JOIN sales s
                          ON s.id = si.saleId

                        WHERE date(s.createdAt)
                          BETWEEN ? AND ?

                        GROUP BY si.productName

                        HAVING netQuantity > 0

                        ORDER BY netQuantity DESC

                        LIMIT 10
                        ''',
                  [
                    from,
                    to,
                    from,
                    to,
                    from,
                    to,
                  ],
                );
              }(),
              builder:
                  (context, snapshot) {
                if (snapshot
                    .connectionState ==
                    ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding:
                      EdgeInsets.all(20),
                      child: Center(
                        child:
                        CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                        16,
                      ),
                      child: Text(
                        'Top selling products load failed.',
                        style:
                        const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                }

                final products =
                    snapshot.data ?? [];

                if (products.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding:
                      EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No sales found for this date range.',
                        ),
                      ),
                    ),
                  );
                }

                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    itemCount:
                    products.length,
                    separatorBuilder:
                        (_, __) =>
                    const Divider(
                      height: 1,
                    ),
                    itemBuilder:
                        (context, index) {
                      final item =
                      products[index];

                      final productName =
                          item['productName']
                              ?.toString() ??
                              '';

                      final sold =
                          (item['soldQuantity']
                          as num?)
                              ?.toInt() ??
                              0;

                      final returned =
                          (item['returnedQuantity']
                          as num?)
                              ?.toInt() ??
                              0;

                      final net =
                          (item['netQuantity']
                          as num?)
                              ?.toInt() ??
                              0;

                      return ListTile(
                        leading:
                        CircleAvatar(
                          child: Text(
                            '${index + 1}',
                          ),
                        ),
                        title: Text(
                          productName,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Sold: $sold  •  '
                              'Returned: $returned',
                        ),
                        trailing: Text(
                          'Net: $net',
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // =================================================
            // STAFF-WISE SALES
            // =================================================

            const Text(
              'Staff-wise Sales',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            FutureBuilder<
                List<Map<String, dynamic>>>(
              future: () async {
                final db =
                await _databaseHelper.database;

                final from =
                _date(_fromDate);
                final to =
                _date(_toDate);

                return await db.rawQuery(
                  '''
                        SELECT
                          s.staffId AS staffId,

                          COALESCE(
                            st.name,
                            'Admin / Unknown'
                          ) AS staffName,

                          COALESCE(
                            SUM(s.grandTotal),
                            0
                          ) AS totalSales,

                          COALESCE(
                            (
                              SELECT SUM(sr.totalAmount)
                              FROM sales_returns sr

                              INNER JOIN sales originalSale
                                ON originalSale.id =
                                   sr.saleId

                              WHERE originalSale.staffId =
                                    s.staffId

                                AND date(sr.createdAt)
                                    BETWEEN ? AND ?
                            ),
                            0
                          ) AS returns

                        FROM sales s

                        LEFT JOIN staff st
                          ON st.id = s.staffId

                        WHERE date(s.createdAt)
                          BETWEEN ? AND ?

                        GROUP BY
                          s.staffId,
                          st.name

                        ORDER BY totalSales DESC
                        ''',
                  [
                    from,
                    to,
                    from,
                    to,
                  ],
                );
              }(),
              builder:
                  (context, snapshot) {
                if (snapshot
                    .connectionState ==
                    ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding:
                      EdgeInsets.all(20),
                      child: Center(
                        child:
                        CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                        16,
                      ),
                      child: Text(
                        'Staff sales load failed: '
                            '${snapshot.error}',
                        style:
                        const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                }

                final staffList =
                    snapshot.data ?? [];

                if (staffList.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding:
                      EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No staff sales found for this date range.',
                        ),
                      ),
                    ),
                  );
                }

                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    itemCount:
                    staffList.length,
                    separatorBuilder:
                        (_, __) =>
                    const Divider(
                      height: 1,
                    ),
                    itemBuilder:
                        (context, index) {
                      final item =
                      staffList[index];

                      final staffName =
                          item['staffName']
                              ?.toString() ??
                              'Admin / Unknown';

                      final sales =
                          (item['totalSales']
                          as num?)
                              ?.toDouble() ??
                              0.0;

                      final returns =
                          (item['returns']
                          as num?)
                              ?.toDouble() ??
                              0.0;

                      final netSales =
                          sales - returns;

                      return ListTile(
                        leading:
                        CircleAvatar(
                          child: Text(
                            '${index + 1}',
                          ),
                        ),
                        title: Text(
                          staffName,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Sales: '
                              '${_money(sales)}  •  '
                              'Returns: '
                              '${_money(returns)}',
                        ),
                        trailing: Text(
                          'Net: '
                              '${_money(netSales)}',
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // =================================================
            // SUMMARY
            // =================================================

            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _reportCard(
              title: 'Total Sales',
              value: _sales,
              icon: Icons.point_of_sale,
              color: Colors.green,
            ),

            const SizedBox(height: 10),

            _reportCard(
              title: 'Returns / Refund',
              value: _returns,
              icon: Icons.assignment_return,
              color: Colors.red,
            ),

            const SizedBox(height: 10),

            _reportCard(
              title: 'Net Sales',
              value: _netSales,
              icon:
              Icons.account_balance_wallet,
              color: Colors.teal,
            ),

            const SizedBox(height: 10),

            _reportCard(
              title: 'Purchase',
              value: _purchase,
              icon: Icons.shopping_cart,
              color: Colors.purple,
            ),

            const SizedBox(height: 10),

            _reportCard(
              title: 'Net Profit',
              value: _profit,
              icon: Icons.trending_up,
              color: Colors.blue,
            ),

            const SizedBox(height: 24),

            // =================================================
            // FORMULA
            // =================================================

            Card(
              child: Padding(
                padding:
                const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Net Sales = Total Sales - '
                            'Returns / Refund',
                        style: TextStyle(
                          color:
                          Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}