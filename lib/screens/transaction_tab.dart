import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:io';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../database/database_helper.dart';
import '../services/thermal_printer_service.dart';
import '../services/sound_service.dart';
import '../widgets/barcode_scanner_sheet.dart';
import 'package:permission_handler/permission_handler.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;
}

class TransactionTab extends StatefulWidget {
  final User user;

  const TransactionTab({super.key, required this.user});

  @override
  State<TransactionTab> createState() => _TransactionTabState();
}

class _TransactionTabState extends State<TransactionTab>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<CartItem> _cart = [];
  bool _isLoading = true;
  bool _isBluetoothOn = false;
  bool _isPrinterConnected = false;
  bool _isAutoReconnecting = false;

  StreamSubscription<List<Product>>? _productSubscription;
  StreamSubscription<BluetoothAdapterState>? _bluetoothSubscription;
  Timer? _printerCheckTimer;

  final ThermalPrinterService _printerService = ThermalPrinterService();
  final SoundService _soundService = SoundService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late AnimationController _cartAnimController;
  late AnimationController _shimmerController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cartAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _requestBluetoothPermissionsEarly();
    _loadProducts();
    _subscribeToProductUpdates();
    _initializeBluetoothAndPrinter();
    _searchController.addListener(_filterProducts);
  }

  Future<void> _requestBluetoothPermissionsEarly() async {
    try {
      print('📋 [INIT] Requesting Bluetooth permissions early...');
      await Future.wait([
        Permission.bluetooth.request(),
        Permission.bluetoothConnect.request(),
        Permission.bluetoothScan.request(),
        Permission.location.request(),
      ]);
      print('✅ [INIT] Permissions requested');
    } catch (e) {
      print('⚠️ [INIT] Error requesting permissions: $e');
    }
  }

  Future<void> _initializeBluetoothAndPrinter() async {
    print('🚀 [TRANSACTION] Initializing Bluetooth and Printer...');
    await _checkBluetoothStatus();
    _subscribeToBluetoothState();
    if (_isBluetoothOn) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _tryConnectPrinter();
    }
    _startPrinterStatusCheck();
  }

  void _startPrinterStatusCheck() {
    _printerCheckTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      if (mounted && _isBluetoothOn && !_isAutoReconnecting) {
        await _checkPrinterConnection();
      }
    });
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      final isOn = adapterState == BluetoothAdapterState.on;
      if (mounted) setState(() => _isBluetoothOn = isOn);
      print(
        '🔵 [TRANSACTION] Initial Bluetooth status: ${isOn ? "ON" : "OFF"}',
      );
    } catch (e) {
      print('❌ [TRANSACTION] Error checking Bluetooth status: $e');
    }
  }

  void _subscribeToBluetoothState() {
    _bluetoothSubscription = FlutterBluePlus.adapterState.listen((state) async {
      if (mounted) {
        final isNowOn = state == BluetoothAdapterState.on;
        final wasOff = !_isBluetoothOn;
        setState(() => _isBluetoothOn = isNowOn);
        print('📡 [TRANSACTION] Bluetooth state changed: $state');
        if (isNowOn && wasOff) {
          print(
            '🔵 [TRANSACTION] Bluetooth turned ON, attempting auto-reconnect...',
          );
          await Future.delayed(const Duration(milliseconds: 1000));
          await _tryConnectPrinter();
        } else if (!isNowOn) {
          print('🔴 [TRANSACTION] Bluetooth turned OFF');
          if (mounted) {
            setState(() {
              _isPrinterConnected = false;
              _isAutoReconnecting = false;
            });
          }
        }
      }
    });
  }

  Future<void> _tryConnectPrinter() async {
    if (!_isBluetoothOn) return;
    if (mounted) setState(() => _isAutoReconnecting = true);
    try {
      final alreadyConnected = await _printerService.isConnected();
      if (alreadyConnected) {
        print('✅ [TRANSACTION] Printer already connected');
        if (mounted) {
          setState(() {
            _isPrinterConnected = true;
            _isAutoReconnecting = false;
          });
        }
        return;
      }
      final success = await _printerService.autoReconnect();
      if (mounted) {
        setState(() {
          _isPrinterConnected = success;
          _isAutoReconnecting = false;
        });
        if (success) {
          print('✅ [TRANSACTION] Printer auto-reconnected successfully');
          _showSnackBar(
            '✅ Printer tersambung otomatis',
            const Color(0xFF03D1C5),
          );
        }
      }
    } catch (e) {
      print('❌ [TRANSACTION] Error connecting printer: $e');
      if (mounted) setState(() => _isAutoReconnecting = false);
    }
  }

  Future<void> _checkPrinterConnection() async {
    if (!_isBluetoothOn) {
      if (mounted && _isPrinterConnected)
        setState(() => _isPrinterConnected = false);
      return;
    }
    try {
      final connected = await _printerService.isConnected();
      if (mounted && _isPrinterConnected != connected) {
        setState(() => _isPrinterConnected = connected);
        print('🔍 [TRANSACTION] Printer connection status: $connected');
      }
    } catch (e) {
      print('❌ [TRANSACTION] Error checking printer: $e');
    }
  }

  void _subscribeToProductUpdates() {
    _productSubscription = DatabaseHelper.instance.productStream.listen((
      products,
    ) {
      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          return product.name.toLowerCase().contains(query) ||
              product.id.toString().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    _bluetoothSubscription?.cancel();
    _printerCheckTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _cartAnimController.dispose();
    _shimmerController.dispose();
    _soundService.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await DatabaseHelper.instance.getAllProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading products: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      _showSnackBar('Stok produk ini habis!', Colors.red);
      return;
    }
    final existingIndex = _cart.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex >= 0) {
      if (_cart[existingIndex].quantity >= product.stock) {
        _showSnackBar('Kuantitas melebihi stok yang tersedia!', Colors.orange);
        return;
      }
      setState(() => _cart[existingIndex].quantity++);
    } else {
      setState(() => _cart.add(CartItem(product: product)));
    }
    _cartAnimController.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _removeFromCart(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeFromCart(index);
    } else {
      final product = _cart[index].product;
      if (newQuantity > product.stock) {
        _showSnackBar('Kuantitas melebihi stok (${product.stock})!', Colors.orange);
        return;
      }
      setState(() => _cart[index].quantity = newQuantity);
    }
  }

  double get _totalAmount {
    return _cart.fold(0, (sum, item) => sum + item.subtotal);
  }

  void _showScanBarcodeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BarcodeScannerSheet(
        onBarcodeScanned: (barcode) async {
          Navigator.pop(context);
          final id = int.tryParse(barcode);
          if (id == null) {
            _showSnackBar('Barcode tidak valid!', Colors.red);
            return;
          }
          final product = await DatabaseHelper.instance.getProductById(id);
          if (product == null) {
            _showSnackBar(
              'Produk dengan ID $id tidak ditemukan!',
              Colors.orange,
            );
            return;
          }
          _addToCart(product);
          _showSnackBar(
            '${product.name} ditambahkan ke keranjang!',
            const Color(0xFF03D1C5),
          );
        },
      ),
    );
  }

  void _showPaymentDialog() {
    if (_cart.isEmpty) {
      _showSnackBar('Keranjang masih kosong!', Colors.orange);
      return;
    }
    if (!_isBluetoothOn) {
      _showBluetoothRequiredDialog();
      return;
    }
    if (!_isPrinterConnected) {
      _showPrinterNotConnectedDialog();
      return;
    }
    _showCashPaymentDialog(canPrint: true);
  }

  void _showBluetoothRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.bluetooth_disabled, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Bluetooth Mati'),
          ],
        ),
        content: const Text(
          'Bluetooth tidak aktif. Transaksi tetap bisa dilanjutkan, tetapi struk tidak akan dicetak.\n\nApakah Anda ingin melanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showCashPaymentDialog(canPrint: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _showPrinterNotConnectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.print_disabled, color: Colors.orange, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Printer Belum Terhubung',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        content: const Text(
          'Printer thermal belum terhubung. Transaksi tetap bisa dilanjutkan, tetapi struk tidak akan dicetak.\n\nApakah Anda ingin melanjutkan?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showCashPaymentDialog(canPrint: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _showCashPaymentDialog({required bool canPrint}) {
    final cashController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (canPrint ? const Color(0xFF03D1C5) : Colors.orange)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.payments_rounded,
                    size: 48,
                    color: canPrint ? const Color(0xFF03D1C5) : Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  canPrint ? 'Pembayaran Cash' : 'Pembayaran Tanpa Struk',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF03D1C5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF03D1C5).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Belanja:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${_formatCurrency(_totalAmount)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF03D1C5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: cashController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Jumlah Uang Diterima',
                    hintText: '0',
                    prefixText: 'Rp ',
                    prefixIcon: const Icon(
                      Icons.attach_money_rounded,
                      color: Color(0xFF03D1C5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF03D1C5),
                        width: 2,
                      ),
                    ),
                    labelStyle: const TextStyle(color: Color(0xFF03D1C5)),
                    filled: true,
                    fillColor: const Color(0xFF03D1C5).withOpacity(0.05),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF03D1C5),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final cash =
                              double.tryParse(cashController.text) ?? 0;
                          if (cash < _totalAmount) {
                            _showSnackBar('Uang tidak cukup!', Colors.red);
                            return;
                          }
                          Navigator.pop(context);
                          await _processTransaction(cash, canPrint);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canPrint
                              ? const Color(0xFF03D1C5)
                              : Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Proses',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processTransaction(
    double cashReceived,
    bool shouldPrint,
  ) async {
    try {
      final change = cashReceived - _totalAmount;
      final transactionCode = await DatabaseHelper.instance
          .generateTransactionCode();
      final transaction = Transaction(
        transactionCode: transactionCode,
        userId: widget.user.id!,
        totalAmount: _totalAmount,
        cashReceived: cashReceived,
        change: change,
        createdAt: DateTime.now(),
      );
      final savedTransaction = await DatabaseHelper.instance.createTransaction(
        transaction,
      );
      for (var cartItem in _cart) {
        final item = TransactionItem(
          transactionId: savedTransaction.id!,
          productId: cartItem.product.id!,
          productName: cartItem.product.name,
          quantity: cartItem.quantity,
          price: cartItem.product.price,
          subtotal: cartItem.subtotal,
        );
        await DatabaseHelper.instance.createTransactionItem(item);
        // Kurangi stok produk
        await DatabaseHelper.instance.decreaseProductStock(cartItem.product.id!, cartItem.quantity);
      }

      // 🆕 AUTO-TRACK: Tambahkan transaksi ke income bulanan dengan info petugas
      await DatabaseHelper.instance.autoTrackMonthlyIncome(_totalAmount, widget.user.name, widget.user.role);

      await _soundService.playKaching();
      bool printSuccess = false;
      if (shouldPrint && _isPrinterConnected) {
        printSuccess = await _autoPrintReceipt(
          transactionCode: transactionCode,
          cashReceived: cashReceived,
          change: change,
          cartItems: _cart,
        );
      }
      _showSuccessDialog(transactionCode, change, printSuccess);
      setState(() => _cart.clear());
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
      print('❌ [TRANSACTION] Error: $e');
    }
  }

  Future<bool> _autoPrintReceipt({
    required String transactionCode,
    required double cashReceived,
    required double change,
    required List<CartItem> cartItems,
  }) async {
    try {
      final items = cartItems.map((cartItem) {
        return {
          'name': cartItem.product.name,
          'quantity': cartItem.quantity,
          'price': cartItem.product.price,
        };
      }).toList();
      await _printerService.printReceipt(
        transactionId: transactionCode,
        transactionDate: DateTime.now(),
        items: items,
        subtotal: _totalAmount,
        discount: 0.0,
        tax: 0.0,
        total: _totalAmount,
        paid: cashReceived,
        change: change,
      );
      print('✅ [TRANSACTION] Print receipt success');
      return true;
    } catch (e) {
      print('❌ [TRANSACTION] Error printing receipt: $e');
      return false;
    }
  }

  void _showSuccessDialog(
    String transactionCode,
    double change,
    bool isPrinted,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF03D1C5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF03D1C5),
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Transaksi Berhasil!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  transactionCode,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF03D1C5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF03D1C5).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Kembalian',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${_formatCurrency(change)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF03D1C5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isPrinted
                      ? const Color(0xFF03D1C5).withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPrinted ? Icons.print : Icons.print_disabled,
                      size: 18,
                      color: isPrinted
                          ? const Color(0xFF03D1C5)
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPrinted
                          ? 'Struk berhasil dicetak'
                          : 'Struk tidak dicetak',
                      style: TextStyle(
                        fontSize: 13,
                        color: isPrinted
                            ? const Color(0xFF03D1C5)
                            : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03D1C5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == const Color(0xFF03D1C5)
                  ? Icons.check_circle
                  : color == Colors.orange
                  ? Icons.warning
                  : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '💲',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
        backgroundColor: const Color(0xFF03D1C5),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isBluetoothOn
                      ? Colors.white.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isBluetoothOn
                        ? Colors.white.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isBluetoothOn
                          ? Icons.bluetooth
                          : Icons.bluetooth_disabled,
                      size: 16,
                      color: _isBluetoothOn ? Colors.white : Colors.red[100],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isBluetoothOn ? 'BT ON' : 'BT OFF',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isBluetoothOn ? Colors.white : Colors.red[100],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isBluetoothOn)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: GestureDetector(
                  onTap: _checkPrinterConnection,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isAutoReconnecting
                          ? Colors.blue.withOpacity(0.2)
                          : _isPrinterConnected
                          ? Colors.white.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isAutoReconnecting
                            ? Colors.blue.withOpacity(0.3)
                            : _isPrinterConnected
                            ? Colors.white.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isAutoReconnecting)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[100]!,
                              ),
                            ),
                          )
                        else
                          Icon(
                            _isPrinterConnected
                                ? Icons.print
                                : Icons.print_disabled,
                            size: 16,
                            color: _isPrinterConnected
                                ? Colors.white
                                : Colors.orange[100],
                          ),
                        const SizedBox(width: 6),
                        Text(
                          _isAutoReconnecting
                              ? 'CONNECTING'
                              : _isPrinterConnected
                              ? 'CONNECTED'
                              : 'NO PRINTER',
                          style: TextStyle(
                            fontSize: 11,
                            color: _isAutoReconnecting
                                ? Colors.blue[100]
                                : _isPrinterConnected
                                ? Colors.white
                                : Colors.orange[100],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text('Kosongkan Keranjang?'),
                    content: const Text(
                      'Semua item akan dihapus dari keranjang.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Batal',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _cart.clear());
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Kosongkan Keranjang',
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF03D1C5),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF03D1C5).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Cari produk...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.grey[400],
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: Colors.grey[400],
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchFocusNode.unfocus();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showScanBarcodeDialog,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFF03D1C5),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: _isLoading
                ? _buildShimmerLoading()
                : _filteredProducts.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    color: const Color(0xFF03D1C5),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return _buildProductCard(product);
                      },
                    ),
                  ),
          ),
          if (_cart.isNotEmpty) _buildCartSection(),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: product.stock > 0 ? () => _addToCart(product) : () => _showSnackBar('Stok habis!', Colors.red),
        borderRadius: BorderRadius.circular(20),
        child: Opacity(
          opacity: product.stock > 0 ? 1.0 : 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: product.imagePath == null ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF03D1C5).withOpacity(0.1),
                        const Color(0xFF03D1C5).withOpacity(0.05),
                      ],
                    ) : null,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: product.imagePath != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.file(
                          File(product.imagePath!), 
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.inventory_2_rounded,
                          size: 48,
                          color: const Color(0xFF03D1C5).withOpacity(0.7),
                        ),
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${product.id} | Stok: ${product.stock}',
                      style: TextStyle(
                        fontSize: 11,
                        color: product.stock > 0 ? Colors.black87 : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF03D1C5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Rp ${_formatCurrency(product.price)}',
                        style: const TextStyle(
                          color: Color(0xFF03D1C5),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSection() {
    return AnimatedBuilder(
      animation: _cartAnimController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: _cart.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final item = _cart[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF03D1C5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: item.product.imagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(File(item.product.imagePath!), fit: BoxFit.cover),
                                )
                              : const Icon(
                                  Icons.inventory_2_rounded,
                                  color: Color(0xFF03D1C5),
                                  size: 24,
                                ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rp ${_formatCurrency(item.product.price)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _updateQuantity(
                                      index,
                                      item.quantity - 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.remove_rounded,
                                        size: 18,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _updateQuantity(
                                      index,
                                      item.quantity + 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        size: 18,
                                        color: Color(0xFF03D1C5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Rp ${_formatCurrency(item.subtotal)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF03D1C5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Belanja',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp ${_formatCurrency(_totalAmount)}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF03D1C5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showPaymentDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF03D1C5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.payments_rounded, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Bayar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF03D1C5).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchController.text.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.inventory_2_outlined,
              size: 64,
              color: const Color(0xFF03D1C5).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _searchController.text.isNotEmpty
                ? 'Produk tidak ditemukan'
                : 'Tidak ada produk tersedia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Coba kata kunci lain'
                : 'Tambahkan produk terlebih dahulu',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.grey[300]!,
                            Colors.grey[200]!,
                            Colors.grey[300]!,
                          ],
                          stops: [
                            _shimmerController.value - 0.3,
                            _shimmerController.value,
                            _shimmerController.value + 0.3,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 24,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
