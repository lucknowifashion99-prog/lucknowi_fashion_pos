import 'product.dart';
import 'product_variant.dart';

class CartItem {
  final Product product;
  final ProductVariant variant;
  int quantity;

  CartItem({
    required this.product,
    required this.variant,
    this.quantity = 1,
  });

  // =========================
  // SELLING PRICE
  // =========================

  double get sellingPrice {
    return variant.sellingPrice;
  }

  // =========================
  // PURCHASE PRICE
  // =========================

  double get purchasePrice {
    return variant.purchasePrice;
  }

  // =========================
  // GST RATE
  // =========================

  double get gstRate {
    return product.gst;
  }

  // =========================
  // BASE TOTAL
  // =========================

  double get baseTotal {
    return sellingPrice * quantity;
  }

  // =========================
  // GST AMOUNT
  // =========================

  double get gstAmount {
    return baseTotal * gstRate / 100;
  }

  // =========================
  // TOTAL
  // =========================

  double get total {
    return baseTotal + gstAmount;
  }

  // =========================
  // PROFIT
  // =========================

  double get profit {
    return (sellingPrice - purchasePrice) * quantity;
  }

  // =========================
  // COPY
  // =========================

  CartItem copyWith({
    int? quantity,
  }) {
    return CartItem(
      product: product,
      variant: variant,
      quantity: quantity ?? this.quantity,
    );
  }
}