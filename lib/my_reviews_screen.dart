import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

/// Daftar ulasan pengguna (dipakai bottom nav pembeli dan drawer katalog).
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<dynamic> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final reviews = await ApiService.getMyReviews();
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat ulasan: $e')),
        );
      }
    }
  }

  /// Tampilkan gambar full-screen saat diklik
  void _openImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image,
                    color: Colors.white24,
                    size: 80,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    return Scaffold(
      backgroundColor: const Color(0xFF0F0918),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ULASAN SAYA',
          style: GoogleFonts.montserrat(
            color: gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : _reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_border, color: Colors.white10, size: 80),
                      const SizedBox(height: 20),
                      Text(
                        'BELUM ADA ULASAN',
                        style: GoogleFonts.montserrat(
                          color: Colors.white24,
                          letterSpacing: 4,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Anda belum memberikan ulasan',
                        style: TextStyle(color: Colors.white10, fontSize: 10),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: gold,
                  onRefresh: _fetchReviews,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];

                      // Backend returns review['images'] as List of {id, imageUrl, reviewId}
                      final rawImages = review['images'];
                      final List<String> imageUrls = rawImages is List
                          ? rawImages
                              .map((img) => ApiService.getFormattedImageUrl(
                                    img is Map ? img['imageUrl']?.toString() : null,
                                  ))
                              .where((u) => u.isNotEmpty)
                              .toList()
                          : [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Header: nama produk + bintang ──
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      review['product']['name'].toString().toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        Icons.star,
                                        color: i < (review['rating'] as num? ?? 0).round()
                                            ? gold
                                            : Colors.white12,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Komentar ──
                            if ((review['comment']?.toString() ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                child: Text(
                                  review['comment'].toString(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    height: 1.5,
                                  ),
                                ),
                              ),

                            // ── Foto ulasan ──
                            if (imageUrls.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 90,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    children: [
                                      for (int i = 0; i < imageUrls.length; i++) ...[
                                        if (i > 0) const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _openImage(context, imageUrls[i]),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              imageUrls[i],
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (_, child, progress) {
                                                if (progress == null) return child;
                                                return Container(
                                                  width: 90,
                                                  height: 90,
                                                  color: Colors.white.withOpacity(0.04),
                                                  child: const Center(
                                                    child: SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        color: gold,
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (_, _, _) => Container(
                                                width: 90,
                                                height: 90,
                                                color: Colors.white.withOpacity(0.04),
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.white24,
                                                  size: 28,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // ── Tanggal ──
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(
                                  DateTime.tryParse(review['createdAt']?.toString() ?? '') ??
                                      DateTime.now(),
                                ),
                                style: const TextStyle(color: Colors.white24, fontSize: 9),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
