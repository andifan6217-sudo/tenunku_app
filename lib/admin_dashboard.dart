import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_service.dart';
import 'orders_screen.dart';
import 'admin_users_screen.dart';
import 'admin_products_screen.dart';
import 'buyer_profile_screen.dart';
import 'globals.dart';
import 'admin_finance_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardTab(),
    const AdminProductsScreen(showAppBar: true),
    const AdminUsersScreen(showAppBar: true),
    const OrdersScreen(showBackButton: false),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const darkSuite = Color(0xFF0F0B1E);

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
          backgroundColor: darkSuite,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: gold,
          unselectedItemColor: Colors.white24,
          selectedLabelStyle: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
          unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 8, letterSpacing: 1),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'DASHBOARD'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'PRODUK'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'USER'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'PESANAN'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'PROFIL'),
          ],
        ),
      ),
    );
  }
}

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  static const gold = Color(0xFFD4AF37);
  static const darkSuite = Color(0xFF0F0B1E);

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await ApiService.getAdminStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal Memuat Statistik')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkSuite,
      appBar: AppBar(
        backgroundColor: darkSuite,
        elevation: 0,
        title: Text(
          'ADMIN EXECUTIVE',
          style: GoogleFonts.montserrat(color: gold, fontWeight: FontWeight.bold, letterSpacing: 4, fontSize: 14),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: gold),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _fetchStats),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : RefreshIndicator(
              onRefresh: _fetchStats,
              color: gold,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── BAGIAN 1: PERLU TINDAKAN SEGERA ───
                    _buildSectionHeader('⚠  PERLU TINDAKAN SEGERA', Colors.amberAccent),
                    const SizedBox(height: 12),
                    _buildUrgentActionCard(
                      label: 'PEMBAYARAN MENUNGGU VERIFIKASI',
                      value: _stats!['totals']['unverified'].toString(),
                      description: 'DP & pelunasan belum diverifikasi',
                      icon: Icons.verified_user_outlined,
                      color: Colors.amberAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrdersScreen(showBackButton: true)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if ((_stats!['totals']['lowStock'] ?? 0) > 0)
                      _buildUrgentActionCard(
                        label: 'STOK PRODUK KRITIS (≤ 5 pcs)',
                        value: _stats!['totals']['lowStock'].toString(),
                        description: 'Produk segera perlu restock',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminProductsScreen(showAppBar: true)),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // ─── BAGIAN 2: KESEHATAN PLATFORM ───
                    _buildSectionHeader('KESEHATAN PLATFORM', gold),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard(
                          'TOTAL PENGGUNA',
                          _stats!['totals']['users'].toString(),
                          Icons.people_outline,
                          gold,
                          subtitle: 'terdaftar',
                        ),
                        _buildStatCard(
                          'TOTAL PRODUK',
                          _stats!['totals']['products'].toString(),
                          Icons.inventory_2_outlined,
                          gold,
                          subtitle: '${_stats!['totals']['inStock']} tersedia',
                        ),
                        _buildStatCard(
                          'TOTAL PESANAN',
                          _stats!['totals']['orders'].toString(),
                          Icons.shopping_bag_outlined,
                          gold,
                          subtitle: 'sepanjang waktu',
                        ),
                        _buildStatCard(
                          'PESANAN SELESAI',
                          _stats!['totals']['processed'].toString(),
                          Icons.check_circle_outline,
                          Colors.greenAccent,
                          subtitle: 'dibayar & dikirim',
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ─── BAGIAN 3: LAPORAN KEUANGAN ───
                    _buildSectionHeader('KEUANGAN', gold),
                    const SizedBox(height: 12),
                    _buildNavCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'LAPORAN KEUANGAN & ARUS DP',
                      subtitle: 'Lihat detail pemasukan, DP masuk, dan pelunasan',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminFinanceScreen()),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ─── BAGIAN 4: PESANAN TERBARU ───
                    _buildSectionHeader('PESANAN TERBARU', gold),
                    const SizedBox(height: 16),

                    if (_stats!['recentOrders'].isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Belum ada pesanan', style: TextStyle(color: Colors.white24)),
                        ),
                      )
                    else
                      ...(_stats!['recentOrders'] as List).map((order) => _buildRecentOrderTile(order)),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── HELPER WIDGETS ───

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: color),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.montserrat(color: color.withOpacity(0.85), fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Card merah/amber untuk item yang BUTUH TINDAKAN — bisa diklik langsung ke action
  Widget _buildUrgentActionCard({
    required String label,
    required String value,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.montserrat(color: color, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(description, style: TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 14),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {String subtitle = ''}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color.withOpacity(0.7), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 8, letterSpacing: 1),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: TextStyle(color: color.withOpacity(0.6), fontSize: 9)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildNavCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          border: Border.all(color: gold.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: gold, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.montserrat(color: gold, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: gold.withOpacity(0.4), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrderTile(dynamic order) {
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
          // ID Badge
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Text(
              '#${order['id']}',
              style: TextStyle(color: gold, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['user']['name'].toString().toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  'Total: ${Globals.formatRupiah(order['totalPrice'])}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              border: Border.all(color: statusColor.withOpacity(0.3), width: 0.5),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
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

  Widget _dialogInput(TextEditingController ctrl, String label, Color color, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color.withOpacity(0.4), fontSize: 9, letterSpacing: 2),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: color.withOpacity(0.1))),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: color)),
      ),
    );
  }
}
