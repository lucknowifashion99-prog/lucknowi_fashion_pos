class Category {
  final int? id;
  final String name;
  final String? image;
  final String createdAt;

  Category({
    this.id,
    required this.name,
    this.image,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'createdAt': createdAt,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      image: map['image'],
      createdAt: map['createdAt'],
    );
  }
}