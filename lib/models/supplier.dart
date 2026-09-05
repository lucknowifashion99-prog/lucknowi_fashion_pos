class Supplier {
  final int? id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String createdAt;

  Supplier({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'createdAt': createdAt,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      createdAt: map['createdAt'],
    );
  }
}