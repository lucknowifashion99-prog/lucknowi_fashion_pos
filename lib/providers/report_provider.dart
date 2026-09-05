import 'package:flutter/material.dart';

import '../repositories/report_repository.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository =
  ReportRepository();

  bool _loading = false;

  // =========================================================
  // SALES / PURCHASE / PROFIT
  // =========================================================

  double _todaySales = 0;
  double _todayPurchase = 0;
  double _todayProfit = 0;
  double _todayReturns = 0;

  double _monthlySales = 0;
  double _monthlyPurchase = 0;
  double _monthlyProfit = 0;
  double _monthlyReturns = 0;

  // =========================================================
  // INVENTORY
  // =========================================================

  int _currentStock = 0;
  int _lowStockCount = 0;

  int _totalProducts = 0;
  int _totalVariants = 0;
  int _totalSuppliers = 0;
  int _totalCustomers = 0;

  // =========================================================
  // PRODUCTS
  // =========================================================

  List<Map<String, dynamic>>
  _topSellingProducts = [];

  List<Map<String, dynamic>>
  _lowStockProducts = [];

  // =========================================================
  // STAFF REPORTS
  // =========================================================

  List<Map<String, dynamic>>
  _staffWiseSales = [];

  List<Map<String, dynamic>>
  _todayStaffWiseSales = [];

  List<Map<String, dynamic>>
  _monthlyStaffWiseSales = [];

  // =========================================================
  // GETTERS
  // =========================================================

  bool get loading => _loading;

  double get todaySales => _todaySales;

  double get todayPurchase =>
      _todayPurchase;

  double get todayProfit =>
      _todayProfit;

  double get todayReturns =>
      _todayReturns;

  double get monthlySales =>
      _monthlySales;

  double get monthlyPurchase =>
      _monthlyPurchase;

  double get monthlyProfit =>
      _monthlyProfit;

  double get monthlyReturns =>
      _monthlyReturns;

  // =========================================================
  // INVENTORY GETTERS
  // =========================================================

  int get currentStock =>
      _currentStock;

  int get lowStockCount =>
      _lowStockCount;

  int get totalProducts =>
      _totalProducts;

  int get totalVariants =>
      _totalVariants;

  int get totalSuppliers =>
      _totalSuppliers;

  int get totalCustomers =>
      _totalCustomers;

  // =========================================================
  // PRODUCT GETTERS
  // =========================================================

  List<Map<String, dynamic>>
  get topSellingProducts =>
      _topSellingProducts;

  List<Map<String, dynamic>>
  get lowStockProducts =>
      _lowStockProducts;

  // =========================================================
  // STAFF GETTERS
  // =========================================================

  List<Map<String, dynamic>>
  get staffWiseSales =>
      _staffWiseSales;

  List<Map<String, dynamic>>
  get todayStaffWiseSales =>
      _todayStaffWiseSales;

  List<Map<String, dynamic>>
  get monthlyStaffWiseSales =>
      _monthlyStaffWiseSales;

  // =========================================================
  // LOAD ALL REPORTS
  // =========================================================

  Future<void> loadReports() async {
    _loading = true;
    notifyListeners();

    try {
      // =====================================================
      // TODAY
      // =====================================================

      _todaySales =
      await _repository.getTodaySales();

      _todayPurchase =
      await _repository.getTodayPurchase();

      _todayProfit =
      await _repository.getTodayProfit();

      _todayReturns =
      await _repository.getTodayReturns();

      // =====================================================
      // MONTH
      // =====================================================

      _monthlySales =
      await _repository.getMonthlySales();

      _monthlyPurchase =
      await _repository.getMonthlyPurchase();

      _monthlyProfit =
      await _repository.getMonthlyProfit();

      _monthlyReturns =
      await _repository.getMonthlyReturns();

      // =====================================================
      // INVENTORY
      // =====================================================

      _currentStock =
      await _repository.getCurrentStock();

      _lowStockCount =
      await _repository.getLowStockCount();

      _totalProducts =
      await _repository.getTotalProducts();

      _totalVariants =
      await _repository.getTotalVariants();

      // =====================================================
      // MASTER DATA
      // =====================================================

      _totalSuppliers =
      await _repository.getTotalSuppliers();

      _totalCustomers =
      await _repository.getTotalCustomers();

      // =====================================================
      // PRODUCTS
      // =====================================================

      _topSellingProducts =
      await _repository.getTopSellingProducts();

      _lowStockProducts =
      await _repository.getLowStockProducts();

      // =====================================================
      // STAFF REPORTS
      // =====================================================

      _staffWiseSales =
      await _repository.getStaffWiseSales();

      _todayStaffWiseSales =
      await _repository.getTodayStaffWiseSales();

      _monthlyStaffWiseSales =
      await _repository
          .getMonthlyStaffWiseSales();
    } catch (e) {
      debugPrint(
        'ReportProvider Error: $e',
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // REFRESH
  // =========================================================

  Future<void> refresh() async {
    await loadReports();
  }

  // =========================================================
  // STAFF TOTAL SALES
  // =========================================================

  Future<double> getStaffTotalSales(
      int staffId,
      ) async {
    return await _repository
        .getStaffTotalSales(
      staffId,
    );
  }

  // =========================================================
  // STAFF BILL COUNT
  // =========================================================

  Future<int> getStaffBillCount(
      int staffId,
      ) async {
    return await _repository
        .getStaffBillCount(
      staffId,
    );
  }

  // =========================================================
  // TODAY STAFF SALES
  // =========================================================

  Future<double> getTodayStaffSales(
      int staffId,
      ) async {
    return await _repository
        .getTodayStaffSales(
      staffId,
    );
  }

  // =========================================================
  // TODAY STAFF BILL COUNT
  // =========================================================

  Future<int> getTodayStaffBillCount(
      int staffId,
      ) async {
    return await _repository
        .getTodayStaffBillCount(
      staffId,
    );
  }
}