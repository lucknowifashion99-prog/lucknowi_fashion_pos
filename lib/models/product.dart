class Product {
  int? id;
  String name;
  String category;
  String brand;
  String size;
  String color;
  double purchasePrice;
  double sellingPrice;
  int stock;
  String barcode;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.size,
    required this.color,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stock,
    required this.barcode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'brand': brand,
      'size': size,
      'color': color,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'stock': stock,
      'barcode': barcode,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      brand: map['brand'],
      size: map['size'],
      color: map['color'],
      purchasePrice: map['purchasePrice'],
      sellingPrice: map['sellingPrice'],
      stock: map['stock'],
      barcode: map['barcode'],
    );
  }
}