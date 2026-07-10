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
import 'package:cached_network_image/cached_network_image.dart';

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
  String _selectedCategory = 'Semua';

  // Filter & Sort State variables
  String _sortBy = 'default';
  bool _onlyInStock = false;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

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
    _minPriceController.dispose();
    _maxPriceController.dispose();
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
      // 1. Filter
      List<dynamic> filtered = _allProducts.where((p) {
        final name = p['name'].toString().toLowerCase();
        final search = _searchController.text.toLowerCase();
        final matchesSearch = name.contains(search);
        
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
        
        return matchesSearch && matchesCategory && matchesStock && matchesMinPrice && matchesMaxPrice;
      }).toList();

      // 2. Sort
      if (_sortBy == 'price_asc') {
        filtered.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
      } else if (_sortBy == 'price_desc') {
        filtered.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
      } else if (_sortBy == 'rating_desc') {
        filtered.sort((a, b) => (b['rating'] ?? 0.0).compareTo(a['rating'] ?? 0.0));
      } else {
        // default: newest/id desc
        filtered.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
      }

      _products = filtered;
    });
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

  @override
  Widget build(BuildContext context) {
    const goldPrimary = Color(0xFFA67C1E); // Rich deep gold
    const lightLuxe = Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: lightLuxe,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05), width: 0.8)),
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
      drawer: widget.showDrawer ? _buildLuxeDrawer(lightLuxe, goldPrimary) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: goldPrimary, strokeWidth: 1))
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, color: goldPrimary.withOpacity(0.2), size: 60),
                      const SizedBox(height: 20),
                      Text('TIDAK DITEMUKAN', style: GoogleFonts.montserrat(color: goldPrimary.withOpacity(0.7), fontSize: 10, letterSpacing: 5)),
                      const SizedBox(height: 8),
                      Text('Coba kata kunci atau atur ulang filter', style: GoogleFonts.montserrat(color: Colors.black38, fontSize: 8, letterSpacing: 1)),
                      if (_hasActiveFilters() || _searchController.text.isNotEmpty) ...[
                        const SizedBox(height: 16),
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
                          icon: const Icon(Icons.refresh, size: 14, color: goldPrimary),
                          label: Text(
                            'RESET SEMUA FILTER',
                            style: GoogleFonts.montserrat(color: goldPrimary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                      ],
                    ],
                  ).animate().fadeIn(),
                )
              : CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                // Horizontal Categories
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'KATEGORI PILIHAN',
                          style: GoogleFonts.montserrat(
                            color: Colors.black45,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: const ['Semua', 'Kain Tenun', 'Baju Jadi', 'Selendang', 'Aksesoris'].length,
                          itemBuilder: (context, idx) {
                            final List<String> categories = const ['Semua', 'Kain Tenun', 'Baju Jadi', 'Selendang', 'Aksesoris'];
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
                                    color: isSelected ? goldPrimary : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? goldPrimary : Colors.black.withOpacity(0.08),
                                      width: 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: goldPrimary.withOpacity(0.2),
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
                  ),
                ),
                // Search Bar in Body
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: _hasActiveFilters() ? goldPrimary.withOpacity(0.5) : Colors.black12,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(Icons.search, color: goldPrimary, size: 16),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textAlignVertical: TextAlignVertical.center,
                              style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                              onChanged: (_) => _filterProducts(),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                hintText: 'Cari koleksi masterpiece...',
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
                              color: _hasActiveFilters() ? goldPrimary : Colors.black45,
                              size: 16,
                            ),
                            tooltip: 'Filter & Urutkan',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _showFilterBottomSheet,
                          ),
                          const SizedBox(width: 12),
                        ],
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
                          childAspectRatio: 0.7,
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
                          onPressed: () => _showProductInfo(product, gold),
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
                          onPressed: () => _showProductOrder(product, gold),
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

  Widget _buildImageShimmer() {
    return Container(
      color: const Color(0xFFF1F3F5),
      child: Container(
        decoration: const BoxDecoration(color: Color(0xFFE9ECEF)),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: const Duration(milliseconds: 1200),
            color: const Color(0xFFDEE2E6),
            angle: 0.3,
          ),
    );
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
              setState(() => _selectedCategory = 'Semua');
              _filterProducts();
            }),
            
            // Nested Categories
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Column(
                children: [
                  _drawerSubTile('KAIN TENUN', () {
                    Navigator.pop(context);
                    setState(() => _selectedCategory = 'Kain Tenun');
                    _filterProducts();
                  }, gold),
                  _drawerSubTile('BAJU JADI', () {
                    Navigator.pop(context);
                    setState(() => _selectedCategory = 'Baju Jadi');
                    _filterProducts();
                  }, gold),
                  _drawerSubTile('SELENDANG', () {
                    Navigator.pop(context);
                    setState(() => _selectedCategory = 'Selendang');
                    _filterProducts();
                  }, gold),
                  _drawerSubTile('AKSESORIS', () {
                    Navigator.pop(context);
                    setState(() => _selectedCategory = 'Aksesoris');
                    _filterProducts();
                  }, gold),
                ],
              ),
            ),
            
            const Divider(color: Colors.black12, height: 20),
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
            const Divider(color: Colors.black12),
            _buildLanguageSelector(gold, lang),
            const SizedBox(height: 30),
            const Divider(color: Colors.black12),
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
      title: Text(title, style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 11, letterSpacing: 3)),
      onTap: onTap,
    );
  }

  Widget _drawerSubTile(String title, VoidCallback onTap, Color gold) {
    return ListTile(
      dense: true,
      title: Text(title, style: GoogleFonts.montserrat(color: Colors.black54, fontSize: 10, letterSpacing: 2)),
      onTap: onTap,
    );
  }

  Widget _buildLanguageSelector(Color gold, LanguageProvider lang) {
    return ListTile(
      leading: Icon(Icons.language, color: gold.withOpacity(0.7), size: 20),
      title: Text(lang.translate('language'), style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 11, letterSpacing: 3)),
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
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
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
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: widget.product['imageUrl'] != null && widget.product['imageUrl'].isNotEmpty
                          ? Image.network(ApiService.getFormattedImageUrl(widget.product['imageUrl']), fit: BoxFit.cover)
                          : const Icon(Icons.image_outlined, color: Colors.black26, size: 50),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(widget.product['name'].toString().toUpperCase(), style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Text(Globals.formatRupiah(widget.product['price']), style: GoogleFonts.playfairDisplay(color: widget.gold, fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    
                    Text('DESKRIPSI', style: GoogleFonts.montserrat(color: Colors.black45, fontSize: 10, letterSpacing: 3)),
                    const SizedBox(height: 8),
                    Text(widget.product['description'] ?? 'Tidak ada deskripsi untuk mahakarya ini.', style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.6)),
                    const SizedBox(height: 32),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('JUMLAH', style: GoogleFonts.montserrat(color: Colors.black45, fontSize: 9, letterSpacing: 2)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _qtyBtn(Icons.remove, () { if (_quantity > 1) setState(() => _quantity--); }),
                                  const SizedBox(width: 16),
                                  Text('$_quantity', style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
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
                              Text('PANJANG (METER)', style: GoogleFonts.montserrat(color: Colors.black45, fontSize: 9, letterSpacing: 2)),
                              TextField(
                                controller: _sizeCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.black87, fontSize: 14),
                                onChanged: (val) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Misal: 2.5',
                                  suffixText: 'Meter',
                                  suffixStyle: TextStyle(color: widget.gold, fontSize: 10),
                                  hintStyle: const TextStyle(color: Colors.black26),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.gold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Text('CATATAN (OPSIONAL)', style: GoogleFonts.montserrat(color: Colors.black45, fontSize: 9, letterSpacing: 2)),
                    TextField(
                      controller: _notesCtrl,
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Tuliskan permintaan khusus anda...',
                        hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.gold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.01),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Column(
                        children: [
                          _summaryRow('Subtotal', Globals.formatRupiah(subtotal), Colors.black87),
                          const SizedBox(height: 8),
                          _summaryRow('DP (Tanda Jadi 50%)', Globals.formatRupiah(dp), widget.gold),
                          const Divider(color: Colors.black12, height: 24),
                          _summaryRow('Total Harga', Globals.formatRupiah(total), Colors.black87, isBold: true),
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
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
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
        decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
        child: Icon(icon, color: widget.gold, size: 16),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.montserrat(color: Colors.black54, fontSize: 11)),
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
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.black12,
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
                          GestureDetector(
                            onTap: () => _showImagePreview(
                              context,
                              ApiService.getFormattedImageUrl(widget.product['imageUrl']),
                              widget.product['name']?.toString() ?? '',
                            ),
                            child: Container(
                              height: 250,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black.withOpacity(0.06))),
                              child: widget.product['imageUrl'] != null &&
                                      widget.product['imageUrl'].isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: ApiService.getFormattedImageUrl(
                                          widget.product['imageUrl']),
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.black.withOpacity(0.02),
                                        child: const Center(
                                          child: CircularProgressIndicator(color: Color(0xFFA67C1E), strokeWidth: 1.5),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.black26,
                                        size: 40,
                                      ),
                                    )
                                  : const Icon(Icons.image_outlined,
                                      color: Colors.black26, size: 50),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(widget.product['name'].toString().toUpperCase(),
                              style: GoogleFonts.montserrat(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(Globals.formatRupiah(widget.product['price']),
                                  style: GoogleFonts.playfairDisplay(
                                      color: widget.gold,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text('${widget.product['rating'] ?? 5.0}',
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text('DESKRIPSI',
                              style: GoogleFonts.montserrat(
                                  color: Colors.black45,
                                  fontSize: 10,
                                  letterSpacing: 3)),
                          const SizedBox(height: 12),
                          Text(widget.product['description'] ?? 'Tidak ada deskripsi.',
                              style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                  height: 1.6)),
                          const SizedBox(height: 32),
                          Text('ULASAN PEMBELI',
                              style: GoogleFonts.montserrat(
                                  color: Colors.black45,
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
                                          color: Colors.black38,
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
        color: Colors.black.withOpacity(0.01),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(rev['userName'] ?? 'Pembeli',
                  style: GoogleFonts.montserrat(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(DateFormat('d MMM yyyy').format(date),
                  style: TextStyle(
                      color: Colors.black38, fontSize: 10)),
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
                        : Colors.black12)),
          ),
          const SizedBox(height: 8),
          Text(rev['comment'] ?? '',
              style: const TextStyle(
                  color: Colors.black54, fontSize: 12, height: 1.4)),
          if (rev['images'] != null && (rev['images'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: (rev['images'] as List).length,
                itemBuilder: (ctx, idx) {
                  final imgUrl = rev['images'][idx]['imageUrl'];
                  final formattedUrl = ApiService.getFormattedImageUrl(imgUrl);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _showImagePreview(context, formattedUrl, 'Foto Ulasan dari ${rev['userName']}'),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 60,
                          height: 60,
                          color: Colors.black.withOpacity(0.01),
                          child: CachedNetworkImage(
                            imageUrl: formattedUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(color: Color(0xFFA67C1E), strokeWidth: 1.5),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image,
                              color: Colors.black26,
                              size: 16,
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
        ],
      ),
    );
  }
}

void _showImagePreview(BuildContext context, String imageUrl, String title) {
  if (imageUrl.isEmpty) return;
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.92),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(ctx).pop(),
            child: Container(color: Colors.transparent, width: double.infinity, height: double.infinity),
          ),
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFA67C1E), strokeWidth: 1.5),
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
                        title.toUpperCase(),
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
                child: const Center(
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
