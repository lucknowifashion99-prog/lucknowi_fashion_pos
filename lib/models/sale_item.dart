class SaleItem {
  final int? id;
  final int saleId;
  final int variantId;
  final String productName;
  final String? color;
  final String? size;
  final String? sku;
  final String? barcode;
  final int quantity;
  final double purchasePrice;
  final double sellingPrice;
  final double gst;
  final double discount;
  final double total;

  SaleItem({
    this.id,
    required this.saleId,
    required this.variantId,
    required this.productName,
    this.color,
    this.size,
    this.sku,
    this.barcode,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.gst,
    required this.discount,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'variantId': variantId,
      'productName': productName,
      'color': color,
      'size': size,
      'sku': sku,
      'barcode': barcode,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'gst': gst,
      'discount': discount,
      'total': total,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['saleId'],
      variantId: map['variantId'],
      productName: map['productName'],
      color: map['color'],
      size: map['size'],
      sku: map['sku'],
      barcode: map['barcode'],
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      purchasePrice:
      (map['purchasePrice'] as num?)?.toDouble() ?? 0,
      sellingPrice:
      (map['sellingPrice'] as num?)?.toDouble() ?? 0,
      gst: (map['gst'] as num?)?.toDouble() ?? 0,
      discount:
      (map['discount'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
    );
  }
}