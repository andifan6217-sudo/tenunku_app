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

  static const gold = Color(0xFFD4AF37);
  static const darkStudio = Color(0xFF0F0B1E);

  @override
  void initState() {
    super.initState();
    _fetchStats();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkStudio,
      appBar: AppBar(
        backgroundColor: darkStudio,
        elevation: 0,
        title: Text('SELLER STUDIO', style: GoogleFonts.montserrat(color: gold, fontWeight: FontWeight.bold, letterSpacing: 4, fontSize: 14)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: gold),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _fetchStats),
        ],
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
                          // ─── BAGIAN 1: AKSI DIPERLUKAN ───
                          _buildSectionHeader('⚠  AKSI DIPERLUKAN', Colors.amberAccent),
                          const SizedBox(height: 12),

                          // Verifikasi DP
                          _buildUrgentCard(
                            label: 'PEMBAYARAN DP MENUNGGU VERIFIKASI',
                            value: ((_stats!['totals']['dpPendingVerification'] ?? 0) +
                                    (_stats!['totals']['fullPayPendingVerification'] ?? 0))
                                .toString(),
                            icon: Icons.verified_user_outlined,
                            color: Colors.amberAccent,
                            subtitle: 'Tap untuk ke halaman verifikasi',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SellerPaymentsView()),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Stok Menipis
                          if ((_stats!['totals']['lowStock'] ?? 0) > 0) ...[
                            _buildUrgentCard(
                              label: 'PRODUK STOK MENIPIS (≤ 5 pcs)',
                              value: _stats!['totals']['lowStock'].toString(),
                              icon: Icons.inventory_2_outlined,
                              color: Colors.redAccent,
                              subtitle: 'Segera tambah stok sebelum kehabisan',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SellerProductsScreen(showAppBar: true)),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Pesanan diproduksi menunggu pelunasan
                          if ((_stats!['totals']['processedUnpaid'] ?? 0) > 0) ...[
                            _buildUrgentCard(
                              label: 'DALAM PRODUKSI — BELUM LUNAS',
                              value: _stats!['totals']['processedUnpaid'].toString(),
                              icon: Icons.engineering_outlined,
                              color: Colors.lightBlueAccent,
                              subtitle: 'Pesanan selesai diproduksi, menunggu pembayaran pelunasan customer',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const OrdersScreen(showBackButton: true)),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          const SizedBox(height: 24),

                          // ─── BAGIAN 2: RINGKASAN BISNIS ───
                          _buildSectionHeader('RINGKASAN BISNIS', gold),
                          const SizedBox(height: 16),

                          // Pendapatan & Pertumbuhan
                          Row(
                            children: [
                              Expanded(
                                child: _buildRevenueCard(
                                  'PENDAPATAN TOTAL',
                                  Globals.formatRupiah(_stats!['totals']['revenue']),
                                  gold,
                                  Icons.account_balance_wallet_outlined,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildRevenueCard(
                                  'PERTUMBUHAN 30 HARI',
                                  _stats!['totals']['growth'],
                                  _isGrowthPositive(_stats!['totals']['growth'])
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  _isGrowthPositive(_stats!['totals']['growth'])
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Statistik pesanan
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                            children: [
                              _buildSmallStat(
                                'TOTAL PESANAN',
                                _stats!['totals']['orders'].toString(),
                                Icons.shopping_bag_outlined,
                                gold,
                              ),
                              _buildSmallStat(
                                'PRODUK AKTIF',
                                _stats!['totals']['activeProducts'].toString(),
                                Icons.store_outlined,
                                Colors.greenAccent,
                              ),
                              _buildSmallStat(
                                'MENUNGGU DP',
                                _stats!['totals']['unpaidDP'].toString(),
                                Icons.pending_actions,
                                Colors.orangeAccent,
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

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

  Widget _buildUrgentCard({
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          border: Border.all(color: color.withOpacity(0.35), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.montserrat(color: color, fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 9)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 13),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildRevenueCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 8, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSmallStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color.withOpacity(0.6), size: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label, style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 7, letterSpacing: 0.5), maxLines: 2),
            ],
          ),
        ],
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
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, e, st) => const Padding(
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
                            Image.network(
                              ApiService.getFormattedImageUrl(order['paymentProofUrl']),
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Center(
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
