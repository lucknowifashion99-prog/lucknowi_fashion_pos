class ColorModel {
  final int? id;
  final String name;
  final String? code;
  final String createdAt;

  ColorModel({
    this.id,
    required this.name,
    this.code,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'createdAt': createdAt,
    };
  }

  factory ColorModel.fromMap(Map<String, dynamic> map) {
    return ColorModel(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      createdAt: map['createdAt'],
    );
  }
}