import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

class SalesDataScreen extends StatefulWidget {
  const SalesDataScreen({super.key});

  @override
  State<SalesDataScreen> createState() => _SalesDataScreenState();
}

class _SalesDataScreenState extends State<SalesDataScreen> {
  static const Color primaryPurple = Color(0xFF6952AE);
  static const Color lightPurple = Color(0xFFAC94F5);
  static const Color backgroundColor = Color(0xFFF7F7FA);

  String? businessId;
  bool loadingBusiness = true;

  // Tanggal yang dipilih untuk filter (default: hari ini)
  DateTime selectedDate = DateTime.now();
  bool showAllDates = false;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    try {
      final id = await getBusinessId();
      if (!mounted) return;
      setState(() {
        businessId = id;
        loadingBusiness = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingBusiness = false);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    if (loadingBusiness) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryPurple),
        ),
      );
    }

    if (businessId == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Data Penjualan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: Text('Data usaha tidak ditemukan. Silakan login ulang.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Data Penjualan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: transactionsRef(businessId!)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Terjadi kesalahan: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryPurple),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];

          // Filter berdasarkan tanggal yang dipilih
          final filteredDocs = allDocs.where((doc) {
            if (showAllDates) return true;
            final ts = doc.data()['createdAt'] as Timestamp?;
            if (ts == null) return false;
            return _isSameDay(ts.toDate(), selectedDate);
          }).toList();

          // Hitung total pemasukan dan total item terjual
          int totalRevenue = 0;
          int totalItemsSold = 0;

          // Rekap penjualan per menu: {menuName: {'qty': int, 'total': int}}
          final Map<String, Map<String, dynamic>> menuSummary = {};

          for (final doc in filteredDocs) {
            final data = doc.data();
            totalRevenue += ((data['total'] as num?) ?? 0).toInt();

            final items = (data['items'] as List<dynamic>?) ?? [];
            for (final raw in items) {
              if (raw is Map<String, dynamic>) {
                final name = (raw['name'] ?? 'Menu').toString();
                final qty = ((raw['qty'] as num?) ?? 0).toInt();
                final subtotal = ((raw['subtotal'] as num?) ?? 0).toInt();

                totalItemsSold += qty;

                if (!menuSummary.containsKey(name)) {
                  menuSummary[name] = {'qty': 0, 'total': 0};
                }
                menuSummary[name]!['qty'] =
                    (menuSummary[name]!['qty'] as int) + qty;
                menuSummary[name]!['total'] =
                    (menuSummary[name]!['total'] as int) + subtotal;
              }
            }
          }

          // Urutkan menu berdasarkan kuantitas terbanyak
          final sortedMenuKeys = menuSummary.keys.toList()
            ..sort((a, b) => (menuSummary[b]!['qty'] as int)
                .compareTo(menuSummary[a]!['qty'] as int));

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =======================================================
                // BAGIAN ATAS: HARI, TANGGAL, DAN TAHUN
                // =======================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tombol mundur hari
                          IconButton(
                            onPressed: () {
                              setState(() {
                                showAllDates = false;
                                selectedDate = selectedDate
                                    .subtract(const Duration(days: 1));
                              });
                            },
                            icon: const Icon(Icons.chevron_left_rounded),
                            color: primaryPurple,
                          ),

                          // Display Tanggal
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                  showAllDates = false;
                                });
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    showAllDates
                                        ? 'Semua Waktu'
                                        : formatTanggalIndonesia(selectedDate),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF26242B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_month_outlined,
                                        size: 13,
                                        color: primaryPurple,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        showAllDates
                                            ? 'Klik untuk pilih tanggal'
                                            : (_isSameDay(selectedDate,
                                                    DateTime.now())
                                                ? 'Hari Ini (Klik untuk ganti)'
                                                : 'Klik untuk ganti tanggal'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Tombol maju hari
                          IconButton(
                            onPressed: () {
                              setState(() {
                                showAllDates = false;
                                selectedDate =
                                    selectedDate.add(const Duration(days: 1));
                              });
                            },
                            icon: const Icon(Icons.chevron_right_rounded),
                            color: primaryPurple,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Shortcut Filter Cepat (Hari Ini & Semua)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  selectedDate = DateTime.now();
                                  showAllDates = false;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: (!showAllDates &&
                                          _isSameDay(
                                              selectedDate, DateTime.now()))
                                      ? primaryPurple
                                      : Colors.grey.shade300,
                                ),
                                backgroundColor: (!showAllDates &&
                                        _isSameDay(
                                            selectedDate, DateTime.now()))
                                    ? lightPurple.withOpacity(0.18)
                                    : Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Hari Ini',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: (!showAllDates &&
                                          _isSameDay(
                                              selectedDate, DateTime.now()))
                                      ? primaryPurple
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  showAllDates = true;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: showAllDates
                                      ? primaryPurple
                                      : Colors.grey.shade300,
                                ),
                                backgroundColor: showAllDates
                                    ? lightPurple.withOpacity(0.18)
                                    : Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Semua Tanggal',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: showAllDates
                                      ? primaryPurple
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // =======================================================
                // RINGKASAN PEMASUKAN & ITEM
                // =======================================================
                Row(
                  children: [
                    // Total Pemasukan
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6952AE), Color(0xFF866FC9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: primaryPurple.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Pemasukan',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatRupiah(totalRevenue),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Total Terjual
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: lightPurple.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_menu_rounded,
                                    color: primaryPurple,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Total Porsi',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$totalItemsSold Porsi',
                              style: const TextStyle(
                                color: Color(0xFF26242B),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // =======================================================
                // BAGIAN BAWAH: MENU APA TERJUAL BERAPA
                // =======================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rekap Menu Terjual',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF26242B),
                      ),
                    ),
                    Text(
                      '${sortedMenuKeys.length} Macam Menu',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                if (sortedMenuKeys.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 36,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Belum ada penjualan pada tanggal ini',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Transaksi kasir akan otomatis terdata di sini secara real-time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedMenuKeys.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final name = sortedMenuKeys[index];
                      final info = menuSummary[name]!;
                      final qty = info['qty'] as int;
                      final subtotal = info['total'] as int;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Row(
                          children: [
                            // Nomor Ranking
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? primaryPurple
                                    : lightPurple.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: index == 0
                                        ? Colors.white
                                        : primaryPurple,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Nama Menu
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF26242B),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    formatRupiah(subtotal),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: primaryPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Terjual Berapa (Qty Badge)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: lightPurple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$qty Terjual',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
