import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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
    const gold = Color(0xFFA67C1E);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: gold,
          unselectedItemColor: Colors.black38,
          selectedLabelStyle: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
          unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 8, letterSpacing: 1),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'DASHBOARD'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'PRODUK'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'USER'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'PESANAN'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'AKUN'),
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

  int _revenueDays = 7;
  bool _showCustomMonth = false;
  DateTime _chartMonth = DateTime.now();
  List<_RevenueDataPoint>? _monthPoints;
  double _monthTotal = 0.0;
  bool _isFetchingMonth = false;

  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _bankAccountCtrl = TextEditingController();
  final TextEditingController _accountNameCtrl = TextEditingController();

  static const gold = Color(0xFFA67C1E);
  static const darkSuite = Color(0xFFF9FAFC);

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
            label: 'LAPORAN KEUANGAN',
            subtitle: 'Analisis & grafik transaksi',
            icon: Icons.analytics_outlined,
            color: gold,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminFinanceScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickMenuButton(
            label: 'PENGATURAN REKENING',
            subtitle: 'Kelola Bank & QRIS platform',
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
          color: Colors.white,
          border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
          ],
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
                      color: Colors.black87,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 7.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Center(
                  child: Text('PENGATURAN REKENING & QRIS',
                      style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                const SizedBox(height: 4),
                const Center(child: Text('Info ini akan ditampilkan kepada pembeli saat melakukan transfer manual.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 10))),
                const SizedBox(height: 28),

                _buildSettingField(_bankNameCtrl, 'Nama Bank', 'Contoh: BCA, Mandiri, BRI, BNI', gold),
                const SizedBox(height: 16),
                _buildSettingField(_bankAccountCtrl, 'Nomor Rekening', 'Contoh: 1234567890', gold, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildSettingField(_accountNameCtrl, 'Nama Pemilik Rekening', 'Contoh: TENUN GEZA OFFICIAL', gold),
                const SizedBox(height: 24),

                const Text('Gambar QRIS', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
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
                          : Colors.black.withOpacity(0.02),
                      border: Border.all(
                        color: (qrisImageUrl != null && qrisImageUrl!.isNotEmpty)
                            ? gold.withOpacity(0.4)
                            : Colors.black12,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isUploadingQris
                        ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFFA67C1E), strokeWidth: 2)))
                        : (qrisImageUrl != null && qrisImageUrl!.isNotEmpty)
                            ? Column(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    ApiService.getFormattedImageUrl(qrisImageUrl),
                                    height: 160, fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Colors.black26, size: 40),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Ketuk untuk ganti gambar QRIS', style: TextStyle(color: gold.withOpacity(0.7), fontSize: 10)),
                              ])
                            : Column(children: [
                                const Icon(Icons.qr_code_2, color: Colors.black38, size: 40),
                                const SizedBox(height: 8),
                                const Text('Ketuk untuk upload gambar QRIS dari galeri', style: TextStyle(color: Colors.black54, fontSize: 11)),
                                const SizedBox(height: 4),
                                const Text('JPG / PNG • Maks 5MB', style: TextStyle(color: Colors.black38, fontSize: 10)),
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
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.black87, fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 11),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: gold),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
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
          color: Colors.white,
          border: Border.all(
            color: Colors.black.withOpacity(0.06),
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: accentColor, size: 13),
                if (onTap != null)
                  const Icon(Icons.arrow_forward_ios, color: Colors.black26, size: 7),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    color: Colors.black54,
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
                    color: Colors.black87,
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
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
                            color: Colors.black87,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'PESANAN',
                          style: GoogleFonts.montserrat(
                            color: Colors.black45,
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
                            color: Colors.black54,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        '${s.count} ($percentage%)',
                        style: GoogleFonts.montserrat(
                          color: Colors.black87,
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
          backgroundColor: Colors.white,
          elevation: 0,
          shape: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05), width: 0.8)),
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
                  child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 15),
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
                        style: GoogleFonts.playfairDisplay(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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

                    // ─── BAGIAN: PERLU TINDAKAN SEGERA ───
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

                    // ─── QUICK SHORTCUTS MENU BAR ───
                    _buildQuickMenuBar(),
                    const SizedBox(height: 24),

                    // ─── BAGIAN 1: KESEHATAN PLATFORM ───
                    _buildSectionHeader('KESEHATAN PLATFORM', gold),
                    const SizedBox(height: 12),
                    _buildPlatformSummaryCards(),

                    const SizedBox(height: 28),

                    // ─── GRAFIK TREN PENDAPATAN ───
                    _buildSectionHeader('TREN PENDAPATAN', gold),
                    const SizedBox(height: 14),
                    _buildRevenueLineChart(),

                    const SizedBox(height: 28),

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
                          child: Text('Belum ada pesanan', style: TextStyle(color: Colors.black38)),
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
          style: GoogleFonts.montserrat(color: color, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w600),
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
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
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
                    style: GoogleFonts.playfairDisplay(color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(description, style: const TextStyle(color: Colors.black54, fontSize: 10)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 14),
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
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
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
                  style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  'Total: ${Globals.formatRupiah(order['totalPrice'])}',
                  style: const TextStyle(color: Colors.black54, fontSize: 10),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
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
        final rawDate = order['createdAt']?.toString() ?? order['tanggal']?.toString() ?? '';
        final date = DateTime.parse(rawDate);
        final key = dayFmt.format(date);
        if (grouped.containsKey(key)) {
          double amount = ((order['totalPrice'] ?? order['total']) as num?)?.toDouble() ?? 0.0;
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
      backgroundColor: Colors.white,
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
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text(
                    'PILIH BULAN GRAFIK',
                    style: GoogleFonts.montserrat(
                      color: Colors.black87,
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
                      style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _showCustomMonth = false;
                      });
                    },
                  ),
                  const Divider(color: Colors.black12),
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
                          color: isSelected ? gold : Colors.black87,
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
            color: isSelected ? gold.withOpacity(0.4) : Colors.black.withOpacity(0.1),
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            color: isSelected ? gold : Colors.black54,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
                        color: Colors.black54,
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
      ..color = Colors.black.withOpacity(0.06)
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
      ..color = Colors.black.withOpacity(0.05)
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
      ..color = Colors.black.withOpacity(0.12)
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
          color: Colors.black45,
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
