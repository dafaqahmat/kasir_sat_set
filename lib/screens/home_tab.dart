import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../database/database_helper.dart';
import '../screens/history_screen.dart';
import '../screens/income_screen.dart';
import '../screens/expense_screen.dart';
import '../screens/financial_report_screen.dart';

class HomeTab extends StatefulWidget {
  final User user;

  const HomeTab({super.key, required this.user});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _totalTransactions = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _remainingBalance = 0;
  int _totalProducts = 0;
  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoading = true;

  StreamSubscription? _transactionSubscription;
  StreamSubscription? _productSubscription;
  StreamSubscription? _userSubscription;
  StreamSubscription? _incomeSubscription;
  StreamSubscription? _expenseSubscription;
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadDashboardData();
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    _transactionSubscription = DatabaseHelper.instance.transactionStream.listen((_) {
      if (mounted) _loadDashboardData();
    });
    _productSubscription = DatabaseHelper.instance.productStream.listen((_) {
      if (mounted) _loadDashboardData();
    });
    _userSubscription = DatabaseHelper.instance.userStream.listen((updatedUser) {
      if (mounted && updatedUser.id == widget.user.id) {
        setState(() => _currentUser = updatedUser);
      }
    });
    _incomeSubscription = DatabaseHelper.instance.incomeStream.listen((_) {
      if (mounted) _loadDashboardData();
    });
    _expenseSubscription = DatabaseHelper.instance.expenseStream.listen((_) {
      if (mounted) _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    _productSubscription?.cancel();
    _userSubscription?.cancel();
    _incomeSubscription?.cancel();
    _expenseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (_weeklyData.isEmpty) setState(() => _isLoading = true);

    try {
      final transactions = await DatabaseHelper.instance.getAllTransactions();
      final products = await DatabaseHelper.instance.getAllProducts();
      final incomes = await DatabaseHelper.instance.getAllIncomes();
      final expenses = await DatabaseHelper.instance.getAllExpenses();

      double totalRev = 0;
      for (var t in transactions) {
        totalRev += t.totalAmount;
      }
      double totalInc = 0;
      for (var i in incomes) {
        totalInc += i.amount;
      }
      double totalExp = 0;
      for (var e in expenses) {
        totalExp += e.amount;
      }

      final weeklyData = _calculateWeeklyData(transactions);

      if (mounted) {
        setState(() {
          _totalTransactions = transactions.length;
          _totalIncome = totalInc;
          _totalExpense = totalExp;
          _remainingBalance = (totalRev + totalInc) - totalExp;
          _totalProducts = products.length;
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
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
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
                            child: const Icon(Icons.store_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Selamat Datang,',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentUser.name,
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
                        _buildBalanceCard(),
                        const SizedBox(height: 16),
                        _buildStatsGrid(),
                        const SizedBox(height: 16),
                        _buildWeeklyChart(),
                        const SizedBox(height: 16),
                        _buildQuickActions(),
                        const SizedBox(height: 16),
                        _buildFinancialChart(),
                        const SizedBox(height: 100),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final isNegative = _remainingBalance < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isNegative
                ? [Colors.red[400]!, Colors.red[700]!]
                : [const Color(0xFF03D1C5), const Color(0xFF02A89E)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isNegative ? Colors.red : const Color(0xFF03D1C5)).withOpacity(0.3),
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
                  child: Icon(
                    isNegative ? Icons.warning_rounded : Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sisa Saldo',
                  style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Rp ${_formatCurrency(_remainingBalance.abs())}',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            if (isNegative) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text('Saldo Minus', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                _buildInlineStat(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Masuk',
                  value: 'Rp ${_formatCurrency(_totalIncome)}',
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 16),
                _buildInlineStat(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Keluar',
                  value: 'Rp ${_formatCurrency(_totalExpense)}',
                  color: Colors.redAccent,
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
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Total Transaksi',
              value: _totalTransactions.toString(),
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF03D1C5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Total Produk',
              value: _totalProducts.toString(),
              icon: Icons.inventory_2_rounded,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                const Text('Penjualan 7 Hari Terakhir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
              },
              icon: const Icon(Icons.history_rounded, color: Colors.white),
              label: const Text('Lihat Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF03D1C5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Uang Masuk',
                  icon: Icons.add_circle_rounded,
                  color: Colors.green,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Uang Keluar',
                  icon: Icons.remove_circle_rounded,
                  color: Colors.red,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Laporan',
                  icon: Icons.assessment_rounded,
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialReportScreen())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialChart() {
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
            const Text('Laporan Keuangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            if (_totalIncome + _totalExpense > 0)
              Center(
                child: SizedBox(
                  height: 200,
                  width: 200,
                  child: CustomPaint(
                    painter: _DonutChartPainter(income: _totalIncome, expense: _totalExpense),
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  children: [
                    Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Belum ada data', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            _buildLegend(
              label: 'Uang Masuk',
              amount: _totalIncome,
              color: Colors.green,
              icon: Icons.arrow_downward_rounded,
            ),
            const SizedBox(height: 12),
            _buildLegend(
              label: 'Uang Keluar',
              amount: _totalExpense,
              color: Colors.red,
              icon: Icons.arrow_upward_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    final total = _totalIncome + _totalExpense;
    final pct = total > 0 ? (amount / total * 100) : 0.0;

    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.w500))),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Rp ${_formatCurrency(amount)}', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
            Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double income;
  final double expense;

  _DonutChartPainter({required this.income, required this.expense});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final total = income + expense;
    if (total == 0) return;

    double startAngle = -pi / 2;

    final incomeAngle = (income / total) * 2 * pi;
    final incomePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, incomeAngle, true, incomePaint);
    startAngle += incomeAngle;

    final expenseAngle = (expense / total) * 2 * pi;
    final expensePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, expenseAngle, true, expensePaint);

    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, centerPaint);

    final borderPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * 0.5, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
