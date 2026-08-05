import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/thermal_printer_service.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final ThermalPrinterService _printerService = ThermalPrinterService();
  List<dynamic> _availablePrinters = [];
  String? _selectedPrinter;
  bool _isScanning = false;
  bool _isConnected = false;
  String _storeName = '';
  String _storeAddress = '';
  String _storePhone = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkConnection();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPrinter = prefs.getString('selected_printer');
      _storeName = prefs.getString('store_name') ?? 'TOKO SATSET';
      _storeAddress = prefs.getString('store_address') ?? 'Jl. Contoh No. 123';
      _storePhone = prefs.getString('store_phone') ?? '08123456789';
    });
  }

  Future<void> _checkConnection() async {
    final connected = await _printerService.isConnected();
    setState(() => _isConnected = connected);
  }

  Future<void> _scanPrinters() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted) {
      setState(() => _isScanning = true);

      try {
        final printers = await _printerService.scanPrinters();
        setState(() {
          _availablePrinters = printers;
          _isScanning = false;
        });

        if (printers.isEmpty) {
          _showSnackBar('Tidak ada printer ditemukan', Colors.orange);
        }
      } catch (e) {
        setState(() => _isScanning = false);
        _showSnackBar('Error scanning: $e', Colors.red);
      }
    } else {
      _showSnackBar('Izin Bluetooth diperlukan', Colors.red);
    }
  }

  Future<void> _connectPrinter(String printerName, String address) async {
    _showLoading();

    try {
      final success = await _printerService.connectPrinter(address);
      if (mounted) Navigator.pop(context);

      if (success) {
        setState(() {
          _selectedPrinter = printerName;
          _isConnected = true;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('printer_address', address);
        await prefs.setString('selected_printer', printerName);

        _showSnackBar('✅ Berhasil terhubung ke $printerName', Colors.green);
      } else {
        _showSnackBar('❌ Gagal terhubung ke printer', Colors.red);
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _disconnectPrinter() async {
    await _printerService.disconnect();
    setState(() => _isConnected = false);
    _showSnackBar('Printer terputus', Colors.orange);
  }

  Future<void> _testPrint() async {
    if (!_isConnected) {
      _showSnackBar('Printer belum terhubung', Colors.orange);
      return;
    }

    try {
      await _printerService.printTestReceipt(
        _storeName,
        _storeAddress,
        _storePhone,
      );
      _showSnackBar('Test print berhasil', Colors.green);
    } catch (e) {
      _showSnackBar('Error print: $e', Colors.red);
    }
  }

  Future<void> _reconnectPrinter() async {
    _showLoading();

    try {
      final success = await _printerService.autoReconnect();
      if (mounted) Navigator.pop(context);

      if (success) {
        setState(() => _isConnected = true);
        _showSnackBar('✅ Berhasil tersambung kembali', Colors.green);
      } else {
        _showSnackBar('❌ Gagal tersambung kembali', Colors.red);
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF03D1C5)),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Pengaturan Printer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF03D1C5),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Connection Status Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF03D1C5),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isConnected ? Icons.print : Icons.print_disabled,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isConnected ? 'Terhubung' : 'Tidak Terhubung',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_selectedPrinter != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _selectedPrinter!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Reconnect Button
                  if (!_isConnected && _selectedPrinter != null) ...[
                    _ActionButton(
                      icon: Icons.refresh,
                      label: 'Sambungkan Ulang',
                      color: Colors.orange,
                      onPressed: _reconnectPrinter,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Scan Button
                  _ActionButton(
                    icon: _isScanning ? null : Icons.search,
                    label: _isScanning ? 'Mencari...' : 'Cari Printer',
                    color: const Color(0xFF03D1C5),
                    onPressed: _isScanning ? null : _scanPrinters,
                    isLoading: _isScanning,
                  ),

                  const SizedBox(height: 12),

                  // Test Print Button
                  _ActionButton(
                    icon: Icons.print,
                    label: 'Test Print',
                    color: const Color(0xFF03D1C5),
                    onPressed: _isConnected ? _testPrint : null,
                    isOutlined: true,
                  ),

                  // Disconnect Button
                  if (_isConnected) ...[
                    const SizedBox(height: 12),
                    _ActionButton(
                      icon: Icons.link_off,
                      label: 'Putuskan Koneksi',
                      color: Colors.red,
                      onPressed: _disconnectPrinter,
                      isOutlined: true,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Available Printers List
            if (_availablePrinters.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF03D1C5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bluetooth,
                        color: Color(0xFF03D1C5),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Printer Tersedia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _availablePrinters.length,
                itemBuilder: (context, index) {
                  final printer = _availablePrinters[index];
                  return _PrinterCard(
                    name: printer['name'] ?? 'Unknown Printer',
                    address: printer['address'] ?? '',
                    onConnect: () => _connectPrinter(
                      printer['name'] ?? 'Printer',
                      printer['address'] ?? '',
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isLoading;

  const _ActionButton({
    this.icon,
    required this.label,
    required this.color,
    this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            disabledForegroundColor: color.withOpacity(0.6), // Gunakan warna asli tapi transparan
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: isDisabled ? color.withOpacity(0.4) : color, width: isDisabled ? 1.5 : 1.0),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : (icon != null ? Icon(icon) : const SizedBox.shrink()),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.5), // Latar belakang warna asli terang
          disabledForegroundColor: Colors.white.withOpacity(0.9), // Teks putih agar jelas
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isDisabled ? 0 : 2,
        ),
      ),
    );
  }
}

// Printer Card Widget
class _PrinterCard extends StatelessWidget {
  final String name;
  final String address;
  final VoidCallback onConnect;

  const _PrinterCard({
    required this.name,
    required this.address,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF03D1C5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.print,
            color: Color(0xFF03D1C5),
            size: 24,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          address,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: ElevatedButton(
          onPressed: onConnect,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF03D1C5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Hubungkan'),
        ),
      ),
    );
  }
}