import 'package:flutter/material.dart';

import '../repositories/purchase_repository.dart';

class PurchaseProvider extends ChangeNotifier {
  final PurchaseRepository _repository =
  PurchaseRepository();

  List<Map<String, dynamic>> _purchases = [];

  bool _loading = false;

  List<Map<String, dynamic>> get purchases => _purchases;

  bool get loading => _loading;

  // =========================================================
  // LOAD PURCHASES
  // =========================================================

  Future<void> loadPurchases() async {
    _loading = true;
    notifyListeners();

    try {
      _purchases =
      await _repository.getAllPurchases();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

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
    final purchaseId =
    await _repository.savePurchase(
      invoiceNumber: invoiceNumber,
      supplierId: supplierId,
      subtotal: subtotal,
      discount: discount,
      gst: gst,
      grandTotal: grandTotal,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      createdAt: createdAt,
      items: items,
    );

    await loadPurchases();

    return purchaseId;
  }

  // =========================================================
  // GET PURCHASE ITEMS
  // =========================================================

  Future<List<Map<String, dynamic>>> getPurchaseItems(
      int purchaseId,
      ) async {
    return await _repository.getPurchaseItems(
      purchaseId,
    );
  }

  // =========================================================
  // GET PURCHASE
  // =========================================================

  Future<Map<String, dynamic>?> getPurchaseById(
      int purchaseId,
      ) async {
    return await _repository.getPurchaseById(
      purchaseId,
    );
  }

  // =========================================================
  // DELETE PURCHASE
  // =========================================================

  Future<void> deletePurchase(
      int purchaseId,
      ) async {
    await _repository.deletePurchase(
      purchaseId,
    );

    await loadPurchases();
  }
}