import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final int currentUserId;

  const ProfileSettingsScreen({super.key, required this.currentUserId});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  String _storeName = '';
  String _storeAddress = '';
  String _storePhone = '';
  String _cashierName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storeName = prefs.getString('store_name') ?? 'TOKO SATSET';
      _storeAddress = prefs.getString('store_address') ?? 'Jl. Contoh No. 123';
      _storePhone = prefs.getString('store_phone') ?? '08123456789';
      _cashierName = prefs.getString('cashier_name') ?? 'Kasir';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store_name', _storeName);
    await prefs.setString('store_address', _storeAddress);
    await prefs.setString('store_phone', _storePhone);
    await prefs.setString('cashier_name', _cashierName);

    try {
      await DatabaseHelper.instance.updateUserName(
        widget.currentUserId,
        _cashierName,
      );
    } catch (e) {
      _showSnackBar('Gagal update database: $e', Colors.red);
    }
  }

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: _storeName);
    final addressCtrl = TextEditingController(text: _storeAddress);
    final phoneCtrl = TextEditingController(text: _storePhone);
    final cashierCtrl = TextEditingController(text: _cashierName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Informasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: nameCtrl,
                label: 'Nama Toko',
                icon: Icons.store,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: addressCtrl,
                label: 'Alamat',
                icon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: phoneCtrl,
                label: 'No. Telepon',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: cashierCtrl,
                label: 'Nama Petugas / Kasir',
                icon: Icons.person,
                helper: 'Mengubah nama akun & nama di struk',
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
              setState(() {
                _storeName = nameCtrl.text;
                _storeAddress = addressCtrl.text;
                _storePhone = phoneCtrl.text;
                _cashierName = cashierCtrl.text;
              });

              await _saveSettings();

              if (context.mounted) {
                Navigator.pop(context);
                _showSnackBar('Data berhasil disimpan', Colors.green);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF03D1C5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? helper,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon, color: const Color(0xFF03D1C5)),
        labelStyle: const TextStyle(color: Color(0xFF03D1C5)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF03D1C5), width: 2),
        ),
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
          'Pengaturan Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF03D1C5),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF03D1C5)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header with Icon
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
                          child: const Icon(
                            Icons.settings_rounded,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Informasi Toko & Petugas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _InfoCard(
                          icon: Icons.store,
                          title: 'Nama Toko',
                          value: _storeName,
                          color: const Color(0xFF03D1C5),
                        ),
                        const SizedBox(height: 12),
                        _InfoCard(
                          icon: Icons.location_on,
                          title: 'Alamat',
                          value: _storeAddress,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 12),
                        _InfoCard(
                          icon: Icons.phone,
                          title: 'No. Telepon',
                          value: _storePhone,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _InfoCard(
                          icon: Icons.person,
                          title: 'Nama Petugas',
                          value: _cashierName,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Edit Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showEditDialog,
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text(
                          'Edit Informasi',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF03D1C5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// Extracted Info Card Widget
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
