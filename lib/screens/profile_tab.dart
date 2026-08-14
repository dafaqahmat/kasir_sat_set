import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../database/database_helper.dart';
import '../screens/login_screen.dart';
import '../screens/printer_settings_screen.dart';
import '../screens/profile_settings_screen.dart';

class ProfileTab extends StatefulWidget {
  final User user;

  const ProfileTab({super.key, required this.user});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  Future<void> _refreshUserData() async {
    if (_currentUser.id == null) return;
    
    final user = await DatabaseHelper.instance.getUserById(_currentUser.id!);
    if (user != null && mounted) {
      setState(() => _currentUser = user);
    }
  }

  void _showSnackBar(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? const Color(0xFF03D1C5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => _PasswordDialog(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
        currentPassword: _currentUser.password,
        userName: _currentUser.name,
        onSuccess: () {
          _showSnackBar('Password berhasil diubah! Silakan login ulang.', Colors.green);
          Future.delayed(const Duration(seconds: 2), _showLogoutDialog);
        },
        onError: (msg) => _showSnackBar(msg, Colors.red),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03D1C5),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              color: const Color(0xFF03D1C5),
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  // Profile Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 50,
                      color: Color(0xFF03D1C5),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // User Name
                  Text(
                    _currentUser.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Join Date Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentUser.isAdmin ? Icons.admin_panel_settings_rounded : Icons.point_of_sale_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_currentUser.isAdmin ? 'Admin' : 'Kasir'} · ${_currentUser.createdAt.day}/${_currentUser.createdAt.month}/${_currentUser.createdAt.year}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content Section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_currentUser.isAdmin)
                          _MenuItem(
                            icon: Icons.person_outline_rounded,
                            title: 'Pengaturan Profil',
                            color: const Color(0xFF03D1C5),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileSettingsScreen(
                                  currentUserId: _currentUser.id!,
                                ),
                              ),
                            ).then((_) => _refreshUserData()),
                          ),
                        _MenuItem(
                          icon: Icons.print_outlined,
                          title: 'Pengaturan Printer',
                          color: const Color(0xFF03D1C5),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
                          ),
                        ),
                        _MenuItem(
                          icon: Icons.lock_outline_rounded,
                          title: 'Ubah Password',
                          color: const Color(0xFF03D1C5),
                          onTap: _showChangePasswordDialog,
                        ),
                        if (_currentUser.isAdmin)
                          _MenuItem(
                            icon: Icons.info_outline_rounded,
                            title: 'Tentang Aplikasi',
                            color: const Color(0xFF03D1C5),
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text(
                                  'Tentang Aplikasi',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                content: const Text(
                                  'Aplikasi Kasir SATSET\n'
                                  'Versi 1.0.0\n\n'
                                  'Dibuat untuk memudahkan transaksi penjualan.\n\n'
                                  'Peringatan:\n'
                                  'Aplikasi ini menyimpan seluruh data di perangkat Anda. '
                                  'Jika Anda menghapus aplikasi atau menghapus data aplikasi, '
                                  'maka seluruh data akan hilang. Aplikasi ini berjalan secara offline.'
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        _MenuItem(
                          icon: Icons.logout_rounded,
                          title: 'Logout',
                          color: const Color(0xFF03D1C5),
                          onTap: _showLogoutDialog,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extracted Menu Item Widget
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Colors.black54,
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 68, color: Colors.black12),
      ],
    );
  }
}

// Extracted Password Dialog Widget
class _PasswordDialog extends StatefulWidget {
  final TextEditingController oldPassword;
  final TextEditingController newPassword;
  final TextEditingController confirmPassword;
  final String currentPassword;
  final String userName;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const _PasswordDialog({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
    required this.currentPassword,
    required this.userName,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF03D1C5)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        labelStyle: const TextStyle(color: Color(0xFF03D1C5)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF03D1C5), width: 2),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final old = widget.oldPassword.text;
    final newP = widget.newPassword.text;
    final confirm = widget.confirmPassword.text;

    if (old.isEmpty || newP.isEmpty || confirm.isEmpty) {
      widget.onError('Semua field harus diisi!');
      return;
    }
    if (newP != confirm) {
      widget.onError('Password baru tidak cocok!');
      return;
    }
    if (newP.length < 6) {
      widget.onError('Password minimal 6 karakter!');
      return;
    }
    if (old != widget.currentPassword) {
      widget.onError('Password lama salah!');
      return;
    }

    try {
      await DatabaseHelper.instance.updatePassword(widget.userName, newP);
      if (mounted) Navigator.pop(context);
      widget.onSuccess();
    } catch (e) {
      widget.onError('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Ubah Password',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPasswordField(
              controller: widget.oldPassword,
              label: 'Password Lama',
              obscure: !_showOld,
              onToggle: () => setState(() => _showOld = !_showOld),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: widget.newPassword,
              label: 'Password Baru (min. 6 karakter)',
              obscure: !_showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: widget.confirmPassword,
              label: 'Konfirmasi Password Baru',
              obscure: !_showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
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
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF03D1C5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}