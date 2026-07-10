import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import 'globals.dart';

class SellerProductsScreen extends StatefulWidget {
  final bool showAppBar;
  const SellerProductsScreen({super.key, this.showAppBar = true});

  @override
  State<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends State<SellerProductsScreen> {
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  int get _totalProduct => _allProducts.length;
  int get _activeProduct => _allProducts.where((p) => p['status'] == 'ACTIVE').length;
  int get _lowStockProduct => _allProducts.where((p) => p['stock'] <= 5).length;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _filteredProducts = _allProducts
          .where((p) => p['name'].toString().toLowerCase().contains(_searchCtrl.text.toLowerCase()))
          .toList();
    });
  }

  Future<void> _fetchProducts() async {
    try {
      final products = await ApiService.getProducts();
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFA67C1E);
    const scaffoldBg = Color(0xFFF9FAFC);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05), width: 0.8)),
        title: Text('PRODUK SAYA', style: GoogleFonts.montserrat(color: gold, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 4)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFA67C1E)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Color(0xFFA67C1E)), onPressed: () => _showProductDialog(null)),
        ],
      ) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFA67C1E)))
          : Column(
              children: [
                _buildStatsHeader(gold),
                _buildSearchField(gold),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _buildProductItem(product, gold, scaffoldBg)
                          .animate()
                          .fadeIn(delay: (index * 50).ms)
                          .slideX(begin: 0.1);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsHeader(Color gold) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.06)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('TOTAL', _totalProduct.toString(), gold),
          _statItem('AKTIF', _activeProduct.toString(), Colors.green),
          _statItem('LOW', _lowStockProduct.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.montserrat(color: Colors.black38, fontSize: 7.5, letterSpacing: 1.5)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.montserrat(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSearchField(Color gold) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          controller: _searchCtrl,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(color: Colors.black87, fontSize: 11),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            hintText: 'Cari produk kebanggaan anda...',
            hintStyle: GoogleFonts.montserrat(color: Colors.black45, fontSize: 10),
            prefixIcon: Icon(Icons.search, color: gold, size: 16),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildProductItem(dynamic product, Color gold, Color lightBg) {
    final bool isActive = product['status'] == 'ACTIVE';

    final String imageUrl = ApiService.getFormattedImageUrl(product['imageUrl']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                  image: imageUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: imageUrl.isEmpty
                    ? const Icon(Icons.image_outlined, color: Colors.black38)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'].toString().toUpperCase(), style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      product['description'] ?? 'No description',
                      style: const TextStyle(color: Colors.black45, fontSize: 10, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _infoBadge(Icons.star, product['rating'].toString(), Colors.orange),
                        const SizedBox(width: 8),
                        _infoBadge(Icons.inventory_2, 'Stok: ${product['stock']}', gold),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                   _statusBadge(isActive),
                   const SizedBox(height: 12),
                    Text(Globals.formatRupiah(product['price']), style: GoogleFonts.playfairDisplay(color: gold, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.black12, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _actionBtn(Icons.edit_outlined, 'Edit', gold, () => _showProductDialog(product)),
              const SizedBox(width: 12),
              _actionBtn(Icons.power_settings_new_outlined, isActive ? 'Nonaktif' : 'Aktifkan', isActive ? Colors.orange : Colors.green, () => _toggleStatus(product['id'])),
              const SizedBox(width: 12),
              _actionBtn(Icons.delete_outline, 'Hapus', Colors.red, () => _confirmDelete(product['id'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(2)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        isActive ? 'AKTIF' : 'NONAKTIF',
        style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.3))),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showProductDialog(dynamic product) {
    final bool isEdit = product != null;
    final nameCtrl = TextEditingController(text: isEdit ? product['name'] : '');
    final descCtrl = TextEditingController(text: isEdit ? product['description'] : '');
    final priceCtrl = TextEditingController(text: isEdit ? product['price'].toString() : '');
    final stockCtrl = TextEditingController(text: isEdit ? product['stock'].toString() : '');
    final ratingCtrl = TextEditingController(text: isEdit ? product['rating'].toString() : '0.0');
    
    XFile? pickedFile;
    Uint8List? pickedFileBytes;
    String? currentImageUrl = isEdit ? product['imageUrl'] : null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.black.withOpacity(0.06)),
                ),
                title: Text(isEdit ? 'Ubah Koleksi' : 'Koleksi Baru', style: GoogleFonts.playfairDisplay(color: const Color(0xFFA67C1E))),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Image Picker UI
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            try {
                              final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                final bytes = await image.readAsBytes();
                                setDialogState(() {
                                  pickedFile = image;
                                  pickedFileBytes = bytes;
                                });
                              }
                            } catch (e) {
                              debugPrint("Image picking error: $e");
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFA67C1E).withOpacity(0.4), width: 1),
                            ),
                            child: pickedFileBytes != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(pickedFileBytes!, fit: BoxFit.cover))
                                : currentImageUrl != null && currentImageUrl.isNotEmpty
                                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(ApiService.getFormattedImageUrl(currentImageUrl), fit: BoxFit.cover))
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add_a_photo_outlined, color: Color(0xFFA67C1E), size: 40),
                                          const SizedBox(height: 12),
                                          Text('TAP UNTUK PILIH FOTO', style: GoogleFonts.montserrat(color: const Color(0xFFA67C1E), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          const Text('(PNG, JPG)', style: TextStyle(color: Colors.black38, fontSize: 8)),
                                        ],
                                      ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _dialogInput(nameCtrl, 'NAMA KAIN'),
                      _dialogInput(descCtrl, 'DESKRIPSI (CERITA DI BALIK KAIN)'),
                      _dialogInput(priceCtrl, 'HARGA (Rp)', type: TextInputType.number),
                      _dialogInput(stockCtrl, 'JUMLAH STOK', type: TextInputType.number),
                      _dialogInput(ratingCtrl, 'RATING (0.0 - 5.0)', type: TextInputType.number),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL', style: TextStyle(color: Colors.black54))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA67C1E), foregroundColor: Colors.white),
                    onPressed: () async {
                      try {
                        // Sanitize numeric inputs (remove dots/commas commonly used in ID formatting)
                        final cleanPrice = priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                        final cleanStock = stockCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                        
                        if (nameCtrl.text.isEmpty || cleanPrice.isEmpty || cleanStock.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi semua data wajib')));
                          return;
                        }

                        String imageUrl = currentImageUrl ?? '';
                        
                        // If new image picked, upload it first
                        if (pickedFile != null) {
                          final uploadedUrl = await ApiService.uploadImage(pickedFile!);
                          if (uploadedUrl != null) imageUrl = uploadedUrl;
                        }

                        if (isEdit) {
                           await ApiService.updateProduct(product['id'], nameCtrl.text, descCtrl.text, int.parse(cleanPrice), imageUrl, int.parse(cleanStock), status: product['status']);
                        } else {
                           await ApiService.addProduct(nameCtrl.text, descCtrl.text, int.parse(cleanPrice), imageUrl, int.parse(cleanStock));
                        }
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _fetchProducts();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Produk diperbarui' : 'Produk ditambahkan')));
                        }
                      } catch (e) {
                         debugPrint("Save error: $e");
                        if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
                      }
                    },
                    child: Text(isEdit ? 'SIMPAN PERUBAHAN' : 'TERBITKAN'),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _dialogInput(TextEditingController ctrl, String label, {TextInputType type = TextInputType.text}) {
    const gold = Color(0xFFA67C1E);
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.black87, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: gold.withOpacity(0.6), fontSize: 9, letterSpacing: 2),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black.withOpacity(0.12))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA67C1E))),
      ),
    );
  }

  void _toggleStatus(int id) async {
    try {
      await ApiService.toggleProductStatus(id);
      _fetchProducts();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengubah status')));
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
        title: const Text('Hapus Koleksi?', style: TextStyle(color: Colors.black87)),
        content: const Text('Tindakan ini tidak dapat dibatalkan.', style: TextStyle(color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL', style: TextStyle(color: Colors.black54))),
          TextButton(onPressed: () async {
            try {
              await ApiService.deleteProduct(id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _fetchProducts();
              }
            } catch (e) {
              if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus')));
            }
          }, child: const Text('HAPUS', style: TextStyle(color: Colors.red))),
        ],
      )
    );
  }
}
