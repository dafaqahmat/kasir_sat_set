import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThermalPrinterService {
  static final ThermalPrinterService _instance =
      ThermalPrinterService._internal();

  factory ThermalPrinterService() {
    return _instance;
  }

  ThermalPrinterService._internal();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _targetCharacteristic;
  bool _isConnected = false;
  StreamSubscription? _connectionSubscription;
  String? _printerModel;

  // UUID karakteristik umum untuk thermal printer
  static const String PRINTER_CHAR_UUID_1 = "0000ff02-0000-1000-8000-00805f9b34fb"; // POS58 common
  static const String PRINTER_CHAR_UUID_2 = "49535343-8841-43f4-a8d4-ecbe34729bb3"; // Alternative
  static const String PRINTER_CHAR_UUID_3 = "0000ffe1-0000-1000-8000-00805f9b34fb"; // HM-10 based

  // Getter untuk status koneksi
  bool get isCurrentlyConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _device;

  Future<bool> isConnected() async {
    return _isConnected;
  }

  Future<Map<String, String>> _getStoreInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'storeName': prefs.getString('store_name') ?? 'TOKO SATSET',
      'storeAddress': prefs.getString('store_address') ?? 'Jl. Contoh No. 123',
      'storePhone': prefs.getString('store_phone') ?? '08123456789',
      'cashierName': prefs.getString('cashier_name') ?? 'Kasir',
    };
  }

  Future<bool> autoReconnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAddress = prefs.getString('printer_address');
      final savedName = prefs.getString('selected_printer');

      if (savedAddress == null || savedName == null) {
        return false;
      }

      print('🔄 [PRINTER] Mencoba koneksi ulang ke: $savedName ($savedAddress)');

      if (_isConnected && _device != null) {
        return true;
      }

      return await connectPrinter(savedAddress);
    } catch (e) {
      print('❌ [PRINTER] Gagal koneksi ulang: $e');
      return false;
    }
  }

  Future<List<Map<String, String>>> scanPrinters() async {
    List<Map<String, String>> printers = [];

    try {
      if (await FlutterBluePlus.isSupported == false) {
        return [];
      }

      // Cek perangkat yang sudah dipasangkan (bonded)
      List<BluetoothDevice> bondedDevices = await FlutterBluePlus.bondedDevices;
      for (var device in bondedDevices) {
        printers.add({
          'name': device.platformName.isNotEmpty
              ? device.platformName
              : 'Perangkat Tidak Dikenal',
          'address': device.remoteId.toString(),
        });
      }

      // Scan perangkat baru
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      var subscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          String deviceName = r.device.platformName;
          if (deviceName.isNotEmpty &&
              !printers.any(
                (p) => p['address'] == r.device.remoteId.toString(),
              )) {
            printers.add({
              'name': deviceName,
              'address': r.device.remoteId.toString(),
            });
          }
        }
      });

      await Future.delayed(const Duration(seconds: 4));
      subscription.cancel();
      await FlutterBluePlus.stopScan();

      return printers;
    } catch (e) {
      print('❌ [PRINTER] Gagal memindai printer: $e');
      return printers;
    }
  }

  Future<bool> connectPrinter(String address) async {
    try {
      print('🔌 [PRINTER] Menghubungkan ke: $address');

      if (_device != null) {
        await disconnect();
      }

      List<BluetoothDevice> devices = await FlutterBluePlus.bondedDevices;
      BluetoothDevice? targetDevice;

      // Cari di daftar perangkat yang sudah dipasangkan
      for (var device in devices) {
        if (device.remoteId.toString() == address) {
          targetDevice = device;
          break;
        }
      }

      // Jika tidak ditemukan, scan sebentar
      if (targetDevice == null) {
         await FlutterBluePlus.startScan(timeout: const Duration(seconds: 2));
         await Future.delayed(const Duration(seconds: 2));
         await FlutterBluePlus.stopScan();
         print('❌ [PRINTER] Perangkat tidak ditemukan dalam daftar paired.');
         return false; 
      }

      _device = targetDevice;
      _printerModel = _device!.platformName;

      // Koneksi ke perangkat
      await _device!.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
        mtu: null
      );
      
      _connectionSubscription = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _isConnected = false;
          _targetCharacteristic = null;
        }
      });

      // Tunggu lebih lama untuk stabilitas
      await Future.delayed(const Duration(milliseconds: 2000));

      print('🔍 [PRINTER] Mencari service dan karakteristik...');
      List<BluetoothService> services = await _device!.discoverServices();
      
      _targetCharacteristic = null;
      List<BluetoothCharacteristic> candidateChars = [];
      
      // Cari karakteristik yang cocok untuk POS58
      for (BluetoothService service in services) {
        print('   📦 Service: ${service.uuid}');
        for (BluetoothCharacteristic char in service.characteristics) {
          String uuidStr = char.uuid.toString().toLowerCase();
          print('      🔸 Char: $uuidStr (W:${char.properties.write}, WNR:${char.properties.writeWithoutResponse})');
          
          // Prioritas tinggi: UUID yang umum untuk thermal printer
          if (uuidStr == PRINTER_CHAR_UUID_1 || 
              uuidStr == PRINTER_CHAR_UUID_2 || 
              uuidStr == PRINTER_CHAR_UUID_3) {
            if (char.properties.write || char.properties.writeWithoutResponse) {
              _targetCharacteristic = char;
              print('         ✅ MATCH! Menggunakan karakteristik ini (UUID cocok)');
              break;
            }
          }
          
          // Simpan kandidat lain yang bisa ditulis
          if (char.properties.write || char.properties.writeWithoutResponse) {
            candidateChars.add(char);
          }
        }
        if (_targetCharacteristic != null) break;
      }

      // Jika tidak menemukan UUID khusus, gunakan kandidat pertama
      if (_targetCharacteristic == null && candidateChars.isNotEmpty) {
        // Prioritaskan writeWithoutResponse
        for (var char in candidateChars) {
          if (char.properties.writeWithoutResponse) {
            _targetCharacteristic = char;
            print('   ✅ Menggunakan karakteristik: ${char.uuid} (writeWithoutResponse)');
            break;
          }
        }
        
        // Fallback ke write biasa
        if (_targetCharacteristic == null) {
          _targetCharacteristic = candidateChars.first;
          print('   ✅ Menggunakan karakteristik: ${_targetCharacteristic!.uuid} (write)');
        }
      }

      if (_targetCharacteristic == null) {
        throw Exception('Tidak ditemukan karakteristik yang dapat ditulis');
      }
      
      _isConnected = true;
      print('✅ [PRINTER] Berhasil terhubung ke printer.');
      
      return true;
    } catch (e) {
      print('❌ [PRINTER] Gagal koneksi: $e');
      _isConnected = false;
      _device = null;
      _targetCharacteristic = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    _connectionSubscription?.cancel();
    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (e) {
        print('⚠️ [PRINTER] Error saat disconnect: $e');
      }
    }
    _isConnected = false;
    _device = null;
    _targetCharacteristic = null;
  }

  // FUNGSI UTAMA: Kirim data dengan metode yang lebih robust untuk POS58
  Future<void> _printBytes(List<int> bytes) async {
    if (_device == null || _targetCharacteristic == null) {
      throw Exception('Printer belum terhubung dengan benar');
    }

    print('\n🖨️ [PRINTER] Memulai pencetakan (${bytes.length} bytes)');
    
    try {
      bool useWithoutResponse = _targetCharacteristic!.properties.writeWithoutResponse;
      
      // Untuk POS58: chunk lebih kecil dan delay lebih lama
      const int chunkSize = 20;
      int delayMs = useWithoutResponse ? 30 : 50; // Delay lebih lama untuk stabilitas
      
      int totalChunks = (bytes.length / chunkSize).ceil();
      print('   📤 Mengirim $totalChunks paket data...');

      for (int i = 0; i < bytes.length; i += chunkSize) {
        int end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        List<int> chunk = bytes.sublist(i, end);

        try {
          if (useWithoutResponse) {
            await _targetCharacteristic!.write(chunk, withoutResponse: true);
          } else {
            await _targetCharacteristic!.write(chunk, withoutResponse: false);
          }
          
          // Progress indicator setiap 10 paket
          if ((i ~/ chunkSize) % 10 == 0) {
            int progress = ((i / bytes.length) * 100).round();
            print('   ⏳ Progress: $progress%');
          }
          
          await Future.delayed(Duration(milliseconds: delayMs));
        } catch (e) {
          print('   ⚠️ Error pada chunk ${i ~/ chunkSize}: $e');
          // Coba kirim ulang sekali
          await Future.delayed(Duration(milliseconds: 100));
          if (useWithoutResponse) {
            await _targetCharacteristic!.write(chunk, withoutResponse: true);
          } else {
            await _targetCharacteristic!.write(chunk, withoutResponse: false);
          }
        }
      }
      
      // Perintah feed kertas minimal
      print('   📄 Mengirim perintah feed kertas...');
      
      // ESC/POS commands untuk feed (lebih hemat kertas)
      List<int> feedCommands = [
        0x1B, 0x64, 0x02,  // Feed 2 lines saja
        0x1D, 0x56, 0x00,  // Full cut (jika didukung)
      ];
      
      if (useWithoutResponse) {
        await _targetCharacteristic!.write(feedCommands, withoutResponse: true);
      } else {
        await _targetCharacteristic!.write(feedCommands, withoutResponse: false);
      }

      // Delay final untuk memastikan printer selesai proses
      await Future.delayed(Duration(milliseconds: 500));

      print('✅ [PRINTER] Pencetakan selesai.');
      
    } catch (e) {
      print('❌ [PRINTER] Gagal mencetak: $e');
      throw Exception('Gagal mengirim data ke printer: $e');
    }
  }

  Future<void> printReceipt({
    required String transactionId,
    required DateTime transactionDate,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
    required double paid,
    required double change,
  }) async {
    try {
      final storeInfo = await _getStoreInfo();
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // Reset printer dan initialize
      bytes += [0x1B, 0x40]; // ESC @ - Initialize printer
      await Future.delayed(Duration(milliseconds: 100));

      // Header
      bytes += generator.text(
        storeInfo['storeName']!,
        styles: const PosStyles(align: PosAlign.center, bold: true)
      );
      bytes += generator.text(
        storeInfo['storeAddress']!,
        styles: const PosStyles(align: PosAlign.center)
      );
      bytes += generator.text(
        'Telp: ${storeInfo['storePhone']}',
        styles: const PosStyles(align: PosAlign.center)
      );
      bytes += generator.text(
        '================================',
        styles: const PosStyles(align: PosAlign.center)
      );
      bytes += generator.text('No: $transactionId');
      bytes += generator.text(
        '${transactionDate.day}/${transactionDate.month}/${transactionDate.year} ${transactionDate.hour}:${transactionDate.minute}'
      );
      bytes += generator.text('Kasir: ${storeInfo['cashierName']}');
      bytes += generator.text(
        '================================',
        styles: const PosStyles(align: PosAlign.center)
      );

      // Items
      for (var item in items) {
        bytes += generator.text(item['name']);
        bytes += generator.row([
          PosColumn(text: ' ${item['quantity']}x', width: 3),
          PosColumn(text: '@${_formatCurrency(item['price'])}', width: 5),
          PosColumn(
            text: _formatCurrency(item['quantity'] * item['price']),
            width: 4,
            styles: const PosStyles(align: PosAlign.right)
          ),
        ]);
      }

      bytes += generator.text(
        '================================',
        styles: const PosStyles(align: PosAlign.center)
      );

      // Subtotal (jika ada diskon/pajak)
      if (discount > 0 || tax > 0) {
        bytes += generator.row([
          PosColumn(text: 'Subtotal', width: 6),
          PosColumn(
            text: _formatCurrency(subtotal),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)
          ),
        ]);
        
        if (discount > 0) {
          bytes += generator.row([
            PosColumn(text: 'Diskon', width: 6),
            PosColumn(
              text: '-${_formatCurrency(discount)}',
              width: 6,
              styles: const PosStyles(align: PosAlign.right)
            ),
          ]);
        }
        
        if (tax > 0) {
          bytes += generator.row([
            PosColumn(text: 'Pajak', width: 6),
            PosColumn(
              text: _formatCurrency(tax),
              width: 6,
              styles: const PosStyles(align: PosAlign.right)
            ),
          ]);
        }
        
        bytes += generator.text('--------------------------------');
      }

      // Total
      bytes += generator.row([
        PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: _formatCurrency(total),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true)
        ),
      ]);
      
      bytes += generator.row([
        PosColumn(text: 'Bayar', width: 6),
        PosColumn(
          text: _formatCurrency(paid),
          width: 6,
          styles: const PosStyles(align: PosAlign.right)
        ),
      ]);
       
      bytes += generator.row([
        PosColumn(text: 'Kembali', width: 6),
        PosColumn(
          text: _formatCurrency(change),
          width: 6,
          styles: const PosStyles(align: PosAlign.right)
        ),
      ]);

      // Footer
      bytes += generator.text(
        '================================',
        styles: const PosStyles(align: PosAlign.center)
      );
      bytes += generator.text(
        'Terima Kasih',
        styles: const PosStyles(align: PosAlign.center, bold: true)
      );
      bytes += generator.text(
        'Atas Kunjungan Anda',
        styles: const PosStyles(align: PosAlign.center)
      );
      
      bytes += generator.feed(1); // Hanya 1 feed
      bytes += [0x0A]; // 1 line feed manual saja

      await _printBytes(bytes);
    } catch (e) {
      print('❌ [PRINTER] Gagal mencetak struk: $e');
      rethrow;
    }
  }

  Future<void> printTestReceipt(String s1, String s2, String s3) async {
    print('🧪 [PRINTER] Mencetak tes struk...');
    List<int> bytes = [];
    
    // Reset printer
    bytes += [0x1B, 0x40]; // ESC @
    await Future.delayed(Duration(milliseconds: 100));
    
    // Konten test
    bytes += [0x1B, 0x61, 0x01]; // Center align
    bytes += "*** TEST PRINT ***\n".codeUnits;
    bytes += [0x1B, 0x61, 0x00]; // Left align
    bytes += "\n".codeUnits;
    // bytes += "POS58B-YS-NOSPI\n".codeUnits;
    bytes += "Koneksi Berhasil!\n".codeUnits;
    bytes += "\n".codeUnits;
    bytes += "Model: $_printerModel\n".codeUnits;
    bytes += "================================\n".codeUnits;
    bytes += "Printer siap digunakan\n".codeUnits;
    bytes += "================================\n".codeUnits;
    bytes += "\n".codeUnits; // Hanya 1 enter
    
    await _printBytes(bytes);
  }

  String _formatCurrency(double amount) {
    // Format angka dengan pemisah ribuan (.)
    String numStr = amount.toStringAsFixed(0);
    String result = '';
    int counter = 0;
    
    // Loop dari belakang untuk menambahkan titik setiap 3 digit
    for (int i = numStr.length - 1; i >= 0; i--) {
      if (counter == 3) {
        result = '.$result';
        counter = 0;
      }
      result = numStr[i] + result;
      counter++;
    }
    
    return 'Rp $result';
  }
}