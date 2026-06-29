import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_service.dart';

class TrackingScreen extends StatefulWidget {
  final int orderId;
  const TrackingScreen({super.key, required this.orderId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin {
  static const _gold = Color(0xFFD4AF37);
  static const _dark = Color(0xFF0F0918);
  static const _darkCard = Color(0xFF1A1030);

  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  String? _userRole;
  bool _isUpdating = false;

  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _courierController = TextEditingController();
  final TextEditingController _awbController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchOrderData());
  }

  Future<void> _loadInitialData() async {
    try {
      final role = await ApiService.getRole();
      if (mounted) setState(() => _userRole = role);
      await _fetchOrderData();
    } catch (e) {
      debugPrint('Error loading role: $e');
      _fetchOrderData();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _statusController.dispose();
    _courierController.dispose();
    _awbController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrderData() async {
    try {
      final order = await ApiService.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
          _error = null;

          if (_statusController.text.isEmpty) _statusController.text = order['trackingStatus'] ?? '';
          if (_courierController.text.isEmpty) _courierController.text = order['courierName'] ?? '';
          if (_awbController.text.isEmpty) _awbController.text = order['awbNumber'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _handleUpdateTracking() async {
    setState(() => _isUpdating = true);
    try {
      await ApiService.updateTracking(
        widget.orderId, 
        courierName: _courierController.text,
        awbNumber: _awbController.text,
        trackingStatus: _statusController.text
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informasi pelacakan berhasil diperbarui!'), backgroundColor: Colors.teal),
        );
        _fetchOrderData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui pelacakan: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleMarkDelivered() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _darkCard,
        shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.greenAccent, width: 0.5), borderRadius: BorderRadius.circular(12)),
        title: const Text('Konfirmasi Sampai', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin pesanan ini telah sampai ke tujuan?', style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL', style: TextStyle(color: Colors.white24))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('YA, SAMPAI', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUpdating = true);
    try {
      await ApiService.updateOrderStatus(widget.orderId, 'DELIVERED');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status diperbarui: PESANAN SAMPAI'), backgroundColor: Colors.green));
        await _fetchOrderData();
        if (_userRole != 'ADMIN' && _userRole != 'PENJUAL') {
          _showReviewDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showReviewDialog() async {
    if (_order == null) return;
    final items = _order!['items'] as List;
    final Map<int, dynamic> uniqueProducts = {};
    for (var i in items) {
      uniqueProducts[i['productId']] = i;
    }
    final productList = uniqueProducts.values.toList();
    
    int? selectedProductId = productList.isNotEmpty ? productList[0]['productId'] : null;
    int rating = 5;
    final commentCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF130B22),
          title: Text('BERI ULASAN', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
          content: Column(
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
                  icon: Icon(Icons.star, color: i < rating ? const Color(0xFFD4AF37) : Colors.white10),
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
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL', style: TextStyle(color: Colors.white24))),
            TextButton(
              onPressed: () async {
                try {
                  if (selectedProductId == null) return;
                  await ApiService.submitReview(selectedProductId!, rating, commentCtrl.text);
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terima kasih atas ulasan anda!')));
                    await _fetchOrderData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                  }
                }
              }, 
              child: const Text('KIRIM', style: TextStyle(color: Color(0xFFD4AF37)))
            ),
          ],
        ),
      ),
    );
    commentCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        backgroundColor: _darkCard,
        elevation: 0,
        title: Text('PELACAKAN PESANAN', style: GoogleFonts.montserrat(color: _gold, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _gold),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _gold),
            onPressed: _fetchOrderData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
            const SizedBox(height: 20),
            Text('Gagal Memuat Data', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () { setState(() => _isLoading = true); _fetchOrderData(); },
              style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black),
              child: const Text('COBA LAGI'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final status = _order?['status'] ?? 'UNKNOWN';
    final trackingStatus = _order?['trackingStatus'] ?? '';
    final courierName = _order?['courierName'] ?? '';
    final awbNumber = _order?['awbNumber'] ?? '';
    final isAdmin = _userRole == 'ADMIN';
    final isSeller = _userRole == 'PENJUAL';
    final isStaff = isAdmin || isSeller;
    
    final statusInfo = _getStatusInfo(status);
    final items = _order?['items'] as List? ?? [];
    final productNames = items.map((i) => i['product']?['name'] ?? '').join(', ');

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PESANAN #${widget.orderId}',
                  style: GoogleFonts.montserrat(color: _gold, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withOpacity(0.15),
                    border: Border.all(color: statusInfo.color.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusInfo.label,
                    style: TextStyle(color: statusInfo.color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (productNames.isNotEmpty)
              Text(
                productNames,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 24),

            _buildProgressBar(status),

            const SizedBox(height: 32),

            // Resi Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _gold.withOpacity(0.2)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, color: _gold, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'INFORMASI PENGIRIMAN',
                        style: GoogleFonts.montserrat(color: _gold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('Kurir Ekspedisi', courierName.isNotEmpty ? courierName : '-'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Nomor Resi', awbNumber.isNotEmpty ? awbNumber : '-'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Status Terakhir', trackingStatus.isNotEmpty ? trackingStatus : 'Menunggu update status...'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (isStaff) ...[
              // ADMIN UPDATE UI
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UPDATE RESI / STATUS PENGIRIMAN',
                      style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _courierController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _inputDeco('Nama Kurir (JNE, J&T, dll)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _awbController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _inputDeco('Nomor Resi / AWB'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _statusController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _inputDeco('Status / Posisi Paket Saat Ini'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isUpdating ? null : _handleUpdateTracking,
                            icon: _isUpdating 
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Icon(Icons.cloud_upload, size: 18),
                            label: Text(
                              _isUpdating ? '...' : 'UPDATE PROGRES',
                              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        if (status == 'SHIPPED') ...[
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: OutlinedButton.icon(
                              onPressed: _isUpdating ? null : _handleMarkDelivered,
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: Text(
                                'SAMPAI',
                                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.greenAccent,
                                side: const BorderSide(color: Colors.greenAccent, width: 0.8),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (status == 'SHIPPED') ...[
              // BUYER CONFIRMATION UI
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : _handleMarkDelivered,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: Text(
                    'KONFIRMASI PESANAN DITERIMA',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
            
            if (!isStaff && status == 'DELIVERED') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showReviewDialog,
                  icon: const Icon(Icons.stars, size: 18),
                  label: Text('BERI ULASAN PRODUK', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1)), borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _gold), borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.black12,
    );
  }

  Widget _buildProgressBar(String status) {
    final steps = [
      _StepInfo('Dipesan', Icons.receipt_long, ['PENDING', 'DP_PAID', 'VERIFIED', 'PAID', 'PROCESSED', 'SHIPPED', 'DELIVERED', 'COMPLETED']),
      _StepInfo('Diproses', Icons.engineering, ['VERIFIED', 'PAID', 'PROCESSED', 'SHIPPED', 'DELIVERED', 'COMPLETED']),
      _StepInfo('Dikirim', Icons.local_shipping, ['SHIPPED', 'DELIVERED', 'COMPLETED']),
      _StepInfo('Sampai', Icons.check_circle, ['DELIVERED', 'COMPLETED']),
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final prevStep = steps[index ~/ 2];
          final isActive = prevStep.activeStatuses.contains(status);
          return Expanded(
            child: Container(
              height: 2,
              color: isActive ? _gold : Colors.white10,
            ),
          );
        }
        final step = steps[index ~/ 2];
        final isActive = step.activeStatuses.contains(status);
        final isCurrent = _isCurrentStep(status, index ~/ 2);

        return Column(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? _gold.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: isCurrent ? _gold : isActive ? _gold.withOpacity(0.5) : Colors.white10,
                  width: isCurrent ? 2 : 1,
                ),
                boxShadow: isCurrent ? [BoxShadow(color: _gold.withOpacity(0.3), blurRadius: 8)] : null,
              ),
              child: Icon(step.icon, color: isActive ? _gold : Colors.white38, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              step.label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white38,
                fontSize: 10,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }

  bool _isCurrentStep(String status, int stepIndex) {
    if (status == 'CANCELLED') return false;
    switch (stepIndex) {
      case 0: return ['PENDING', 'DP_PAID', 'PAID'].contains(status);
      case 1: return ['VERIFIED', 'PROCESSED'].contains(status);
      case 2: return status == 'SHIPPED';
      case 3: return ['DELIVERED', 'COMPLETED'].contains(status);
      default: return false;
    }
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'PENDING': return _StatusInfo('Menunggu Pembayaran', Colors.orange);
      case 'DP_PAID': return _StatusInfo('DP Dibayar (Tunggu Verifikasi)', Colors.blue);
      case 'VERIFIED': return _StatusInfo('Pembayaran Diverifikasi', Colors.greenAccent);
      case 'PROCESSED': return _StatusInfo('Diproses / Ditenun', Colors.purpleAccent);
      case 'FULL_PAY_PAID': return _StatusInfo('Lunas (Tunggu Verifikasi)', Colors.blue);
      case 'PAID': return _StatusInfo('Lunas', Colors.green);
      case 'SHIPPED': return _StatusInfo('Dikirim', Colors.lightBlueAccent);
      case 'DELIVERED': return _StatusInfo('Sampai Tujuan', Colors.green);
      case 'COMPLETED': return _StatusInfo('Selesai', Colors.teal);
      case 'CANCELLED': return _StatusInfo('Dibatalkan', Colors.red);
      default: return _StatusInfo(status, Colors.grey);
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  _StatusInfo(this.label, this.color);
}
class _StepInfo {
  final String label;
  final IconData icon;
  final List<String> activeStatuses;
  _StepInfo(this.label, this.icon, this.activeStatuses);
}
