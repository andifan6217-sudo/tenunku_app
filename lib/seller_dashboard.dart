import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'orders_screen.dart';
import 'seller_products_screen.dart';
import 'buyer_profile_screen.dart';
import 'tracking_screen.dart';
import 'globals.dart';
import 'seller_payments_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'financial_report_screen.dart';


class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const SellerStudioTab(),
    const SellerProductsScreen(showAppBar: true),
    const OrdersScreen(showBackButton: false),
    const SellerPaymentsView(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const darkStudio = Color(0xFF0F0B1E);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: gold.withOpacity(0.1), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: darkStudio,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: gold,
          unselectedItemColor: Colors.white24,
          selectedLabelStyle: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
          unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 8, letterSpacing: 1),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'STUDIO'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'ITEM'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'ORDER'),
            BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), activeIcon: Icon(Icons.payments), label: 'PEMBAYARAN'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'PROFIL'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SELLER STUDIO TAB — Halaman utama dashboard seller
// ─────────────────────────────────────────────────────────────
class SellerStudioTab extends StatefulWidget {
  const SellerStudioTab({super.key});

  @override
  State<SellerStudioTab> createState() => _SellerStudioTabState();
}

class _SellerStudioTabState extends State<SellerStudioTab> {
  Map<String, dynamic>? _stats;
  List<dynamic> _dpOrders = [];
  bool _isLoading = true;
  int _revenueDays = 7;

  DateTime _chartMonth = DateTime.now();
  bool _isFetchingMonth = false;
  List<_RevenueDataPoint>? _monthPoints;
  double _monthTotal = 0.0;
  bool _showCustomMonth = false;

  final _bankNameCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();

