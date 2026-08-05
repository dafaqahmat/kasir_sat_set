// models/income_model.dart
class Income {
  final int? id;
  final String description;
  final double amount;
  final DateTime date;

  Income({
    this.id,
    required this.description,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_income': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id_income'],
      description: map['description'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
    );
  }

  Income copyWith({
    int? id,
    String? description,
    double? amount,
    DateTime? date,
  }) {
    return Income(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }
}

