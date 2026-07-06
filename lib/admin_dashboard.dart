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

  void _changeTab(int index) {
    final parentState = context.findAncestorStateOfType<_AdminDashboardState>();
    if (parentState != null) {
      parentState.setState(() {
        parentState._selectedIndex = index;
      });
    }
  }

  Widget _buildQuickMenuBar() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickMenuButton(
            label: 'TREN KEUANGAN',
            subtitle: 'Grafik & omzet',
            icon: Icons.analytics_outlined,
            color: gold,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminFinanceScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickMenuButton(
            label: 'KELOLA USER',
            subtitle: 'Data pengguna',
            icon: Icons.people_outline,
            color: const Color(0xFF1ABC9C),
            onTap: () => _changeTab(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickMenuButton(
            label: 'KELOLA PRODUK',
            subtitle: 'Katalog tenun',
            icon: Icons.inventory_2_outlined,
            color: Colors.lightBlueAccent,
            onTap: () => _changeTab(1),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.8),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 7,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformSummaryCards() {
    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildCompactSummaryCard(
            'TOTAL PENGGUNA',
            _stats!['totals']['users'].toString(),
            Icons.people_outline,
            gold,
            onTap: () => _changeTab(2),
          ),
          const SizedBox(width: 10),
          _buildCompactSummaryCard(
            'TOTAL PRODUK',
            _stats!['totals']['products'].toString(),
            Icons.inventory_2_outlined,
            gold,
            onTap: () => _changeTab(1),
          ),
          const SizedBox(width: 10),
          _buildCompactSummaryCard(
            'TOTAL PESANAN',
            _stats!['totals']['orders'].toString(),
            Icons.shopping_bag_outlined,
            gold,
            onTap: () => _changeTab(3),
          ),
          const SizedBox(width: 10),
          _buildCompactSummaryCard(
            'PESANAN SELESAI',
            _stats!['totals']['processed'].toString(),
            Icons.check_circle_outline,
            Colors.greenAccent,
            onTap: () => _changeTab(3),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummaryCard(
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
        width: 120,
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
                    fontSize: 13,
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

  Widget _buildAdminPipelineChart() {
    final recentOrders = (_stats!['recentOrders'] as List?) ?? [];

    int countPending   = recentOrders.where((o) => o['status'] == 'PENDING' || o['status'] == 'DP_PAID').length;
    int countVerified  = recentOrders.where((o) => o['status'] == 'VERIFIED').length;
    int countProcessed = recentOrders.where((o) => o['status'] == 'PROCESSED' || o['status'] == 'FULL_PAY_PAID' || o['status'] == 'PAID').length;
    int countCompleted = recentOrders.where((o) => o['status'] == 'COMPLETED' || o['status'] == 'DELIVERED' || o['status'] == 'SHIPPED').length;

    final List<_AdminPipelineStage> stages = [
      _AdminPipelineStage('PENDING',     countPending,   Colors.orangeAccent),
      _AdminPipelineStage('VERIFIED',    countVerified,  Colors.amberAccent),
      _AdminPipelineStage('DIPRODUKSI',  countProcessed, Colors.lightBlueAccent),
      _AdminPipelineStage('SELESAI',     countCompleted, Colors.greenAccent),
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
                        painter: AdminDonutChartPainter(stages: stages, animationProgress: value),
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
                          'PESANAN',
                          style: GoogleFonts.montserrat(
                            color: Colors.white30,
                            fontSize: 6.5,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkSuite,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: darkSuite,
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
                  child: Icon(Icons.admin_panel_settings_rounded, color: Colors.black, size: 15),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SELAMAT DATANG DI SUITE',
                        style: GoogleFonts.montserrat(color: gold, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ADMIN EXECUTIVE',
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

                    // ─── QUICK SHORTCUTS MENU BAR ───
                    _buildQuickMenuBar(),
                    const SizedBox(height: 24),

                    // ─── BAGIAN 1: KESEHATAN PLATFORM ───
                    _buildSectionHeader('KESEHATAN PLATFORM', gold),
                    const SizedBox(height: 12),
                    _buildPlatformSummaryCards(),

                    const SizedBox(height: 28),

                    // ─── BAGIAN 2: PERLU TINDAKAN SEGERA ───
                    _buildSectionHeader('⚠  PERLU TINDAKAN SEGERA', Colors.amberAccent),
                    const SizedBox(height: 12),
                    _buildUrgentActionCard(
                      label: 'PEMBAYARAN MENUNGGU VERIFIKASI',
                      value: _stats!['totals']['unverified'].toString(),
                      description: 'DP & pelunasan belum diverifikasi',
                      icon: Icons.verified_user_outlined,
                      color: Colors.amberAccent,
                      onTap: () => _changeTab(3),
                    ),
                    const SizedBox(height: 12),
                    if ((_stats!['totals']['lowStock'] ?? 0) > 0) ...[
                      _buildUrgentActionCard(
                        label: 'STOK PRODUK KRITIS (≤ 5 pcs)',
                        value: _stats!['totals']['lowStock'].toString(),
                        description: 'Produk segera perlu restock',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        onTap: () => _changeTab(1),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const SizedBox(height: 24),

                    // ─── BAGIAN 3: PIPELINE PESANAN ───
                    _buildSectionHeader('PIPELINE PESANAN', gold),
                    const SizedBox(height: 14),
                    _buildAdminPipelineChart(),

                    const SizedBox(height: 28),

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

}

// ─────────────────────────────────────────────────────────────
// DATA CLASS & PAINTER — Untuk diagram donat platform
// ─────────────────────────────────────────────────────────────
class _AdminPipelineStage {
  final String label;
  final int count;
  final Color color;

  const _AdminPipelineStage(this.label, this.count, this.color);
}

class AdminDonutChartPainter extends CustomPainter {
  final List<_AdminPipelineStage> stages;
  final double animationProgress;

  AdminDonutChartPainter({required this.stages, required this.animationProgress});

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
  bool shouldRepaint(covariant AdminDonutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress || oldDelegate.stages != stages;
  }
}
