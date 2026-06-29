import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'language_provider.dart';
import 'api_service.dart';
import 'orders_screen.dart';
import 'login_screen.dart';
import 'seller_products_screen.dart';
import 'buyer_profile_screen.dart';
import 'tracking_screen.dart';
import 'globals.dart';

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
    const SellerMonitorTab(),
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
            BottomNavigationBarItem(icon: Icon(Icons.verified_user_outlined), activeIcon: Icon(Icons.verified_user), label: 'MONITOR'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'PROFIL'),
          ],
        ),
      ),
    );
  }
}

class SellerStudioTab extends StatefulWidget {
  const SellerStudioTab({super.key});

  @override
  State<SellerStudioTab> createState() => _SellerStudioTabState();
}

class _SellerStudioTabState extends State<SellerStudioTab> {
  Map<String, dynamic>? _stats;
  List<dynamic> _dpOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
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
    const gold = Color(0xFFD4AF37);
    const darkStudio = Color(0xFF0F0B1E);

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
                ? Center(
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
                  )
                : RefreshIndicator(
                    onRefresh: _fetchStats,
                    color: gold,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RINGKASAN BISNIS', style: GoogleFonts.montserrat(color: gold.withOpacity(0.6), fontSize: 10, letterSpacing: 4)),
                          const SizedBox(height: 20),
                          
                          Row(
                            children: [
                              Expanded(child: _buildMainStat('PENDAPATAN', Globals.formatRupiah(_stats!['totals']['revenue']), gold, Icons.account_balance_wallet_outlined)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildMainStat('PERTUMBUHAN', _stats!['totals']['growth'], Colors.greenAccent, Icons.trending_up)),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          Text('MONITORING AKTIF', style: GoogleFonts.montserrat(color: gold.withOpacity(0.6), fontSize: 10, letterSpacing: 4)),
                          const SizedBox(height: 16),
                          _buildAlertStat('PESANAN PERLU VERIFIKASI', ((_stats!['totals']['dpPendingVerification'] ?? 0) + (_stats!['totals']['fullPayPendingVerification'] ?? 0)).toString(), Icons.verified_user_outlined, Colors.amber),
                          const SizedBox(height: 12),
                          _buildAlertStat('PESANAN DALAM PRODUKSI', (_stats!['totals']['verified'] ?? 0).toString(), Icons.engineering_outlined, Colors.lightBlueAccent),
                          
                          const SizedBox(height: 32),

                          if (_dpOrders.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('VERIFIKASI DP (CEPAT)', style: GoogleFonts.montserrat(color: Colors.amber, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.bold)),
                                Text('${_dpOrders.length}', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._dpOrders.map((order) => _buildDPVerificationCard(order, gold)),
                            const SizedBox(height: 16),
                          ],
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('PESANAN TERBARU', style: GoogleFonts.montserrat(color: gold.withOpacity(0.6), fontSize: 10, letterSpacing: 4)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          if (_stats!['recentOrders'].isEmpty)
                            const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Belum ada pesanan', style: TextStyle(color: Colors.white24, fontSize: 12))))
                          else
                            ...(_stats!['recentOrders'] as List).map((order) => _buildOrderRow(order, gold)),
                            
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildMainStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 16),
          Text(label, style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 9, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildAlertStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10))),
          Text(value, style: GoogleFonts.montserrat(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOrderRow(dynamic order, Color gold) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ORD-${order['id']}', style: GoogleFonts.montserrat(color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(order['pelanggan'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(Globals.formatRupiah(order['total']), style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDPVerificationCard(dynamic order, Color gold) {
    final userName = order['user']?['name'] ?? 'Pelanggan';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.05),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(userName.toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(Globals.formatRupiah(order['dpAmount']), style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text('VERIFIKASI', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectOrder(order['id']),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                  child: const Text('TOLAK', style: TextStyle(fontSize: 10)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

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
              const Divider(height: 32, color: Colors.white10),
              Row(
                children: [
                  Expanded(child: ElevatedButton(onPressed: () async {
                    try {
                       if (isFull) await ApiService.verifyFinalPayment(order['id']);
                       else await ApiService.verifyOrder(order['id']);
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
            Icon(Icons.location_off, color: Colors.white24, size: 12),
            const SizedBox(width: 4),
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
                Text('${addr['name']} \u2022 ${addr['phone']}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
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
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.white24, size: 12),
            const SizedBox(width: 4),
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
                Text('${addr['name']} \u2022 ${addr['phone']}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
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
                    trackingStatus: statusCtrl.text
                  );
                  await ApiService.updateOrderStatus(orderId, 'SHIPPED');
                  Navigator.pop(ctx);
                  _fetch();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Info pengiriman berhasil diupdate!')));
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                }
              }, 
              child: const Text('UPDATE', style: TextStyle(color: Color(0xFFD4AF37)))
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
              // Production/Shipping Actions
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
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.white24, size: 12),
            const SizedBox(width: 4),
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
