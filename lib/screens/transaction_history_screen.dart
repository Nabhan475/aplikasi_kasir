import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'utils.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  static const Color primaryPurple = Color(0xFF6952AE);

  String? businessId;

  bool loadingBusiness = true;

  @override
  void initState() {
    super.initState();

    loadBusiness();
  }

  // ====================================
  // AMBIL BUSINESS ID USER LOGIN
  // ====================================

  Future<void> loadBusiness() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            loadingBusiness = false;
          });
        }

        return;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final data = doc.data();

      String? id = data?['businessId']?.toString();

      // Untuk admin lama yang belum punya
      // businessId
      if ((id == null || id.isEmpty) &&
          data?['role']?.toString().toLowerCase() == 'admin') {
        id = user.uid;

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'businessId': id,
          'ownerId': user.uid,
        }, SetOptions(merge: true));
      }

      if (!mounted) return;

      setState(() {
        businessId = id;
        loadingBusiness = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingBusiness = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil data usaha: $e')));
    }
  }

  // ====================================
  // FORMAT TANGGAL
  // ====================================

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return '-';
    }

    final date = timestamp.toDate();

    String two(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${two(date.day)}/'
        '${two(date.month)}/'
        '${date.year} '
        '${two(date.hour)}:'
        '${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    if (loadingBusiness) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (businessId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Data usaha tidak ditemukan.\n'
            'Silakan login ulang.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ======================================
      // HANYA TRANSAKSI DARI BUSINESS INI
      // ======================================
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: transactionsRef(businessId!).snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan: '
                '${snapshot.error}',
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Copy data supaya bisa di-sort
          final docs = snapshot.data!.docs.toList();

          // ==================================
          // URUTKAN TRANSAKSI TERBARU
          // ==================================
          //
          // Kita sort di aplikasi supaya tidak
          // perlu composite index Firestore.
          docs.sort((a, b) {
            final timeA = a.data()['createdAt'];

            final timeB = b.data()['createdAt'];

            if (timeA is! Timestamp && timeB is! Timestamp) {
              return 0;
            }

            if (timeA is! Timestamp) {
              return 1;
            }

            if (timeB is! Timestamp) {
              return -1;
            }

            return timeB.compareTo(timeA);
          });

          // Batasi maksimal 100 transaksi
          final limitedDocs = docs.length > 100 ? docs.sublist(0, 100) : docs;

          if (limitedDocs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada transaksi',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),

            itemCount: limitedDocs.length,

            separatorBuilder: (_, __) => const SizedBox(height: 10),

            itemBuilder: (context, index) {
              final data = limitedDocs[index].data();

              final total = (data['total'] as num?)?.toInt() ?? 0;

              final totalItems = (data['totalItems'] as num?)?.toInt() ?? 0;

              final items = (data['items'] as List?) ?? [];

              final cashierEmail = (data['cashierEmail'] ?? '-').toString();

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),

                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),

                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),

                    title: Text(
                      formatRupiah(total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryPurple,
                        fontSize: 17,
                      ),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        Text(
                          '${_formatDate(data['createdAt'] as Timestamp?)}  •  '
                          '$totalItems item',
                        ),

                        const SizedBox(height: 3),

                        Text(
                          'Kasir: '
                          '$cashierEmail',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),

                    children: [
                      const Divider(),

                      for (final raw in items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${raw['qty']}x '
                                  '${raw['name']}',
                                ),
                              ),

                              const SizedBox(width: 10),

                              Text(
                                formatRupiah((raw['subtotal'] as num?) ?? 0),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