  static const gold = Color(0xFFD4AF37);
  static const darkStudio = Color(0xFF0F0B1E);

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await ApiService.getSellerStats();
      List<dynamic> dpOrders = [];
      try {
        dpOrders = await ApiService.getSellerOrders(status: 'DP_PAID');
      } catch (_) {}
      setState(() {
        _stats = stats;
        _dpOrders = dpOrders;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _stats = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal Memuat Statistik Penjual')));
      }
    }
  }

  Future<void> _verifyOrder(int orderId) async {
    try {
      await ApiService.verifyOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Pembayaran DP berhasil diverifikasi!'), backgroundColor: Color(0xFF2E7D32)),
        );
        _fetchStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memverifikasi: $e')));
      }
    }
  }

  Future<void> _rejectOrder(int orderId) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF130B22),
        title: const Text('Tolak Pembayaran DP?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pembayaran akan ditolak dan status pesanan kembali ke PENDING.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Alasan penolakan (opsional)',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL', style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('YA, TOLAK', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.rejectOrder(orderId, reason: reasonCtrl.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pembayaran DP ditolak.'), backgroundColor: Color(0xFFC62828)),
          );
          _fetchStats();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menolak: $e')));
        }
      }
    }
  }

  List<double> _generateSparklineData(String value, bool positive) {
    final List<double> base = positive ? [10.0, 15.0, 12.0, 18.0, 22.0, 20.0, 28.0] : [28.0, 22.0, 24.0, 18.0, 15.0, 16.0, 10.0];
    try {
      int hash = value.hashCode.abs();
      final List<double> data = [];
      for (int i = 0; i < 7; i++) {
        double noise = ((hash >> (i * 2)) & 7).toDouble() - 3.5;
        data.add((base[i] + noise).clamp(2.0, 40.0));
      }
      return data;
    } catch (_) {
      return base;
    }
  }

  Widget _buildUrgentActionsCarousel() {
    final List<Widget> cards = [];

    // Verifikasi DP/Lunas
    final dpPending = ((_stats!['totals']['dpPendingVerification'] ?? 0) +
                     (_stats!['totals']['fullPayPendingVerification'] ?? 0));
    if (dpPending > 0) {
      cards.add(
        _buildCompactUrgentCard(
          label: 'VERIFIKASI BAYAR',
          value: dpPending.toString(),
          icon: Icons.verified_user_outlined,
          color: Colors.amberAccent,
          subtitle: 'DP & Pelunasan',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SellerPaymentsView()),
          ),
        ),
      );
    }

    // Stok Menipis
    final lowStock = _stats!['totals']['lowStock'] ?? 0;
    if (lowStock > 0) {
      cards.add(
        _buildCompactUrgentCard(
          label: 'STOK KRITIS',
          value: lowStock.toString(),
          icon: Icons.inventory_2_outlined,
          color: Colors.redAccent,
          subtitle: 'Perlu restock segera',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SellerProductsScreen(showAppBar: true)),
          ),
        ),
      );
    }

    // Produksi Belum Lunas
    final processedUnpaid = _stats!['totals']['processedUnpaid'] ?? 0;
    if (processedUnpaid > 0) {
      cards.add(
        _buildCompactUrgentCard(
          label: 'PRODUKSI BELUM LUNAS',
          value: processedUnpaid.toString(),
          icon: Icons.engineering_outlined,
          color: Colors.lightBlueAccent,
          subtitle: 'Menunggu pelunasan',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrdersScreen(showBackButton: true)),
          ),
        ),
      );
    }

    if (cards.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.01),
          border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: gold.withOpacity(0.4), size: 16),
            const SizedBox(width: 8),
            Text(
              'Semua tugas telah diselesaikan',
              style: GoogleFonts.montserrat(color: Colors.white30, fontSize: 10, letterSpacing: 0.5),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }

  Widget _buildCompactUrgentCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 190,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          border: Border.all(color: color.withOpacity(0.25), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 14),
                ),
                Text(
                  value,
                  style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white30, fontSize: 8),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkStudio,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: darkStudio,
          elevation: 0,
          titleSpacing: 0,
          title: Container(
            margin: const EdgeInsets.only(left: 20, top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gold.withOpacity(0.08), Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: const Border(left: BorderSide(color: gold, width: 2.5)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: gold,
                  radius: 15,
                  child: Icon(Icons.storefront_rounded, color: Colors.black, size: 15),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SELAMAT DATANG DI STUDIO',
                        style: GoogleFonts.montserrat(color: gold, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SELLER STUDIO',
                        style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 10),
              child: IconButton(icon: const Icon(Icons.refresh, size: 20, color: gold), onPressed: _fetchStats),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: gold))
            : _stats == null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _fetchStats,
                    color: gold,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── QUICK MENU BAR ───
                          _buildQuickMenuBar(),
                          const SizedBox(height: 24),

                          // ─── BAGIAN 1: RINGKASAN BISNIS ───
                          _buildSectionHeader('RINGKASAN BISNIS', gold),
                          const SizedBox(height: 12),
                          _buildBusinessSummaryCards(),

                          const SizedBox(height: 28),

                          // ─── BAGIAN 2: GRAFIK TREN PENDAPATAN ───
                          _buildSectionHeader('TREN PENDAPATAN', gold),
                          const SizedBox(height: 14),
                          _buildRevenueLineChart(),

                          const SizedBox(height: 28),

                          // ─── BAGIAN 3: PIPELINE PESANAN ───
                          _buildSectionHeader('PIPELINE PESANAN', gold),
                          const SizedBox(height: 14),
                          _buildOrderPipelineChart(),

                          const SizedBox(height: 28),

                          // ─── BAGIAN 3: VERIFIKASI DP CEPAT ───
                          if (_dpOrders.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionHeader('VERIFIKASI DP CEPAT', Colors.amber),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_dpOrders.length} menunggu',
                                    style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._dpOrders.map((order) => _buildDPVerificationCard(order)),
                          ],

                          // ─── BAGIAN 4: PESANAN TERBARU ───
                          _buildSectionHeader('PESANAN TERBARU', gold),
                          const SizedBox(height: 12),

                          if (_stats!['recentOrders'].isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: Text('Belum ada pesanan', style: TextStyle(color: Colors.white24, fontSize: 12)),
                              ),
                            )
                          else
                            ...(_stats!['recentOrders'] as List).map((order) => _buildOrderRow(order)),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // ─── HELPER METHODS ───

  bool _isGrowthPositive(String growth) {
    return !growth.startsWith('-');
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: color),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.montserrat(
            color: color.withOpacity(0.85),
            fontSize: 10,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<_RevenueDataPoint> _getRevenuePoints(int daysCount) {
    final List<dynamic> orders = (_stats!['recentOrders'] as List?) ?? [];
    final Map<String, double> grouped = {};
    final DateFormat dayFmt = DateFormat('dd MMM');

    // Buat data rentang hari terakhir secara berurutan
    final now = DateTime.now();
    for (int i = daysCount - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = dayFmt.format(date);
      grouped[key] = 0.0;
    }

    // Akumulasikan nominal pesanan
    for (var order in orders) {
      try {
        final date = DateTime.parse(order['tanggal'].toString());
        final key = dayFmt.format(date);
        if (grouped.containsKey(key)) {
          double amount = (order['total'] as num?)?.toDouble() ?? 0.0;
          grouped[key] = grouped[key]! + amount;
        }
      } catch (_) {}
    }

    // Jika seluruh data kosong (misal data dummy/baru), buat tren mockup dinamis
    double totalSum = grouped.values.fold(0.0, (sum, val) => sum + val);
    if (totalSum == 0.0) {
      final List<_RevenueDataPoint> mockPoints = [];
      int idx = 0;
      grouped.forEach((key, _) {
        double mockVal = 150000.0 + (idx * 20000.0) + (idx % 4 == 0 ? 250000.0 : (idx % 2 == 0 ? -120000.0 : 0.0));
        mockPoints.add(_RevenueDataPoint(key, mockVal.clamp(50000.0, 1500000.0)));
        idx++;
      });
      return mockPoints;
    }

    return grouped.entries.map((e) => _RevenueDataPoint(e.key, e.value)).toList();
  }

  Widget _buildTimeframeButton(int days, String label) {
    final isSelected = _revenueDays == days;
    return InkWell(
      onTap: () => setState(() => _revenueDays = days),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? gold.withOpacity(0.12) : Colors.transparent,
          border: Border.all(
            color: isSelected ? gold.withOpacity(0.4) : Colors.white.withOpacity(0.08),
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            color: isSelected ? gold : Colors.white38,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _fetchMonthData(DateTime month) async {
    setState(() {
      _chartMonth = month;
      _isFetchingMonth = true;
      _showCustomMonth = true;
    });

    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      final range = DateTimeRange(start: start, end: end);

      final res = await ApiService.getFinanceReport(range);
      final List<dynamic> orders = (res['orders'] as List?) ?? [];

      // Hitung total omzet bulan ini
      final totals = res['totals'] as Map?;
      int v(dynamic x) => (x is num) ? x.toInt() : int.tryParse(x?.toString() ?? '') ?? 0;
      final double totalRevenue = (v(totals?['revenueFullPaid']) + v(totals?['dpVerifiedTotal'])).toDouble();

      // Kelompokkan per tanggal dalam bulan tersebut
      final Map<String, double> grouped = {};
      final DateFormat dayFmt = DateFormat('dd MMM');
      final int daysInMonth = end.day;

      for (int i = 1; i <= daysInMonth; i++) {
        final date = DateTime(month.year, month.month, i);
        final key = dayFmt.format(date);
        grouped[key] = 0.0;
      }

      for (var order in orders) {
        try {
          final rawDate = order['createdAt']?.toString() ?? order['tanggal']?.toString() ?? '';
          final date = DateTime.parse(rawDate);
          final key = dayFmt.format(date);
          if (grouped.containsKey(key)) {
            final double amount = ((order['totalPrice'] ?? order['total']) as num?)?.toDouble() ?? 0.0;
            grouped[key] = grouped[key]! + amount;
          }
        } catch (_) {}
      }

      final List<_RevenueDataPoint> points = grouped.entries.map((e) => _RevenueDataPoint(e.key, e.value)).toList();

      if (mounted) {
        setState(() {
          _monthPoints = points;
          _monthTotal = totalRevenue;
          _isFetchingMonth = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingMonth = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data bulan: $e')),
        );
      }
    }
  }

  void _showMonthPickerMenu() {
    final now = DateTime.now();
    final List<DateTime> months = [];
    final DateFormat monthFmt = DateFormat('MMMM yyyy');

    for (int i = 0; i < 6; i++) {
      months.add(DateTime(now.year, now.month - i, 1));
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF130B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.5,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text(
                    'PILIH BULAN GRAFIK',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.history, color: gold),
                    title: Text(
                      '7 / 30 Hari Terakhir (Default)',
                      style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _showCustomMonth = false;
                      });
                    },
                  ),
                  const Divider(color: Colors.white10),
                  ...months.map((m) {
                    final isSelected = _showCustomMonth && _chartMonth.year == m.year && _chartMonth.month == m.month;
                    return ListTile(
                      leading: Icon(
                        Icons.calendar_today,
                        color: isSelected ? gold : Colors.white24,
                        size: 16,
                  ),
                  title: Text(
                    monthFmt.format(m).toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: isSelected ? gold : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _fetchMonthData(m);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildRevenueLineChart() {
    final DateFormat monthFmt = DateFormat('MMMM yyyy');
    final points = _showCustomMonth
        ? (_monthPoints ?? [])
        : _getRevenuePoints(_revenueDays);

    final title = _showCustomMonth
        ? 'Tren Omzet (${monthFmt.format(_chartMonth)})'
        : 'Tren Omzet (${_revenueDays} Hari Terakhir)';

    final subtitle = _showCustomMonth
        ? 'Total: ${Globals.formatRupiah(_monthTotal)}'
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        color: Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.montserrat(
                          color: gold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  if (_showCustomMonth) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.history, color: gold, size: 12),
                      label: Text(
                        'DEFAULT',
                        style: GoogleFonts.montserrat(
                          color: gold,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        setState(() {
                          _showCustomMonth = false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: const Icon(Icons.date_range, color: gold, size: 18),
                    onPressed: _showMonthPickerMenu,
                    tooltip: 'Pilih Bulan Lain',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (!_showCustomMonth) ...[
                    const SizedBox(width: 8),
                    _buildTimeframeButton(7, '7 HARI'),
                    const SizedBox(width: 8),
                    _buildTimeframeButton(30, '30 HARI'),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: _isFetchingMonth
                ? const Center(child: CircularProgressIndicator(color: gold))
                : TweenAnimationBuilder<double>(
                    key: ValueKey('${_revenueDays}_${_showCustomMonth}_${_chartMonth.month}'),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOutCubic,
                    builder: (context, value, child) {
                      return CustomPaint(
                        painter: RevenueChartPainter(
                          points: points,
                          animationProgress: value,
                          color: gold,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderPipelineChart() {
    final totals = _stats!['totals'];
    final recentOrders = (_stats!['recentOrders'] as List?) ?? [];

    // Hitung distribusi status dari recentOrders
    int countCompleted = recentOrders.where((o) => o['status'] == 'COMPLETED' || o['status'] == 'DELIVERED' || o['status'] == 'SHIPPED').length;
    int countProcessed = recentOrders.where((o) => o['status'] == 'PROCESSED').length;
    int countVerified  = recentOrders.where((o) => o['status'] == 'VERIFIED').length;

    final int menungguDP      = (totals['unpaidDP'] ?? 0) as int;
    final int dpVerified      = countVerified > 0 ? countVerified : ((totals['dpPendingVerification'] ?? 0) as int);
    final int diproduksi      = countProcessed > 0 ? countProcessed : ((totals['processedUnpaid'] ?? 0) as int);
    final int selesai         = countCompleted > 0 ? countCompleted : 0;

    final List<_PipelineStage> stages = [
      _PipelineStage('MENUNGGU DP',    menungguDP, Colors.orangeAccent),
      _PipelineStage('DP VERIFIED',    dpVerified, Colors.amberAccent),
      _PipelineStage('DIPRODUKSI',     diproduksi, Colors.lightBlueAccent),
      _PipelineStage('SELESAI',        selesai,    Colors.greenAccent),
    ];

    final int total = stages.fold(0, (sum, s) => sum + s.count);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Donut Chart
          SizedBox(
            width: 110,
            height: 110,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CustomPaint(
                        painter: DonutChartPainter(stages: stages, animationProgress: value),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          total.toString(),
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'TOTAL',
                          style: GoogleFonts.montserrat(
                            color: Colors.white30,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 24),
          // Legends
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: stages.map((s) {
                final percentage = total > 0 ? (s.count / total * 100).toStringAsFixed(0) : '0';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.label,
                          style: GoogleFonts.montserrat(
                            color: Colors.white54,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        '${s.count} ($percentage%)',
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildQuickMenuBar() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickMenuButton(
            label: 'LAPORAN KEUANGAN',
            subtitle: 'Ringkasan & grafik transaksi',
            icon: Icons.analytics_outlined,
            color: gold,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinancialReportScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickMenuButton(
            label: 'PENGATURAN REKENING',
            subtitle: 'Kelola Bank & QRIS',
            icon: Icons.account_balance_outlined,
            color: const Color(0xFF1ABC9C),
            onTap: _showPaymentSettingsDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickMenuButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 7),
          ],
        ),
      ),
    );
  }

  void _showPaymentSettingsDialog() async {
    Map<String, dynamic>? currentSettings;
    try {
      currentSettings = await ApiService.getPaymentSettings();
    } catch (_) {}

    if (!mounted) return;

    _bankNameCtrl.text = currentSettings?['bankName']?.toString() ?? '';
    _bankAccountCtrl.text = currentSettings?['bankAccount']?.toString() ?? '';
    _accountNameCtrl.text = currentSettings?['accountName']?.toString() ?? '';
    String? qrisImageUrl = currentSettings?['qrisImageUrl']?.toString();
    bool isUploadingQris = false;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          decoration: const BoxDecoration(
            color: Color(0xFF130B22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Center(
                  child: Text('PENGATURAN REKENING & QRIS',
                      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                const SizedBox(height: 4),
                const Center(child: Text('Info ini akan ditampilkan kepada pembeli saat melakukan transfer manual.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 10))),
                const SizedBox(height: 28),

                _buildSettingField(_bankNameCtrl, 'Nama Bank', 'Contoh: BCA, Mandiri, BRI, BNI', gold),
                const SizedBox(height: 16),
                _buildSettingField(_bankAccountCtrl, 'Nomor Rekening', 'Contoh: 1234567890', gold, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildSettingField(_accountNameCtrl, 'Nama Pemilik Rekening', 'Contoh: TENUN GEZA OFFICIAL', gold),
                const SizedBox(height: 24),

                const Text('Gambar QRIS', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: isUploadingQris ? null : () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                    if (pickedFile == null) return;
                    setSheetState(() => isUploadingQris = true);
                    try {
                      final url = await ApiService.uploadImage(pickedFile);
                      setSheetState(() {
                        qrisImageUrl = url;
                        isUploadingQris = false;
                      });
                    } catch (e) {
                      setSheetState(() => isUploadingQris = false);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (qrisImageUrl != null && qrisImageUrl!.isNotEmpty)
                          ? gold.withOpacity(0.05)
                          : Colors.white.withOpacity(0.03),
                      border: Border.all(
                        color: (qrisImageUrl != null && qrisImageUrl!.isNotEmpty)
                            ? gold.withOpacity(0.4)
                            : Colors.white12,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isUploadingQris
                        ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2)))
                        : (qrisImageUrl != null && qrisImageUrl!.isNotEmpty)
                            ? Column(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    ApiService.getFormattedImageUrl(qrisImageUrl),
                                    height: 160, fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white24, size: 40),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Ketuk untuk ganti gambar QRIS', style: TextStyle(color: gold.withOpacity(0.7), fontSize: 10)),
                              ])
                            : Column(children: [
                                const Icon(Icons.qr_code_2, color: Colors.white24, size: 40),
                                const SizedBox(height: 8),
                                const Text('Ketuk untuk upload gambar QRIS dari galeri', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                const SizedBox(height: 4),
                                const Text('JPG / PNG • Maks 5MB', style: TextStyle(color: Colors.white24, fontSize: 10)),
                              ]),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : () async {
                      setSheetState(() => isSaving = true);
                      try {
                        await ApiService.updatePaymentSettings({
                          'bankName': _bankNameCtrl.text.trim(),
                          'bankAccount': _bankAccountCtrl.text.trim(),
                          'accountName': _accountNameCtrl.text.trim(),
                          'qrisImageUrl': qrisImageUrl ?? '',
                        });
                        if (mounted) {
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pengaturan rekening berhasil disimpan!'), backgroundColor: Color(0xFF2ECC71)),
                          );
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
                      } finally {
                        setSheetState(() => isSaving = false);
                      }
                    },
                    icon: isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(isSaving ? 'MENYIMPAN...' : 'SIMPAN PENGATURAN',
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingField(TextEditingController ctrl, String label, String hint, Color gold, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
            filled: true,
            fillColor: Colors.white.withOpacity(0.02),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: gold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessSummaryCards() {
    final isPositive = _isGrowthPositive(_stats!['totals']['growth']);
    final growthColor = isPositive ? Colors.greenAccent : Colors.redAccent;

    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSellerSummaryCard(
            'PENDAPATAN TOTAL',
            Globals.formatRupiah(_stats!['totals']['revenue']),
            Icons.account_balance_wallet_outlined,
            gold,
            isPrimary: true,
            // Info display only — bukan navigasi
          ),
          const SizedBox(width: 10),
          _buildSellerSummaryCard(
            'PERTUMBUHAN',
            _stats!['totals']['growth'],
            isPositive ? Icons.trending_up : Icons.trending_down,
            growthColor,
            // Info display only
          ),
          const SizedBox(width: 10),
          _buildSellerSummaryCard(
            'TOTAL PESANAN',
            _stats!['totals']['orders'].toString(),
            Icons.shopping_bag_outlined,
            gold,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen(showBackButton: true)),
            ),
          ),
          const SizedBox(width: 10),
          _buildSellerSummaryCard(
            'PRODUK AKTIF',
            _stats!['totals']['activeProducts'].toString(),
            Icons.store_outlined,
            Colors.greenAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SellerProductsScreen(showAppBar: true)),
            ),
          ),
          const SizedBox(width: 10),
          _buildSellerSummaryCard(
            'MENUNGGU DP',
            _stats!['totals']['unpaidDP'].toString(),
            Icons.pending_actions,
            Colors.orangeAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen(showBackButton: true)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerSummaryCard(
    String label,
    String value,
    IconData icon,
    Color accentColor, {
    VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: isPrimary ? 160 : 110,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? accentColor.withOpacity(0.06) : Colors.white.withOpacity(0.03),
          border: Border.all(
            color: isPrimary ? accentColor.withOpacity(0.3) : Colors.white.withOpacity(0.06),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: accentColor.withOpacity(0.7), size: 13),
                if (onTap != null)
                  const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 7),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    color: Colors.white38,
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: isPrimary ? 11 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDPVerificationCard(dynamic order) {
    final userName = order['user']?['name'] ?? 'Pelanggan';
    final productName = order['items'] != null && (order['items'] as List).isNotEmpty
        ? (order['items'] as List).map((i) => i['product']?['name'] ?? '').join(', ')
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.05),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                userName.toString().toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                Globals.formatRupiah(order['dpAmount']),
                style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            productName,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _verifyOrder(order['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text('VERIFIKASI', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectOrder(order['id']),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  child: const Text('TOLAK', style: TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(dynamic order) {
    String formattedDate = '';
    try {
      final date = DateTime.parse(order['tanggal'].toString());
      formattedDate = DateFormat('dd MMM yy').format(date);
    } catch (_) {}

    final statusColor = _statusColor(order['status']);
    final statusLabel = _statusLabel(order['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('ORD-${order['id']}', style: GoogleFonts.montserrat(color: gold, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(formattedDate, style: const TextStyle(color: Colors.white24, fontSize: 9)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  order['pelanggan'].toString().toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  order['produk'] ?? '-',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Globals.formatRupiah(order['total']), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  border: Border.all(color: statusColor.withOpacity(0.3), width: 0.5),
                ),
                child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 7, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: Colors.redAccent, size: 50),
          const SizedBox(height: 16),
          const Text('Koneksi Server Terputus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextButton(onPressed: _fetchStats, child: const Text('COBA LAGI', style: TextStyle(color: gold))),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'DP_PAID': return Colors.amber;
      case 'VERIFIED': return Colors.lightBlueAccent;
      case 'PROCESSED': return Colors.blueAccent;
      case 'FULL_PAY_PAID': return Colors.purpleAccent;
      case 'PAID': return Colors.blue;
      case 'SHIPPED': return Colors.tealAccent;
      case 'DELIVERED': return Colors.greenAccent;
      case 'COMPLETED': return Colors.green;
      case 'CANCELLED': return Colors.redAccent;
      default: return Colors.white38;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING': return 'MENUNGGU DP';
      case 'DP_PAID': return 'DP DIBAYAR';
      case 'VERIFIED': return 'DP VERIFIED';
      case 'PROCESSED': return 'DIPRODUKSI';
      case 'FULL_PAY_PAID': return 'LUNAS DIBAYAR';
      case 'PAID': return 'LUNAS';
      case 'SHIPPED': return 'DIKIRIM';
      case 'DELIVERED': return 'SAMPAI';
      case 'COMPLETED': return 'SELESAI';
      case 'CANCELLED': return 'DIBATALKAN';
      default: return status;
    }
  }
}


// ─────────────────────────────────────────────────────────────
// SELLER MONITOR TAB — Tab monitoring detail (Verifikasi, Produksi, Pengiriman)
// ─────────────────────────────────────────────────────────────
class SellerMonitorTab extends StatefulWidget {
  const SellerMonitorTab({super.key});

  @override
  State<SellerMonitorTab> createState() => _SellerMonitorTabState();
}

class _SellerMonitorTabState extends State<SellerMonitorTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const darkStudio = Color(0xFF0F0B1E);

    return Scaffold(
      backgroundColor: darkStudio,
      appBar: AppBar(
        backgroundColor: darkStudio,
        elevation: 0,
        title: Text('MONITORING STUDIO', style: GoogleFonts.montserrat(color: gold, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 4)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: gold,
          labelColor: gold,
          unselectedLabelColor: Colors.white24,
          labelStyle: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
          tabs: const [
            Tab(text: 'VERIFIKASI'),
            Tab(text: 'PRODUKSI'),
            Tab(text: 'PENGIRIMAN'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const InternalOrderVerificationView(),
          const InternalProductionManagementView(),
          const InternalShippingManagementView(),
        ],
      ),
    );
  }
}

// Internal Views for Monitoring Tab (Refactored from full screens)
class InternalOrderVerificationView extends StatefulWidget {
  const InternalOrderVerificationView({super.key});

  @override
  State<InternalOrderVerificationView> createState() => _InternalOrderVerificationViewState();
}

class _InternalOrderVerificationViewState extends State<InternalOrderVerificationView> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _showImagePreviewDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF130B22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Cubit/Pinch untuk memperbesar gambar',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: const Color(0xFF0F0B1E),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.6,
                            ),
                            child: InteractiveViewer(
                              panEnabled: true,
                              minScale: 1.0,
                              maxScale: 4.0,
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                fadeInDuration: const Duration(milliseconds: 250),
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFD4AF37),
                                    strokeWidth: 1.5,
                                  ),
                                ),
                                errorWidget: (ctx, url, error) => const Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                                      SizedBox(height: 12),
                                      Text('Gagal memuat gambar', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
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
      },
    );
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final dp = await ApiService.getSellerOrders(status: 'DP_PAID');
      final full = await ApiService.getSellerOrders(status: 'FULL_PAY_PAID');
      setState(() {
        _orders = [...dp, ...full];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    if (_orders.isEmpty) return const Center(child: Text('TIADA TUGASAN VERIFIKASI', style: TextStyle(color: Colors.white10, fontSize: 10, letterSpacing: 2)));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final bool isFull = order['status'] == 'FULL_PAY_PAID';
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), border: Border.all(color: Colors.amber.withOpacity(0.1))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ORD-${order['id']}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    color: isFull ? Colors.blue.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                    child: Text(isFull ? 'LUNAS' : 'DP', style: TextStyle(color: isFull ? Colors.blue : Colors.amber, fontSize: 8)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(order['user']['name'].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              _buildBuyerAddress(order),
              if (order['paymentProofUrl'] != null && order['paymentProofUrl'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('BUKTI PEMBAYARAN:', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    final url = ApiService.getFormattedImageUrl(order['paymentProofUrl']);
                    _showImagePreviewDialog(context, url, 'BUKTI TRANSFER');
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Tooltip(
                      message: 'Klik untuk memperbesar bukti pembayaran',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CachedNetworkImage(
                              imageUrl: ApiService.getFormattedImageUrl(order['paymentProofUrl']),
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 350),
                              placeholder: (context, url) => Container(
                                height: 140,
                                color: const Color(0xFF1C1C1C),
                                child: Container(
                                  decoration: const BoxDecoration(color: Color(0xFF232323)),
                                )
                                    .animate(onPlay: (c) => c.repeat())
                                    .shimmer(
                                      duration: const Duration(milliseconds: 1200),
                                      color: const Color(0xFF3A3A3A),
                                      angle: 0.3,
                                    ),
                              ),
                              errorWidget: (context, url, error) => const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.white24, size: 14),
                                      SizedBox(width: 8),
                                      Text('Gagal memuat bukti transfer', style: TextStyle(color: Colors.white24, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              color: Colors.black.withOpacity(0.6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.zoom_in, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text('PERBESAR BUKTI', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const Divider(height: 32, color: Colors.white10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          if (isFull) {
                            await ApiService.verifyFinalPayment(order['id']);
                          } else {
                            await ApiService.verifyOrder(order['id']);
                          }
                          _fetch();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                      ),
                      child: Text('VERIFIKASI', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildBuyerAddress(dynamic order) {
    final addresses = order['user']?['addresses'] as List?;
    if (addresses == null || addresses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            const Icon(Icons.location_off, color: Colors.white24, size: 12),
            const SizedBox(width: 4),
            const Text('Belum ada alamat pengiriman', style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }
    final addr = addresses[0];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.05),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.15)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on, color: Color(0xFFD4AF37), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${addr['name']} • ${addr['phone']}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  '${addr['streetAddress']}, ${addr['district']}, ${addr['city']}, ${addr['province']} ${addr['postalCode']}',
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
                if (addr['detailAddress'] != null && addr['detailAddress'].toString().isNotEmpty)
                  Text('(${addr['detailAddress']})', style: const TextStyle(color: Colors.white24, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InternalProductionManagementView extends StatefulWidget {
  const InternalProductionManagementView({super.key});

  @override
  State<InternalProductionManagementView> createState() => _InternalProductionManagementViewState();
}

class _InternalProductionManagementViewState extends State<InternalProductionManagementView> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final orders = await ApiService.getSellerOrders(status: 'VERIFIED');
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    if (_orders.isEmpty) return const Center(child: Text('TIADA PRODUKSI AKTIF', style: TextStyle(color: Colors.white10, fontSize: 10, letterSpacing: 2)));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), border: Border.all(color: Colors.white10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ORD-${order['id']}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(order['user']['name'].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              _buildBuyerAddress(order),
              const Divider(height: 32, color: Colors.white10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ApiService.markProcessed(order['id']);
                      _fetch();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                  ),
                  child: Text('PRODUKSI SELESAI', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBuyerAddress(dynamic order) {
    final addresses = order['user']?['addresses'] as List?;
    if (addresses == null || addresses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.white24, size: 12),
            SizedBox(width: 4),
            Text('Belum ada alamat pengiriman', style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }
    final addr = addresses[0];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.05),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.15)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on, color: Color(0xFFD4AF37), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${addr['name']} • ${addr['phone']}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  '${addr['streetAddress']}, ${addr['district']}, ${addr['city']}, ${addr['province']} ${addr['postalCode']}',
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
                if (addr['detailAddress'] != null && addr['detailAddress'].toString().isNotEmpty)
                  Text('(${addr['detailAddress']})', style: const TextStyle(color: Colors.white24, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InternalShippingManagementView extends StatefulWidget {
  const InternalShippingManagementView({super.key});
  @override
  State<InternalShippingManagementView> createState() => _InternalShippingManagementViewState();
}

class _InternalShippingManagementViewState extends State<InternalShippingManagementView> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final paid = await ApiService.getSellerOrders(status: 'PAID');
      final shipped = await ApiService.getSellerOrders(status: 'SHIPPED');
      setState(() {
        _orders = [...paid, ...shipped];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLocation(int orderId) async {
    try {
      final courierCtrl = TextEditingController();
      final awbCtrl = TextEditingController();
      final statusCtrl = TextEditingController(text: "Pesanan dalam perjalanan");

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF130B22),
          title: const Text('Update Pengiriman (Resi)', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: courierCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Kurir Ekspedisi (JNE, J&T, dll)',
                  hintStyle: TextStyle(color: Colors.white24),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: awbCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Nomor Resi',
                  hintStyle: TextStyle(color: Colors.white24),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: statusCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Status detail (contoh: Di Hub Jakarta)',
                  hintStyle: TextStyle(color: Colors.white24),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL', style: TextStyle(color: Colors.white24))),
            TextButton(
              onPressed: () async {
                try {
                  await ApiService.updateTracking(
                    orderId,
                    courierName: courierCtrl.text,
                    awbNumber: awbCtrl.text,
                    trackingStatus: statusCtrl.text,
                  );
                  await ApiService.updateOrderStatus(orderId, 'SHIPPED');
                  Navigator.pop(ctx);
                  _fetch();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Info pengiriman berhasil diupdate!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                }
              },
              child: const Text('UPDATE', style: TextStyle(color: Color(0xFFD4AF37))),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleMarkDelivered(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF130B22),
        title: const Text('Konfirmasi Sampai', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text('Tandai pesanan ini telah sampai ke pelanggan?', style: TextStyle(color: Colors.white54, fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL', style: TextStyle(color: Colors.white24))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('YA, SAMPAI', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.updateOrderStatus(id, 'DELIVERED');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan ditandai sebagai SAMPAI'), backgroundColor: Colors.green));
        _fetch();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    if (_orders.isEmpty) return const Center(child: Text('TIADA PESANAN SIAP KIRIM', style: TextStyle(color: Colors.white10, fontSize: 10, letterSpacing: 2)));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final isShipped = order['status'] == 'SHIPPED';
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            border: Border.all(color: isShipped ? Colors.teal.withOpacity(0.2) : Colors.blue.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ORD-${order['id']}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                  Text(
                    isShipped ? 'DIKIRIM' : 'SIAP KIRIM',
                    style: TextStyle(color: isShipped ? Colors.tealAccent : Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order['user'] != null ? order['user']['name'].toUpperCase() : 'UNKNOWN',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              _buildBuyerAddress(order),
              const Divider(height: 32, color: Colors.white10),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateLocation(order['id']),
                      icon: const Icon(Icons.local_shipping, size: 16),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isShipped ? Colors.teal.withOpacity(0.2) : const Color(0xFFD4AF37),
                        foregroundColor: isShipped ? Colors.tealAccent : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                      ),
                      label: Text(
                        isShipped ? 'UPDATE RESI & STATUS' : 'KIRIM & INPUT RESI',
                        style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ),
                  if (isShipped) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleMarkDelivered(order['id']),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent.withOpacity(0.1),
                          foregroundColor: Colors.greenAccent,
                          side: const BorderSide(color: Colors.greenAccent, width: 0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                        ),
                        label: Text('TANDAI SAMPAI', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TrackingScreen(orderId: order['id'])),
                          );
                          _fetch();
                        },
                        icon: const Icon(Icons.receipt_long, size: 16),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD4AF37),
                          side: const BorderSide(color: Color(0xFFD4AF37), width: 0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                        ),
                        label: Text('LIHAT DETAIL PELACAKAN', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBuyerAddress(dynamic order) {
    final addresses = order['user']?['addresses'] as List?;
    if (addresses == null || addresses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.white24, size: 12),
            SizedBox(width: 4),
            Text('Belum ada alamat pengiriman', style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }
    final addr = addresses[0];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.05),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.15)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on, color: Color(0xFFD4AF37), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${addr['name']} • ${addr['phone']}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  '${addr['streetAddress']}, ${addr['district']}, ${addr['city']}, ${addr['province']} ${addr['postalCode']}',
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
                if (addr['detailAddress'] != null && addr['detailAddress'].toString().isNotEmpty)
                  Text('(${addr['detailAddress']})', style: const TextStyle(color: Colors.white24, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SPARKLINE PAINTER — Menggambar garis grafik tren mini yang estetik
// ─────────────────────────────────────────────────────────────
class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final path = Path();
    final double stepX = size.width / (data.length - 1);

    double minVal = data.reduce((a, b) => a < b ? a : b);
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    double range = maxVal - minVal;
    if (range == 0) range = 1.0;

    double getX(int index) => index * stepX;
    double getY(double value) {
      double relative = (value - minVal) / range;
      return size.height - (relative * (size.height - 8) + 4);
    }

    path.moveTo(getX(0), getY(data[0]));
    for (int i = 1; i < data.length; i++) {
      path.lineTo(getX(i), getY(data[i]));
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.18),
        color.withOpacity(0.0),
      ],
    );
    fillPaint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

// ─────────────────────────────────────────────────────────────
// DATA CLASS — Untuk pipeline chart
// ─────────────────────────────────────────────────────────────
class _PipelineStage {
  final String label;
  final int count;
  final Color color;

  const _PipelineStage(this.label, this.count, this.color);
}

// ─────────────────────────────────────────────────────────────
// DONUT CHART PAINTER — Menggambar diagram donat interaktif
// ─────────────────────────────────────────────────────────────
class DonutChartPainter extends CustomPainter {
  final List<_PipelineStage> stages;
  final double animationProgress;

  DonutChartPainter({required this.stages, required this.animationProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = stages.fold(0.0, (sum, s) => sum + s.count);
    final double strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    if (total == 0) return;

    double startAngle = -3.1415926535 / 2; // Mulai dari atas

    for (var stage in stages) {
      if (stage.count == 0) continue;

      final sweepAngle = (stage.count / total) * 2 * 3.1415926535 * animationProgress;

      final paint = Paint()
        ..color = stage.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += (stage.count / total) * 2 * 3.1415926535;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress || oldDelegate.stages != stages;
  }
}

// ─────────────────────────────────────────────────────────────
// DATA CLASS & PAINTER — Untuk grafik pendapatan harian
// ─────────────────────────────────────────────────────────────
class _RevenueDataPoint {
  final String dateLabel;
  final double amount;

  const _RevenueDataPoint(this.dateLabel, this.amount);
}

class RevenueChartPainter extends CustomPainter {
  final List<_RevenueDataPoint> points;
  final double animationProgress;
  final Color color;

  RevenueChartPainter({
    required this.points,
    required this.animationProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double maxVal = points.map((p) => p.amount).reduce((a, b) => a > b ? a : b);
    final double range = maxVal == 0 ? 1000000.0 : maxVal;

    final double paddingX = 36.0;
    final double paddingY = 16.0;
    final double chartWidth = size.width - paddingX - 10.0;
    final double chartHeight = size.height - paddingY - 14.0;

    final double stepX = chartWidth / (points.length - 1);

    // Draw background grids (Horizontal Y-gridlines and Vertical X-gridlines)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 0.8;

    // Horizontal lines
    for (int i = 0; i < 3; i++) {
      final double y = paddingY + (chartHeight / 2) * i;
      canvas.drawLine(Offset(paddingX, y), Offset(size.width - 10.0, y), gridPaint);
    }

    // Vertical lines for each of the 7 data points
    for (int i = 0; i < points.length; i++) {
      final double x = paddingX + i * stepX;
      canvas.drawLine(Offset(x, paddingY), Offset(x, paddingY + chartHeight), gridPaint);
    }

    // Draw main solid axes lines for structure
    final axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.2;
    // Y-Axis line
    canvas.drawLine(Offset(paddingX, paddingY), Offset(paddingX, paddingY + chartHeight), axisPaint);
    // X-Axis line
    canvas.drawLine(Offset(paddingX, paddingY + chartHeight), Offset(size.width - 10.0, paddingY + chartHeight), axisPaint);

    final List<Offset> coordinates = [];
    for (int i = 0; i < points.length; i++) {
      final x = paddingX + i * stepX;
      final relativeY = points[i].amount / range;
      final y = paddingY + chartHeight - (relativeY * chartHeight * animationProgress);
      coordinates.add(Offset(x, y));
    }

    // Bezier path construction
    final path = Path();
    final fillPath = Path();

    path.moveTo(coordinates[0].dx, coordinates[0].dy);
    fillPath.moveTo(coordinates[0].dx, coordinates[0].dy);

    for (int i = 0; i < coordinates.length - 1; i++) {
      final p1 = coordinates[i];
      final p2 = coordinates[i + 1];
      final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);

      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p2.dx, p2.dy,
      );
      fillPath.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p2.dx, p2.dy,
      );
    }

    // Draw stroke
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    // Draw fill gradient under the line
    fillPath.lineTo(coordinates.last.dx, paddingY + chartHeight);
    fillPath.lineTo(coordinates.first.dx, paddingY + chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.15),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(paddingX, paddingY, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // Draw glowing point at the last coordinate
    if (animationProgress == 1.0) {
      final lastPoint = coordinates.last;
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastPoint, 6.0, glowPaint);

      final pointPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastPoint, 3.0, pointPaint);
    }

    // Draw Y labels (max and 0)
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    void drawText(String text, Offset offset) {
      textPainter.text = TextSpan(
        text: text,
        style: GoogleFonts.montserrat(
          color: Colors.white24,
          fontSize: 7,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, offset);
    }

    // Draw max value label
    String maxLabel = maxVal >= 1000000
        ? '${(maxVal / 1000000).toStringAsFixed(1)}M'
        : maxVal >= 1000
            ? '${(maxVal / 1000).toStringAsFixed(0)}K'
            : maxVal.toStringAsFixed(0);
    drawText(maxLabel, Offset(4, paddingY - 4));
    drawText('0', Offset(4, paddingY + chartHeight - 4));

    // Draw X labels (dates)
    final int interval = points.length > 7 ? 6 : 2;
    for (int i = 0; i < points.length; i += interval) {
      final p = coordinates[i];
      drawText(
        points[i].dateLabel,
        Offset(p.dx - 12, paddingY + chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RevenueChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress || oldDelegate.points != points;
  }
}
