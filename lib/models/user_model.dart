class User {
  final int? id;
  final String name;
  final String password;
  final String role;
  final DateTime createdAt;

  User({
    this.id,
    required this.name,
    required this.password,
    this.role = 'kasir',
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isKasir => role == 'kasir';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'password': password,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      password: map['password'],
      role: map['role'] ?? 'kasir',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  User copyWith({int? id, String? name, String? password, String? role, DateTime? createdAt}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      password: password ?? this.password,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
