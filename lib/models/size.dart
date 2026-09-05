class SizeModel {
  final int? id;
  final String name;
  final String createdAt;

  SizeModel({
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

  factory SizeModel.fromMap(Map<String, dynamic> map) {
    return SizeModel(
      id: map['id'],
      name: map['name'],
      createdAt: map['createdAt'],
    );
  }
}