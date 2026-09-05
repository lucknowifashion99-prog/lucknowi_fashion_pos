import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'date_range_report_screen.dart';

import '../../providers/report_provider.dart';
import '../../providers/staff_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadReports();
    });
  }

  // =========================================================
  // REFRESH
  // =========================================================

  Future<void> _refresh() async {
    await context.read<ReportProvider>().refresh();
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
    required String value,
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
              backgroundColor: color.withValues(
                alpha: 0.12,
              ),
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
                    value,
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
  // SECTION TITLE
  // =========================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================================
  // STAFF PERFORMANCE CARD
  // =========================================================

  Widget _staffPerformanceCard(
      Map<String, dynamic> item, {
        bool today = false,
      }) {
    final staffName =
        item['staffName']?.toString() ??
            item['name']?.toString() ??
            'Unknown Staff';

    final billCount =
        (item['billCount'] as num?)?.toInt() ??
            (item['bills'] as num?)?.toInt() ??
            0;

    final sales =
        (item['sales'] as num?)?.toDouble() ??
            (item['totalSales'] as num?)?.toDouble() ??
            0;

    final itemsSold =
        (item['itemsSold'] as num?)?.toInt() ??
            (item['quantity'] as num?)?.toInt() ??
            0;

    final profit =
        (item['profit'] as num?)?.toDouble() ??
            0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: today
                      ? Colors.blue.withValues(
                    alpha: 0.12,
                  )
                      : Colors.deepPurple.withValues(
                    alpha: 0.12,
                  ),
                  child: Icon(
                    Icons.person,
                    color: today
                        ? Colors.blue
                        : Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    staffName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _staffStat(
                    Icons.receipt_long,
                    'Bills',
                    '$billCount',
                  ),
                ),
                Expanded(
                  child: _staffStat(
                    Icons.point_of_sale,
                    'Net Sales',
                    _money(sales),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _staffStat(
                    Icons.inventory_2,
                    'Items Sold',
                    '$itemsSold',
                  ),
                ),
                Expanded(
                  child: _staffStat(
                    Icons.trending_up,
                    'Profit',
                    _money(profit),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // STAFF STAT
  // =========================================================

  Widget _staffStat(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade700,
        ),
        const SizedBox(width: 8),
        Expanded(
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
              const SizedBox(height: 2),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // EMPTY DATA
  // =========================================================

  Widget _emptyData(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TODAY STAFF SALES
  // =========================================================

  Widget _todayStaffSales(
      ReportProvider provider,
      ) {
    final data = provider.todayStaffWiseSales;

    if (data.isEmpty) {
      return _emptyData(
        'No staff sales recorded today.',
      );
    }

    return Column(
      children: data.map((item) {
        return _staffPerformanceCard(
          item,
          today: true,
        );
      }).toList(),
    );
  }

  // =========================================================
  // ALL STAFF SALES
  // =========================================================

  Widget _allStaffSales(
      ReportProvider provider,
      ) {
    final data = provider.staffWiseSales;

    if (data.isEmpty) {
      return _emptyData(
        'No staff sales data available.',
      );
    }

    return Column(
      children: data.map((item) {
        return _staffPerformanceCard(item);
      }).toList(),
    );
  }

  // =========================================================
  // TOP SELLING PRODUCTS
  // =========================================================

  Widget _topSellingProducts(
      ReportProvider provider,
      ) {
    if (provider.topSellingProducts.isEmpty) {
      return _emptyData(
        'No sales data available.',
      );
    }

    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics:
        const NeverScrollableScrollPhysics(),
        itemCount:
        provider.topSellingProducts.length,
        separatorBuilder: (_, index) =>
        const Divider(height: 1),
        itemBuilder: (
            context,
            index,
            ) {
          final item =
          provider.topSellingProducts[index];

          final name =
              item['productName']?.toString() ??
                  '-';

          final quantity =
              (item['quantity'] as num?)
                  ?.toInt() ??
                  0;

          final total =
              (item['total'] as num?)
                  ?.toDouble() ??
                  0;

          return ListTile(
            leading: CircleAvatar(
              child: Text(
                '${index + 1}',
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Net Sold: $quantity',
            ),
            trailing: Text(
              _money(total),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // LOW STOCK
  // =========================================================

  Widget _lowStockProducts(
      ReportProvider provider,
      ) {
    if (provider.lowStockProducts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No low-stock products.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics:
        const NeverScrollableScrollPhysics(),
        itemCount:
        provider.lowStockProducts.length,
        separatorBuilder: (_, index) =>
        const Divider(height: 1),
        itemBuilder: (
            context,
            index,
            ) {
          final item =
          provider.lowStockProducts[index];

          final productName =
              item['productName']?.toString() ??
                  '-';

          final color =
              item['color']?.toString() ??
                  '-';

          final size =
              item['size']?.toString() ??
                  '-';

          final sku =
              item['sku']?.toString() ??
                  '-';

          final stock =
              (item['stock'] as num?)
                  ?.toInt() ??
                  0;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
              Colors.red.withValues(
                alpha: 0.12,
              ),
              child: const Icon(
                Icons.warning_amber,
                color: Colors.red,
              ),
            ),
            title: Text(
              productName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '$color / $size\nSKU: $sku',
            ),
            isThreeLine: true,
            trailing: Text(
              '$stock left',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final staffProvider =
    context.watch<StaffProvider>();

    final isAdmin =
        staffProvider.isAdmin;

    final staff =
        staffProvider.loggedInStaff;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Reports' : 'My Reports',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const DateRangeReportScreen(),
                ),
              );
            },
            icon: const Icon(Icons.date_range),
            tooltip: 'Date-wise Report',
          ),
          IconButton(
            onPressed: _refresh,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (
            context,
            provider,
            child,
            ) {
          if (provider.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding:
              const EdgeInsets.all(16),
              children: [
                // =================================================
                // USER HEADER
                // =================================================

                Card(
                  elevation: 2,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding:
                    const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor:
                          isAdmin
                              ? Colors
                              .deepPurple
                              .withValues(
                            alpha: 0.12,
                          )
                              : Colors.blue
                              .withValues(
                            alpha: 0.12,
                          ),
                          child: Icon(
                            isAdmin
                                ? Icons
                                .admin_panel_settings
                                : Icons.person,
                            color: isAdmin
                                ? Colors.deepPurple
                                : Colors.blue,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                isAdmin
                                    ? 'Admin Reports'
                                    : 'My Sales Report',
                                style:
                                const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                isAdmin
                                    ? 'All staff performance'
                                    : '${staff?.name ?? 'Staff'} • Sales report',
                                style: TextStyle(
                                  color: Colors
                                      .grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // =================================================
                // TODAY
                // =================================================

                _sectionTitle('Today'),

                _reportCard(
                  title: 'Net Sales',
                  value: _money(
                    provider.todaySales,
                  ),
                  icon:
                  Icons.point_of_sale,
                  color: Colors.green,
                ),

                const SizedBox(height: 10),

                _reportCard(
                  title: 'Returns / Refund',
                  value: _money(
                    provider.todayReturns,
                  ),
                  icon:
                  Icons.assignment_return,
                  color: Colors.red,
                ),

                const SizedBox(height: 10),

                _reportCard(
                  title: 'Purchase',
                  value: _money(
                    provider.todayPurchase,
                  ),
                  icon:
                  Icons.shopping_cart,
                  color: Colors.purple,
                ),

                const SizedBox(height: 10),

                _reportCard(
                  title: 'Net Profit',
                  value: _money(
                    provider.todayProfit,
                  ),
                  icon:
                  Icons.trending_up,
                  color: Colors.blue,
                ),

                const SizedBox(height: 24),

                // =================================================
                // TODAY STAFF PERFORMANCE
                // =================================================

                _sectionTitle(
                  'Today Staff Performance',
                ),

                _todayStaffSales(provider),

                const SizedBox(height: 24),

                // =================================================
                // MONTH
                // =================================================

                _sectionTitle(
                  'This Month',
                ),

                _reportCard(
                  title: 'Monthly Net Sales',
                  value: _money(
                    provider.monthlySales,
                  ),
                  icon: Icons.bar_chart,
                  color: Colors.green,
                ),

                const SizedBox(height: 10),

                _reportCard(
                  title: 'Monthly Returns / Refund',
                  value: _money(
                    provider.monthlyReturns,
                  ),
                  icon:
                  Icons.assignment_return,
                  color: Colors.red,
                ),

                const SizedBox(height: 10),

                _reportCard(
                  title: 'Monthly Purchase',
                  value: _money(
                    provider.monthlyPurchase,
                  ),
                  icon:
                  Icons.shopping_bag,
                  color: Colors.purple,
                ),

                const SizedBox(height: 10),

                _reportCard(
                  title: 'Monthly Net Profit',
                  value: _money(
                    provider.monthlyProfit,
                  ),
                  icon:
                  Icons.analytics,
                  color: Colors.blue,
                ),

                const SizedBox(height: 24),

                // =================================================
                // STAFF PERFORMANCE
                // =================================================

                _sectionTitle(
                  'Staff Performance',
                ),

                _allStaffSales(provider),

                const SizedBox(height: 24),

                // =================================================
                // INVENTORY - ADMIN ONLY
                // =================================================

                if (isAdmin) ...[
                  _sectionTitle(
                    'Inventory',
                  ),

                  _reportCard(
                    title: 'Total Products',
                    value:
                    '${provider.totalProducts}',
                    icon:
                    Icons.inventory_2,
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 10),

                  _reportCard(
                    title: 'Current Stock',
                    value:
                    '${provider.currentStock}',
                    icon:
                    Icons.warehouse,
                    color: Colors.teal,
                  ),

                  const SizedBox(height: 10),

                  _reportCard(
                    title: 'Low Stock',
                    value:
                    '${provider.lowStockCount}',
                    icon:
                    Icons.warning_amber,
                    color: Colors.red,
                  ),

                  const SizedBox(height: 10),

                  _reportCard(
                    title: 'Total Variants',
                    value:
                    '${provider.totalVariants}',
                    icon: Icons.style,
                    color: Colors.indigo,
                  ),

                  const SizedBox(height: 24),

                  // =================================================
                  // MASTER DATA
                  // =================================================

                  _sectionTitle(
                    'Master Data',
                  ),

                  _reportCard(
                    title: 'Suppliers',
                    value:
                    '${provider.totalSuppliers}',
                    icon:
                    Icons.local_shipping,
                    color:
                    Colors.deepOrange,
                  ),

                  const SizedBox(height: 10),

                  _reportCard(
                    title: 'Customers',
                    value:
                    '${provider.totalCustomers}',
                    icon: Icons.people,
                    color: Colors.teal,
                  ),

                  const SizedBox(height: 24),
                ],

                // =================================================
                // TOP SELLING
                // =================================================

                _sectionTitle(
                  'Top Selling Products',
                ),

                _topSellingProducts(
                  provider,
                ),

                const SizedBox(height: 24),

                // =================================================
                // LOW STOCK
                // =================================================

                if (isAdmin) ...[
                  _sectionTitle(
                    'Low Stock Products',
                  ),

                  _lowStockProducts(
                    provider,
                  ),

                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}