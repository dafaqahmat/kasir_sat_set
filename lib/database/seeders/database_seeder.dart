// lib/database/seeders/database_seeder.dart

import 'package:sqflite/sqflite.dart';
import 'product_seeder.dart';
// Import seeder lain di sini jika ada

class DatabaseSeeder {
  /// Jalankan semua seeder
  static Future<void> run(Database db) async {
    print('\n🌱 Starting database seeding...\n');

    try {
      // Jalankan seeder satu per satu
      await ProductSeeder.run(db);

      // Tambahkan seeder lain di sini
      // await CategorySeeder.run(db);
      // await IncomeSeeder.run(db);

      print('\n✅ All seeders completed successfully!\n');
    } catch (e) {
      print('\n❌ Seeding failed: $e\n');
      rethrow;
    }
  }

  /// Jalankan seeder hanya jika tabel masih kosong
  static Future<void> seedIfEmpty(Database db) async {
    print('\n🌱 Checking if seeding is needed...\n');

    try {
      await ProductSeeder.seedIfEmpty(db);

      print('\n✅ Seeding check completed!\n');
    } catch (e) {
      print('\n❌ Seeding check failed: $e\n');
      rethrow;
    }
  }

  /// Reset semua data dan seed ulang (untuk development/testing)
  static Future<void> fresh(Database db) async {
    print('\n🔄 Resetting database and reseeding...\n');

    try {
      // Hapus semua data dari tabel
      await db.delete('products');
      await db.delete('users');
      await db.delete('transactions');
      await db.delete('transaction_items');
      await db.delete('incomes');
      await db.delete('expenses');

      print('🗑️  All tables cleared');

      // Jalankan seeder
      await run(db);

      print('\n✅ Database reset and reseeded successfully!\n');
    } catch (e) {
      print('\n❌ Database reset failed: $e\n');
      rethrow;
    }
  }
}
