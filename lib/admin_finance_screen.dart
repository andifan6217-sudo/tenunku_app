import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'api_service.dart';
import 'globals.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> {
  bool _isLoading = true;
  String? _error;
  bool _isPrinting = false;
  
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  Map<String, dynamic>? _reportData;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  List<dynamic> _pendingOrders = [];

  String _searchQuery = '';
  String _statusFilter = 'All'; // All, completed, pending, failed

  // Analytics
  int _totalDpReceived = 0;
  int _totalDpPending = 0;
  int _totalDpRejected = 0;
  int _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiService.getFinanceReport(_range);
      
      final orders = res['orders'] as List? ?? [];
      _processReportData(orders);

      if (!mounted) return;
      setState(() {
        _reportData = res;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _processReportData(List<dynamic> orders) {
    List<Map<String, dynamic>> txList = [];
    List<dynamic> pendingDpOrders = [];

    int totalDpReceived = 0;
    int totalDpPending = 0;
    int totalDpRejected = 0;
    int totalRevenue = 0;

    final fullPaidStatuses = ['PAID', 'SHIPPED', 'DELIVERED', 'COMPLETED'];
    final dpVerifiedStatuses = ['VERIFIED', 'PROCESSED', 'FULL_PAY_PAID', ...fullPaidStatuses];

    for (var o in orders) {
      final orderId = o['id'];
      final createdAtStr = o['createdAt']?.toString() ?? '';
      final customerName = o['customerName']?.toString() ?? 'Pelanggan';
      final totalPrice = (o['totalPrice'] as num?)?.toInt() ?? 0;
      final dpAmount = (o['dpAmount'] as num?)?.toInt() ?? 0;
      final remainingAmount = totalPrice - dpAmount;
      final status = o['status']?.toString() ?? 'PENDING';

      // Keep track of pending DP orders for alerts
      if (status == 'PENDING') {
        pendingDpOrders.add(o);
      }

      // Generate DP Transaction
      if (dpAmount > 0) {
        String dpStatus = 'pending';
        if (dpVerifiedStatuses.contains(status)) {
          dpStatus = 'completed';
          totalDpReceived += dpAmount;
          totalRevenue += dpAmount;
        } else if (status == 'CANCELLED') {
          dpStatus = 'failed';
          totalDpRejected += dpAmount;
        } else {
          dpStatus = 'pending';
          totalDpPending += dpAmount;
        }

        txList.add({
          'id': 'TRX-DP-$orderId',
          'orderId': '$orderId',
          'customerName': customerName,
          'type': 'dp',
          'amount': dpAmount,
          'status': dpStatus,
          'createdAt': createdAtStr,
          'products': o['products'] ?? '',
        });
      }

      // Generate Full Payment Transaction
      if (remainingAmount > 0 && status != 'PENDING' && status != 'DP_PAID') {
        String fpStatus = 'pending';
        if (fullPaidStatuses.contains(status)) {
          fpStatus = 'completed';
          totalRevenue += remainingAmount;
        } else if (status == 'CANCELLED') {
          fpStatus = 'failed';
        }

        txList.add({
          'id': 'TRX-FP-$orderId',
          'orderId': '$orderId',
          'customerName': customerName,
          'type': 'full_payment',
          'amount': remainingAmount,
          'status': fpStatus,
          'createdAt': createdAtStr,
          'products': o['products'] ?? '',
        });
      }
    }

    _transactions = txList;
    _pendingOrders = pendingDpOrders;
    _totalDpReceived = totalDpReceived;
    _totalDpPending = totalDpPending;
    _totalDpRejected = totalDpRejected;
    _totalRevenue = totalRevenue;

    _applyFilters();
  }

  void _applyFilters() {
    _filteredTransactions = _transactions.where((tx) {
      final matchesSearch = tx['id'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx['orderId'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx['customerName'].toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _statusFilter == 'All' || tx['status'] == _statusFilter.toLowerCase();
      
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: _range,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
              surface: Color(0xFF130B22),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF130B22),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _range = picked);
      await _fetchReport();
    }
  }

  Future<void> _printReport() async {
    if (_reportData == null) return;
    setState(() => _isPrinting = true);
    try {
      final pdf = await _buildPdf();
      final fmt = DateFormat('yyyyMMdd');
      final filename = 'laporan_keuangan_${fmt.format(_range.start)}-${fmt.format(_range.end)}.pdf';

      await Printing.layoutPdf(
        name: filename,
        onLayout: (_) async => pdf.save(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencetak: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<pw.Document> _buildPdf() async {
    final doc = pw.Document();
    final fmt = DateFormat('dd MMM yyyy');
    final rangeLabel = '${fmt.format(_range.start)} - ${fmt.format(_range.end)}';

    pw.TextStyle h1 = pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold);
    pw.TextStyle h2 = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    pw.TextStyle small = const pw.TextStyle(fontSize: 8);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Text('LAPORAN KEUANGAN - ADMIN', style: h1),
            pw.SizedBox(height: 4),
            pw.Text('Rentang: $rangeLabel', style: small),
            pw.SizedBox(height: 16),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total DP Masuk: ${Globals.formatRupiah(_totalDpReceived)}', style: small),
                pw.Text('DP Menunggu: ${Globals.formatRupiah(_totalDpPending)}', style: small),
                pw.Text('DP Ditolak/Gagal: ${Globals.formatRupiah(_totalDpRejected)}', style: small),
                pw.Text('Total Pendapatan: ${Globals.formatRupiah(_totalRevenue)}', style: small),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Text('DAFTAR TRANSAKSI', style: h2),
            pw.SizedBox(height: 8),

            if (_transactions.isEmpty)
              pw.Text('Tidak ada transaksi pada rentang ini.', style: small)
            else
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 7),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellAlignment: pw.Alignment.centerLeft,
                headers: const ['TX ID', 'Order ID', 'Pelanggan', 'Tipe', 'Jumlah', 'Status', 'Tanggal'],
                data: _transactions.map((tx) {
                  return [
                    tx['id'],
                    '#${tx['orderId']}',
                    tx['customerName'],
                    tx['type'] == 'dp' ? 'DP' : 'Pelunasan',
                    Globals.formatRupiah(tx['amount']),
                    tx['status'].toString().toUpperCase(),
                    tx['createdAt'].toString().split('T')[0],
                  ];
                }).toList(),
              ),
          ];
        },
      ),
    );
    return doc;
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const darkBg = Color(0xFF0F0B1E);
    const cardBg = Color(0xFF161226);

    final fmt = DateFormat('dd MMM yyyy');
    final rangeLabel = '${fmt.format(_range.start)} - ${fmt.format(_range.end)}';

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'KEUANGAN & DP',
          style: GoogleFonts.montserrat(color: gold, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 4),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isPrinting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: gold))
                : const Icon(Icons.print_outlined, color: gold),
            onPressed: _reportData == null || _isPrinting ? null : _printReport,
            tooltip: 'Cetak Laporan',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: gold),
            onPressed: _fetchReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : _error != null
              ? _buildErrorWidget(gold)
              : RefreshIndicator(
                  color: gold,
                  onRefresh: _fetchReport,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Date range selector
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range, color: gold, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                rangeLabel,
                                style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            TextButton(
                              onPressed: _pickRange,
                              child: const Text('UBAH', style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // KPI Cards
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.35,
                        children: [
                          _buildKpiCard('TOTAL DP MASUK', Globals.formatRupiah(_totalDpReceived), Icons.payments, Colors.greenAccent, cardBg),
                          _buildKpiCard('DP MENUNGGU', Globals.formatRupiah(_totalDpPending), Icons.hourglass_top, Colors.orangeAccent, cardBg),
                          _buildKpiCard('DP DITOLAK', Globals.formatRupiah(_totalDpRejected), Icons.cancel_outlined, Colors.redAccent, cardBg),
                          _buildKpiCard('TOTAL PENDAPATAN', Globals.formatRupiah(_totalRevenue), Icons.account_balance, gold, cardBg),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Alerts for unpaid DP orders
                      if (_pendingOrders.isNotEmpty) ...[
                        _buildAlertSection(gold),
                        const SizedBox(height: 24),
                      ],

                      // Transactions log header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DAFTAR TRANSAKSI',
                            style: GoogleFonts.montserrat(color: gold.withOpacity(0.6), fontSize: 10, letterSpacing: 4, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_filteredTransactions.length} Transaksi',
                            style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Search & Filter controls
                      _buildSearchAndFilters(gold, cardBg),
                      const SizedBox(height: 16),

                      // Transactions
                      if (_filteredTransactions.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          alignment: Alignment.center,
                          child: const Text(
                            'Tidak ada transaksi',
                            style: TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = _filteredTransactions[index];
                            return _buildTransactionRow(tx, gold, cardBg);
                          },
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              Icon(icon, color: color.withOpacity(0.8), size: 16),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Periode terpilih',
            style: TextStyle(color: Colors.white12, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSection(Color gold) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'PESANAN MENUNGGU PEMBAYARAN DP',
                style: GoogleFonts.montserrat(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingOrders.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 12),
            itemBuilder: (context, idx) {
              final o = _pendingOrders[idx];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${o['id']} - ${o['customerName']}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          o['products'] ?? 'Item tenun',
                          style: const TextStyle(color: Colors.white30, fontSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Globals.formatRupiah(o['dpAmount']),
                    style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(Color gold, Color bg) {
    return Column(
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                _applyFilters();
              });
            },
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Cari log transaksi...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Colors.white30, size: 16),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: ['All', 'Completed', 'Pending', 'Failed'].map((filter) {
            bool isSelected = _statusFilter == filter;
            String label = filter == 'All' ? 'Semua' : filter == 'Completed' ? 'Berhasil' : filter == 'Pending' ? 'Pending' : 'Gagal';
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 10)),
                selected: isSelected,
                selectedColor: gold,
                backgroundColor: bg,
                checkmarkColor: Colors.black,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _statusFilter = filter;
                      _applyFilters();
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTransactionRow(Map<String, dynamic> tx, Color gold, Color bg) {
    final isDp = tx['type'] == 'dp';
    final isSuccess = tx['status'] == 'completed';
    final isFailed = tx['status'] == 'failed';

    Color statusColor = Colors.orangeAccent;
    String statusLabel = 'PENDING';
    if (isSuccess) {
      statusColor = Colors.greenAccent;
      statusLabel = 'BERHASIL';
    } else if (isFailed) {
      statusColor = Colors.redAccent;
      statusLabel = 'GAGAL';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDp ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDp ? Icons.payment : Icons.done_all,
              color: isDp ? Colors.blueAccent : Colors.greenAccent,
              size: 16,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tx['id'],
                      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDp ? Colors.blueAccent.withOpacity(0.1) : gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isDp ? 'DP' : 'PELUNASAN',
                        style: TextStyle(color: isDp ? Colors.blueAccent : gold, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Order #${tx['orderId']} • ${tx['customerName']}',
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Globals.formatRupiah(tx['amount']),
                style: GoogleFonts.montserrat(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withOpacity(0.2), width: 0.5),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Color gold) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat keuangan',
              style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _fetchReport,
              style: OutlinedButton.styleFrom(foregroundColor: gold, side: BorderSide(color: gold.withOpacity(0.6))),
              child: const Text('COBA LAGI'),
            ),
          ],
        ),
      ),
    );
  }
}
