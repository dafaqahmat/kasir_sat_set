# Kasir Sat-Set

Aplikasi kasir (Point of Sale) berbasis Flutter untuk UMKM dengan sistem multi-role (Admin & Kasir). Berjalan offline dengan database SQLite.

## Fitur

### Admin
- **Dashboard lengkap** - Ringkasan keuangan, grafik penjualan 7 hari, laporan keuangan (donut chart)
- **Kelola produk** - CRUD produk dengan foto, harga beli/jual, stok
- **Transaksi** - Proses penjualan dengan keranjang, hitung kembalian otomatis
- **Kelola kasir** - Tambah, edit, hapus, reset password kasir
- **Laporan keuangan** - Uang masuk, uang keluar, riwayat transaksi, laporan keuangan
- **Pengaturan** - Profil toko, printer thermal, ubah password

### Kasir
- **Dashboard ringkas** - Ringkasan transaksi hari ini, grafik penjualan 7 hari (hanya transaksi sendiri)
- **Transaksi** - Proses penjualan (tidak bisa kelola produk/kasir)
- **Pengaturan printer** - Koneksi printer thermal Bluetooth
- **Ubah password** - Ganti password sendiri

### Fitur Umum
- **Login multi-role** - Username & password, routing otomatis ke dashboard sesuai role
- **Auto-track income** - Pencatatan pendapatan bulanan otomatis per petugas (contoh: "Transaksi Masuk 2026 Bulan Agustus dari Admin Dafa")
- **Print thermal Bluetooth** - Cetak struk ke printer thermal (transaksi tetap bisa lanjut meski bluetooth mati)
- **Scan barcode** - Tambah produk ke keranjang dengan scan barcode
- **Realtime update** - Data terupdate otomatis menggunakan Stream
- **Sound effect** - Notifikasi suara saat transaksi berhasil

## Teknologi

- **Flutter** (Dart)
- **SQLite** (sqflite) - Database lokal
- **flutter_blue_plus** - Bluetooth thermal printer
- **mobile_scanner** - Scan barcode
- **shared_preferences** - Session management
- **StreamController** - State management

## Cara Menjalankan

```bash
flutter pub get
flutter run
```

## Struktur Role

### Admin Pertama
User pertama yang mendaftar otomatis menjadi **Admin**. Admin bisa:
- Kelola semua aspek toko
- Tambah/hapus/edit kasir
- Lihat semua laporan keuangan

### Kasir
Kasir ditambahkan oleh Admin melalui menu "Kelola Kasir". Kasir hanya bisa:
- Transaksi
- Lihat dashboard sendiri (hanya transaksi milik mereka)
- Ubah password sendiri
- Pengaturan printer

## Database

Tabel utama:
- `users` - id, name, password, role (admin/kasir), created_at
- `products` - id, nama, harga, harga_beli, image_path, stock
- `transactions` - id, transaction_code, user_id, total_amount, cash_received, change, created_at
- `incomes` - id, description, amount, date
- `expenses` - id, description, amount, date

## Catatan Penting

- Aplikasi berjalan **100% offline**
- Data tersimpan di perangkat, jika aplikasi di-uninstall maka data hilang
- Untuk produksi, matikan seeder di `lib/database/database_helper.dart` (hapus pemanggilan `DatabaseSeeder.run(db)`)

## Lisensi

Aplikasi ini dibuat untuk keperluan pembelajaran dan UMKM.

