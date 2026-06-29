import 'dart:ui';
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

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal Memuat Data Pelanggan: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const darkLuxe = Color(0xFF0F0918);
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: darkLuxe,
      appBar: AppBar(
        backgroundColor: darkLuxe,
        elevation: 0,
        title: Text('CUSTOMER SUITE', style: GoogleFonts.montserrat(color: gold, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 4)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: gold),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _fetchDashboardData),
        ],
      ),
      drawer: widget.showDrawer ? _buildCustomerDrawer(context, gold, darkLuxe, lang) : null,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: gold))
            : _stats == null
                ? _buildErrorPlaceholder(gold)
                : RefreshIndicator(
                    onRefresh: _fetchDashboardData,
                    color: gold,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RINGKASAN AKTIVITAS', style: GoogleFonts.montserrat(color: gold.withOpacity(0.6), fontSize: 10, letterSpacing: 4)),
                          const SizedBox(height: 20),
                          
                          // 1. Total Belanja (Main Stat)
                          _buildMainStat(
                            'TOTAL BELANJA', 
                            Globals.formatRupiah(_stats!['totals']['spent']), 
                            gold, 
                            Icons.account_balance_wallet_outlined,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen(initialStatus: 'ALL'))),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // 2, 3, 4. Grid of stats
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
                                'PESANAN AKTIF', 
                                _stats!['totals']['pending'].toString(), 
                                Icons.pending_actions, 
                                Colors.orangeAccent,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen(initialStatus: 'ACTIVE'))),
                              ),
                              _buildStatCard(
                                'PESANAN SELESAI', 
                                _stats!['totals']['completed'].toString(), 
                                Icons.check_circle_outline, 
                                Colors.greenAccent,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen(initialStatus: 'COMPLETED'))),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Active Monitoring / Alert section
                          Text('PROGRES SAAT INI', style: GoogleFonts.montserrat(color: gold.withOpacity(0.6), fontSize: 10, letterSpacing: 4)),
                          const SizedBox(height: 16),
                          
                          if (_stats!['activeOrder'] != null)
                             _buildActiveTrackingCard(_stats!['activeOrder'], gold)
                          else
                            _buildAlertStat(
                              'PESANAN DALAM PROSES', 
                              _stats!['totals']['pending'].toString(), 
                              Icons.pending_actions, 
                              Colors.orangeAccent,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen(initialStatus: 'ACTIVE'))),
                            ),
                          
                          const SizedBox(height: 48),
                          
                          // RIWAYAT PESANAN (Recent Orders)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('RIWAYAT PESANAN', style: GoogleFonts.montserrat(color: gold.withOpacity(0.6), fontSize: 10, letterSpacing: 4)),
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
                                child: Text('LIHAT SEMUA', style: TextStyle(color: gold, fontSize: 10, letterSpacing: 1)),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          if (_stats!['recentOrders'].isEmpty)
                             const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Belum ada riwayat pesanan', style: TextStyle(color: Colors.white24, fontSize: 12))))
                          else
                            ...(_stats!['recentOrders'] as List).map((order) => _buildOrderRow(order, gold, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
                            })),
                          
                          const SizedBox(height: 40),
                          _buildExploreButton(gold, context),
                        ],
                      ),
                    ).animate().fadeIn(duration: 600.ms),
                  ),
      ),
    );
  }

  Widget _buildActiveTrackingCard(dynamic order, Color gold) {
    String stepText = "";
    double progress = 0.0;
    Color stepColor = Colors.orangeAccent;

    switch (order['status']) {
      case 'PENDING':
        stepText = "Menunggu Pembayaran DP";
        progress = 0.15;
        break;
      case 'DP_PAID':
        stepText = "DP Dibayar — Menunggu Verifikasi Penjual";
        progress = 0.35;
        stepColor = Colors.amber;
        break;
      case 'VERIFIED':
        stepText = "DP Terverifikasi — Sedang Diproses";
        progress = 0.5;
        stepColor = Colors.lightBlueAccent;
        break;
      case 'PAID':
        stepText = "Pesanan Sedang Diproses";
        progress = 0.6;
        stepColor = Colors.blueAccent;
        break;
      case 'SHIPPED':
        stepText = "Pesanan Dalam Pengiriman";
        progress = 0.8;
        stepColor = Colors.tealAccent;
        break;
      case 'DELIVERED':
        stepText = "Pesanan Telah Sampai";
        progress = 1.0;
        stepColor = Colors.greenAccent;
        break;
    }

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen(initialStatus: 'ACTIVE'))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: stepColor.withOpacity(0.05),
          border: Border.all(color: stepColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, color: stepColor, size: 20),
                const SizedBox(width: 12),
                Text('PELACAKAN PESANAN #${order['id']}', style: GoogleFonts.montserrat(color: stepColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 16),
            Text(order['produk'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(stepText, style: TextStyle(color: stepColor.withOpacity(0.8), fontSize: 12)),
            const SizedBox(height: 20),
            
            // Progress Bar
            Stack(
              children: [
                Container(height: 4, width: double.infinity, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(height: 4, decoration: BoxDecoration(color: stepColor, borderRadius: BorderRadius.circular(2))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status: ${order['status']}', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                Text('${(progress * 100).toInt()}%', style: TextStyle(color: stepColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
            // Tombol Lihat Peta untuk pesanan yang sudah dikirim
            if (order['status'] == 'SHIPPED' || order['status'] == 'DELIVERED') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TrackingScreen(orderId: order['id'])),
                  ),
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: Text('DETAIL PELACAKAN', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildErrorPlaceholder(Color gold) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
          const SizedBox(height: 16),
          const Text('Gagal Memuat Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextButton(onPressed: _fetchDashboardData, child: Text('COBA LAGI', style: TextStyle(color: gold))),
        ],
      ),
    );
  }

  Widget _buildMainStat(String label, String value, Color color, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), Colors.transparent], 
            begin: Alignment.topLeft, 
            end: Alignment.bottomRight
          ),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 20),
            Text(label, style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color.withOpacity(0.6), size: 16),
            const SizedBox(height: 12),
            Text(label, style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 8, letterSpacing: 1), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertStat(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500))),
            Text(value, style: GoogleFonts.montserrat(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildOrderRow(dynamic order, Color gold, {VoidCallback? onTap}) {
    DateTime? date;
    String formattedDate = '';
    try {
      date = DateTime.parse(order['tanggal']);
      formattedDate = DateFormat('dd MMM yyyy').format(date);
    } catch (_) {}

    return InkWell(
      onTap: onTap,
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
                Text('ID: #${order['id']}', style: GoogleFonts.montserrat(color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(formattedDate, style: const TextStyle(color: Colors.white24, fontSize: 9)),
              ],
            ),
            const SizedBox(height: 12),
            Text(order['produk'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${Globals.formatRupiah(order['total'])}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['status']).withOpacity(0.12),
                    border: Border.all(color: _getStatusColor(order['status']).withOpacity(0.3), width: 0.5),
                  ),
                  child: Text(
                    order['status'],
                    style: TextStyle(color: _getStatusColor(order['status']), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'DP_PAID': return Colors.amber;
      case 'VERIFIED': return Colors.lightBlueAccent;
      case 'PAID': return Colors.blue;
      case 'COMPLETED': return Colors.green;
      case 'DELIVERED': return Colors.teal;
      case 'CANCELLED': return Colors.red;
      default: return Colors.white38;
    }
  }

  Widget _buildExploreButton(Color gold, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.grid_view_outlined, size: 18),
        label: Text('JELAJAHI KOLEKSI TERBARU', style: GoogleFonts.montserrat(fontSize: 11, letterSpacing: 4)),
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

  Widget _buildCustomerDrawer(BuildContext context, Color gold, Color darkLuxe, LanguageProvider lang) {
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
              if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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

  Widget _buildLanguageSelector(Color gold, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: gold.withOpacity(0.6), size: 16),
              const SizedBox(width: 12),
              Text(lang.translate('language').toUpperCase(), style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _langBtn('ID', lang.currentLocale.languageCode == 'id', () => lang.changeLanguage('id'), gold),
              const SizedBox(width: 8),
              _langBtn('EN', lang.currentLocale.languageCode == 'en', () => lang.changeLanguage('en'), gold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _langBtn(String label, bool isActive, VoidCallback onTap, Color gold) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? gold : Colors.transparent,
          border: Border.all(color: gold, width: 0.5),
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.black : gold, fontSize: 8, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
