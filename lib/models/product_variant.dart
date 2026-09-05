class ProductVariant {
  final int? id;
  final int productId;
  final String sku;
  final String barcode;
  final String color;
  final String size;
  final double purchasePrice;
  final double sellingPrice;
  final int stock;
  final String? image;
  final bool isActive;

  ProductVariant({
    this.id,
    required this.productId,
    required this.sku,
    required this.barcode,
    required this.color,
    required this.size,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stock,
    this.image,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'sku': sku,
      'barcode': barcode,
      'color': color,
      'size': size,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'stock': stock,
      'image': image,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] is num
          ? (map['id'] as num).toInt()
          : int.tryParse(map['id']?.toString() ?? ''),
      productId: map['productId'] is num
          ? (map['productId'] as num).toInt()
          : int.tryParse(map['productId']?.toString() ?? '') ?? 0,
      sku: map['sku']?.toString() ?? '',
      barcode: map['barcode']?.toString() ?? '',
      color: map['color']?.toString() ?? '',
      size: map['size']?.toString() ?? '',
      purchasePrice:
      (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice:
      (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      image: map['image']?.toString(),
      isActive: map['isActive'] == 1 ||
          map['isActive'] == true,
    );
  }
}