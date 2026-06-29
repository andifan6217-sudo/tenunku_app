import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'globals.dart';
import 'api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  int get _totalPrice {
    return Globals.cart.fold(0, (sum, item) => sum + (item['price'] as int) * (item['quantity'] as int));
  }

  int get _totalDP {
    return (_totalPrice * 0.5).toInt();
  }

  void _checkout() async {
    if (Globals.cart.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final items = Globals.cart.map((e) => {
        'productId': e['id'],
        'quantity': e['quantity'],
        'price': e['price'],
        'size': e['size'],
        'notes': e['notes'],
      }).toList();
      
      await ApiService.createOrder(items, _totalPrice, dpAmount: _totalDP);
      Globals.cart.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan Berjaya Direkodkan!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const darkPurple = Color(0xFF130B22);

    return Scaffold(
      backgroundColor: darkPurple,
      appBar: AppBar(
        backgroundColor: darkPurple,
        elevation: 0,
        title: Text('PETI KOLEKSI', style: GoogleFonts.montserrat(color: gold, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 4)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: gold),
      ),
      body: Globals.cart.isEmpty
          ? Center(child: Text('TIADA KOLEKSI DALAM PETI', style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 10, letterSpacing: 4)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: Globals.cart.length,
                    itemBuilder: (context, index) {
                      final item = Globals.cart[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: gold, size: 20),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'].toString().toUpperCase(), style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _infoTag('QTY: ${item['quantity']}', gold),
                                      const SizedBox(width: 8),
                                      _infoTag('SIZE: ${item['size'] ?? '-'}', gold),
                                    ],
                                  ),
                                  if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text('Note: ${item['notes']}', style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic)),
                                    ),
                                ],
                              ),
                            ),
                            Text(Globals.formatRupiah(item['price'] * item['quantity']), style: GoogleFonts.playfairDisplay(color: gold, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white24, size: 18),
                              onPressed: () => setState(() => Globals.cart.removeAt(index)),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(40.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F0918),
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: Column(
                    children: [
                      _summaryRow('SUBTOTAL', Globals.formatRupiah(_totalPrice), Colors.white38, gold),
                      const SizedBox(height: 12),
                      _summaryRow('DP (TANDA JADI)', Globals.formatRupiah(_totalDP), gold.withOpacity(0.8), gold),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white10)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL PESANAN', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.bold)),
                          Text(Globals.formatRupiah(_totalPrice), style: GoogleFonts.playfairDisplay(color: gold, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 40),
                      _isLoading
                          ? const CircularProgressIndicator(color: gold)
                          : SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: gold,
                                  foregroundColor: darkPurple,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                onPressed: _checkout,
                                child: Text('SAHKAN PESANAN', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, letterSpacing: 4, fontSize: 12)),
                              ),
                            ),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  Widget _infoTag(String label, Color gold) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: gold.withOpacity(0.2))),
      child: Text(label, style: GoogleFonts.montserrat(color: gold.withOpacity(0.7), fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _summaryRow(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.montserrat(color: labelColor, fontSize: 9, letterSpacing: 2)),
        Text(value, style: GoogleFonts.montserrat(color: valueColor, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
