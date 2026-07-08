import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'api_service.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'language_provider.dart';
import 'buyer_profile_screen.dart';
import 'my_reviews_screen.dart';
import 'globals.dart';

class CustomerDashboardScreen extends StatefulWidget {
  final bool showDrawer;
  const CustomerDashboardScreen({super.key, this.showDrawer = true});

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _popularProducts = [];
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
      final results = await Future.wait([
        ApiService.getCustomerStats(),
        ApiService.getProducts(),
      ]);
      final stats = results[0] as Map<String, dynamic>;
      final products = List<dynamic>.from(results[1] as List);

      // Sort by rating desc
      products.sort((a, b) {
        final double rA = (a['rating'] ?? 0.0).toDouble();
        final double rB = (b['rating'] ?? 0.0).toDouble();
        return rB.compareTo(rA);
      });
      final popular = products.take(4).toList();

      setState(() {
        _stats = stats;
        _popularProducts = popular;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _stats = null;
          _popularProducts = [];
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
        toolbarHeight: 74,
        iconTheme: const IconThemeData(color: gold),
        leading: widget.showDrawer
            ? Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
              )
            : null,
        title: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: gold.withOpacity(0.15), width: 0.8),
            ),
            child: TextField(
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                hintText: 'Cari kain tenun...',
                hintStyle: GoogleFonts.montserrat(color: Colors.white30, fontSize: 10),
                prefixIcon: const Icon(Icons.search, color: gold, size: 16),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen(initialSearch: value.trim(), showDrawer: false)),
                  );
                }
              },
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 20, color: gold),
              onPressed: _fetchDashboardData,
              tooltip: 'Segarkan',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, size: 20, color: gold),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
              tooltip: 'Keranjang',
            ),
          ),
          const SizedBox(width: 8),
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
                          // ─── PRODUK TERPOPULER ───
                          _buildSectionHeader('PRODUK TERPOPULER', gold),
                          const SizedBox(height: 12),

                          _buildPopularProductsGrid(),

                          const SizedBox(height: 28),

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
  // SHARED WIDGETS
  // ─────────────────────────────────────────────────────────────

  /// Animated shimmer placeholder saat gambar sedang dimuat
  Widget _buildImageShimmer() {
    return Container(
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
    );
  }

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

  void _showImagePreview(BuildContext context, String imageUrl, String productName) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Fullscreen tappable area to close
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(color: Colors.transparent, width: double.infinity, height: double.infinity),
            ),
            // Zoomable image in center
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  fadeInDuration: const Duration(milliseconds: 250),
                  placeholder: (context, url) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: gold, strokeWidth: 1.5),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 80,
                  ),
                ),
              ),
            ),
            // Top bar: product name + close button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          productName.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom hint: pinch to zoom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Cubit atau rentangkan untuk zoom',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularProductsGrid() {
    if (_popularProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Tidak ada produk populer tersedia',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _popularProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
      ),
      itemBuilder: (context, index) {
        final product = _popularProducts[index];
        return _buildPopularProductItem(product);
      },
    );
  }

  Widget _buildPopularProductItem(dynamic product) {
    final double rating = (product['rating'] ?? 0.0).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.04), width: 0.8)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => _showImagePreview(
                        context,
                        ApiService.getFormattedImageUrl(product['imageUrl'] ?? ''),
                        product['name']?.toString() ?? '',
                      ),
                      child: product['imageUrl'] != null && product['imageUrl'].isNotEmpty
                          ? Container(
                              color: const Color(0xFF111111),
                              child: CachedNetworkImage(
                                imageUrl: ApiService.getFormattedImageUrl(product['imageUrl']),
                                fit: BoxFit.cover,
                                fadeInDuration: const Duration(milliseconds: 350),
                                placeholder: (context, url) => _buildImageShimmer(),
                                errorWidget: (context, url, error) => const Center(
                                  child: Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 32),
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image_outlined, color: Colors.white24, size: 32),
                            ),
                    ),
                  ),
                  // Rating Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Preview hint icon
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.zoom_in_rounded, color: Colors.white70, size: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Details Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'].toString().toUpperCase(),
                  style: GoogleFonts.montserrat(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  Globals.formatRupiah(product['price']),
                  style: GoogleFonts.playfairDisplay(color: gold, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: gold.withOpacity(0.3), width: 0.5),
                            foregroundColor: Colors.white70,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => ProductInfoSheet(product: product, gold: gold),
                            );
                          },
                          child: Text('DETAIL', style: GoogleFonts.montserrat(fontSize: 8, letterSpacing: 0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold.withOpacity(0.85),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => ProductOrderSheet(product: product, gold: gold),
                            );
                          },
                          child: Text('PESAN', style: GoogleFonts.montserrat(fontSize: 8, letterSpacing: 0.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05);
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


