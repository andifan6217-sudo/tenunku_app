import 'dart:ui';
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

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await ApiService.getAdminStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal Memuat Statistik')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const darkSuite = Color(0xFF0F0B1E);

    return Scaffold(
      backgroundColor: darkSuite,
      appBar: AppBar(
        backgroundColor: darkSuite,
        elevation: 0,
        title: Text('ADMIN EXECUTIVE', style: GoogleFonts.montserrat(color: gold, fontWeight: FontWeight.bold, letterSpacing: 4, fontSize: 14)),
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RINGKASAN EKSEKUTIF', style: GoogleFonts.montserrat(color: gold.withOpacity(0.6), fontSize: 10, letterSpacing: 4)),
                    const SizedBox(height: 20),
                    
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard('PENGGUNA', _stats!['totals']['users'].toString(), Icons.people_outline, gold),
                        _buildStatCard('PRODUK', _stats!['totals']['products'].toString(), Icons.inventory_2_outlined, gold),
                        _buildStatCard('TOTAL PESANAN', _stats!['totals']['orders'].toString(), Icons.shopping_bag_outlined, gold),
                        _buildStatCard('TERPROSES', _stats!['totals']['processed'].toString(), Icons.verified_outlined, gold),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    _buildStatCard('MENUNGGU DP (BELUM VERIFIKASI)', _stats!['totals']['unverified'].toString(), Icons.payment_outlined, Colors.orangeAccent, fullWidth: true),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFinanceScreen())),
                      child: _buildStatCard(
                        'KEUANGAN & ARUS DP (KLIK UNTUK DETAIL)',
                        'Buka Pembayaran & Keuangan',
                        Icons.account_balance_wallet_outlined,
                        gold,
                        fullWidth: true,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text('PESANAN TERBARU', style: GoogleFonts.montserrat(color: gold.withOpacity(0.6), fontSize: 10, letterSpacing: 4)),
                    const SizedBox(height: 16),
                    
                    if (_stats!['recentOrders'].isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Tiada pesanan baru', style: TextStyle(color: Colors.white24))))
                    else
                      ...(_stats!['recentOrders'] as List).map((order) {
                        return _buildRecentOrderTile(order, gold);
                      }),
                      
                    const SizedBox(height: 40),
                    _buildAdminAction(Icons.add_circle_outline, 'TAMBAH KOLEKSI MASTERPIECE', () => _showAddProductDialog(context, gold, darkSuite)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 9, letterSpacing: 1), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildRecentOrderTile(dynamic order, Color gold) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: gold.withOpacity(0.1), child: Text(order['id'].toString(), style: TextStyle(color: gold, fontSize: 12))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['user']['name'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                Text('Total: ${Globals.formatRupiah(order['totalPrice'])}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: order['status'] == 'PENDING' ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
            child: Text(order['status'], style: TextStyle(color: order['status'] == 'PENDING' ? Colors.orange : Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildAdminAction(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label, style: GoogleFonts.montserrat(fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w400)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD4AF37), width: 0.5),
          foregroundColor: const Color(0xFFD4AF37),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
        onPressed: onTap,
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, Color gold, Color darkBg) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    final stockCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: darkBg.withOpacity(0.9),
            shape: const RoundedRectangleBorder(side: BorderSide(color: Color(0xFFD4AF37), width: 0.5), borderRadius: BorderRadius.zero),
            title: Text('Koleksi Baru', style: GoogleFonts.playfairDisplay(color: gold, fontSize: 24)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogInput(nameCtrl, 'NAMA ITEM', gold),
                  _dialogInput(descCtrl, 'DESKRIPSI', gold),
                  _dialogInput(priceCtrl, 'HARGA (Rp)', gold, type: TextInputType.number),
                  _dialogInput(imageCtrl, 'URL GAMBAR', gold),
                  _dialogInput(stockCtrl, 'JUMLAH STOK', gold, type: TextInputType.number),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL', style: TextStyle(color: Colors.white24))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0))),
                onPressed: () async {
                  try {
                    await ApiService.addProduct(nameCtrl.text, descCtrl.text, int.parse(priceCtrl.text), imageCtrl.text, int.parse(stockCtrl.text));
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _fetchStats();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koleksi Berhasil Disimpan')));
                    }
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan')));
                  }
                },
                child: const Text('SIMPAN ITEM'),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _dialogInput(TextEditingController ctrl, String label, Color gold, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: gold.withOpacity(0.4), fontSize: 9, letterSpacing: 2),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold.withOpacity(0.1))),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold)),
      ),
    );
  }
}
