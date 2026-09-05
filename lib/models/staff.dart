class Staff {
  final int? id;
  final String name;
  final String username;
  final String password;
  final String role;
  final bool isActive;
  final String createdAt;

  Staff({
    this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'role': role,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      role: map['role']?.toString() ?? 'Staff',
      isActive: (map['isActive'] ?? 1) == 1,
      createdAt: map['createdAt']?.toString() ?? '',
    );
  }

  Staff copyWith({
    int? id,
    String? name,
    String? username,
    String? password,
    String? role,
    bool? isActive,
    String? createdAt,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}