import 'package:flutter/material.dart';

import '../models/sales_return.dart';
import '../models/sales_return_item.dart';
import '../repositories/sales_return_repository.dart';

class SalesReturnProvider extends ChangeNotifier {
  final SalesReturnRepository _repository =
  SalesReturnRepository();

  // =========================================================
  // STATE
  // =========================================================

  bool _loading = false;
  String _searchText = '';

  List<SalesReturn> _returns = [];
  List<SalesReturn> _filteredReturns = [];

  // =========================================================
  // GETTERS
  // =========================================================

  bool get loading => _loading;

  String get searchText => _searchText;

  List<SalesReturn> get returns =>
      List.unmodifiable(_returns);

  List<SalesReturn> get filteredReturns =>
      List.unmodifiable(_filteredReturns);

  // =========================================================
  // TOTALS
  // =========================================================

  double get totalReturnAmount {
    return _returns.fold<double>(
      0,
          (sum, item) => sum + item.totalAmount,
    );
  }

  double get filteredReturnAmount {
    return _filteredReturns.fold<double>(
      0,
          (sum, item) => sum + item.totalAmount,
    );
  }

  int get totalReturnCount => _returns.length;

  int get filteredReturnCount =>
      _filteredReturns.length;

  // =========================================================
  // LOAD RETURNS
  // =========================================================

  Future<void> loadReturns() async {
    _loading = true;
    notifyListeners();

    try {
      final result =
      await _repository.getAllReturns();

      _returns = result;

      _applySearch();
    } catch (e) {
      debugPrint(
        'SalesReturnProvider Load Error: $e',
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
    await loadReturns();
  }

  // =========================================================
  // SEARCH
  // =========================================================

  void searchReturns(String value) {
    _searchText = value;
    _applySearch();
    notifyListeners();
  }

  // =========================================================
  // CLEAR SEARCH
  // =========================================================

  void clearSearch() {
    _searchText = '';
    _applySearch();
    notifyListeners();
  }

  // =========================================================
  // APPLY SEARCH
  // =========================================================

  void _applySearch() {
    final search =
    _searchText.trim().toLowerCase();

    if (search.isEmpty) {
      _filteredReturns = List<SalesReturn>.from(
        _returns,
      );
      return;
    }

    _filteredReturns = _returns.where((item) {
      final returnNumber =
      item.returnNumber.toLowerCase();

      final refundMethod =
      item.refundMethod.toLowerCase();

      final reason =
          item.reason?.toLowerCase() ?? '';

      final saleId =
      item.saleId.toString();

      final customerId =
          item.customerId?.toString() ?? '';

      return returnNumber.contains(search) ||
          refundMethod.contains(search) ||
          reason.contains(search) ||
          saleId.contains(search) ||
          customerId.contains(search);
    }).toList();
  }

  // =========================================================
  // GET RETURN BY ID
  // =========================================================

  Future<SalesReturn?> getReturnById(
      int id,
      ) async {
    try {
      return await _repository.getReturnById(
        id,
      );
    } catch (e) {
      debugPrint(
        'Get Return Error: $e',
      );
      return null;
    }
  }

  // =========================================================
  // GET RETURN ITEMS
  // =========================================================

  Future<List<SalesReturnItem>> getReturnItems(
      int returnId,
      ) async {
    try {
      return await _repository.getReturnItems(
        returnId,
      );
    } catch (e) {
      debugPrint(
        'Get Return Items Error: $e',
      );
      return [];
    }
  }

  // =========================================================
  // GET RETURNS FOR SALE
  // =========================================================

  Future<List<SalesReturn>> getReturnsForSale(
      int saleId,
      ) async {
    try {
      return await _repository.getReturnsForSale(
        saleId,
      );
    } catch (e) {
      debugPrint(
        'Get Sale Returns Error: $e',
      );
      return [];
    }
  }

  // =========================================================
  // RETURNED QUANTITY
  // =========================================================

  Future<int> getReturnedQuantity(
      int saleItemId,
      ) async {
    try {
      return await _repository
          .getReturnedQuantity(
        saleItemId,
      );
    } catch (e) {
      debugPrint(
        'Get Returned Quantity Error: $e',
      );
      return 0;
    }
  }

  // =========================================================
  // AVAILABLE RETURN QUANTITY
  // =========================================================

  Future<int> getAvailableReturnQuantity(
      dynamic saleItem,
      ) async {
    try {
      return await _repository
          .getAvailableReturnQuantity(
        saleItem,
      );
    } catch (e) {
      debugPrint(
        'Get Available Return Quantity Error: $e',
      );
      return 0;
    }
  }

  // =========================================================
  // TOTAL RETURN AMOUNT FROM DATABASE
  // =========================================================

  Future<double> getTotalReturnAmountFromDatabase() async {
    try {
      return await _repository
          .getTotalReturnAmount();
    } catch (e) {
      debugPrint(
        'Get Total Return Amount Error: $e',
      );
      return 0;
    }
  }

  // =========================================================
  // TODAY RETURN AMOUNT
  // =========================================================

  Future<double> getTodayReturnAmount() async {
    try {
      return await _repository
          .getTodayReturnAmount();
    } catch (e) {
      debugPrint(
        'Get Today Return Amount Error: $e',
      );
      return 0;
    }
  }

  // =========================================================
  // TOTAL RETURN COUNT FROM DATABASE
  // =========================================================

  Future<int> getTotalReturnCountFromDatabase() async {
    try {
      return await _repository
          .getTotalReturnCount();
    } catch (e) {
      debugPrint(
        'Get Total Return Count Error: $e',
      );
      return 0;
    }
  }

  // =========================================================
  // TODAY RETURN COUNT
  // =========================================================

  Future<int> getTodayReturnCount() async {
    try {
      return await _repository
          .getTodayReturnCount();
    } catch (e) {
      debugPrint(
        'Get Today Return Count Error: $e',
      );
      return 0;
    }
  }
}