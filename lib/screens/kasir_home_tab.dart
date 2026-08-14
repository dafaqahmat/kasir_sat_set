import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../database/database_helper.dart';

class KasirHomeTab extends StatefulWidget {
  final User user;

  const KasirHomeTab({super.key, required this.user});

  @override
  State<KasirHomeTab> createState() => _KasirHomeTabState();
}

class _KasirHomeTabState extends State<KasirHomeTab> {
  int _todayTransactions = 0;
  double _todaySales = 0;
  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoading = true;

  StreamSubscription? _transactionSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _transactionSubscription = DatabaseHelper.instance.transactionStream.listen((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final transactions = await DatabaseHelper.instance.getAllTransactions();
      final now = DateTime.now();

      final myTransactions = transactions.where((t) => t.userId == widget.user.id).toList();

      final todayTransactions = myTransactions.where((t) {
        return t.createdAt.year == now.year &&
            t.createdAt.month == now.month &&
            t.createdAt.day == now.day;
      }).toList();

      double todayTotal = 0;
      for (var t in todayTransactions) {
        todayTotal += t.totalAmount;
      }

      final weeklyData = _calculateWeeklyData(myTransactions);

      if (mounted) {
        setState(() {
          _todayTransactions = todayTransactions.length;
          _todaySales = todayTotal;
          _weeklyData = weeklyData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _calculateWeeklyData(List transactions) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayTransactions = transactions.where((t) {
        return t.createdAt.year == date.year &&
            t.createdAt.month == date.month &&
            t.createdAt.day == date.day;
      }).toList();

      double dayTotal = 0;
      for (var t in dayTransactions) {
        dayTotal += t.totalAmount;
      }

      final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      final dayName = dayNames[(date.weekday - 1) % 7];

      data.add({
        'day': dayName,
        'amount': dayTotal,
        'count': dayTransactions.length,
      });
    }
    return data;
  }

  String _formatCurrency(double amount) {
    return 'Rp${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  String _getTodayString() {
    final now = DateTime.now();
    final dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final monthNames = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${dayNames[now.weekday - 1]}, ${now.day} ${monthNames[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF03D1C5),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 100,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF03D1C5),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF03D1C5), Color(0xFF02A89E)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Halo, Kasir',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.user.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: Color(0xFF03D1C5)),
                      ),
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildTodayCard(),
                        const SizedBox(height: 16),
                        _buildWeeklyChart(),
                        const SizedBox(height: 16),
                        _buildDateCard(),
                        const SizedBox(height: 100),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF03D1C5), Color(0xFF02A89E)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF03D1C5).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.today_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ringkasan Hari Ini',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInlineStat(
                    icon: Icons.receipt_long_rounded,
                    label: 'Transaksi',
                    value: _todayTransactions.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInlineStat(
                    icon: Icons.attach_money_rounded,
                    label: 'Penjualan',
                    value: _formatCurrency(_todaySales),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyData.isEmpty) return const SizedBox();

    final maxAmount = _weeklyData.map((d) => d['amount'] as double).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Penjualan 7 Hari', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF03D1C5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Minggu ini', style: TextStyle(fontSize: 11, color: Color(0xFF03D1C5), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _weeklyData.map((data) {
                  final amount = data['amount'] as double;
                  final count = data['count'] as int;
                  final height = maxAmount > 0 ? (amount / maxAmount) * 120 : 0.0;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (count > 0)
                            Text(
                              count.toString(),
                              style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600),
                            ),
                          if (count > 0) const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            height: height < 15 && amount > 0 ? 15.0 : height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF03D1C5),
                                  const Color(0xFF03D1C5).withOpacity(0.6),
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['day'],
                            style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF03D1C5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event_available_rounded, color: Color(0xFF03D1C5), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTodayString(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _todayTransactions == 0
                        ? 'Belum ada transaksi hari ini'
                        : '$_todayTransactions transaksi berhasil',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
