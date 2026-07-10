import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'globals.dart';

class SellerPaymentsView extends StatefulWidget {
  const SellerPaymentsView({super.key});

  @override
  State<SellerPaymentsView> createState() => _SellerPaymentsViewState();
}

class _SellerPaymentsViewState extends State<SellerPaymentsView> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, completed, pending, failed

  // Finance metrics
  int _totalReceived = 0;
  int _pendingPayments = 0;
  int _totalDpReceived = 0;
  String _growth = '0%';
  bool _isGrowthPositive = true;

  int _countSuccess = 0;
  int _countPending = 0;
  int _countFailed = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch orders for the last year
      final range = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 365)),
        end: DateTime.now(),
      );
      final res = await ApiService.getFinanceReport(range);
      final orders = res['orders'] as List? ?? [];
      
      _processOrdersAndTransactions(orders);
      
      if (!mounted) return;
      setState(() {
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

  void _processOrdersAndTransactions(List<dynamic> orders) {
    List<Map<String, dynamic>> txList = [];
    int totalReceived = 0;
    int pendingPayments = 0;
    int totalDpReceived = 0;

    int countSuccess = 0;
    int countPending = 0;
    int countFailed = 0;

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
      
      // Calculate received, pending, dp values
      if (fullPaidStatuses.contains(status)) {
        totalReceived += totalPrice;
        totalDpReceived += dpAmount;
      } else if (dpVerifiedStatuses.contains(status)) {
        totalReceived += dpAmount;
        totalDpReceived += dpAmount;
        if (status == 'PROCESSED') {
          pendingPayments += remainingAmount;
        } else if (status == 'FULL_PAY_PAID') {
          pendingPayments += remainingAmount;
        }
      } else {
        // PENDING, DP_PAID
        pendingPayments += dpAmount;
      }

      // Generate DP Transaction
      if (dpAmount > 0) {
        String dpStatus = 'pending';
        if (dpVerifiedStatuses.contains(status)) {
          dpStatus = 'completed';
        } else if (status == 'CANCELLED') {
          dpStatus = 'failed';
        }

        txList.add({
          'id': 'TRX-DP-$orderId',
          'orderId': '$orderId',
          'customerName': customerName,
          'type': 'dp',
          'amount': dpAmount,
          'status': dpStatus,
          'createdAt': createdAtStr,
        });

        if (dpStatus == 'completed') countSuccess++;
        if (dpStatus == 'pending') countPending++;
        if (dpStatus == 'failed') countFailed++;
      }

      // Generate Full Payment Transaction
      if (remainingAmount > 0) {
        String fpStatus = 'pending';
        if (fullPaidStatuses.contains(status)) {
          fpStatus = 'completed';
        } else if (status == 'CANCELLED') {
          fpStatus = 'failed';
        }

        // Only add full payment transaction if the order has progressed past DP verification
        // or if it's already full_pay_paid
        if (status != 'PENDING' && status != 'DP_PAID') {
          txList.add({
            'id': 'TRX-FP-$orderId',
            'orderId': '$orderId',
            'customerName': customerName,
            'type': 'full_payment',
            'amount': remainingAmount,
            'status': fpStatus,
            'createdAt': createdAtStr,
          });

          if (fpStatus == 'completed') countSuccess++;
          if (fpStatus == 'pending') countPending++;
          if (fpStatus == 'failed') countFailed++;
        }
      }
    }

    // Growth calculation (comparing last 30 days vs 30 days before that)
    final nowTime = DateTime.now();
    final thirtyDaysAgo = nowTime.subtract(const Duration(days: 30));
    final sixtyDaysAgo = nowTime.subtract(const Duration(days: 60));

    int currentPeriodRevenue = 0;
    int previousPeriodRevenue = 0;

    for (var o in orders) {
      final createdAtStr = o['createdAt']?.toString() ?? '';
      if (createdAtStr.isEmpty) continue;
      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt == null) continue;

      int orderRevenue = 0;
      final totalPrice = (o['totalPrice'] as num?)?.toInt() ?? 0;
      final dpAmount = (o['dpAmount'] as num?)?.toInt() ?? 0;
      final status = o['status']?.toString() ?? 'PENDING';

      if (fullPaidStatuses.contains(status)) {
        orderRevenue = totalPrice;
      } else if (dpVerifiedStatuses.contains(status)) {
        orderRevenue = dpAmount;
      }

      if (createdAt.isAfter(thirtyDaysAgo) && createdAt.isBefore(nowTime)) {
        currentPeriodRevenue += orderRevenue;
      } else if (createdAt.isAfter(sixtyDaysAgo) && createdAt.isBefore(thirtyDaysAgo)) {
        previousPeriodRevenue += orderRevenue;
      }
    }

    String growthText = '0%';
    bool isGrowthPositive = true;
    if (previousPeriodRevenue == 0) {
      if (currentPeriodRevenue > 0) {
        growthText = '+100%';
        isGrowthPositive = true;
      } else {
        growthText = '0%';
        isGrowthPositive = true;
      }
    } else {
      final growthPercent = ((currentPeriodRevenue - previousPeriodRevenue) / previousPeriodRevenue) * 100;
      final sign = growthPercent >= 0 ? '+' : '';
      growthText = '$sign${growthPercent.toStringAsFixed(1)}%';
      isGrowthPositive = growthPercent >= 0;
    }

    _transactions = txList;
    _totalReceived = totalReceived;
    _pendingPayments = pendingPayments;
    _totalDpReceived = totalDpReceived;
    _growth = growthText;
    _isGrowthPositive = isGrowthPositive;
    _countSuccess = countSuccess;
    _countPending = countPending;
    _countFailed = countFailed;
    
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

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFA67C1E);
    const lightBg = Color(0xFFF9FAFC);
    const cardBg = Colors.white;

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0x0D000000), width: 0.8)),
        title: Text(
          'PEMBAYARAN TOKO',
          style: GoogleFonts.montserrat(color: gold, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 4),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: gold, size: 20),
            onPressed: _fetchData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : _error != null
              ? _buildErrorWidget(gold)
              : RefreshIndicator(
                  color: gold,
                  onRefresh: _fetchData,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'ANALISIS KEUANGAN',
                        style: GoogleFonts.montserrat(color: Colors.black54, fontSize: 10, letterSpacing: 4, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // KPI Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.4,
                        children: [
                          _buildKpiCard('TOTAL DITERIMA', Globals.formatRupiah(_totalReceived), Icons.check_circle_outline, Colors.green, cardBg),
                          _buildKpiCard('PENDING VERIFIKASI', Globals.formatRupiah(_pendingPayments), Icons.hourglass_empty, Colors.orange, cardBg),
                          _buildKpiCard('TOTAL DP MASUK', Globals.formatRupiah(_totalDpReceived), Icons.payments_outlined, gold, cardBg),
                          _buildKpiCard('PERTUMBUHAN', _growth, _isGrowthPositive ? Icons.trending_up : Icons.trending_down, _isGrowthPositive ? Colors.green : Colors.redAccent, cardBg),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Status Summary Counters
                      Row(
                        children: [
                          Expanded(child: _buildCounterTile('Berhasil', _countSuccess, Colors.green, cardBg)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildCounterTile('Pending', _countPending, Colors.orange, cardBg)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildCounterTile('Gagal', _countFailed, Colors.redAccent, cardBg)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Search and Filter Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RIWAYAT TRANSAKSI',
                            style: GoogleFonts.montserrat(color: Colors.black54, fontSize: 10, letterSpacing: 4, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_filteredTransactions.length} Transaksi',
                            style: GoogleFonts.montserrat(color: Colors.black38, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Search and filter controls
                      _buildSearchAndFilters(gold, cardBg),
                      const SizedBox(height: 16),
                      
                      // Transaction list
                      if (_filteredTransactions.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          alignment: Alignment.center,
                          child: Text(
                            'Tidak ada transaksi ditemukan',
                            style: TextStyle(color: Colors.black38, fontSize: 12, fontStyle: FontStyle.italic),
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
        border: Border.all(color: Colors.black.withOpacity(0.06)),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(color: Colors.black45, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              Icon(icon, color: color.withOpacity(0.8), size: 16),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            'Bulan ini',
            style: TextStyle(color: Colors.black38, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterTile(String label, int count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: GoogleFonts.montserrat(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: Colors.black45, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(Color gold, Color bg) {
    return Column(
      children: [
        // Search text field
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                _applyFilters();
              });
            },
            style: const TextStyle(color: Colors.black87, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Cari transaksi, order, pelanggan...',
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Colors.black45, size: 16),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Filter pills
        Row(
          children: ['All', 'Completed', 'Pending', 'Failed'].map((filter) {
            bool isSelected = _statusFilter == filter;
            String label = filter == 'All' ? 'Semua' : filter == 'Completed' ? 'Berhasil' : filter == 'Pending' ? 'Pending' : 'Gagal';
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontSize: 10)),
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

    Color statusColor = Colors.orange;
    String statusLabel = 'PENDING';
    if (isSuccess) {
      statusColor = Colors.green;
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
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
          // Icon indicator
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDp ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDp ? Icons.payment : Icons.done_all,
              color: isDp ? Colors.blue : Colors.green,
              size: 16,
            ),
          ),
          const SizedBox(width: 14),
          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tx['id'],
                      style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
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
                  style: const TextStyle(color: Colors.black45, fontSize: 9),
                ),
              ],
            ),
          ),
          // Amount & status column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Globals.formatRupiah(tx['amount']),
                style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
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
              'Gagal memuat pembayaran',
              style: GoogleFonts.montserrat(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: const TextStyle(color: Colors.black45, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _fetchData,
              style: OutlinedButton.styleFrom(foregroundColor: gold, side: BorderSide(color: gold.withOpacity(0.6))),
              child: const Text('COBA LAGI'),
            ),
          ],
        ),
      ),
    );
  }
}
