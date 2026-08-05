class Product {
  final int? id;
  final String name;
  final double price; // Harga Jual
  final double purchasePrice; // Harga Beli
  final String? imagePath;
  final int stock;

  Product({
    this.id,
    required this.name,
    required this.price,
    this.purchasePrice = 0,
    this.imagePath,
    this.stock = 0,
  });

  Map<String, dynamic> toMap() {
    // Jika id null, jangan include dalam map (biar auto increment)
    final map = <String, dynamic>{
      'nama': name,
      'harga': price,
      'harga_beli': purchasePrice, // Pastikan compiler membaca ini
      'image_path': imagePath,
      'stock': stock,
    };
    
    // Hanya tambahkan id_product jika id tidak null
    if (id != null) {
      map['id_product'] = id;
    }
    
    return map;
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id_product'],
      name: map['nama'],
      price: (map['harga'] as num).toDouble(),
      purchasePrice: (map['harga_beli'] as num?)?.toDouble() ?? 0,
      imagePath: map['image_path'],
      stock: map['stock'] ?? 0,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    double? price,
    double? purchasePrice,
    String? imagePath,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      imagePath: imagePath ?? this.imagePath,
      stock: stock ?? this.stock,
    );
  }
}