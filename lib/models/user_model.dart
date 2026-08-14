class User {
  final int? id;
  final String name;
  final String password;
  final DateTime createdAt;

  User({
    this.id,
    required this.name,
    required this.password,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'password': password,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      password: map['password'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  User copyWith({int? id, String? name, String? password, DateTime? createdAt}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
