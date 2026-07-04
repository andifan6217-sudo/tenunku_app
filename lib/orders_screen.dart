import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'tracking_screen.dart';
import 'globals.dart';


class OrdersScreen extends StatefulWidget {
  final String? initialStatus;
  final bool showBackButton;
  const OrdersScreen({super.key, this.initialStatus, this.showBackButton = true});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _allOrders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
  String? _filterStatus;
  String? _userRole;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filterStatus = widget.initialStatus;
    _searchController.addListener(_applyFilter);
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchOrders() async {
    try {
      final role = await ApiService.getRole();
      final orders = await ApiService.getOrders();
      if (mounted) {
        setState(() {
          _userRole = role;
          _allOrders = orders;
          _isLoading = false;
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat pesanan. ($e)')));
      }
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    List<dynamic> temp = _allOrders;

    if (query.isNotEmpty) {
      temp = temp.where((o) {
        final idStr = o['id'].toString().toLowerCase();
        final items = o['items'] as List;
        final hasProduct = items.any((i) => i['product']['name'].toString().toLowerCase().contains(query));
        return idStr.contains(query) || hasProduct;
      }).toList();
    }

    if (_filterStatus != null && _filterStatus != 'ALL') {
      if (_filterStatus == 'ACTIVE') {
        temp = temp.where((o) => ['PENDING', 'DP_PAID', 'VERIFIED', 'PROCESSED', 'FULL_PAY_PAID', 'PAID', 'SHIPPED'].contains(o['status'])).toList();
      } else if (_filterStatus == 'COMPLETED') {
        temp = temp.where((o) => ['COMPLETED', 'DELIVERED'].contains(o['status'])).toList();
      } else {
        temp = temp.where((o) => o['status'] == _filterStatus).toList();
      }
    }

    setState(() {
      _filteredOrders = temp;
    });
  }

  Future<void> _handleCancel(int id) async {
    try {
      await ApiService.cancelOrder(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan berhasil dibatalkan')));
      _fetchOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _handlePayment(int id, XFile? proofFile, {bool isFullPayment = false}) async {
    if (proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tolong unggah bukti transfer!')));
      return;
    }
    
    final statusToSet = isFullPayment ? 'FULL_PAY_PAID' : 'DP_PAID';

    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mengunggah bukti ${isFullPayment ? 'pelunasan' : 'DP'} dan mengirim...')));
      
      String? proofUrl = await ApiService.uploadImage(proofFile);
      if (proofUrl == null) {
        throw Exception('Gagal mengunggah gambar');
      }

      await ApiService.updateOrderStatus(id, statusToSet, paymentProofUrl: proofUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Pembayaran ${isFullPayment ? 'pelunasan' : 'DP'} berhasil dikirim! Menunggu verifikasi penjual.'),
          duration: const Duration(seconds: 3),
        ));
        _fetchOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _handleMarkDelivered(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF130B22),
        title: const Text('Konfirmasi Sampai', style: TextStyle(color: Colors.white)),
        content: const Text('Tandai pesanan ini telah sampai ke pelanggan?', style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL', style: TextStyle(color: Colors.white24))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('YA, SAMPAI', style: TextStyle(color: Colors.greenAccent))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.updateOrderStatus(id, 'DELIVERED');
      _fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan ditandai sebagai SAMPAI'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
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
          _fetchOrders();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menolak: $e')));
        }
      }
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
                  _fetchOrders();
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

  Future<void> _payWithGateway(int orderId, String amountType, {String? method}) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menghubungkan ke sistem pembayaran...'), duration: Duration(seconds: 2)),
      );

      final result = await ApiService.getPaymentToken(orderId, amountType: amountType, method: method);
      final String? redirectUrl = result['redirectUrl'];

      if (redirectUrl != null && await canLaunchUrl(Uri.parse(redirectUrl))) {
        await launchUrl(Uri.parse(redirectUrl), mode: LaunchMode.externalApplication);

        if (mounted) {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: const Color(0xFF130B22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(children: [
                const Icon(Icons.open_in_browser, color: Color(0xFFD4AF37), size: 20),
                const SizedBox(width: 10),
                Text('Halaman Pembayaran Dibuka', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ]),
              content: const Text(
                'Selesaikan pembayaran pada browser yang terbuka.\n\nStatus pesanan akan diperbarui secara otomatis setelah pembayaran berhasil.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              actions: [
                TextButton(
                  onPressed: () { Navigator.pop(dialogContext); _fetchOrders(); },
                  child: Text('SELESAI', style: GoogleFonts.montserrat(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('URL pembayaran tidak valid atau tidak dapat dibuka');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '').replaceAll('Ralat sistem pembayaran: Exception: ', '');
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF130B22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
              const SizedBox(width: 10),
              Text('Pembayaran Online Gagal', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1ABC9C).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1ABC9C).withOpacity(0.3)),
                  ),
                  child: const Text(
                    '💡 Anda tetap dapat membayar via Transfer Bank atau QRIS menggunakan tombol "Kirim Bukti Transfer".',
                    style: TextStyle(color: Color(0xFF1ABC9C), fontSize: 11),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('MENGERTI', style: GoogleFonts.montserrat(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showReviewDialog(dynamic order) async {
    final items = order['items'] as List;
    // De-duplicate products to prevent DropdownButton errors
    final Map<int, dynamic> uniqueProducts = {};
    for (var i in items) {
      uniqueProducts[i['productId']] = i;
    }
    final productList = uniqueProducts.values.toList();

    int? selectedProductId = productList.isNotEmpty ? productList[0]['productId'] : null;
    int rating = 5;
    final commentCtrl = TextEditingController();
    // Store (XFile, bytes) tuples — XFile for upload, Uint8List for web-safe preview
    final List<(XFile, Uint8List)> selectedImages = [];
    bool isUploading = false;
    const gold = Color(0xFFD4AF37);
    final picker = ImagePicker();

    // Fungsi untuk menampilkan pilihan sumber gambar (Kamera / Galeri)
    Future<void> pickImage(StateSetter setDialogState) async {
      await showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1128),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Text('TAMBAH FOTO ULASAN',
                  style: GoogleFonts.montserrat(
                    color: gold, fontSize: 11,
                    fontWeight: FontWeight.bold, letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Tombol Kamera
                    InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 1080,      // Kompres resolusi untuk mobile
                          maxHeight: 1080,
                          imageQuality: 80,    // 80% kualitas — hemat data
                        );
                        if (image != null && selectedImages.length < 5) {
                          final bytes = await image.readAsBytes();
                          setDialogState(() => selectedImages.add((image, bytes)));
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        decoration: BoxDecoration(
                          color: gold.withOpacity(0.08),
                          border: Border.all(color: gold.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.camera_alt_outlined, color: gold, size: 32),
                            const SizedBox(height: 8),
                            Text('KAMERA', style: GoogleFonts.montserrat(color: gold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),
                    // Tombol Galeri
                    InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1080,
                          maxHeight: 1080,
                          imageQuality: 80,
                        );
                        if (image != null && selectedImages.length < 5) {
                          final bytes = await image.readAsBytes();
                          setDialogState(() => selectedImages.add((image, bytes)));
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(color: Colors.white12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.photo_library_outlined, color: Colors.white70, size: 32),
                            const SizedBox(height: 8),
                            Text('GALERI', style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF130B22),
          title: Text(
            'BERI ULASAN PADA #${order['id']}',
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (productList.length > 1) ...[
                  const Text('PILIH PRODUK:', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButton<int>(
                      value: selectedProductId,
                      dropdownColor: const Color(0xFF130B22),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: productList.map<DropdownMenuItem<int>>((i) => DropdownMenuItem<int>(
                        value: i['productId'],
                        child: Text(i['product']['name'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11)),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedProductId = val),
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else if (productList.isNotEmpty) ...[
                  Text(productList[0]['product']['name'].toString().toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                ],

                const Center(child: Text('RATING ANDA', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => IconButton(
                    icon: Icon(Icons.star, color: i < rating ? gold : Colors.white10),
                    onPressed: () => setDialogState(() => rating = i + 1),
                  )),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Tuliskan ulasan anda...',
                    hintStyle: TextStyle(color: Colors.white10),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                  ),
                ),
                const SizedBox(height: 20),

                // ===== SECTION: FOTO ULASAN =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('FOTO ULASAN', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text('${selectedImages.length}/5', style: const TextStyle(color: Colors.white24, fontSize: 9)),
                  ],
                ),
                const SizedBox(height: 10),

                // Grid preview gambar yang sudah dipilih
                if (selectedImages.isNotEmpty) ...[
                  SizedBox(
                    height: 80,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < selectedImages.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  // Use Image.memory for web-safe preview (works on all platforms)
                                  child: Image.memory(
                                    selectedImages[i].$2,
                                    width: 80, height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 80, height: 80,
                                      color: Colors.white10,
                                      child: const Icon(Icons.image, color: Colors.white24),
                                    ),
                                  ),
                                ),
                                // Tombol hapus gambar
                                Positioned(
                                  top: 2, right: 2,
                                  child: GestureDetector(
                                    onTap: () => setDialogState(() => selectedImages.removeAt(i)),
                                    child: Container(
                                      width: 20, height: 20,
                                      decoration: const BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Tombol tambah foto
                if (selectedImages.length < 5)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => pickImage(setDialogState),
                      icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                      label: Text(
                        selectedImages.isEmpty ? 'TAMBAH FOTO' : 'TAMBAH FOTO LAGI',
                        style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: gold,
                        side: BorderSide(color: gold.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),

                // Loading indicator saat upload
                if (isUploading) ...[
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: gold, strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Mengunggah foto...', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(ctx),
              child: const Text('BATAL', style: TextStyle(color: Colors.white24)),
            ),
            TextButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      try {
                        if (selectedProductId == null) return;
                        setDialogState(() => isUploading = true);

                        // Upload semua gambar satu per satu ke backend
                        final List<String> uploadedUrls = [];
                        for (final img in selectedImages) {
                          final url = await ApiService.uploadImage(img.$1); // use XFile from tuple
                          if (url != null) uploadedUrls.add(url);
                        }

                        // Kirim ulasan beserta URL gambar yang sudah terunggah
                        await ApiService.submitReview(
                          selectedProductId!,
                          rating,
                          commentCtrl.text,
                          imageUrls: uploadedUrls,
                        );

                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(uploadedUrls.isNotEmpty
                                  ? 'Terima kasih! Ulasan dengan ${uploadedUrls.length} foto berhasil dikirim.'
                                  : 'Terima kasih atas ulasan anda!'),
                              backgroundColor: const Color(0xFF2ECC71),
                            ),
                          );
                          _fetchOrders();
                        }
                      } catch (e) {
                        setDialogState(() => isUploading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                        }
                      }
                    },
              child: Text(
                isUploading ? 'MENGIRIM...' : 'KIRIM',
                style: TextStyle(color: isUploading ? Colors.white24 : gold),
              ),
            ),
          ],
        ),
      ),
    );
    commentCtrl.dispose();
  }


  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const darkArt = Color(0xFF0F0918);
    const darkAccent = Color(0xFF1A1128);

    final activeOrders = _filteredOrders.where((o) => ['PENDING', 'DP_PAID', 'VERIFIED', 'PROCESSED', 'FULL_PAY_PAID', 'PAID', 'SHIPPED'].contains(o['status'])).toList();
    final historyOrders = _filteredOrders.where((o) => !['PENDING', 'DP_PAID', 'VERIFIED', 'PROCESSED', 'FULL_PAY_PAID', 'PAID', 'SHIPPED'].contains(o['status'])).toList();

    return Scaffold(
      backgroundColor: darkArt,
      appBar: AppBar(
        backgroundColor: darkArt,
        elevation: 0,
        leading: widget.showBackButton 
            ? IconButton(icon: const Icon(Icons.arrow_back, color: gold), onPressed: () => Navigator.pop(context))
            : null,
        title: Text('PESANAN SAYA', style: GoogleFonts.montserrat(color: gold, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 4)),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: gold))
          : RefreshIndicator(
              onRefresh: () async => _fetchOrders(),
              color: gold,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lihat dan lacak semua pesanan Anda', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 24),
                    
                    _buildSearchBar(gold, darkAccent),
                    const SizedBox(height: 24),
                    
                    _buildSummaryChips(gold),
                    const SizedBox(height: 32),
                    
                    if (activeOrders.isNotEmpty) ...[
                      _sectionHeader('PESANAN AKTIF', gold),
                      const SizedBox(height: 16),
                      ...activeOrders.map((o) => _buildActiveOrderCard(o, gold, darkAccent)),
                      const SizedBox(height: 32),
                    ],
                    
                    if (historyOrders.isNotEmpty) ...[
                      _sectionHeader('RIWAYAT PESANAN', gold),
                      const SizedBox(height: 16),
                      ...historyOrders.map((o) => _buildHistoryOrderCard(o, gold, darkAccent)),
                    ],
                    
                    if (_filteredOrders.isEmpty)
                      Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('TIADA PESANAN DITEMUI', style: GoogleFonts.montserrat(color: Colors.white10, fontSize: 10, letterSpacing: 4)))),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSearchBar(Color gold, Color darkAccent) {
    return Container(
      decoration: BoxDecoration(color: darkAccent, borderRadius: BorderRadius.circular(8)),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Cari pesanan...',
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSummaryChips(Color gold) {
    final int total = _allOrders.length;
    final int active = _allOrders.where((o) => ['PENDING', 'DP_PAID', 'VERIFIED', 'PROCESSED', 'FULL_PAY_PAID', 'PAID', 'SHIPPED'].contains(o['status'])).length;
    final int history = total - active;

    return Row(
      children: [
        _chip('Total: $total', _filterStatus == null || _filterStatus == 'ALL', () => setState(() { _filterStatus = 'ALL'; _applyFilter(); }), gold),
        const SizedBox(width: 8),
        _chip('Aktif: $active', _filterStatus == 'ACTIVE', () => setState(() { _filterStatus = 'ACTIVE'; _applyFilter(); }), Colors.orangeAccent),
        const SizedBox(width: 8),
        _chip('Selesai: $history', _filterStatus == 'COMPLETED', () => setState(() { _filterStatus = 'COMPLETED'; _applyFilter(); }), Colors.greenAccent),
      ],
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : Colors.transparent,
          border: Border.all(color: active ? color : Colors.white.withOpacity(0.1), width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label.toUpperCase(), style: GoogleFonts.montserrat(color: active ? color : Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  Widget _sectionHeader(String title, Color gold) {
    return Text(title, style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 4));
  }

  Widget _buildActiveOrderCard(dynamic order, Color gold, Color darkAccent) {
    final firstItem = (order['items'] as List)[0];
    final date = DateTime.parse(order['createdAt']);
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: darkAccent,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(firstItem['product']['name'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('ORD-${order['id']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    _statusBadge(order['status']),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildProgressTracker(order['status'], gold),
                
                _buildBuyerAddress(order),
                
                if (order['paymentProofUrl'] != null && order['paymentProofUrl'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('BUKTI PEMBAYARAN:', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      final url = ApiService.getFormattedImageUrl(order['paymentProofUrl']);
                      _showImagePreviewDialog(url, 'BUKTI TRANSFER');
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Tooltip(
                        message: 'Klik untuk memperbesar bukti pembayaran',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Image.network(
                                ApiService.getFormattedImageUrl(order['paymentProofUrl']),
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.white24, size: 16),
                                        SizedBox(width: 8),
                                        Text('Gagal memuat bukti transfer', style: TextStyle(color: Colors.white24, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                color: Colors.black.withOpacity(0.6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text('PERBESAR BUKTI', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                if (order['courierName'] != null || order['awbNumber'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      border: Border.all(color: Colors.white10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined, color: Color(0xFFD4AF37), size: 14),
                            const SizedBox(width: 8),
                            Text('INFORMASI PENGIRIMAN', style: GoogleFonts.montserrat(color: const Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Kurir: ${order['courierName'] ?? '-'}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('No. Resi: ${order['awbNumber'] ?? '-'}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        if (order['trackingStatus'] != null && order['trackingStatus'].toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Status: ${order['trackingStatus']}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        ],
                      ],
                    ),
                  ),
                ],
                
                const Divider(color: Colors.white10, height: 40),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: ${Globals.formatRupiah(order['totalPrice'])}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(formattedDate, style: const TextStyle(color: Colors.white24, fontSize: 11)),
                  ],
                ),

                if (_userRole == 'ADMIN' || _userRole == 'PENJUAL') ...[
                  if (order['status'] == 'PENDING') ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showCancelDialog(order['id']),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('BATALKAN PESANAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                  if (order['status'] == 'DP_PAID') ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await ApiService.verifyOrder(order['id']);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran DP berhasil diverifikasi!'), backgroundColor: Colors.green));
                                _fetchOrders();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal verifikasi: $e')));
                              }
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('VERIFIKASI DP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2ECC71),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _rejectOrder(order['id']),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('TOLAK DP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (order['status'] == 'VERIFIED') ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await ApiService.markProcessed(order['id']);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan selesai diproduksi!'), backgroundColor: Colors.green));
                            _fetchOrders();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                          }
                        },
                        icon: const Icon(Icons.engineering_outlined, size: 16),
                        label: const Text('PRODUKSI SELESAI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                  if (order['status'] == 'PROCESSED') ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.hourglass_empty, color: Colors.white38, size: 18),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Menunggu pelunasan pembayaran dari pelanggan.',
                              style: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (order['status'] == 'FULL_PAY_PAID') ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await ApiService.verifyFinalPayment(order['id']);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran pelunasan berhasil diverifikasi!'), backgroundColor: Colors.green));
                            _fetchOrders();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal verifikasi: $e')));
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('VERIFIKASI PELUNASAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                  if (order['status'] == 'PAID') ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _updateLocation(order['id']),
                        icon: const Icon(Icons.local_shipping, size: 16),
                        label: const Text('KIRIM & INPUT RESI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                  if (order['status'] == 'SHIPPED') ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _updateLocation(order['id']),
                        icon: const Icon(Icons.edit_road_outlined, size: 16),
                        label: const Text('UPDATE DETAIL RESI & STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: gold,
                          side: BorderSide(color: gold, width: 0.8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],

                if (order['status'] == 'PENDING' && _userRole != 'PENJUAL' && _userRole != 'ADMIN') ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showPaymentDialog(order, gold),
                          icon: const Icon(Icons.payment, size: 16),
                          label: Text('BAYAR DP (${Globals.formatRupiah(order['dpAmount'])})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2ECC71).withOpacity(0.8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showCancelDialog(order['id']),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('BATAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],

                if (order['status'] == 'DP_PAID') ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top, color: Colors.amber, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Menunggu Verifikasi Penjual', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('Pembayaran DP Anda sedang diperiksa oleh penjual.', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (order['status'] == 'VERIFIED') ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.greenAccent, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('DP Terverifikasi ✓', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('Pesanan Anda sedang diproses oleh penjual.', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (order['status'] == 'PROCESSED' && _userRole != 'PENJUAL' && _userRole != 'ADMIN') ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.05),
                      border: Border.all(color: gold.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.stars, color: gold, size: 18),
                            const SizedBox(width: 12),
                            Text('PESANAN SELESAI DIPROSES', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Karya agung Anda telah siap. Sila selesaikan baki bayaran untuk proses penghantaran.', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showPaymentDialog(order, gold, isPelunasan: true),
                            icon: const Icon(Icons.account_balance_wallet, size: 16),
                            label: Text('BAYAR PELUNASAN (${Globals.formatRupiah(order['totalPrice'] - (order['dpAmount'] ?? 0))})', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (order['status'] == 'FULL_PAY_PAID') ...[
                   const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_bottom, color: Colors.blueAccent, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Menunggu Verifikasi Pelunasan', style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('Bukti pelunasan Anda sedang diperiksa oleh penjual.', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (['SHIPPED', 'PAID', 'FULL_PAY_PAID', 'DELIVERED', 'COMPLETED'].contains(order['status'])) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping, color: Colors.tealAccent, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order['status'] == 'SHIPPED' ? 'Pesanan Dalam Pengiriman' : 'Informasi Pengiriman', 
                                    style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold)
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order['status'] == 'SHIPPED' 
                                      ? 'Pesanan Anda sedang dalam perjalanan.' 
                                      : 'Lacak posisi paket secara real-time di peta.', 
                                    style: const TextStyle(color: Colors.white38, fontSize: 10)
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                         const SizedBox(height: 16),
                         Row(
                           children: [
                             Expanded(
                               child: OutlinedButton.icon(
                                 onPressed: () async {
                                   await Navigator.push(
                                     context,
                                     MaterialPageRoute(builder: (_) => TrackingScreen(orderId: order['id'])),
                                   );
                                   _fetchOrders();
                                 },
                                 icon: const Icon(Icons.receipt_long, size: 14),
                                 label: Text('DETAIL PELACAKAN', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                 style: OutlinedButton.styleFrom(
                                   foregroundColor: Colors.tealAccent,
                                   side: const BorderSide(color: Colors.tealAccent, width: 0.8),
                                   padding: const EdgeInsets.symmetric(vertical: 12),
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                 ),
                               ),
                             ),
                             if (['ADMIN', 'PENJUAL'].contains(_userRole) && order['status'] == 'SHIPPED') ...[
                               const SizedBox(width: 8),
                               Expanded(
                                 child: ElevatedButton.icon(
                                   onPressed: () => _handleMarkDelivered(order['id']),
                                   icon: const Icon(Icons.check_circle_outline, size: 14),
                                   label: const Text('TANDAI SAMPAI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: Colors.greenAccent.withOpacity(0.2),
                                     foregroundColor: Colors.greenAccent,
                                     padding: const EdgeInsets.symmetric(vertical: 12),
                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                   ),
                                 ),
                               ),
                             ] else if (order['status'] == 'SHIPPED' && _userRole != 'ADMIN' && _userRole != 'PENJUAL') ...[
                               const SizedBox(width: 8),
                               Expanded(
                                 child: ElevatedButton.icon(
                                   onPressed: () => _handleMarkDelivered(order['id']),
                                   icon: const Icon(Icons.check_circle, size: 14),
                                   label: const Text('KONFIRMASI TERIMA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: Colors.greenAccent,
                                     foregroundColor: Colors.black,
                                     padding: const EdgeInsets.symmetric(vertical: 12),
                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                   ),
                                 ),
                               ),
                             ],
                           ],
                         ),
                       ],
                     ),
                   ),
                ],

                if (['COMPLETED', 'DELIVERED'].contains(order['status']) && _userRole != 'PENJUAL' && _userRole != 'ADMIN') ...[

                   const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.greenAccent, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Pesanan Selesai ✓', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 2),
                                  Text('Terima kasih telah berbelanja di Tenun Geza!', style: TextStyle(color: Colors.white38, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showReviewDialog(order),
                            icon: const Icon(Icons.rate_review_outlined, size: 14),
                            label: const Text('BERI ULASAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: gold,
                              side: BorderSide(color: gold.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildHistoryOrderCard(dynamic order, Color gold, Color darkAccent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: darkAccent.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        iconColor: gold,
        collapsedIconColor: gold.withOpacity(0.5),
        title: Text('ORDER #${order['id']}', style: GoogleFonts.montserrat(color: gold, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 2)),
        subtitle: Text('Status: ${order['status']} | Total: ${Globals.formatRupiah(order['totalPrice'])}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
        children: [
          _buildBuyerAddress(order),
          ...(order['items'] as List).map<Widget>((item) {
            return ListTile(
              dense: true,
              title: Text(item['product']['name'].toString().toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11)),
              trailing: Text('x${item['quantity']}', style: TextStyle(color: gold, fontSize: 11)),
            );
          }),
          if (['COMPLETED', 'DELIVERED'].contains(order['status']) && _userRole != 'PENJUAL' && _userRole != 'ADMIN')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.greenAccent, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Pesanan Selesai ✓', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('Terima kasih telah berbelanja di Tenun Geza!', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showReviewDialog(order),
                        icon: const Icon(Icons.rate_review_outlined, size: 14),
                        label: const Text('BERI ULASAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: gold,
                          side: BorderSide(color: gold.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker(String status, Color gold) {
    int currentStep = 0;
    if (status == 'DP_PAID') currentStep = 1;
    if (status == 'VERIFIED') currentStep = 2;
    if (status == 'PROCESSED' || status == 'FULL_PAY_PAID') currentStep = 3;
    if (status == 'PAID') currentStep = 4;
    if (status == 'SHIPPED') currentStep = 5;
    if (['DELIVERED', 'COMPLETED'].contains(status)) currentStep = 6;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          _trackerStep(Icons.receipt_outlined, currentStep >= 0, gold),
          _trackerLine(currentStep >= 1, gold),
          _trackerStep(Icons.payments_outlined, currentStep >= 1, gold),
          _trackerLine(currentStep >= 2, gold),
          _trackerStep(Icons.auto_awesome, currentStep >= 2, gold),
          _trackerLine(currentStep >= 3, gold),
          _trackerStep(Icons.inventory_2_outlined, currentStep >= 3, gold),
          _trackerLine(currentStep >= 4, gold),
          _trackerStep(Icons.fact_check_outlined, currentStep >= 4, gold),
          _trackerLine(currentStep >= 5, gold),
          _trackerStep(Icons.local_shipping_outlined, currentStep >= 5, gold),
          _trackerLine(currentStep >= 6, gold),
          _trackerStep(Icons.verified_outlined, currentStep >= 6, gold),
        ],
      ),
    );
  }

  Widget _trackerStep(IconData icon, bool active, Color gold) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: active ? gold.withOpacity(0.15) : Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: active ? gold : Colors.white10),
      ),
      child: Icon(icon, color: active ? gold : Colors.white24, size: 16),
    );
  }

  Widget _trackerLine(bool active, Color gold) {
    return Expanded(
      child: Container(
        height: 1,
        color: active ? gold : Colors.white10,
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.white24;
    String text = status;
    if (status == 'PENDING') { color = Colors.orangeAccent; text = 'Menunggu DP'; }
    if (status == 'DP_PAID') { color = Colors.amber; text = 'Verifikasi DP'; }
    if (status == 'VERIFIED') { color = Colors.lightBlueAccent; text = 'Sedang Diproses'; }
    if (status == 'PROCESSED') { color = Colors.indigoAccent; text = 'Menunggu Pelunasan'; }
    if (status == 'FULL_PAY_PAID') { color = Colors.blue; text = 'Verifikasi Pelunasan'; }
    if (status == 'PAID') { color = Colors.tealAccent; text = 'Sudah Lunas'; }
    if (status == 'SHIPPED') { color = Colors.tealAccent; text = 'Dikirim'; }
    if (status == 'DELIVERED') { color = Colors.greenAccent; text = 'Sampai'; }
    if (status == 'CANCELLED') { color = Colors.redAccent; text = 'Batal'; }
    if (status == 'COMPLETED') { color = Colors.greenAccent; text = 'Selesai'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  void _showCancelDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF130B22),
        title: const Text('Batalkan Pesanan?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text('Tindakan ini tidak dapat dibatalkan.', style: TextStyle(color: Colors.white54, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('TIDAK', style: TextStyle(color: Colors.white24))),
          TextButton(onPressed: () { Navigator.pop(context); _handleCancel(id); }, child: const Text('YA, BATALKAN', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  void _showImagePreviewDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF130B22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Cubit/Pinch untuk memperbesar gambar',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: const Color(0xFF0F0B1E),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.6,
                            ),
                            child: InteractiveViewer(
                              panEnabled: true,
                              minScale: 1.0,
                              maxScale: 4.0,
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, e, st) => const Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                                      SizedBox(height: 12),
                                      Text('Gagal memuat gambar', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showQrisPreview(String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF130B22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'QRIS PEMBAYARAN',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pindai kode QR untuk melakukan pembayaran',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.45,
                            ),
                            child: InteractiveViewer(
                              panEnabled: true,
                              minScale: 1.0,
                              maxScale: 4.0,
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, e, st) => const Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                                      SizedBox(height: 12),
                                      Text('Gagal memuat gambar QRIS',
                                          style: TextStyle(color: Colors.black54, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFF1ABC9C), size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Sentuh dengan dua jari untuk memperbesar (zoom). Anda juga dapat mengambil screenshot untuk membayar via e-wallet.',
                                  style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPaymentDialog(dynamic order, Color gold, {bool isPelunasan = false}) {
    final firstItem = (order['items'] as List)[0];
    final dpAmount = order['dpAmount'] ?? 0;
    final remainingAmount = order['totalPrice'] - dpAmount;
    final paymentAmount = isPelunasan ? remainingAmount : dpAmount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        Map<String, dynamic>? paymentSettings;
        bool modalLoading = true;
        String? modalError;
        XFile? selectedImage;
        bool isUploading = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            if (modalLoading && modalError == null) {
              ApiService.getPaymentSettings().then((data) {
                if (mounted) {
                  setModalState(() {
                    paymentSettings = data;
                    modalLoading = false;
                  });
                }
              }).catchError((e) {
                if (mounted) {
                  setModalState(() {
                    modalError = e.toString();
                    modalLoading = false;
                  });
                }
              });
            }

            return Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
              decoration: const BoxDecoration(
                color: Color(0xFF130B22),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        isPelunasan ? 'KONFIRMASI PELUNASAN' : 'KONFIRMASI PEMBAYARAN DP',
                        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Payment Summary ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(children: [
                        _detailRow('ID Pesanan', 'ORD-${order['id']}'),
                        const SizedBox(height: 8),
                        _detailRow('Produk', firstItem['product']['name']),
                        const Divider(color: Colors.white10, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isPelunasan ? 'Jumlah Pelunasan' : 'Jumlah DP (50%)',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(Globals.formatRupiah(paymentAmount),
                                style: const TextStyle(color: Color(0xFF1ABC9C), fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ]),
                    ),
                    const SizedBox(height: 28),

                    // ── BAYAR ONLINE ──
                    Row(children: [
                      const Expanded(child: Divider(color: Colors.white10)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('BAYAR ONLINE', style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 9, letterSpacing: 3)),
                      ),
                      const Expanded(child: Divider(color: Colors.white10)),
                    ]),
                    const SizedBox(height: 16),

                    // Widget pemilihan channel — diisi oleh FutureBuilder
                    FutureBuilder<Map<String, dynamic>>(
                      future: ApiService.getPaymentConfig(),
                      builder: (ctx, configSnap) {
                        final gateway = configSnap.data?['gateway'] ?? 'midtrans';

                        if (gateway == 'tripay') {
                          // ── TriPay: tampilkan pilihan channel ──
                          return FutureBuilder<List<dynamic>>(
                            future: ApiService.getPaymentChannels(),
                            builder: (ctx2, chSnap) {
                              if (chSnap.connectionState == ConnectionState.waiting) {
                                return const Center(child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2),
                                ));
                              }
                              final channels = chSnap.data ?? [];
                              if (channels.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Tidak ada metode pembayaran online yang tersedia saat ini.\nSilakan gunakan transfer manual.', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                );
                              }
                              // Kelompokkan channel berdasarkan grup
                              final Map<String, List<dynamic>> grouped = {};
                              for (var ch in channels) {
                                final grp = ch['group']?.toString() ?? 'Lainnya';
                                grouped.putIfAbsent(grp, () => []).add(ch);
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Pilih Metode Pembayaran:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                  const SizedBox(height: 12),
                                  ...grouped.entries.map((entry) => Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(entry.key.toUpperCase(), style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          childAspectRatio: 2.5,
                                        ),
                                        itemCount: entry.value.length,
                                        itemBuilder: (ctx3, i) {
                                          final ch = entry.value[i];
                                          return InkWell(
                                            onTap: () {
                                              Navigator.pop(context);
                                              _payWithGateway(order['id'], isPelunasan ? 'FULL' : 'DP', method: ch['code'].toString());
                                            },
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.04),
                                                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                              child: Center(
                                                child: Text(
                                                  ch['name']?.toString() ?? ch['code'],
                                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  )),
                                ],
                              );
                            },
                          );
                        }

                        // ── Midtrans (cadangan): satu tombol besar ──
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _payWithGateway(order['id'], isPelunasan ? 'FULL' : 'DP');
                            },
                            icon: const Icon(Icons.flash_on, size: 18),
                            label: Text('QRIS / VA Bank / GoPay / Kartu Kredit',
                                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    const Center(child: Text('Anda akan diarahkan ke halaman pembayaran',
                        style: TextStyle(color: Colors.white24, fontSize: 10))),
                    const SizedBox(height: 28),

                    // ── TRANSFER MANUAL ──
                    Row(children: [
                      const Expanded(child: Divider(color: Colors.white10)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('ATAU TRANSFER MANUAL', style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 9, letterSpacing: 3)),
                      ),
                      const Expanded(child: Divider(color: Colors.white10)),
                    ]),
                    const SizedBox(height: 16),

                    if (modalLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2),
                      ))
                    else if (modalError != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(8)),
                        child: const Text('Gagal memuat info rekening. Gunakan pembayaran online di atas.',
                            style: TextStyle(color: Colors.white38, fontSize: 11)),
                      )
                    else ...[
                      // Bank info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: gold.withOpacity(0.25)),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: gold.withOpacity(0.1), shape: BoxShape.circle),
                            child: Icon(Icons.account_balance, color: gold, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(paymentSettings!['bankName'] ?? 'BANK',
                                  style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(paymentSettings!['bankAccount'] ?? '-',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                              Text('a.n ${paymentSettings!['accountName'] ?? '-'}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          )),
                        ]),
                      ),

                      // QRIS image if available
                      if ((paymentSettings!['qrisImageUrl'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(children: [
                            Row(children: [
                              const Icon(Icons.qr_code_2, color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Text('BAYAR VIA QRIS', style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ]),
                            const SizedBox(height: 4),
                            const Text('Ketuk gambar untuk memperbesar (preview)', style: TextStyle(color: Colors.white38, fontSize: 9)),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                _showQrisPreview(ApiService.getFormattedImageUrl(paymentSettings!['qrisImageUrl']));
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        ApiService.getFormattedImageUrl(paymentSettings!['qrisImageUrl']),
                                        height: 200, fit: BoxFit.contain,
                                        errorBuilder: (ctx, e, st) => const Text('Gagal memuat gambar QRIS',
                                            style: TextStyle(color: Colors.white38, fontSize: 11)),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),

                    // Upload bukti transfer
                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                        if (pickedFile != null) setModalState(() => selectedImage = pickedFile);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: selectedImage != null ? const Color(0xFF1ABC9C).withOpacity(0.08) : const Color(0xFF1A1128),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selectedImage != null ? const Color(0xFF1ABC9C) : Colors.white10),
                        ),
                        child: Column(children: [
                          Icon(
                            selectedImage != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                            color: selectedImage != null ? const Color(0xFF1ABC9C) : Colors.white24, size: 30,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedImage != null ? '✓ ${selectedImage!.name}' : 'Pilih Bukti Transfer dari Galeri',
                            style: TextStyle(
                              color: selectedImage != null ? const Color(0xFF1ABC9C) : Colors.white54,
                              fontSize: 12, fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (selectedImage == null) ...[
                            const SizedBox(height: 4),
                            const Text('JPG / PNG • Maks 5MB',
                                style: TextStyle(color: Colors.white24, fontSize: 10)),
                          ],
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kirim bukti button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (isUploading || selectedImage == null) ? null : () async {
                          setModalState(() => isUploading = true);
                          Navigator.pop(context);
                          await _handlePayment(order['id'], selectedImage, isFullPayment: isPelunasan);
                        },
                        icon: isUploading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, size: 16),
                        label: Text(
                          isUploading ? 'MENGIRIM...' : 'KIRIM BUKTI TRANSFER',
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1ABC9C),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF1ABC9C).withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('BATAL', style: TextStyle(color: Colors.white24, fontSize: 11)),
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


  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBuyerAddress(dynamic order) {
    if (_userRole != 'PENJUAL' && _userRole != 'ADMIN') return const SizedBox.shrink();
    
    final addresses = order['user']?['addresses'] as List?;
    if (addresses == null || addresses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.white24, size: 14),
            const SizedBox(width: 8),
            Text('Belum ada alamat pengiriman', style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }
    
    final addr = addresses[0];
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.05),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.15)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFD4AF37), size: 16),
              const SizedBox(width: 8),
              Text('ALAMAT PENGIRIMAN', style: GoogleFonts.montserrat(color: const Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(order['user']['name'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${addr['name']} • ${addr['phone']}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            '${addr['streetAddress']}, ${addr['district']}, ${addr['city']}, ${addr['province']} ${addr['postalCode']}',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          if (addr['detailAddress'] != null && addr['detailAddress'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('(${addr['detailAddress']})', style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ),
        ],
      ),
    );
  }
}
