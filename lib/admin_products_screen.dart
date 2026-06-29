import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_service.dart';
import 'globals.dart';

class AdminProductsScreen extends StatefulWidget {
  final bool showAppBar;
  const AdminProductsScreen({super.key, this.showAppBar = true});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts() async {
    try {
      final products = await ApiService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const darkSuite = Color(0xFF0F0B1E);

    return Scaffold(
      backgroundColor: darkSuite,
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: darkSuite,
        elevation: 0,
        title: Text('PRODUCT MONITORING', style: GoogleFonts.montserrat(color: gold, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 4)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: gold),
      ) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Colors.white.withOpacity(0.05),
                          child: product['imageUrl'] != null && product['imageUrl'].isNotEmpty
                              ? Image.network(ApiService.getFormattedImageUrl(product['imageUrl']), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: Colors.white24))
                              : const Icon(Icons.image_outlined, color: Colors.white24),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product['name'].toUpperCase(), style: GoogleFonts.montserrat(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1),
                            const SizedBox(height: 4),
                             Text(Globals.formatRupiah(product['price']), style: const TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Stok: ${product['stock']}', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                          ],
                        ),
                      )
                    ],
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).scale(begin: const Offset(0.9, 0.9));
              },
            ),
    );
  }
}
