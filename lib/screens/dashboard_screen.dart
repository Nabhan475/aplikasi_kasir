import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'manage_cashier_screen.dart';
import 'transaction_history_screen.dart';
import 'inventori_screen.dart';
import 'shift_screen.dart';
import 'pesanan_online_screen.dart';
import 'diskon_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const purple = Color(0xFF6952AE);
  static const bg = Color(0xFFF7F6FA);

  String username = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!mounted) return;
      setState(() {
        username = doc.data()?['username']?.toString() ?? 'Admin';
      });
    } catch (_) {}
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = (constraints.maxHeight / 760).clamp(0.72, 1.0);
            double s(double n) => n * scale;

            return Padding(
              padding: EdgeInsets.fromLTRB(s(16), s(12), s(16), s(68)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    children: [
                      Container(
                        width: s(48),
                        height: s(48),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAE2FF),
                          borderRadius: BorderRadius.circular(s(16)),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: purple,
                          size: s(27),
                        ),
                      ),
                      SizedBox(width: s(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello,',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: s(12),
                              ),
                            ),
                            Text(
                              username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: s(19),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF292532),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: s(15)),

                  // RINGKASAN USAHA
                  Container(
                    width: double.infinity,
                    height: s(105),
                    padding: EdgeInsets.symmetric(horizontal: s(19)),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8068CB), Color(0xFF6952AE)],
                      ),
                      borderRadius: BorderRadius.circular(s(23)),
                      boxShadow: [
                        BoxShadow(
                          color: purple.withValues(alpha: 0.17),
                          blurRadius: s(12),
                          offset: Offset(0, s(4)),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ringkasan Usaha',
                                style: TextStyle(
                                  fontSize: s(18),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: s(5)),
                              Text(
                                'Kelola aktivitas usaha\n'
                                'dalam satu tempat.',
                                style: TextStyle(
                                  fontSize: s(11),
                                  height: 1.3,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: s(56),
                          height: s(56),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.17),
                            borderRadius: BorderRadius.circular(s(17)),
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                            size: s(30),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: s(16)),

                  Text(
                    'Kelola Usaha',
                    style: TextStyle(
                      fontSize: s(18),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF292532),
                    ),
                  ),
                  SizedBox(height: s(11)),

                  // ENAM MENU
                  Row(
                    children: [
                      Expanded(
                        child: _menu(
                          s,
                          'Kelola Kasir',
                          'Akun karyawan',
                          Icons.group_add_outlined,
                          purple,
                          const Color(0xFFEDE7FF),
                          () => _open(const ManageCashierScreen()),
                        ),
                      ),
                      SizedBox(width: s(12)),
                      Expanded(
                        child: _menu(
                          s,
                          'Riwayat',
                          'Transaksi',
                          Icons.receipt_long_outlined,
                          const Color(0xFF4F7FDB),
                          const Color(0xFFE9F0FF),
                          () => _open(const TransactionHistoryScreen()),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: s(11)),
                  Row(
                    children: [
                      Expanded(
                        child: _menu(
                          s,
                          'Inventori',
                          'Bahan baku',
                          Icons.inventory_2_outlined,
                          const Color(0xFFE05F67),
                          const Color(0xFFFFEDEE),
                          () => _open(const InventoriScreen()),
                        ),
                      ),
                      SizedBox(width: s(12)),
                      Expanded(
                        child: _menu(
                          s,
                          'Shift',
                          'Jadwal karyawan',
                          Icons.schedule_rounded,
                          const Color(0xFF35A78E),
                          const Color(0xFFE5F7F2),
                          () => _open(const ShiftScreen()),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: s(11)),
                  Row(
                    children: [
                      Expanded(
                        child: _menu(
                          s,
                          'Pesanan Online',
                          'Pesanan terjadwal',
                          Icons.shopping_bag_outlined,
                          const Color(0xFFC454B0),
                          const Color(0xFFFCE9F9),
                          () => _open(const PesananOnlineScreen()),
                        ),
                      ),
                      SizedBox(width: s(12)),
                      Expanded(
                        child: _menu(
                          s,
                          'Diskon',
                          'Promo menu',
                          Icons.discount_outlined,
                          const Color(0xFFE59A37),
                          const Color(0xFFFFF3DF),
                          () => _open(const DiskonScreen()),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: s(10)),

                  // AKTIVITAS - KONTEN LEBIH RINGKAS
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: s(14),
                        vertical: s(8),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(s(21)),
                        border: Border.all(color: const Color(0xFFECE7F4)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Aktivitas Hari Ini',
                                  style: TextStyle(
                                    fontSize: s(15),
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF292532),
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: s(10),
                                  vertical: s(5),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE7FF),
                                  borderRadius: BorderRadius.circular(s(12)),
                                ),
                                child: Text(
                                  'Hari ini',
                                  style: TextStyle(
                                    color: purple,
                                    fontSize: s(10),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: s(5)),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _activity(
                                    s,
                                    Icons.receipt_long_rounded,
                                    '0',
                                    'Transaksi',
                                    purple,
                                    const Color(0xFFEDE7FF),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: s(40),
                                  color: const Color(0xFFEAE6F0),
                                ),
                                Expanded(
                                  child: _activity(
                                    s,
                                    Icons.shopping_bag_outlined,
                                    '0',
                                    'Pesanan',
                                    const Color(0xFFC454B0),
                                    const Color(0xFFFCE9F9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: s(9),
                              vertical: s(7),
                            ),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(s(11)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: const Color(0xFF35A78E),
                                  size: s(15),
                                ),
                                SizedBox(width: s(7)),
                                Expanded(
                                  child: Text(
                                    'Operasional usaha berjalan normal',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: s(10),
                                      color: Colors.grey.shade600,
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _menu(
    double Function(double) s,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Color soft,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(s(19)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s(19)),
        child: Container(
          height: s(92),
          padding: EdgeInsets.symmetric(horizontal: s(10)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(s(19)),
            border: Border.all(color: const Color(0xFFEEEEF2)),
          ),
          child: Row(
            children: [
              Container(
                width: s(44),
                height: s(44),
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(s(14)),
                ),
                child: Icon(icon, color: color, size: s(23)),
              ),
              SizedBox(width: s(9)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: s(12.5),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF292532),
                      ),
                    ),
                    SizedBox(height: s(5)),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: s(9.5),
                        color: Colors.grey.shade500,
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
  }

  Widget _activity(
    double Function(double) s,
    IconData icon,
    String value,
    String label,
    Color color,
    Color soft,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: s(34),
          height: s(34),
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(s(11)),
          ),
          child: Icon(icon, color: color, size: s(18)),
        ),
        SizedBox(height: s(3)),
        Text(
          value,
          style: TextStyle(
            fontSize: s(16),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF292532),
          ),
        ),
        SizedBox(height: s(1)),
        Text(
          label,
          style: TextStyle(fontSize: s(10), color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
