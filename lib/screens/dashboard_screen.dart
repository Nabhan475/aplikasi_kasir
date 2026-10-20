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
  static const Color primaryPurple = Color(0xFF6952AE);
  static const Color backgroundColor = Color(0xFFF7F7FA);

  String username = 'Admin';
  bool loadingUser = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // =====================================================
  // AMBIL DATA USER YANG SEDANG LOGIN
  // =====================================================
  Future<void> loadUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            loadingUser = false;
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

      if (!mounted) return;

      setState(() {
        username = (data?['username'] ?? 'Admin').toString();
        loadingUser = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingUser = false;
      });
    }
  }

  // =====================================================
  // FITUR BELUM DIBUAT
  // =====================================================
  void comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature sedang dalam pengembangan'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================================
              // HEADER PROFILE
              // =====================================================
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E2FF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: primaryPurple,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hello,',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),

                        const SizedBox(height: 2),

                        loadingUser
                            ? Container(
                              width: 85,
                              height: 15,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            )
                            : Text(
                              username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF26242B),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // =====================================================
              // RINGKASAN USAHA
              // =====================================================
              Container(
                width: double.infinity,
                height: 98,
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFEAE6F5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ringkasan Usaha',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF26242B),
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            'Kelola aktivitas usaha\n'
                            'dalam satu tempat.',
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.3,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE7FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: primaryPurple,
                        size: 29,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // =====================================================
              // TITLE
              // =====================================================
              const Text(
                'Kelola Usaha',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF26242B),
                ),
              ),

              const SizedBox(height: 10),

              // =====================================================
              // BARIS 1
              // =====================================================
              Row(
                children: [
                  Expanded(
                    child: DashboardFeatureCard(
                      title: 'Kelola Kasir',
                      subtitle: 'Akun karyawan',
                      icon: Icons.group_add_outlined,
                      accentColor: const Color(0xFF6952AE),
                      softColor: const Color(0xFFEDE7FF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageCashierScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: DashboardFeatureCard(
                      title: 'Riwayat',
                      subtitle: 'Transaksi',
                      icon: Icons.receipt_long_outlined,
                      accentColor: const Color(0xFF4F7FDB),
                      softColor: const Color(0xFFE9F0FF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransactionHistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              // =====================================================
              // BARIS 2
              // =====================================================
              Row(
                children: [
                  Expanded(
                    child: DashboardFeatureCard(
                      title: 'Inventori',
                      subtitle: 'Stok bahan',
                      icon: Icons.inventory_2_outlined,
                      accentColor: const Color(0xFFE05F67),
                      softColor: const Color(0xFFFFEDEE),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InventoriScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: DashboardFeatureCard(
                      title: 'Shift',
                      subtitle: 'Jadwal karyawan',
                      icon: Icons.schedule_rounded,
                      accentColor: const Color(0xFF44A992),
                      softColor: const Color(0xFFE5F7F2),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ShiftScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              // =====================================================
              // BARIS 3
              // =====================================================
              Row(
                children: [
                  Expanded(
                    child: DashboardFeatureCard(
                      title: 'Pesanan Online',
                      subtitle: 'Pesanan terjadwal',
                      icon: Icons.shopping_bag_outlined,
                      accentColor: const Color(0xFFC95BB7),
                      softColor: const Color(0xFFFCE9F9),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PesananOnlineScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: DashboardFeatureCard(
                      title: 'Diskon',
                      subtitle: 'Promo',
                      icon: Icons.discount_outlined,
                      accentColor: const Color(0xFFE59A37),
                      softColor: const Color(0xFFFFF3DF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DiskonScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // =====================================================
              // AKTIVITAS HARI INI
              // =====================================================
              Expanded(
                child: Container(
                  width: double.infinity,

                  padding: const EdgeInsets.fromLTRB(16, 11, 16, 9),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.025),
                        blurRadius: 9,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // =========================
                      // HEADER
                      // =========================
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Aktivitas Hari Ini',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF29272F),
                              ),
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE7FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Hari ini',
                              style: TextStyle(
                                color: primaryPurple,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // =========================
                      // STATISTIK
                      // =========================
                      const Row(
                        children: [
                          Expanded(
                            child: ActivityItem(
                              icon: Icons.receipt_long_outlined,
                              value: '0',
                              title: 'Transaksi',
                              iconColor: Color(0xFF6952AE),
                              iconBackground: Color(0xFFEDE7FF),
                            ),
                          ),

                          ActivityDivider(),

                          Expanded(
                            child: ActivityItem(
                              icon: Icons.shopping_bag_outlined,
                              value: '0',
                              title: 'Pesanan',
                              iconColor: Color(0xFFC95BB7),
                              iconBackground: Color(0xFFFCE9F9),
                            ),
                          ),

                          ActivityDivider(),

                          Expanded(
                            child: ActivityItem(
                              icon: Icons.inventory_2_outlined,
                              value: '0',
                              title: 'Stok',
                              iconColor: Color(0xFFE05F67),
                              iconBackground: Color(0xFFFFEDEE),
                            ),
                          ),
                        ],
                      ),

                      // =========================
                      // STATUS
                      // =========================
                      Container(
                        width: double.infinity,

                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),

                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7FA),
                          borderRadius: BorderRadius.circular(10),
                        ),

                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: Color(0xFF44A992),
                              size: 14,
                            ),

                            SizedBox(width: 7),

                            Expanded(
                              child: Text(
                                'Operasional usaha berjalan normal',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  color: Color(0xFF777777),
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
        ),
      ),
    );
  }
}

// ======================================================
// CARD MENU
// ======================================================

class DashboardFeatureCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  final Color accentColor;
  final Color softColor;

  final VoidCallback onTap;

  const DashboardFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.softColor,
    required this.onTap,
  });

  @override
  State<DashboardFeatureCard> createState() => _DashboardFeatureCardState();
}

class _DashboardFeatureCardState extends State<DashboardFeatureCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          pressed = true;
        });
      },

      onTapCancel: () {
        setState(() {
          pressed = false;
        });
      },

      onTapUp: (_) {
        setState(() {
          pressed = false;
        });

        widget.onTap();
      },

      child: AnimatedScale(
        scale: pressed ? 0.97 : 1,

        duration: const Duration(milliseconds: 120),

        curve: Curves.easeOut,

        child: Container(
          height: 78,

          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color:
                  pressed
                      ? widget.accentColor.withOpacity(0.35)
                      : const Color(0xFFEEEEEE),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Row(
            children: [
              // ICON
              Container(
                width: 38,
                height: 38,

                decoration: BoxDecoration(
                  color: widget.softColor,
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Icon(widget.icon, color: widget.accentColor, size: 20),
              ),

              const SizedBox(width: 9),

              // TEXT
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF29272F),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      widget.subtitle,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(fontSize: 9, color: Colors.grey),
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
}

// ======================================================
// ITEM AKTIVITAS
// ======================================================

class ActivityItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;
  final Color iconColor;
  final Color iconBackground;

  const ActivityItem({
    super.key,
    required this.icon,
    required this.value,
    required this.title,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,

          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(9),
          ),

          child: Icon(icon, color: iconColor, size: 16),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF29272F),
          ),
        ),

        const SizedBox(height: 1),

        Text(title, style: const TextStyle(fontSize: 8, color: Colors.grey)),
      ],
    );
  }
}

// ======================================================
// DIVIDER AKTIVITAS
// ======================================================

class ActivityDivider extends StatelessWidget {
  const ActivityDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: const Color(0xFFEAEAEA));
  }
}
