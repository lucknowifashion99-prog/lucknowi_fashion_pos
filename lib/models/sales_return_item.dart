class SalesReturnItem {
  final int? id;
  final int returnId;
  final int saleItemId;
  final int variantId;

  final String productName;
  final String? color;
  final String? size;
  final String? sku;
  final String? barcode;

  final int quantity;

  final double sellingPrice;
  final double gst;
  final double discount;
  final double total;

  SalesReturnItem({
    this.id,
    required this.returnId,
    required this.saleItemId,
    required this.variantId,
    required this.productName,
    this.color,
    this.size,
    this.sku,
    this.barcode,
    required this.quantity,
    required this.sellingPrice,
    required this.gst,
    required this.discount,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'returnId': returnId,
      'saleItemId': saleItemId,
      'variantId': variantId,
      'productName': productName,
      'color': color,
      'size': size,
      'sku': sku,
      'barcode': barcode,
      'quantity': quantity,
      'sellingPrice': sellingPrice,
      'gst': gst,
      'discount': discount,
      'total': total,
    };
  }

  factory SalesReturnItem.fromMap(
      Map<String, dynamic> map,
      ) {
    return SalesReturnItem(
      id: map['id'],
      returnId:
      (map['returnId'] as num?)?.toInt() ?? 0,
      saleItemId:
      (map['saleItemId'] as num?)?.toInt() ?? 0,
      variantId:
      (map['variantId'] as num?)?.toInt() ?? 0,
      productName:
      map['productName']?.toString() ?? '',
      color:
      map['color']?.toString(),
      size:
      map['size']?.toString(),
      sku:
      map['sku']?.toString(),
      barcode:
      map['barcode']?.toString(),
      quantity:
      (map['quantity'] as num?)?.toInt() ?? 0,
      sellingPrice:
      (map['sellingPrice'] as num?)
          ?.toDouble() ??
          0,
      gst:
      (map['gst'] as num?)?.toDouble() ?? 0,
      discount:
      (map['discount'] as num?)
          ?.toDouble() ??
          0,
      total:
      (map['total'] as num?)?.toDouble() ?? 0,
    );
  }
}