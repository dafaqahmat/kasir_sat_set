class User {
  final int? id;
  final String name; // Mengganti username
  final String pin; // Mengganti password
  final DateTime createdAt;

  User({
    this.id,
    required this.name,
    required this.pin,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pin': pin,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      pin: map['pin'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  User copyWith({int? id, String? name, String? pin, DateTime? createdAt}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      pin: pin ?? this.pin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
