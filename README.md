# 🛒 Kasir Sat-Set (Aplikasi Kasir Pintar)

Kasir Sat-Set adalah aplikasi Point of Sale (POS) atau kasir pintar berbasis **Flutter** yang dirancang khusus untuk toko bangunan, pertanian, atau ritel lainnya. Aplikasi ini berjalan secara *offline* sepenuhnya dengan dukungan database SQLite, memberikan kecepatan dan keamanan data maksimal tanpa bergantung pada koneksi internet.

## ✨ Fitur Utama

*   **📦 Manajemen Produk (Master Data):** 
    *   Kelola nama barang, foto produk, harga beli (modal), harga jual, dan jumlah stok.
    *   Sistem pencarian (Search) yang responsif dan cepat.
*   **🛒 Transaksi Kasir (Point of Sale):**
    *   Keranjang belanja dinamis.
    *   Perhitungan total, uang tunai, dan kembalian otomatis.
    *   Pembuatan kode transaksi unik (TRX...) secara otomatis.
*   **📈 Pencatatan Uang Masuk & Keluar:**
    *   **Uang Masuk:** Mencatat setiap transaksi penjualan secara otomatis.
    *   **Uang Keluar:** Sistem cerdas yang mengotomatisasi pencatatan pengeluaran (Harga Beli × Jumlah) setiap kali Anda melakukan **Stok Masuk** (Kulakan/Restock) dari *suplier*.
*   **🖨️ Dukungan Print Thermal:** Mencetak struk belanja langsung ke printer *Bluetooth thermal*.
*   **📊 Dashboard & Laporan Realtime:** Menampilkan ringkasan total pendapatan, pengeluaran, dan sisa saldo secara *real-time* berbasis Stream.

## 🛠️ Teknologi yang Digunakan

*   **Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **Database:** SQLite (`sqflite` package)
*   **Format Uang:** `intl` (NumberFormat untuk Rupiah)
*   **Kamera & Galeri:** `image_picker` (Untuk foto produk)
*   **State Management:** Reactive Programming dengan `StreamController` murni.

## 🚀 Cara Menjalankan Aplikasi (Development)

1. Pastikan Anda telah menginstal Flutter SDK dan Android Studio / VS Code.
2. *Clone* atau unduh *repository* ini.
3. Buka terminal di direktori proyek dan jalankan:
   ```bash
   flutter pub get
   ```
4. Hubungkan perangkat Android (fisik) atau nyalakan Emulator.
5. Jalankan aplikasi:
   ```bash
   flutter run
   ```

## ⚠️ Catatan Penting (Mode Rilis)
Jika Anda ingin merilis aplikasi ini untuk produksi (digunakan oleh toko sungguhan), pastikan Anda **mematikan fungsi Seeder** (Data Palsu) agar database dimulai dari keadaan kosong.
*   Buka file `lib/database/database_helper.dart`
*   Beri komentar pada pemanggilan `await DatabaseSeeder.run(db);` di fungsi `_createDB()`.

---
*Dibuat dengan ❤️ untuk mempermudah UMKM Indonesia.*
