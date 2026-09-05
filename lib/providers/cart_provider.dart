import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/product_variant.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  double _discount = 0;

  // =========================
  // ITEMS
  // =========================

  List<CartItem> get items =>
      List.unmodifiable(_items);

  // =========================
  // CART COUNT
  // =========================

  int get itemCount => _items.length;

  int get totalQuantity {
    return _items.fold(
      0,
          (sum, item) => sum + item.quantity,
    );
  }

  // =========================
  // SUBTOTAL
  // =========================

  double get subtotal {
    return _items.fold(
      0,
          (sum, item) => sum + item.baseTotal,
    );
  }

  // =========================
  // GST
  // =========================

  double get gst {
    return _items.fold(
      0,
          (sum, item) => sum + item.gstAmount,
    );
  }

  // =========================
  // DISCOUNT
  // =========================

  double get discount {
    return _discount;
  }

  // =========================
  // DISCOUNT BASE
  // =========================

  double get discountBase {
    return subtotal + gst;
  }

  // =========================
  // DISCOUNT PERCENT
  // =========================

  double get discountPercent {
    if (discountBase <= 0) {
      return 0;
    }

    return (_discount / discountBase) * 100;
  }

  // =========================
  // SET DISCOUNT ₹
  // =========================

  void setDiscount(double value) {
    if (value < 0) {
      _discount = 0;
    } else if (value > discountBase) {
      _discount = discountBase;
    } else {
      _discount = value;
    }

    notifyListeners();
  }

  // =========================
  // SET DISCOUNT %
  // =========================

  void setDiscountPercent(double percent) {
    if (percent < 0) {
      percent = 0;
    }

    if (percent > 100) {
      percent = 100;
    }

    _discount =
        discountBase * percent / 100;

    notifyListeners();
  }

  // =========================
  // GRAND TOTAL
  // =========================

  double get grandTotal {
    final total =
        subtotal + gst - discount;

    return total < 0 ? 0 : total;
  }

  // =========================
  // PROFIT
  // =========================

  double get totalProfit {
    return _items.fold(
      0,
          (sum, item) => sum + item.profit,
    );
  }

  // =========================
  // FIND ITEM
  // =========================

  bool containsVariant(int variantId) {
    return _items.any(
          (item) => item.variant.id == variantId,
    );
  }

  CartItem? getItem(int variantId) {
    for (final item in _items) {
      if (item.variant.id == variantId) {
        return item;
      }
    }

    return null;
  }

  // =========================
  // ADD ITEM
  // =========================

  void addItem({
    required Product product,
    required ProductVariant variant,
    int quantity = 1,
  }) {
    if (variant.id == null) {
      return;
    }

    if (quantity <= 0) {
      return;
    }

    final existing =
    getItem(variant.id!);

    if (existing != null) {
      final newQuantity =
          existing.quantity + quantity;

      if (newQuantity <= variant.stock) {
        existing.quantity = newQuantity;
      }

      notifyListeners();
      return;
    }

    if (quantity > variant.stock) {
      return;
    }

    _items.add(
      CartItem(
        product: product,
        variant: variant,
        quantity: quantity,
      ),
    );

    notifyListeners();
  }

  // =========================
  // INCREASE
  // =========================

  void increaseQuantity(int variantId) {
    final item =
    getItem(variantId);

    if (item == null) {
      return;
    }

    if (item.quantity < item.variant.stock) {
      item.quantity++;
      notifyListeners();
    }
  }

  // =========================
  // DECREASE
  // =========================

  void decreaseQuantity(int variantId) {
    final item =
    getItem(variantId);

    if (item == null) {
      return;
    }

    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(item);
    }

    _fixDiscount();

    notifyListeners();
  }

  // =========================
  // SET QUANTITY
  // =========================

  void setQuantity(
      int variantId,
      int quantity,
      ) {
    final item =
    getItem(variantId);

    if (item == null) {
      return;
    }

    if (quantity <= 0) {
      _items.remove(item);
    } else if (quantity <= item.variant.stock) {
      item.quantity = quantity;
    }

    _fixDiscount();

    notifyListeners();
  }

  // =========================
  // REMOVE ITEM
  // =========================

  void removeItem(int variantId) {
    _items.removeWhere(
          (item) =>
      item.variant.id == variantId,
    );

    _fixDiscount();

    notifyListeners();
  }

  // =========================
  // CLEAR CART
  // =========================

  void clearCart() {
    _items.clear();
    _discount = 0;

    notifyListeners();
  }

  // =========================
  // FIX DISCOUNT
  // =========================

  void _fixDiscount() {
    final maximum =
        subtotal + gst;

    if (_discount > maximum) {
      _discount = maximum;
    }

    if (_discount < 0) {
      _discount = 0;
    }
  }
}