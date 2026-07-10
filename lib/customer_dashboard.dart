import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
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
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = true;

  static const gold = Color(0xFFA67C1E);
  static const darkLuxe = Color(0xFFF9FAFC);

  // Filter & Sort State variables
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'default';
  bool _onlyInStock = false;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  // Redesign states
  String _selectedCategory = 'Semua';
  int _currentBannerIndex = 0;
  final PageController _pageController = PageController();
  Timer? _bannerTimer;

  // Banner data (custom gradients & slogans)
  final List<Map<String, String>> _banners = [
    {
      'title': 'Warisan Budaya Terbaik',
      'subtitle': 'Sentuhan karya seni tenun premium langsung dari pengrajin lokal.',
    },
    {
      'title': 'Koleksi Mahakarya Geza',
      'subtitle': 'Dibuat dengan dedikasi tinggi dan benang emas berkualitas tinggi.',
    },
    {
      'title': 'Keanggunan Tradisi',
      'subtitle': 'Hiasi momen istimewa Anda dengan balutan tenun bernilai seni tinggi.',
    },
  ];

  double? get _minPrice {
    final text = _minPriceController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  double? get _maxPrice {
    final text = _maxPriceController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  bool _hasActiveFilters() {
    return _sortBy != 'default' || _onlyInStock || _minPriceController.text.isNotEmpty || _maxPriceController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextIndex = (_currentBannerIndex + 1) % _banners.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _pageController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
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
        _allProducts = products;
        _popularProducts = popular;
        _isLoading = false;
        _filterProducts();
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
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: _hasActiveFilters() ? gold.withOpacity(0.5) : Colors.black12,
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: gold, size: 16),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                    onChanged: (_) => _filterProducts(),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      hintText: 'Cari kain tenun...',
                      hintStyle: GoogleFonts.montserrat(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    color: _hasActiveFilters() ? gold : Colors.black45,
                    size: 16,
                  ),
                  tooltip: 'Filter & Urutkan',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _showFilterBottomSheet,
                ),
                const SizedBox(width: 8),
              ],
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
                          if (!_hasActiveFilters() && _searchController.text.isEmpty && _selectedCategory == 'Semua') ...[
                            _buildCarouselBanner(),
                            const SizedBox(height: 24),
                          ],
                          
                          _buildCategoryChips(),
                          const SizedBox(height: 28),

                          if (_hasActiveFilters() || _searchController.text.isNotEmpty || _selectedCategory != 'Semua') ...[
                            _buildSectionHeader(
                              _selectedCategory != 'Semua'
                                  ? 'KATEGORI: ${_selectedCategory.toUpperCase()}'
                                  : 'HASIL PENCARIAN & FILTER',
                              gold,
                            ),
                            const SizedBox(height: 12),
                            _buildFilteredProductsGrid(),
                            if (_filteredProducts.isEmpty) ...[
                              const SizedBox(height: 20),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.search_off_rounded, color: gold.withOpacity(0.2), size: 48),
                                    const SizedBox(height: 12),
                                    Text('TIDAK DITEMUKAN', style: GoogleFonts.montserrat(color: gold.withOpacity(0.7), fontSize: 10, letterSpacing: 3)),
                                    const SizedBox(height: 6),
                                    Text('Coba kata kunci atau atur ulang filter', style: GoogleFonts.montserrat(color: Colors.black38, fontSize: 8)),
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _sortBy = 'default';
                                          _onlyInStock = false;
                                          _selectedCategory = 'Semua';
                                          _searchController.clear();
                                          _minPriceController.clear();
                                          _maxPriceController.clear();
                                          _filterProducts();
                                        });
                                      },
                                      icon: const Icon(Icons.refresh, size: 12, color: gold),
                                      label: Text(
                                        'RESET FILTER',
                                        style: GoogleFonts.montserrat(color: gold, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ] else ...[
                            _buildSectionHeader('PRODUK TERPOPULER', gold),
                            const SizedBox(height: 12),

                            _buildPopularProductsGrid(),

                            const SizedBox(height: 28),

                            _buildExploreButton(context),
                          ],

                          const SizedBox(height: 36),
                          const Divider(color: Colors.black12, height: 1),
                          const SizedBox(height: 36),

                          _buildValuePropositionBadges(),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ).animate().fadeIn(duration: 600.ms),
                  ),
        ),
    );
  }

  Widget _buildCarouselBanner() {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
            itemCount: _banners.length,
            itemBuilder: (context, idx) {
              final banner = _banners[idx];
              final List<Color> gradientColors = idx == 0
                  ? [const Color(0xFF0F0918), const Color(0xFF2C1B4D)]
                  : idx == 1
                      ? [const Color(0xFFA67C1E), const Color(0xFFD4AF37)]
                      : [const Color(0xFF1E352F), const Color(0xFF3B574E)];

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        bottom: -30,
                        child: Icon(
                          Icons.pattern,
                          size: 150,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              banner['title']!.toUpperCase(),
                              style: GoogleFonts.montserrat(
                                color: idx == 1 ? Colors.black87 : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              banner['subtitle']!,
                              style: GoogleFonts.montserrat(
                                color: idx == 1 ? Colors.black54 : Colors.white.withOpacity(0.8),
                                fontSize: 10,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (idx) {
                final isActive = _currentBannerIndex == idx;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? (_currentBannerIndex == 1 ? Colors.black87 : Colors.white)
                        : (_currentBannerIndex == 1 ? Colors.black26 : Colors.white30),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final List<String> categories = ['Semua', 'Kain Tenun', 'Baju Jadi', 'Selendang', 'Aksesoris'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KATEGORI PILIHAN',
          style: GoogleFonts.montserrat(
            color: Colors.black45,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, idx) {
              final cat = categories[idx];
              final isSelected = _selectedCategory == cat;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                      _filterProducts();
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? gold : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? gold : Colors.black.withOpacity(0.08),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: gold.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: GoogleFonts.montserrat(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildValuePropositionBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildBadgeItem(Icons.gesture, '100% HANDMADE', 'Karya asli pengrajin'),
        _buildBadgeItem(Icons.verified_outlined, 'PREMIUM QUALITY', 'Benang emas pilihan'),
        _buildBadgeItem(Icons.favorite_border, 'SUPPORT LOCAL', 'Dukung komunitas'),
      ],
    );
  }

  Widget _buildBadgeItem(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: gold.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: gold, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black38, fontSize: 8),
            textAlign: TextAlign.center,
          ),
        ],
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
          const Text('Gagal Memuat Data', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
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
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.06), width: 0.8)),
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
                  style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
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
                            foregroundColor: Colors.black87,
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

            const Divider(color: Colors.black12, height: 40),

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
            const Divider(color: Colors.black12),

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
      title: Text(title, style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 10, letterSpacing: 2)),
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
              Text(lang.translate('language').toUpperCase(), style: GoogleFonts.montserrat(color: Colors.black54, fontSize: 9, letterSpacing: 1)),
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

  void _filterProducts() {
    setState(() {
      // 1. Filter
      List<dynamic> filtered = _allProducts.where((p) {
        final name = p['name'].toString().toLowerCase();
        final search = _searchController.text.toLowerCase();
        final matchesSearch = name.contains(search);
        
        // Stock filter
        bool matchesStock = true;
        if (_onlyInStock) {
          final int stock = p['stock'] ?? 0;
          matchesStock = stock > 0;
        }
        
        // Price filter
        final int price = p['price'] ?? 0;
        bool matchesMinPrice = _minPrice == null || price >= _minPrice!;
        bool matchesMaxPrice = _maxPrice == null || price <= _maxPrice!;
        
        // Category filter
        bool matchesCategory = true;
        if (_selectedCategory != 'Semua') {
          final description = (p['description'] ?? '').toString().toLowerCase();
          final titleLower = p['name'].toString().toLowerCase();
          
          if (_selectedCategory == 'Kain Tenun') {
            matchesCategory = titleLower.contains('kain') || titleLower.contains('sarung') || titleLower.contains('tenun') ||
                              description.contains('kain') || description.contains('sarung') || description.contains('tenun');
          } else if (_selectedCategory == 'Baju Jadi') {
            matchesCategory = titleLower.contains('baju') || titleLower.contains('pakaian') || titleLower.contains('kemeja') || titleLower.contains('sepasang') ||
                              description.contains('baju') || description.contains('pakaian') || description.contains('kemeja') || description.contains('sepasang');
          } else if (_selectedCategory == 'Selendang') {
            matchesCategory = titleLower.contains('selendang') || titleLower.contains('syal') || titleLower.contains('scarf') ||
                              description.contains('selendang') || description.contains('syal') || description.contains('scarf');
          } else if (_selectedCategory == 'Aksesoris') {
            matchesCategory = titleLower.contains('aksesoris') || titleLower.contains('topi') || titleLower.contains('tanjak') || titleLower.contains('sepatu') || titleLower.contains('sandal') ||
                              description.contains('aksesoris') || description.contains('topi') || description.contains('tanjak') || description.contains('sepatu') || description.contains('sandal');
          }
        }
        
        return matchesSearch && matchesStock && matchesMinPrice && matchesMaxPrice && matchesCategory;
      }).toList();

      // 2. Sort
      if (_sortBy == 'price_asc') {
        filtered.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
      } else if (_sortBy == 'price_desc') {
        filtered.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
      } else if (_sortBy == 'rating_desc') {
        filtered.sort((a, b) => (b['rating'] ?? 0.0).compareTo(a['rating'] ?? 0.0));
      } else {
        // default
        filtered.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
      }

      _filteredProducts = filtered;
    });
  }

  Widget _buildFilteredProductsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
      ),
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildPopularProductItem(product);
      },
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'FILTER & URUTKAN',
                          style: GoogleFonts.montserrat(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _sortBy = 'default';
                              _onlyInStock = false;
                              _minPriceController.clear();
                              _maxPriceController.clear();
                            });
                          },
                          child: Text(
                            'Atur Ulang',
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFFA67C1E),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.black12, height: 16),
                    
                    // Sort section
                    Text(
                      'URUTKAN BERDASARKAN',
                      style: GoogleFonts.montserrat(
                        color: Colors.black45,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSortRadioTile(setModalState, 'default', 'Terbaru / Default'),
                    _buildSortRadioTile(setModalState, 'price_asc', 'Harga: Terendah ke Tertinggi'),
                    _buildSortRadioTile(setModalState, 'price_desc', 'Harga: Tertinggi ke Terendah'),
                    _buildSortRadioTile(setModalState, 'rating_desc', 'Penilaian Tertinggi'),
                    const SizedBox(height: 16),

                    // Filter section
                    Text(
                      'FILTER PRODUK',
                      style: GoogleFonts.montserrat(
                        color: Colors.black45,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      activeColor: const Color(0xFFA67C1E),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Hanya Ready Stock',
                        style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 11),
                      ),
                      subtitle: Text(
                        'Menyembunyikan produk yang stoknya habis',
                        style: GoogleFonts.montserrat(color: Colors.black38, fontSize: 8),
                      ),
                      value: _onlyInStock,
                      onChanged: (val) {
                        setModalState(() => _onlyInStock = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Price range section
                    Text(
                      'RENTANG HARGA (Rp)',
                      style: GoogleFonts.montserrat(
                        color: Colors.black45,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _minPriceController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.black87, fontSize: 11),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                hintText: 'Harga Min',
                                hintStyle: GoogleFonts.montserrat(color: Colors.black38, fontSize: 10),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('-', style: TextStyle(color: Colors.black38)),
                        ),
                        Expanded(
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _maxPriceController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.black87, fontSize: 11),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                hintText: 'Harga Maks',
                                hintStyle: GoogleFonts.montserrat(color: Colors.black38, fontSize: 10),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA67C1E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _filterProducts();
                        },
                        child: Text(
                          'TERAPKAN FILTER',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortRadioTile(StateSetter setModalState, String value, String title) {
    return RadioListTile<String>(
      activeColor: const Color(0xFFA67C1E),
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        title,
        style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 11),
      ),
      value: value,
      groupValue: _sortBy,
      onChanged: (val) {
        if (val != null) {
          setModalState(() => _sortBy = val);
        }
      },
    );
  }
}


