import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'manage_cashier_screen.dart';
import 'utils.dart';

/// Halaman profil.
/// Data diambil real-time dari Firestore: users/{uid}
/// (username, email, role, businessId, createdAt).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color purple = Color(0xFF6952AE);
  static const Color lightPurple = Color(0xFFAC94F5);
  static const Color bg = Color(0xFFF7F6FA);
  static const Color ink = Color(0xFF292532);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Text('Sesi login tidak ditemukan. Silakan login ulang.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: purple),
            );
          }

          final data = snap.data?.data() ?? <String, dynamic>{};

          final name = _firstNotEmpty([
            data['username'],
            user.displayName,
            'Pengguna',
          ]);
          final email = _firstNotEmpty([data['email'], user.email, '-']);
          final isAdmin = (data['role'] ?? '').toString().toLowerCase() ==
              'admin';

          String? businessId = data['businessId']?.toString();
          if ((businessId == null || businessId.isEmpty) && isAdmin) {
            businessId = user.uid;
          }
          final hasBusiness = businessId != null && businessId.isNotEmpty;

          final createdAt = data['createdAt'];
          final joined =
              createdAt is Timestamp
                  ? formatTanggalIndonesia(createdAt.toDate())
                  : '-';

          return SingleChildScrollView(
            // padding bawah supaya konten tidak tertutup navbar melayang
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              children: [
                _Header(
                  name: name,
                  email: email,
                  isAdmin: isAdmin,
                  photoUrl: user.photoURL,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),

                      if (hasBusiness) ...[
                        _TodayStats(businessId: businessId),
                        const SizedBox(height: 16),
                      ],

                      // ===== INFO AKUN =====
                      _Card(
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Username',
                              value: name,
                            ),
                            const _Divider(),
                            _InfoRow(
                              icon: Icons.mail_outline_rounded,
                              label: 'Email',
                              value: email,
                            ),
                            const _Divider(),
                            _InfoRow(
                              icon: Icons.verified_user_outlined,
                              label: 'Peran',
                              value: isAdmin ? 'Admin' : 'Kasir',
                            ),
                            const _Divider(),
                            _InfoRow(
                              icon: Icons.calendar_month_outlined,
                              label: 'Bergabung sejak',
                              value: joined,
                            ),
                          ],
                        ),
                      ),

                      // ===== KELOLA KASIR (hanya admin) =====
                      if (isAdmin && hasBusiness) ...[
                        const SizedBox(height: 16),
                        _CashierCard(businessId: businessId),
                      ],

                      const SizedBox(height: 22),

                      // ===== LOGOUT =====
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmLogout(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text(
                            'Keluar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _firstNotEmpty(List<dynamic> values) {
    for (final v in values) {
      final s = v?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
    return '-';
  }

  static Future<void> _confirmLogout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Keluar dari akun?'),
            content: const Text('Anda perlu login lagi untuk memakai aplikasi.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Keluar'),
              ),
            ],
          ),
    );

    if (yes != true) return;

    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    // Hapus semua halaman di stack supaya tombol back tidak bisa kembali
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

// ==========================================
// HEADER (gradient + avatar)
// ==========================================
class _Header extends StatelessWidget {
  final String name;
  final String email;
  final bool isAdmin;
  final String? photoUrl;

  const _Header({
    required this.name,
    required this.email,
    required this.isAdmin,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top + 18, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8068CB), ProfileScreen.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Column(
        children: [
          const Text(
            'Profil Saya',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // AVATAR
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: Colors.white,
              backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
              child:
                  hasPhoto
                      ? null
                      : Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: ProfileScreen.purple,
                        ),
                      ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFE9E1FF), fontSize: 13),
          ),
          const SizedBox(height: 14),

          // CHIP ROLE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAdmin
                      ? Icons.admin_panel_settings_outlined
                      : Icons.point_of_sale_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isAdmin ? 'Admin' : 'Kasir',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// STATISTIK HARI INI (transaksi & pendapatan)
// ==========================================
class _TodayStats extends StatelessWidget {
  final String businessId;

  const _TodayStats({required this.businessId});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          transactionsRef(businessId)
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        int revenue = 0;
        for (final d in docs) {
          revenue += ((d.data()['total'] as num?) ?? 0).toInt();
        }

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.receipt_long_rounded,
                color: ProfileScreen.purple,
                soft: const Color(0xFFEDE7FF),
                label: 'Transaksi hari ini',
                value: '${docs.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF35A78E),
                soft: const Color(0xFFE5F7F2),
                label: 'Pendapatan hari ini',
                value: formatRupiah(revenue),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color soft;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.soft,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ProfileScreen.ink,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// KARTU KELOLA KASIR (admin)
// ==========================================
class _CashierCard extends StatelessWidget {
  final String businessId;

  const _CashierCard({required this.businessId});

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageCashierScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      onTap: () => _open(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.group_add_outlined,
                  color: ProfileScreen.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Akun Kasir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ProfileScreen.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .where('businessId', isEqualTo: businessId)
                              .snapshots(),
                      builder: (context, snap) {
                        final count =
                            (snap.data?.docs ?? []).where((d) {
                              final role =
                                  d.data()['role']?.toString().toLowerCase();
                              return role == 'kasir' || role == 'user';
                            }).length;
                        return Text(
                          count == 0
                              ? 'Belum ada kasir terdaftar'
                              : '$count kasir terdaftar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: ProfileScreen.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _open(context),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: const Text(
                'Tambah Kasir',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// KOMPONEN KECIL
// ==========================================
class _Card extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Card({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFECE8F3)),
        boxShadow: [
          BoxShadow(
            color: ProfileScreen.purple.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Color(0xFFF0EDF5)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ProfileScreen.lightPurple.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: ProfileScreen.purple, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: ProfileScreen.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}