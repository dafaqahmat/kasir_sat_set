import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_pkg;
import '../database/database_helper.dart';
import '../models/product_model.dart';
import '../models/expense_model.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  StreamSubscription<List<Product>>? _productSubscription;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _subscribeToProductUpdates();
    _searchController.addListener(_filterProducts);
  }
  
  void _subscribeToProductUpdates() {
    _productSubscription = DatabaseHelper.instance.productStream.listen((products) {
      if (mounted) {
        print('🔄 Realtime update received: ${products.length} products');
        setState(() {
          _products = products;
          _filterProducts();
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      print('Loading products from database...');
      final products = await DatabaseHelper.instance.getAllProducts();
      print('Loaded ${products.length} products');
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() => _isLoading = false);
      _showSnackBar('Error: $e', Colors.red);
    }
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

  void _showAddEditDialog({Product? product}) {
    final isEdit = product != null;
    final idController = TextEditingController(text: product?.id?.toString() ?? '');
    final nameController = TextEditingController(text: product?.name ?? '');
    
    // PERBAIKAN: Konversi price ke integer string tanpa desimal
    final priceController = TextEditingController(
      text: product != null ? product.price.round().toString() : '',
    );
    final purchasePriceController = TextEditingController(
      text: product != null ? product.purchasePrice.round().toString() : '',
    );
    final stockController = TextEditingController(
      text: product != null ? product.stock.toString() : '0',
    );
    
    File? selectedImage = product?.imagePath != null ? File(product!.imagePath!) : null;
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEdit ? 'Edit Produk' : 'Tambah Produk',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: idController,
                decoration: InputDecoration(
                  labelText: 'ID Produk',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.tag, color: Color(0xFF03D1C5)),
                  hintText: 'Contoh: 1001',
                  labelStyle: const TextStyle(color: Color(0xFF03D1C5)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF03D1C5), width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Produk',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.inventory_2_outlined, color: Color(0xFF03D1C5)),
                  labelStyle: const TextStyle(color: Color(0xFF03D1C5)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF03D1C5), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: purchasePriceController,
                decoration: InputDecoration(
                  labelText: 'Harga Beli (Rp)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF03D1C5)),
                  labelStyle: const TextStyle(color: Color(0xFF03D1C5)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF03D1C5), width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'Harga Jual (Rp)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF03D1C5)),
                  labelStyle: const TextStyle(color: Color(0xFF03D1C5)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF03D1C5), width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                decoration: InputDecoration(
                  labelText: isEdit ? 'Penyesuaian Stok' : 'Stok Awal',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.inventory_2, color: Color(0xFF03D1C5)),
                  labelStyle: const TextStyle(color: Color(0xFF03D1C5)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF03D1C5), width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final source = await showModalBottomSheet<ImageSource>(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => SafeArea(
                      child: Wrap(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Pilih Sumber Foto',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.camera_alt, color: Color(0xFF03D1C5)),
                            title: const Text('Kamera'),
                            onTap: () => Navigator.of(context).pop(ImageSource.camera),
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library, color: Color(0xFF03D1C5)),
                            title: const Text('Galeri HP'),
                            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                          ),
                        ],
                      ),
                    ),
                  );

                  if (source != null) {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(
                      source: source,
                      imageQuality: 70, // Kompresi ringan agar tidak memenuhi memori
                    );
                    if (pickedFile != null) {
                      setStateDialog(() {
                        selectedImage = File(pickedFile.path);
                      });
                    }
                  }
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF03D1C5), width: 1),
                  ),
                  child: selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(selectedImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: Colors.grey[400], size: 40),
                            const SizedBox(height: 8),
                            Text('Tambah Foto Produk', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = int.tryParse(idController.text);
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0;
              final purchasePrice = double.tryParse(purchasePriceController.text) ?? 0;
              final stock = int.tryParse(stockController.text) ?? 0;

              if (name.isEmpty || price <= 0 || purchasePrice <= 0) {
                setStateDialog(() { errorMessage = 'Nama dan harga harus diisi!'; });
                return;
              }

              if (!isEdit && (id == null || id <= 0)) {
                setStateDialog(() { errorMessage = 'ID produk harus diisi dengan angka!'; });
                return;
              }

              try {
                String? imagePathToSave = product?.imagePath;
                if (selectedImage != null && selectedImage!.path != product?.imagePath) {
                  final appDir = await getApplicationDocumentsDirectory();
                  final fileName = path_pkg.basename(selectedImage!.path);
                  final savedImage = await selectedImage!.copy('${appDir.path}/$fileName');
                  imagePathToSave = savedImage.path;
                }

                if (isEdit) {
                  if (id == null || id <= 0) {
                    setStateDialog(() { errorMessage = 'ID produk harus diisi dengan angka!'; });
                    return;
                  }

                  if (id != product.id) {
                    final existingProduct = await DatabaseHelper.instance.getProductById(id);
                    if (existingProduct != null) {
                      setStateDialog(() { errorMessage = 'ID produk sudah digunakan!'; });
                      return;
                    }
                  }

                  final updatedProduct = Product(id: id, name: name, price: price, purchasePrice: purchasePrice, imagePath: imagePathToSave, stock: stock);
                  
                  if (id != product.id) {
                    await DatabaseHelper.instance.deleteProduct(product.id!);
                    await DatabaseHelper.instance.createProduct(updatedProduct);
                  } else {
                    await DatabaseHelper.instance.updateProduct(updatedProduct);
                  }
                  
                  _showSnackBar('Produk berhasil diupdate!', const Color(0xFF03D1C5));
                } else {
                  final existingProduct = await DatabaseHelper.instance.getProductById(id!);
                  if (existingProduct != null) {
                    setStateDialog(() { errorMessage = 'ID produk sudah digunakan!'; });
                    return;
                  }

                  final newProduct = Product(id: id, name: name, price: price, purchasePrice: purchasePrice, imagePath: imagePathToSave, stock: stock);
                  await DatabaseHelper.instance.createProduct(newProduct);
                  _showSnackBar('Produk berhasil ditambahkan!', const Color(0xFF03D1C5));
                }

                Navigator.pop(context);
              } catch (e) {
                print('ERROR: $e');
                setStateDialog(() { errorMessage = 'Error: $e'; });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF03D1C5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isEdit ? 'Update' : 'Simpan'),
          ),
        ],
      ),
      ),
    );
  }

  void _showStockInDialog() {
    Product? selectedProduct;
    final quantityController = TextEditingController();
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Barang Masuk (Suplier)', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                Autocomplete<Product>(
                  displayStringForOption: (Product option) => '${option.id} - ${option.name}',
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<Product>.empty();
                    }
                    return _products.where((Product option) {
                      return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                             option.id.toString().contains(textEditingValue.text);
                    });
                  },
                  onSelected: (Product selection) {
                    setStateDialog(() {
                      selectedProduct = selection;
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Cari Produk...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF03D1C5)),
                      ),
                    );
                  },
                ),
                if (selectedProduct != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2, color: Color(0xFF03D1C5)),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Stok saat ini: ${selectedProduct!.stock}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Masuk',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.add_box, color: Color(0xFF03D1C5)),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      setStateDialog(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedProduct!.purchasePrice > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Otomatis tercatat di Pengeluaran:\nRp ${_formatCurrency(selectedProduct!.purchasePrice * (int.tryParse(quantityController.text) ?? 0))}',
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Harga Beli produk ini Rp 0. Pengeluaran tidak akan dicatat. Edit produk untuk mengatur Harga Beli.',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                const Text('Barang belum terdaftar?', style: TextStyle(color: Colors.grey)),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddEditDialog();
                  },
                  child: const Text('Tambah Produk Baru', style: TextStyle(color: Color(0xFF03D1C5), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedProduct == null) {
                  setStateDialog(() { errorMessage = 'Pilih produk terlebih dahulu'; });
                  return;
                }
                final qty = int.tryParse(quantityController.text) ?? 0;
                final cost = selectedProduct!.purchasePrice * qty;
                if (qty <= 0) {
                  setStateDialog(() { errorMessage = 'Jumlah harus lebih dari 0'; });
                  return;
                }
                
                try {
                  final updated = selectedProduct!.copyWith(stock: selectedProduct!.stock + qty);
                  await DatabaseHelper.instance.updateProduct(updated);
                  
                  if (cost > 0) {
                    final expense = Expense(
                      description: 'Beli produk ${selectedProduct!.name}',
                      amount: cost,
                      date: DateTime.now(),
                    );
                    await DatabaseHelper.instance.createExpense(expense);
                  }
                  
                  Navigator.pop(context);
                  _showSnackBar('Stok berhasil ditambahkan!', const Color(0xFF03D1C5));
                } catch (e) {
                  setStateDialog(() { errorMessage = 'Error: $e'; });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF03D1C5)),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await DatabaseHelper.instance.deleteProduct(product.id!);
                Navigator.pop(context);
                _showSnackBar('Produk berhasil dihapus!', const Color(0xFF03D1C5));
              } catch (e) {
                _showSnackBar('Error: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Kelola Produk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF03D1C5),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF03D1C5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF03D1C5).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
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
                  hintText: 'Cari produk atau ID...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                          onPressed: () {
                            _searchController.clear();
                            _searchFocusNode.unfocus();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          
          // Product List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF03D1C5)),
                  )
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        color: const Color(0xFF03D1C5),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'stock_in',
            onPressed: () => _showStockInDialog(),
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.archive),
            label: const Text('Stok Masuk'),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'add_product',
            onPressed: () => _showAddEditDialog(),
            backgroundColor: const Color(0xFF03D1C5),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Produk'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: product.imagePath == null ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF03D1C5).withOpacity(0.15),
                const Color(0xFF03D1C5).withOpacity(0.05),
              ],
            ) : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: product.imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(File(product.imagePath!), fit: BoxFit.cover),
              )
            : const Icon(
                Icons.inventory_2_rounded,
                color: Color(0xFF03D1C5),
                size: 28,
              ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'ID: ${product.id}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jual: Rp ${_formatCurrency(product.price)}',
                        style: const TextStyle(
                          color: Color(0xFF03D1C5),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Beli: Rp ${_formatCurrency(product.purchasePrice)}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Stok: ${product.stock}',
                  style: TextStyle(
                    color: product.stock > 0 ? Colors.black87 : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: const [
                  Icon(Icons.edit, size: 20, color: Color(0xFF03D1C5)),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
              onTap: () {
                Future.delayed(
                  Duration.zero,
                  () => _showAddEditDialog(product: product),
                );
              },
            ),
            PopupMenuItem(
              child: Row(
                children: const [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Hapus'),
                ],
              ),
              onTap: () {
                Future.delayed(
                  Duration.zero,
                  () => _deleteProduct(product),
                );
              },
            ),
          ],
        ),
      ),
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
                : 'Belum ada produk',
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
                : 'Tambahkan produk dengan tombol di bawah',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}