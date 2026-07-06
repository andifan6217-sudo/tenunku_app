import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'buyer_profile_screen.dart';
import 'my_reviews_screen.dart';
import 'api_service.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'globals.dart';
import 'login_screen.dart';
import 'customer_dashboard.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final String? initialSearch;
  final String? initialCategory;
  final bool showDrawer;
  const HomeScreen({super.key, this.initialSearch, this.initialCategory, this.showDrawer = true});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _allProducts = [];
  List<dynamic> _products = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'SEMUA';

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
    }
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchProducts() async {
    try {
      final products = await ApiService.getProducts();
      setState(() {
        _allProducts = products;
        _products = products;
        _isLoading = false;
        _filterProducts();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat produk. Periksa koneksi ke server. ($e)')),
        );
      }
    }
  }

  void _filterProducts() {
    setState(() {
      _products = _allProducts.where((p) {
        final name = p['name'].toString().toLowerCase();
        final search = _searchController.text.toLowerCase();
        final matchesSearch = name.contains(search);
        
        if (_selectedCategory == 'TENUN') {
          return matchesSearch && name.contains('tenun');
        } else if (_selectedCategory == 'SONGKET') {
          return matchesSearch && name.contains('songket');
        }
        return matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    const goldPrimary = Color(0xFFD4AF37);
    const darkLuxe = Color(0xFF1A1128);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0918),
      appBar: AppBar(
        backgroundColor: darkLuxe,
        elevation: 0,
        title: Text('TENUN GEZA', style: GoogleFonts.playfairDisplay(color: goldPrimary, fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 20)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: goldPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        ],
      ),
      drawer: widget.showDrawer ? _buildLuxeDrawer(darkLuxe, goldPrimary) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: goldPrimary, strokeWidth: 1))
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, color: goldPrimary.withOpacity(0.2), size: 60),
                      const SizedBox(height: 20),
                      Text('TIDAK DITEMUKAN', style: GoogleFonts.montserrat(color: goldPrimary.withOpacity(0.5), fontSize: 10, letterSpacing: 5)),
                      const SizedBox(height: 8),
                      Text('Coba kata kunci atau kategori lain', style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 8, letterSpacing: 1)),
                    ],
                  ).animate().fadeIn(),
                )
              : CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                // Horizontal Categories
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                    child: Row(
                      children: [
                        _categoryChip('SEMUA', Icons.all_inclusive_outlined, goldPrimary),
                        _categoryChip('TENUN', Icons.waves_outlined, goldPrimary),
                        _categoryChip('SONGKET', Icons.grid_view_outlined, goldPrimary),
                      ],
                    ),
                  ),
                ),
                // Search Bar in Body
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: goldPrimary.withOpacity(0.15), width: 0.8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                        onChanged: (_) => _filterProducts(),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          hintText: 'Cari koleksi masterpiece...',
                          hintStyle: GoogleFonts.montserrat(color: Colors.white30, fontSize: 10),
                          prefixIcon: const Icon(Icons.search, color: goldPrimary, size: 16),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                // Gallery Grid
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.6,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 32,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = _products[index];
                            return _buildGalleryItem(product, goldPrimary);
                          },
                          childCount: _products.length,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }


  Widget _buildGalleryItem(dynamic product, Color gold) {
    return InkWell(
      onTap: () => _showProductInfo(product, gold),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border:
                    Border.all(color: Colors.white.withOpacity(0.05), width: 1),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: product['imageUrl'] != null &&
                            product['imageUrl'].isNotEmpty
                        ? Image.network(
                            ApiService.getFormattedImageUrl(product['imageUrl']),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                                Icons.image_outlined,
                                color: Colors.white24))
                        : const Icon(Icons.image_outlined, color: Colors.white24),
                  ),
                  Positioned(
                      top: 10,
                      right: 10,
                      child: Icon(Icons.auto_awesome,
                          color: gold.withOpacity(0.4), size: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            product['name'].toString().toUpperCase(),
            style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            Globals.formatRupiah(product['price']),
            style: GoogleFonts.playfairDisplay(
                color: gold, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: gold.withOpacity(0.3), width: 0.5),
                      foregroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                    ),
                    onPressed: () => _showProductInfo(product, gold),
                    child: Text('DETAIL', style: GoogleFonts.montserrat(fontSize: 8, letterSpacing: 1)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold.withOpacity(0.8),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                      elevation: 0,
                    ),
                    onPressed: () => _showProductOrder(product, gold),
                    child: Text('PESAN', style: GoogleFonts.montserrat(fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }

  void _showProductInfo(dynamic product, Color gold) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductInfoSheet(product: product, gold: gold),
    );
  }

  void _showProductOrder(dynamic product, Color gold) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductOrderSheet(product: product, gold: gold),
    );
  }

  Widget _buildLuxeDrawer(Color darkLuxe, Color gold) {
    final lang = Provider.of<LanguageProvider>(context);
    return Drawer(
      child: Container(
        color: darkLuxe,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.blur_on_rounded, color: gold, size: 40),
                  const SizedBox(height: 16),
                  Text('TENUN GEZA', style: GoogleFonts.playfairDisplay(color: gold, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
                ],
              ),
            ),
            
            _drawerTile(Icons.dashboard_outlined, 'DASHBOARD PELANGGAN', gold, () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerDashboardScreen()));
            }),
            _drawerTile(Icons.grid_view_outlined, 'KATALOG PRODUK', gold, () {
              Navigator.pop(context);
              setState(() => _selectedCategory = 'SEMUA');
              _filterProducts();
            }),
            
            // Nested Categories
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Column(
                children: [
                  _drawerSubTile('KAIN TENUN', () {
                    Navigator.pop(context);
                    setState(() => _selectedCategory = 'TENUN');
                    _filterProducts();
                  }, gold),
                  _drawerSubTile('KAIN SONGKET', () {
                    Navigator.pop(context);
                    setState(() => _selectedCategory = 'SONGKET');
                    _filterProducts();
                  }, gold),
                ],
              ),
            ),
            
            const Divider(color: Colors.white10, height: 20),
            _drawerTile(Icons.history_edu_outlined, 'PESANAN SAYA', gold, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
            }),
            _drawerTile(Icons.rate_review_outlined, 'ULASAN SAYA', gold, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReviewsScreen()));
            }),
            _drawerTile(Icons.person_pin_outlined, 'PROFIL', gold, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
            const Divider(color: Colors.white10),
            _buildLanguageSelector(gold, lang),
            const SizedBox(height: 30),
            const Divider(color: Colors.white10),
            _drawerTile(Icons.power_settings_new_rounded, lang.translate('exit_suite'), gold, () async {
              await ApiService.logout();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String category, IconData icon, Color gold) {
    bool isActive = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          setState(() => _selectedCategory = category);
          _filterProducts();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: isActive ? gold : Colors.transparent,
            border: Border.all(color: gold.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(icon, color: isActive ? Colors.black : gold, size: 14),
              const SizedBox(width: 8),
              Text(category, style: GoogleFonts.montserrat(color: isActive ? Colors.black : gold, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, Color gold, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: gold.withOpacity(0.7), size: 20),
      title: Text(title, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 11, letterSpacing: 3)),
      onTap: onTap,
    );
  }

  Widget _drawerSubTile(String title, VoidCallback onTap, Color gold) {
    return ListTile(
      dense: true,
      title: Text(title, style: GoogleFonts.montserrat(color: Colors.white60, fontSize: 10, letterSpacing: 2)),
      onTap: onTap,
    );
  }

  Widget _buildLanguageSelector(Color gold, LanguageProvider lang) {
    return ListTile(
      leading: Icon(Icons.language, color: gold.withOpacity(0.7), size: 20),
      title: Text(lang.translate('language'), style: GoogleFonts.montserrat(color: Colors.white, fontSize: 11, letterSpacing: 3)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langBtn('ID', lang.currentLocale.languageCode == 'id', () => lang.changeLanguage('id'), gold),
          const SizedBox(width: 8),
          _langBtn('EN', lang.currentLocale.languageCode == 'en', () => lang.changeLanguage('en'), gold),
        ],
      ),
    );
  }

  Widget _langBtn(String label, bool isActive, VoidCallback onTap, Color gold) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? gold : Colors.transparent,
          border: Border.all(color: gold, width: 0.5),
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.black : gold, fontSize: 9, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class ProductOrderSheet extends StatefulWidget {
  final dynamic product;
  final Color gold;

  const ProductOrderSheet({super.key, required this.product, required this.gold});

  @override
  State<ProductOrderSheet> createState() => _ProductOrderSheetState();
}

class _ProductOrderSheetState extends State<ProductOrderSheet> {
  int _quantity = 1;
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _sizeCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _notesCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = (widget.product['price'] as num).toInt();
    double meters = double.tryParse(_sizeCtrl.text) ?? 1.0;
    final subtotal = (price * meters * _quantity).toInt();
    final dp = (subtotal * 0.5).toInt();
    final total = subtotal;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0918).withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: widget.gold.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: widget.gold.withOpacity(0.1)),
                      ),
                      child: widget.product['imageUrl'] != null && widget.product['imageUrl'].isNotEmpty
                          ? Image.network(ApiService.getFormattedImageUrl(widget.product['imageUrl']), fit: BoxFit.cover)
                          : const Icon(Icons.image_outlined, color: Colors.white24, size: 50),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(widget.product['name'].toString().toUpperCase(), style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Text(Globals.formatRupiah(widget.product['price']), style: GoogleFonts.playfairDisplay(color: widget.gold, fontSize: 24, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    
                    Text('DESKRIPSI', style: GoogleFonts.montserrat(color: widget.gold.withOpacity(0.5), fontSize: 10, letterSpacing: 3)),
                    const SizedBox(height: 8),
                    Text(widget.product['description'] ?? 'Tidak ada deskripsi untuk mahakarya ini.', style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
                    const SizedBox(height: 32),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('JUMLAH', style: GoogleFonts.montserrat(color: widget.gold.withOpacity(0.5), fontSize: 9, letterSpacing: 2)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _qtyBtn(Icons.remove, () { if (_quantity > 1) setState(() => _quantity--); }),
                                  const SizedBox(width: 16),
                                  Text('$_quantity', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 16),
                                  _qtyBtn(Icons.add, () => setState(() => _quantity++)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                         Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PANJANG (METER)', style: GoogleFonts.montserrat(color: widget.gold.withOpacity(0.5), fontSize: 9, letterSpacing: 2)),
                              TextField(
                                controller: _sizeCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                onChanged: (val) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Misal: 2.5',
                                  suffixText: 'Meter',
                                  suffixStyle: TextStyle(color: widget.gold, fontSize: 10),
                                  hintStyle: const TextStyle(color: Colors.white10),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.gold.withOpacity(0.2))),
                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.gold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Text('CATATAN (OPSIONAL)', style: GoogleFonts.montserrat(color: widget.gold.withOpacity(0.5), fontSize: 9, letterSpacing: 2)),
                    TextField(
                      controller: _notesCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Tuliskan permintaan khusus anda...',
                        hintStyle: const TextStyle(color: Colors.white10, fontSize: 13),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.gold.withOpacity(0.2))),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.gold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        border: Border.all(color: widget.gold.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          _summaryRow('Subtotal', Globals.formatRupiah(subtotal), Colors.white70),
                          const SizedBox(height: 8),
                          _summaryRow('DP (Tanda Jadi 50%)', Globals.formatRupiah(dp), widget.gold),
                          const Divider(color: Colors.white10, height: 24),
                          _summaryRow('Total Harga', Globals.formatRupiah(total), Colors.white, isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                  ),
                  onPressed: () {
                    final price = (widget.product['price'] as num).toInt();
                    final meters = double.tryParse(_sizeCtrl.text.trim());
                    if (meters == null || meters <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Masukkan panjang kain (meter) yang valid, misalnya 1 atau 2.5')),
                      );
                      return;
                    }
                    
                    Globals.cart.add({
                      'id': widget.product['id'],
                      'name': widget.product['name'],
                      'price': (price * meters).toInt(),
                      'quantity': _quantity,
                      'size': '${_sizeCtrl.text} Meter',
                      'notes': _notesCtrl.text,
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${widget.product['name']} ditambahkan ke pesanan'),
                      backgroundColor: widget.gold,
                    ));
                  },
                  child: Text('MASUKKAN KE PESANAN', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: widget.gold.withOpacity(0.3))),
        child: Icon(icon, color: widget.gold, size: 16),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.montserrat(color: color.withOpacity(0.6), fontSize: 11)),
        Text(value, style: GoogleFonts.montserrat(color: color, fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}

class ProductInfoSheet extends StatefulWidget {
  final dynamic product;
  final Color gold;
  const ProductInfoSheet({super.key, required this.product, required this.gold});

  @override
  State<ProductInfoSheet> createState() => _ProductInfoSheetState();
}

class _ProductInfoSheetState extends State<ProductInfoSheet> {
  Map<String, dynamic>? _fullProduct;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() async {
    try {
      final detail = await ApiService.getProductDetail(widget.product['id']);
      if (mounted) {
        setState(() {
        _fullProduct = detail;
        _loading = false;
      });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0918).withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: widget.gold.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: widget.gold))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 250,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: widget.gold.withOpacity(0.1))),
                            child: widget.product['imageUrl'] != null &&
                                    widget.product['imageUrl'].isNotEmpty
                                ? Image.network(
                                    ApiService.getFormattedImageUrl(
                                        widget.product['imageUrl']),
                                    fit: BoxFit.cover)
                                : const Icon(Icons.image_outlined,
                                    color: Colors.white24, size: 50),
                          ),
                          const SizedBox(height: 24),
                          Text(widget.product['name'].toString().toUpperCase(),
                              style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(Globals.formatRupiah(widget.product['price']),
                                  style: GoogleFonts.playfairDisplay(
                                      color: widget.gold,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text('${widget.product['rating'] ?? 5.0}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text('DESKRIPSI',
                              style: GoogleFonts.montserrat(
                                  color: widget.gold.withOpacity(0.5),
                                  fontSize: 10,
                                  letterSpacing: 3)),
                          const SizedBox(height: 12),
                          Text(widget.product['description'] ?? 'Tidak ada deskripsi.',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.6)),
                          const SizedBox(height: 32),
                          Text('ULASAN PEMBELI',
                              style: GoogleFonts.montserrat(
                                  color: widget.gold.withOpacity(0.5),
                                  fontSize: 10,
                                  letterSpacing: 3)),
                          const SizedBox(height: 16),
                          if (_fullProduct?['reviews'] == null ||
                              (_fullProduct?['reviews'] as List).isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                  child: Text(
                                      'Belum ada ulasan untuk mahakarya ini.',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.2),
                                          fontSize: 12))),
                            )
                          else
                            ...(_fullProduct!['reviews'] as List)
                                .map((rev) => _buildReviewItem(rev)),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(dynamic rev) {
    DateTime date = DateTime.tryParse(rev['createdAt'] ?? '') ?? DateTime.now();
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: widget.gold.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(rev['userName'] ?? 'Pembeli',
                  style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(DateFormat('d MMM yyyy').format(date),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
                5,
                (index) => Icon(Icons.star,
                    size: 12,
                    color: index < (rev['rating'] ?? 5)
                        ? Colors.amber
                        : Colors.white10)),
          ),
          const SizedBox(height: 8),
          Text(rev['comment'] ?? '',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}
