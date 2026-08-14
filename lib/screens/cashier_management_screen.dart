import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../database/database_helper.dart';

class CashierManagementScreen extends StatefulWidget {
  const CashierManagementScreen({super.key});

  @override
  State<CashierManagementScreen> createState() => _CashierManagementScreenState();
}

class _CashierManagementScreenState extends State<CashierManagementScreen> {
  List<User> _kasirUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKasirUsers();
  }

  Future<void> _loadKasirUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await DatabaseHelper.instance.getKasirUsers();
      if (mounted) {
        setState(() {
          _kasirUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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

  void _showAddCashierDialog() {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Tambah Kasir',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Masukkan username',
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF03D1C5)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF03D1C5), width: 2),
                    ),
                    labelStyle: const TextStyle(color: Color(0xFF03D1C5)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password (min. 6 karakter)',
                    hintText: 'Masukkan password',
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF03D1C5)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setDialogState(() => isPasswordVisible = !isPasswordVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF03D1C5), width: 2),
                    ),
                    labelStyle: const TextStyle(color: Color(0xFF03D1C5)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final password = passwordController.text;

                if (name.isEmpty || password.isEmpty) {
                  _showSnackBar('Semua field harus diisi!', Colors.red);
                  return;
                }
                if (password.length < 6) {
                  _showSnackBar('Password minimal 6 karakter!', Colors.red);
                  return;
                }

                final isTaken = await DatabaseHelper.instance.isNameTaken(name);
                if (isTaken) {
                  _showSnackBar('Username sudah digunakan!', Colors.red);
                  return;
                }

                final newUser = User(
                  name: name,
                  password: password,
                  role: 'kasir',
                  createdAt: DateTime.now(),
                );
                await DatabaseHelper.instance.createUser(newUser);
                Navigator.pop(dialogContext);
                _loadKasirUsers();
                _showSnackBar('Kasir berhasil ditambahkan!', Colors.green);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF03D1C5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCashierDialog(User cashier) {
    final nameController = TextEditingController(text: cashier.name);
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Edit Kasir',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF03D1C5)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF03D1C5), width: 2),
                    ),
                    labelStyle: const TextStyle(color: Color(0xFF03D1C5)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password baru (kosongkan jika tidak diubah)',
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF03D1C5)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setDialogState(() => isPasswordVisible = !isPasswordVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF03D1C5), width: 2),
                    ),
                    labelStyle: const TextStyle(color: Color(0xFF03D1C5)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final password = passwordController.text;

                if (name.isEmpty) {
                  _showSnackBar('Username tidak boleh kosong!', Colors.red);
                  return;
                }

                if (name != cashier.name) {
                  final isTaken = await DatabaseHelper.instance.isNameTaken(name);
                  if (isTaken) {
                    _showSnackBar('Username sudah digunakan!', Colors.red);
                    return;
                  }
                  await DatabaseHelper.instance.updateUserNameById(cashier.id!, name);
                }

                if (password.isNotEmpty) {
                  if (password.length < 6) {
                    _showSnackBar('Password minimal 6 karakter!', Colors.red);
                    return;
                  }
                  await DatabaseHelper.instance.updatePasswordById(cashier.id!, password);
                }

                Navigator.pop(dialogContext);
                _loadKasirUsers();
                _showSnackBar('Kasir berhasil diupdate!', Colors.green);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF03D1C5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(User cashier) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Reset password untuk kasir "${cashier.name}"?\n\nPassword baru akan dibuat secara otomatis.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPassword = _generateRandomPassword();
              await DatabaseHelper.instance.updatePasswordById(cashier.id!, newPassword);
              Navigator.pop(dialogContext);
              _showResetResultDialog(cashier.name, newPassword);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF03D1C5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showResetResultDialog(String name, String newPassword) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Password Baru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF03D1C5), size: 50),
            const SizedBox(height: 16),
            Text('Password baru untuk "$name":'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    newPassword,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Color(0xFF03D1C5)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: newPassword));
                      _showSnackBar('Password disalin!', Colors.green);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Segera sampaikan password baru kepada kasir.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF03D1C5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(User cashier) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Kasir',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Hapus kasir "${cashier.name}"?\n\nKasir yang dihapus tidak bisa login lagi.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteUser(cashier.id!);
              Navigator.pop(dialogContext);
              _loadKasirUsers();
              _showSnackBar('Kasir berhasil dihapus!', Colors.green);
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

  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03D1C5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF03D1C5),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Kelola Kasir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola akun kasir toko Anda',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF03D1C5)))
                    : _kasirUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Belum ada kasir',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tambah kasir untuk mulai',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadKasirUsers,
                            color: const Color(0xFF03D1C5),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              itemCount: _kasirUsers.length,
                              itemBuilder: (context, index) {
                                final cashier = _kasirUsers[index];
                                return _buildCashierCard(cashier);
                              },
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCashierDialog,
        backgroundColor: const Color(0xFF03D1C5),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Tambah Kasir', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCashierCard(User cashier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF03D1C5).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Color(0xFF03D1C5),
            size: 24,
          ),
        ),
        title: Text(
          cashier.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Bergabung ${cashier.createdAt.day}/${cashier.createdAt.month}/${cashier.createdAt.year}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditCashierDialog(cashier);
                break;
              case 'reset':
                _showResetPasswordDialog(cashier);
                break;
              case 'delete':
                _showDeleteConfirmation(cashier);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 20, color: Color(0xFF03D1C5)),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reset',
              child: Row(
                children: [
                  Icon(Icons.lock_reset_rounded, size: 20, color: Color(0xFFFF9800)),
                  SizedBox(width: 12),
                  Text('Reset Password'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Hapus', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
