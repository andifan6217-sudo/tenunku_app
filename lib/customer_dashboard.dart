import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'login_screen.dart';
import 'language_provider.dart';
import 'buyer_profile_screen.dart';
import 'my_reviews_screen.dart';
import 'tracking_screen.dart';
import 'globals.dart';

class CustomerDashboardScreen extends StatefulWidget {
  final bool showDrawer;
  const CustomerDashboardScreen({super.key, this.showDrawer = true});

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  static const gold = Color(0xFFD4AF37);
  static const darkLuxe = Color(0xFF0F0918);

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await ApiService.getCustomerStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _stats = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal Memuat Data: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: darkLuxe,
      appBar: AppBar(
        backgroundColor: darkLuxe,
        elevation: 0,
        title: Text(
          'CUSTOMER SUITE',
          style: GoogleFonts.montserrat(color: gold, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 4),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: gold),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _fetchDashboardData),
        ],
      ),
      drawer: widget.showDrawer ? _buildCustomerDrawer(context, lang) : null,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: gold))
            : _stats == null
                ? _buildErrorPlaceholder()
                : RefreshIndicator(
                    onRefresh: _fetchDashboardData,
                    color: gold,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── BAGIAN 1: PESANAN AKTIF SAYA (prioritas utama) ───
                          _buildSectionHeader('PESANAN AKTIF SAYA', gold),
                          const SizedBox(height: 12),

                          if (_stats!['activeOrder'] != null)
                            _buildActiveOrderCard(_stats!['activeOrder'])
                          else
                            _buildNoActiveOrderBanner(),

                          const SizedBox(height: 32),

                          // ─── BAGIAN 2: RINGKASAN AKTIVITAS ───
                          _buildSectionHeader('RINGKASAN AKTIVITAS', gold),
                          const SizedBox(height: 16),

                          // Total Belanja (highlight utama)
                          _buildTotalSpentCard(),

                          const SizedBox(height: 16),

                          // Grid statistik 3 kolom
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                            children: [
                              _buildStatCard(
                                'TOTAL PESANAN',
                                _stats!['totals']['orders'].toString(),
                                Icons.shopping_basket_outlined,
                                gold,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen(initialStatus: 'ALL'))),
                              ),
                              _buildStatCard(
                                'SEDANG PROSES',
                                _stats!['totals']['pending'].toString(),
                                Icons.pending_actions,
                                Colors.orangeAccent,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen(initialStatus: 'ACTIVE'))),
                              ),
                              _buildStatCard(
                                'SELESAI',
                                _stats!['totals']['completed'].toString(),
                                Icons.check_circle_outline,
                                Colors.greenAccent,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen(initialStatus: 'COMPLETED'))),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // ─── BAGIAN 3: RIWAYAT PESANAN ───
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader('RIWAYAT PESANAN', gold),
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
                                child: Text('LIHAT SEMUA', style: TextStyle(color: gold, fontSize: 10, letterSpacing: 1)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_stats!['recentOrders'].isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: Text('Belum ada riwayat pesanan', style: TextStyle(color: Colors.white24, fontSize: 12)),
                              ),
                            )
                          else
                            ...(_stats!['recentOrders'] as List).map((order) => _buildOrderRow(order)),

                          const SizedBox(height: 24),

                          // ─── TOMBOL JELAJAH ───
                          _buildExploreButton(context),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ).animate().fadeIn(duration: 600.ms),
                  ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BAGIAN 1 WIDGETS: Pesanan Aktif
  // ─────────────────────────────────────────────────────────────

  /// Card utama yang LANGSUNG menampilkan status pesanan aktif customer
  Widget _buildActiveOrderCard(dynamic order) {
    final info = _getStatusInfo(order['status']);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrdersScreen(initialStatus: 'ACTIVE')),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: info.color.withOpacity(0.06),
          border: Border.all(color: info.color.withOpacity(0.35), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.track_changes, color: info.color, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'PESANAN #${order['id']}',
                    style: GoogleFonts.montserrat(color: info.color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: info.color.withOpacity(0.5), size: 13),
              ],
            ),
            const SizedBox(height: 14),

            // Nama produk
            Text(
              order['produk'] ?? '-',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Status dalam bahasa manusia
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: info.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                info.label,
                style: TextStyle(color: info.color, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),

            // Progress bar
            Stack(
              children: [
                Container(height: 5, width: double.infinity, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3))),
                FractionallySizedBox(
                  widthFactor: info.progress,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: info.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(info.description, style: const TextStyle(color: Colors.white38, fontSize: 9)),
                Text('${(info.progress * 100).toInt()}%', style: TextStyle(color: info.color, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),

            // Tombol aksi kontekstual
            if (info.actionLabel != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen(initialStatus: 'ACTIVE')),
                  ),
                  icon: Icon(info.actionIcon!, size: 16),
                  label: Text(
                    info.actionLabel!,
                    style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: info.color,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            // Tombol detail pelacakan (jika sudah dikirim)
            if (order['status'] == 'SHIPPED' || order['status'] == 'DELIVERED') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TrackingScreen(orderId: order['id'])),
                  ),
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: Text(
                    'DETAIL PELACAKAN',
                    style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.tealAccent,
                    side: const BorderSide(color: Colors.tealAccent, width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildNoActiveOrderBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, color: gold.withOpacity(0.4), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tidak ada pesanan aktif', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Mulai belanja untuk memesan produk tenun', style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen(showDrawer: false))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.1),
                border: Border.all(color: gold.withOpacity(0.4), width: 0.8),
              ),
              child: Text('BELANJA', style: GoogleFonts.montserrat(color: gold, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BAGIAN 2 WIDGETS: Ringkasan Aktivitas
  // ─────────────────────────────────────────────────────────────

  Widget _buildTotalSpentCard() {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen(initialStatus: 'ALL'))),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gold.withOpacity(0.12), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: gold.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, color: gold, size: 20),
                const SizedBox(width: 10),
                Text('TOTAL BELANJA SAYA', style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              Globals.formatRupiah(_stats!['totals']['spent']),
              style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('dari semua pesanan', style: TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color.withOpacity(0.6), size: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 8, letterSpacing: 0.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BAGIAN 3 WIDGETS: Riwayat Pesanan
  // ─────────────────────────────────────────────────────────────

  Widget _buildOrderRow(dynamic order) {
    DateTime? date;
    String formattedDate = '';
    try {
      date = DateTime.parse(order['tanggal'].toString());
      formattedDate = DateFormat('dd MMM yyyy').format(date);
    } catch (_) {}

    final info = _getStatusInfo(order['status'] ?? '');

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pesanan #${order['id']}', style: GoogleFonts.montserrat(color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(formattedDate, style: const TextStyle(color: Colors.white24, fontSize: 9)),
              ],
            ),
            const SizedBox(height: 8),
            // Nama produk sebagai informasi utama
            Text(
              order['produk'] ?? '-',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${Globals.formatRupiah(order['total'])}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: info.color.withOpacity(0.12),
                    border: Border.all(color: info.color.withOpacity(0.3), width: 0.5),
                  ),
                  child: Text(
                    info.label,
                    style: TextStyle(color: info.color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  // ─────────────────────────────────────────────────────────────
  // SHARED WIDGETS
  // ─────────────────────────────────────────────────────────────

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

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
          const SizedBox(height: 16),
          const Text('Gagal Memuat Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextButton(onPressed: _fetchDashboardData, child: const Text('COBA LAGI', style: TextStyle(color: gold))),
        ],
      ),
    );
  }

  Widget _buildExploreButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.grid_view_outlined, size: 18),
        label: Text('JELAJAHI KOLEKSI TERBARU', style: GoogleFonts.montserrat(fontSize: 11, letterSpacing: 3)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: gold, width: 0.8),
          foregroundColor: gold,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen(showDrawer: false)),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STATUS HELPER — Konversi kode status ke bahasa manusia
  // ─────────────────────────────────────────────────────────────

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'PENDING':
        return _StatusInfo(
          color: Colors.orange,
          label: 'Menunggu Pembayaran DP',
          description: 'Silakan lakukan pembayaran DP untuk memulai produksi',
          progress: 0.15,
          actionLabel: 'BAYAR DP SEKARANG',
          actionIcon: Icons.payment,
        );
      case 'DP_PAID':
        return _StatusInfo(
          color: Colors.amber,
          label: 'DP Dibayar — Menunggu Konfirmasi Penjual',
          description: 'Penjual sedang memverifikasi pembayaran DP kamu',
          progress: 0.35,
        );
      case 'VERIFIED':
        return _StatusInfo(
          color: Colors.lightBlueAccent,
          label: 'DP Dikonfirmasi — Dalam Produksi',
          description: 'Produk kamu sedang dibuat oleh pengrajin',
          progress: 0.5,
        );
      case 'PROCESSED':
        return _StatusInfo(
          color: Colors.blueAccent,
          label: 'Produksi Selesai — Silakan Lunasi',
          description: 'Produk selesai, lakukan pembayaran pelunasan',
          progress: 0.65,
          actionLabel: 'BAYAR PELUNASAN',
          actionIcon: Icons.payment,
        );
      case 'FULL_PAY_PAID':
        return _StatusInfo(
          color: Colors.purpleAccent,
          label: 'Pelunasan Dibayar — Menunggu Konfirmasi',
          description: 'Penjual sedang memverifikasi pembayaran pelunasan',
          progress: 0.75,
        );
      case 'PAID':
        return _StatusInfo(
          color: Colors.blue,
          label: 'Lunas — Menunggu Pengiriman',
          description: 'Pesanan akan segera dikirim ke alamat kamu',
          progress: 0.82,
        );
      case 'SHIPPED':
        return _StatusInfo(
          color: Colors.tealAccent,
          label: 'Dalam Perjalanan',
          description: 'Pesanan sedang dalam pengiriman',
          progress: 0.9,
        );
      case 'DELIVERED':
        return _StatusInfo(
          color: Colors.greenAccent,
          label: 'Telah Sampai di Tujuan',
          description: 'Pesanan sudah diterima',
          progress: 1.0,
        );
      case 'COMPLETED':
        return _StatusInfo(
          color: Colors.green,
          label: 'Selesai',
          description: 'Pesanan telah selesai',
          progress: 1.0,
        );
      case 'CANCELLED':
        return _StatusInfo(
          color: Colors.redAccent,
          label: 'Dibatalkan',
          description: 'Pesanan ini telah dibatalkan',
          progress: 0.0,
        );
      default:
        return _StatusInfo(
          color: Colors.white38,
          label: status,
          description: '',
          progress: 0.0,
        );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DRAWER
  // ─────────────────────────────────────────────────────────────

  Widget _buildCustomerDrawer(BuildContext context, LanguageProvider lang) {
    return Drawer(
      child: Container(
        color: darkLuxe,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: gold.withOpacity(0.1)))),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_pin, color: gold, size: 40),
                    const SizedBox(height: 12),
                    Text('CUSTOMER SUITE', style: GoogleFonts.montserrat(color: gold, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 3)),
                  ],
                ),
              ),
            ),

            _drawerTile(Icons.dashboard_outlined, 'DASHBOARD SAYA', gold, () => Navigator.pop(context)),
            _drawerTile(Icons.grid_view_outlined, 'KATALOG PRODUK', gold, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen(showDrawer: false)));
            }),

            const Divider(color: Colors.white10, height: 40),

            _drawerTile(Icons.shopping_bag_outlined, 'PESANAN SAYA', gold, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
            }),
            _drawerTile(Icons.rate_review_outlined, 'ULASAN SAYA', gold, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReviewsScreen()));
            }),
            _drawerTile(Icons.person_outline, 'PROFIL SAYA', gold, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),

            const Spacer(),

            _buildLanguageSelector(gold, lang),
            const Divider(color: Colors.white10),

            _drawerTile(Icons.logout, lang.translate('exit_suite'), Colors.redAccent.withOpacity(0.8), () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color.withOpacity(0.8), size: 20),
      title: Text(title, style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10, letterSpacing: 2)),
      onTap: onTap,
    );
  }

  Widget _buildLanguageSelector(Color color, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: color.withOpacity(0.6), size: 16),
              const SizedBox(width: 12),
              Text(lang.translate('language').toUpperCase(), style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _langBtn('ID', lang.currentLocale.languageCode == 'id', () => lang.changeLanguage('id'), color),
              const SizedBox(width: 8),
              _langBtn('EN', lang.currentLocale.languageCode == 'en', () => lang.changeLanguage('en'), color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _langBtn(String label, bool isActive, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          border: Border.all(color: color, width: 0.5),
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.black : color, fontSize: 8, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DATA CLASS untuk informasi status pesanan
// ─────────────────────────────────────────────────────────────

class _StatusInfo {
  final Color color;
  final String label;       // Bahasa manusia (bukan kode teknis)
  final String description; // Penjelasan apa yang sedang terjadi
  final double progress;    // 0.0 - 1.0 untuk progress bar
  final String? actionLabel;  // Tombol aksi jika ada
  final IconData? actionIcon;

  _StatusInfo({
    required this.color,
    required this.label,
    required this.description,
    required this.progress,
    this.actionLabel,
    this.actionIcon,
  });
}
