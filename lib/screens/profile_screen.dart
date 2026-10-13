import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color primaryPurple = Color(0xFF6952AE);
  static const Color backgroundColor = Color(0xFFF7F7F7);
  static const Color lightPurple = Color(0xFFAC94F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // =========================
              // PROFILE CARD
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  children: [
                    // AVATAR
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: lightPurple.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryPurple, width: 3),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 55,
                        color: primaryPurple,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // NAMA
                    const Text(
                      'Nama Pengguna',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // EMAIL
                    const Text(
                      'admin@example.com',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),

                    const SizedBox(height: 14),

                    // ROLE
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: lightPurple.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Admin',
                        style: TextStyle(
                          color: primaryPurple,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =========================
              // INFO CARD
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: const Column(
                  children: [
                    ProfileInfoRow(
                      icon: Icons.person_outline,
                      title: 'Username',
                      value: 'Nama Pengguna',
                    ),

                    Divider(height: 28),

                    ProfileInfoRow(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: 'admin@example.com',
                    ),

                    Divider(height: 28),

                    ProfileInfoRow(
                      icon: Icons.badge_outlined,
                      title: 'Role',
                      value: 'Admin',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // =========================
              // LOGOUT BUTTON
              // =========================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  // Hapus semua halaman di stack supaya tombol back tidak bisa kembali ke halaman admin/kasir
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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

// =========================
// PROFILE INFO ROW
// =========================
class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6952AE);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFAC94F5).withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person_outline, color: primaryPurple),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
