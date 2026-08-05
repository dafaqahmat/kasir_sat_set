class Transaction {
  final int? id;
  final String transactionCode;
  final int userId;
  final double totalAmount;
  final double cashReceived;
  final double change;
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.transactionCode,
    required this.userId,
    required this.totalAmount,
    required this.cashReceived,
    required this.change,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_code': transactionCode,
      'user_id': userId,
      'total_amount': totalAmount,
      'cash_received': cashReceived,
      'change': change,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      transactionCode: map['transaction_code'],
      userId: map['user_id'],
      totalAmount: map['total_amount'],
      cashReceived: map['cash_received'],
      change: map['change'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class TransactionItem {
  final int? id;
  final int transactionId;
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;

  TransactionItem({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      transactionId: map['transaction_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      quantity: map['quantity'],
      price: map['price'],
      subtotal: map['subtotal'],
    );
  }
}