class ProductVariant {
  int? id;
  int? productId;

  String sku;
  String color;
  String size;

  double purchasePrice;
  double sellingPrice;

  int stock;

  ProductVariant({
    this.id,
    this.productId,
    required this.sku,
    required this.color,
    required this.size,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stock,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'sku': sku,
      'color': color,
      'size': size,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'stock': stock,
    };
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] as int?,
      productId: map['productId'] as int?,
      sku: map['sku'] ?? '',
      color: map['color'] ?? '',
      size: map['size'] ?? '',
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      sellingPrice: (map['sellingPrice'] as num).toDouble(),
      stock: map['stock'] ?? 0,
    );
  }
}