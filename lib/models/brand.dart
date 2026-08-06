class Brand {
  final int? id;
  final String name;
  final String createdAt;

  Brand({
    this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt,
    };
  }

  factory Brand.fromMap(Map<String, dynamic> map) {
    return Brand(
      id: map['id'],
      name: map['name'],
      createdAt: map['createdAt'],
    );
  }
}