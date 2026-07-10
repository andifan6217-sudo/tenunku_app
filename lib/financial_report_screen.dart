import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'api_service.dart';
import 'globals.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  bool _printing = false;

  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getFinanceReport(_range);
      if (!mounted) return;
      setState(() {
        _data = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
              surfaceContainerHigh: Color(0xFF130B22),
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Color(0xFF130B22),
              headerBackgroundColor: Color(0xFF0F0918),
              headerForegroundColor: Colors.white,
              rangePickerHeaderBackgroundColor: Color(0xFF0F0918),
              rangePickerHeaderForegroundColor: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF130B22)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _range = picked);
      await _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFA67C1E);
    const dark = Color(0xFFF9FAFC);
    const card = Colors.white;

    final fmt = DateFormat('dd MMM yyyy');
    final rangeLabel = '${fmt.format(_range.start)} - ${fmt.format(_range.end)}';

    final totals = (_data?['totals'] as Map?)?.cast<String, dynamic>();
    final orders = (_data?['orders'] as List?)?.cast<dynamic>() ?? const [];

    int v(dynamic x) => (x is num) ? x.toInt() : int.tryParse(x?.toString() ?? '') ?? 0;

    final revenueFullPaid = v(totals?['revenueFullPaid']);
    final dpVerifiedTotal = v(totals?['dpVerifiedTotal']);
    final outstandingDpTotal = v(totals?['outstandingDpTotal']);
    final outstandingFullTotal = v(totals?['outstandingFullTotal']);
    final countOrders = v(totals?['orders']);

    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05), width: 0.8)),
        title: Text(
          'LAPORAN KEUANGAN',
          style: GoogleFonts.montserrat(
            color: gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: gold),
        actions: [
          IconButton(
            onPressed: (_data == null || _loading || _printing) ? null : () => _printReport(),
            icon: _printing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: gold),
                  )
                : const Icon(Icons.print_outlined),
            tooltip: 'Cetak / Download PDF',
          ),
          IconButton(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range_outlined),
            tooltip: 'Pilih rentang tanggal',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : _error != null
               ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal memuat laporan',
                          style: GoogleFonts.montserrat(color: Colors.black87, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.black45, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _fetch,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: gold,
                            side: BorderSide(color: gold.withOpacity(0.6)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('COBA LAGI'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: gold,
                  onRefresh: _fetch,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: card,
                          border: Border.all(color: Colors.black.withOpacity(0.06)),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: gold, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                rangeLabel,
                                style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton(
                              onPressed: _pickRange,
                              child: const Text('UBAH', style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _kpiCard('TOTAL PESANAN', '$countOrders', Icons.receipt_long, gold, card),
                      const SizedBox(height: 12),
                      _kpiCard('PENDAPATAN (LUNAS)', Globals.formatRupiah(revenueFullPaid), Icons.payments_outlined, Colors.green, card),
                      const SizedBox(height: 12),
                      _kpiCard('DP TERVERIFIKASI', Globals.formatRupiah(dpVerifiedTotal), Icons.verified_outlined, gold, card),
                      const SizedBox(height: 12),
                      _kpiCard('TUNGGAKAN DP', Globals.formatRupiah(outstandingDpTotal), Icons.hourglass_top, Colors.orange, card),
                      const SizedBox(height: 12),
                      _kpiCard('TUNGGAKAN PELUNASAN', Globals.formatRupiah(outstandingFullTotal), Icons.hourglass_bottom, Colors.blue, card),

                      const SizedBox(height: 28),
                      Text(
                        'RINCIAN PESANAN',
                        style: GoogleFonts.montserrat(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 4),
                      ),
                      const SizedBox(height: 12),

                      if (orders.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text('Tidak ada transaksi pada rentang ini', style: GoogleFonts.montserrat(color: Colors.black38, fontSize: 11)),
                          ),
                        )
                      else
                        ...orders.map((o) => _orderRow(o, gold, card)),
                    ],
                  ),
                ),
    );
  }

  Future<void> _printReport() async {
    if (_data == null) return;
    setState(() => _printing = true);
    try {
      final pdf = await _buildPdf(_data!, _range);
      final filename = _buildFileName(_range);

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
      if (mounted) setState(() => _printing = false);
    }
  }

  String _buildFileName(DateTimeRange range) {
    final f = DateFormat('yyyyMMdd');
    return 'laporan_keuangan_${f.format(range.start)}-${f.format(range.end)}.pdf';
  }

  Future<pw.Document> _buildPdf(Map<String, dynamic> data, DateTimeRange range) async {
    final doc = pw.Document();
    final fmt = DateFormat('dd MMM yyyy');
    final rangeLabel = '${fmt.format(range.start)} - ${fmt.format(range.end)}';

    final totals = (data['totals'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final orders = (data['orders'] as List?)?.cast<dynamic>() ?? const [];

    int v(dynamic x) => (x is num) ? x.toInt() : int.tryParse(x?.toString() ?? '') ?? 0;

    final revenueFullPaid = v(totals['revenueFullPaid']);
    final dpVerifiedTotal = v(totals['dpVerifiedTotal']);
    final outstandingDpTotal = v(totals['outstandingDpTotal']);
    final outstandingFullTotal = v(totals['outstandingFullTotal']);
    final countOrders = v(totals['orders']);

    pw.TextStyle h1 = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
    pw.TextStyle h2 = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
    pw.TextStyle small = const pw.TextStyle(fontSize: 9);

    pw.Widget kpi(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: small.copyWith(color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Text('LAPORAN KEUANGAN', style: h1),
            pw.SizedBox(height: 4),
            pw.Text('Rentang: $rangeLabel', style: small),
            pw.SizedBox(height: 16),

            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                kpi('Total Pesanan', '$countOrders'),
                kpi('Pendapatan (Lunas)', Globals.formatRupiah(revenueFullPaid)),
                kpi('DP Terverifikasi', Globals.formatRupiah(dpVerifiedTotal)),
                kpi('Tunggakan DP', Globals.formatRupiah(outstandingDpTotal)),
                kpi('Tunggakan Pelunasan', Globals.formatRupiah(outstandingFullTotal)),
              ],
            ),

            pw.SizedBox(height: 18),
            pw.Text('RINCIAN PESANAN', style: h2),
            pw.SizedBox(height: 8),

            if (orders.isEmpty)
              pw.Text('Tidak ada transaksi pada rentang ini.', style: small)
            else
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.1),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1.1),
                  3: const pw.FlexColumnWidth(2.5),
                  4: const pw.FlexColumnWidth(1.2),
                  5: const pw.FlexColumnWidth(1.2),
                  6: const pw.FlexColumnWidth(1.2),
                },
                headers: const ['Order', 'Tanggal', 'Status', 'Produk', 'Total', 'DP', 'Sisa'],
                data: orders.map((o) {
                  final createdAt = DateTime.tryParse(o['createdAt']?.toString() ?? '');
                  final date = createdAt != null ? DateFormat('dd/MM/yy').format(createdAt) : '-';
                  final products = (o['products']?.toString() ?? '-');
                  return [
                    'ORD-${o['id']}',
                    date,
                    o['status']?.toString() ?? '-',
                    products,
                    Globals.formatRupiah(o['totalPrice'] ?? 0),
                    Globals.formatRupiah(o['dpAmount'] ?? 0),
                    Globals.formatRupiah(o['remainingAmount'] ?? 0),
                  ];
                }).toList(),
              ),
          ];
        },
      ),
    );

    return doc;
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color, Color card) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.montserrat(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 2)),
                const SizedBox(height: 6),
                Text(value, style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderRow(dynamic o, Color gold, Color card) {
    final createdAt = DateTime.tryParse(o['createdAt']?.toString() ?? '');
    final date = createdAt != null ? DateFormat('dd MMM yyyy').format(createdAt) : '-';
    final status = o['status']?.toString() ?? '-';
    final total = o['totalPrice'] ?? 0;
    final dp = o['dpAmount'] ?? 0;
    final remaining = o['remainingAmount'] ?? 0;
    final products = o['products']?.toString() ?? '-';
    final customer = o['customerName']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Text('ORD-${o['id']}', style: GoogleFonts.montserrat(color: gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const Spacer(),
              Text(date, style: const TextStyle(color: Colors.black38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(products, style: const TextStyle(color: Colors.black87, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('Pelanggan: $customer', style: const TextStyle(color: Colors.black54, fontSize: 10)),
          const SizedBox(height: 12),
          Row(
            children: [
              _pill('Status: $status', Colors.black38),
              const SizedBox(width: 8),
              _pill('Total: ${Globals.formatRupiah(total)}', gold.withOpacity(0.8)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _mini('DP', Globals.formatRupiah(dp))),
              const SizedBox(width: 8),
              Expanded(child: _mini('Sisa', Globals.formatRupiah(remaining))),
            ],
          )
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(text, style: TextStyle(color: color.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _mini(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black45, fontSize: 9)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

