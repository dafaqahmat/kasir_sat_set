import 'dart:async';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import 'seeders/database_seeder.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static sql.Database? _database;

  final _productStreamController = StreamController<List<Product>>.broadcast();
  final _transactionStreamController =
      StreamController<List<Transaction>>.broadcast();
  final _userStreamController = StreamController<User>.broadcast();

  // Stream Controllers (tambahkan di bagian atas class)
  final _incomeStreamController = StreamController<List<Income>>.broadcast();
  final _expenseStreamController = StreamController<List<Expense>>.broadcast();

  Stream<List<Income>> get incomeStream => _incomeStreamController.stream;
  Stream<List<Expense>> get expenseStream => _expenseStreamController.stream;

  Stream<List<Product>> get productStream => _productStreamController.stream;
  Stream<List<Transaction>> get transactionStream =>
      _transactionStreamController.stream;
  Stream<User> get userStream => _userStreamController.stream;
  DatabaseHelper._init();

  Future<void> _notifyIncomesChanged() async {
    final incomes = await getAllIncomes();
    _incomeStreamController.add(incomes);
  }

  Future<void> _notifyExpensesChanged() async {
    final expenses = await getAllExpenses();
    _expenseStreamController.add(expenses);
  }

  Future<sql.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kasir_satset.db');
    return _database!;
  }

  Future<sql.Database> _initDB(String filePath) async {
    final dbPath = await sql.getDatabasesPath();
    final path = join(dbPath, filePath);

    return await sql.openDatabase(
      path,
      version: 11,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(sql.Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'kasir',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id_product INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        harga REAL NOT NULL,
        harga_beli REAL NOT NULL DEFAULT 0,
        image_path TEXT,
        stock INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_code TEXT NOT NULL UNIQUE,
        user_id INTEGER NOT NULL,
        total_amount REAL NOT NULL,
        cash_received REAL NOT NULL,
        change REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id),
        FOREIGN KEY (product_id) REFERENCES products (id_product)
      )
    ''');
    // NEW: Income table
    await db.execute('''
      CREATE TABLE incomes (
        id_income INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // NEW: Expense table
    await db.execute('''
      CREATE TABLE expenses (
        id_expense INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    // 🌱 JALANKAN SEEDER SETELAH TABEL DIBUAT
    print('\n📦 Database created, running seeders...');
    await DatabaseSeeder.run(db);
  }

  /// Seed ulang data (untuk development/testing)
  Future<void> reseedDatabase() async {
    final db = await instance.database;
    await DatabaseSeeder.fresh(db);

    // Refresh streams
    _notifyProductsChanged();
    _notifyTransactionsChanged();
  }

  /// Seed hanya jika tabel kosong
  Future<void> seedIfEmpty() async {
    final db = await instance.database;
    await DatabaseSeeder.seedIfEmpty(db);

    // Refresh streams
    _notifyProductsChanged();
    _notifyTransactionsChanged();
  }

  Future _onUpgrade(sql.Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN harga_beli REAL NOT NULL DEFAULT 0');
      } catch (e) {
        print('Kolom harga_beli mungkin sudah ada: $e');
      }
    }

    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        pin TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
      CREATE TABLE incomes (
        id_income INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

      await db.execute('''
      CREATE TABLE expenses (
        id_expense INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    }

    if (oldVersion < 5) {
      await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
    }

    if (oldVersion < 6) {
      await db.execute('ALTER TABLE products ADD COLUMN stock INTEGER DEFAULT 0');
    }

    if (oldVersion < 10) {
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    }

    if (oldVersion < 11) {
      await db.execute("ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'kasir'");
      await db.rawUpdate("UPDATE users SET role = 'admin' WHERE id = (SELECT MIN(id) FROM users)");
    }
  }

  // ========== USER METHODS ==========

  // Create User (Register)
  Future<User> createUser(User user) async {
    final db = await instance.database;
    try {
      final id = await db.insert('users', user.toMap());
      return user.copyWith(id: id);
    } catch (e) {
      print("Error creating user: $e");
      rethrow;
    }
  }

  // Login menggunakan username dan password
  Future<User?> loginByUsernameAndPassword(String username, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'name = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // Cek apakah nama sudah dipakai (saat register)
  Future<bool> isNameTaken(String name) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'name = ?', whereArgs: [name]);
    return result.isNotEmpty;
  }

  // Cari user berdasarkan Nama (untuk reset password)
  Future<User?> getUserByName(String name) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // Update Password
  Future<int> updatePassword(String name, String newPassword) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  // ========== PRODUCT & TRANSACTION METHODS (TETAP SAMA) ==========
  // ... (Kode produk dan transaksi tetap sama seperti sebelumnya,
  // namun pastikan untuk copy-paste bagian ini dari file lama jika tidak ingin dihapus)

  Future<Product> createProduct(Product product) async {
    final db = await instance.database;
    if (product.id != null) {
      await db.rawInsert(
        'INSERT INTO products (id_product, nama, harga, harga_beli, image_path, stock) VALUES (?, ?, ?, ?, ?, ?)',
        [product.id, product.name, product.price, product.purchasePrice, product.imagePath, product.stock],
      );
    } else {
      final id = await db.insert('products', product.toMap());
      product = product.copyWith(id: id);
    }
    _notifyProductsChanged();
    return product;
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'nama ASC');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<void> _notifyProductsChanged() async {
    final products = await getAllProducts();
    _productStreamController.add(products);
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    final result = await db.rawUpdate(
      'UPDATE products SET nama = ?, harga = ?, harga_beli = ?, image_path = ?, stock = ? WHERE id_product = ?',
      [product.name, product.price, product.purchasePrice, product.imagePath, product.stock, product.id],
    );
    _notifyProductsChanged();
    return result;
  }

  Future<void> decreaseProductStock(int id, int quantity) async {
    final db = await instance.database;
    await db.rawUpdate(
      'UPDATE products SET stock = stock - ? WHERE id_product = ? AND stock >= ?',
      [quantity, id, quantity],
    );
    _notifyProductsChanged();
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    final result = await db.delete(
      'products',
      where: 'id_product = ?',
      whereArgs: [id],
    );
    _notifyProductsChanged();
    return result;
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    final db = await instance.database;
    final id = await db.insert('transactions', transaction.toMap());
    _notifyTransactionsChanged();
    return Transaction(
      id: id,
      transactionCode: transaction.transactionCode,
      userId: transaction.userId,
      totalAmount: transaction.totalAmount,
      cashReceived: transaction.cashReceived,
      change: transaction.change,
      createdAt: transaction.createdAt,
    );
  }

  Future<int> createTransactionItem(TransactionItem item) async {
    final db = await instance.database;
    return await db.insert('transaction_items', item.toMap());
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'created_at DESC');
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  // Tambahkan ini di dalam class DatabaseHelper
  Future<User?> getUserById(int id) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<void> _notifyTransactionsChanged() async {
    final transactions = await getAllTransactions();
    _transactionStreamController.add(transactions);
  }

  Future<int> updateUserName(int id, String newName) async {
    final db = await instance.database;
    final result = await db.update(
      'users',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );

    // TAMBAHKAN INI: Notify perubahan user
    _notifyUserChanged(id);

    return result;
  }

  // TAMBAHKAN METHOD INI:
  Future<void> _notifyUserChanged(int userId) async {
    final user = await getUserById(userId);
    if (user != null) {
      _userStreamController.add(user);
    }
  }

  Future<String> generateTransactionCode() async {
    final now = DateTime.now();
    return 'TRX${now.year}${now.month}${now.day}${now.hour}${now.minute}${now.second}';
  }
  // ... kode yang sudah ada ...

  // Tambahkan method ini di bagian // ========== PRODUCT METHODS ==========
  Future<Product?> getProductById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'products',
      where: 'id_product = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  Future<List<TransactionItem>> getTransactionItems(int transactionId) async {
    final db = await instance.database;
    final result = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'id ASC',
    );
    return result.map((map) => TransactionItem.fromMap(map)).toList();
  }

  Future<bool> hasUsers() async {
    final db = await instance.database;
    final result = await db.query('users', limit: 1);
    return result.isNotEmpty;
  }

  Future close() async {
    final db = await instance.database;
    _productStreamController.close();
    _transactionStreamController.close();
    _userStreamController.close(); // TAMBAHKAN INI
    db.close();
  }

  // INCOME METHODS
  Future<Income> createIncome(Income income) async {
    final db = await instance.database;
    final id = await db.insert('incomes', income.toMap());
    _notifyIncomesChanged();
    return income.copyWith(id: id);
  }

  Future<List<Income>> getAllIncomes() async {
    final db = await instance.database;
    final result = await db.query('incomes', orderBy: 'date DESC');
    return result.map((map) => Income.fromMap(map)).toList();
  }

  Future<int> updateIncome(Income income) async {
    final db = await instance.database;
    final result = await db.update(
      'incomes',
      income.toMap(),
      where: 'id_income = ?',
      whereArgs: [income.id],
    );
    _notifyIncomesChanged();
    return result;
  }

  Future<int> deleteIncome(int id) async {
    final db = await instance.database;
    final result = await db.delete(
      'incomes',
      where: 'id_income = ?',
      whereArgs: [id],
    );
    _notifyIncomesChanged();
    return result;
  }

  // EXPENSE METHODS
  Future<Expense> createExpense(Expense expense) async {
    final db = await instance.database;
    final id = await db.insert('expenses', expense.toMap());
    _notifyExpensesChanged();
    return expense.copyWith(id: id);
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await instance.database;
    final result = await db.update(
      'expenses',
      expense.toMap(),
      where: 'id_expense = ?',
      whereArgs: [expense.id],
    );
    _notifyExpensesChanged();
    return result;
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    final result = await db.delete(
      'expenses',
      where: 'id_expense = ?',
      whereArgs: [id],
    );
    _notifyExpensesChanged();
    return result;
  }

  // AUTO-TRACK: Tambah/update income dari transaksi bulanan dengan info petugas
  Future<void> autoTrackMonthlyIncome(double amount, String userName, String userRole) async {
    final now = DateTime.now();
    final monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final roleLabel = userRole == 'admin' ? 'Admin' : 'Kasir';
    final description =
        'Transaksi Masuk ${now.year} Bulan ${monthNames[now.month - 1]} dari $roleLabel $userName';

    final db = await instance.database;

    // Cek apakah sudah ada income untuk bulan ini dari user ini
    final result = await db.query(
      'incomes',
      where: 'description = ?',
      whereArgs: [description],
      limit: 1,
    );

    if (result.isNotEmpty) {
      // UPDATE: Tambahkan amount ke income yang sudah ada
      final existingIncome = Income.fromMap(result.first);
      final updatedIncome = existingIncome.copyWith(
        amount: existingIncome.amount + amount,
        date: now,
      );
      await updateIncome(updatedIncome);
      print(
        '✅ [AUTO-TRACK] Updated monthly income: +Rp$amount (Total: Rp${updatedIncome.amount}) - $description',
      );
    } else {
      // CREATE: Buat income baru untuk bulan ini
      final newIncome = Income(
        description: description,
        amount: amount,
        date: now,
      );
      await createIncome(newIncome);
      print('✅ [AUTO-TRACK] Created new monthly income: Rp$amount - $description');
    }
  }

  Future<List<User>> getAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users', orderBy: 'name ASC');
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<List<User>> getKasirUsers() async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: "role = 'kasir'",
      orderBy: 'name ASC',
    );
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updatePasswordById(int id, String newPassword) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateUserNameById(int id, String newName) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
