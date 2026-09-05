class Product {
  final int? id;
  final String name;
  final int categoryId;
  final int? brandId;
  final String? department;
  final String? hsn;
  final double gst;
  final String? description;
  final String createdAt;
  final String updatedAt;

  Product({
    this.id,
    required this.name,
    required this.categoryId,
    this.brandId,
    this.department,
    this.hsn,
    required this.gst,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'brandId': brandId,
      'department': department,
      'hsn': hsn,
      'gst': gst,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      categoryId: map['categoryId'],
      brandId: map['brandId'],
      department: map['department'],
      hsn: map['hsn'],
      gst: (map['gst'] as num?)?.toDouble() ?? 0.0,
      description: map['description'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }
}