import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageCashierScreen extends StatelessWidget {
  const ManageCashierScreen({super.key});

  static const Color primaryOrange = Color(0xFFFF5A1F);
  static const Color softOrange = Color(0xFFFFEEE8);

  Future<void> _openForm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CashierFormDialog(),
    );

    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun kasir berhasil dibuat')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kelola Akun Kasir',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah Kasir'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', whereIn: ['kasir', 'user'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada akun kasir.\nTekan "Tambah Kasir" untuk membuat.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: softOrange,
                    child: Icon(Icons.person, color: primaryOrange),
                  ),
                  title: Text(
                    (data['username'] ?? '-').toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text((data['email'] ?? '-').toString()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =========================
// DIALOG BUAT AKUN KASIR
// =========================
class _CashierFormDialog extends StatefulWidget {
  const _CashierFormDialog();

  @override
  State<_CashierFormDialog> createState() => _CashierFormDialogState();
}

class _CashierFormDialogState extends State<_CashierFormDialog> {
  final usernameC = TextEditingController();
  final emailC = TextEditingController();
  final passwordC = TextEditingController();

  bool obscure = true;
  bool saving = false;
  String? errorText;

  @override
  void dispose() {
    usernameC.dispose();
    emailC.dispose();
    passwordC.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final username = usernameC.text.trim();
    final email = emailC.text.trim();
    final password = passwordC.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => errorText = 'Semua data harus diisi');
      return;
    }
    if (password.length < 6) {
      setState(() => errorText = 'Password minimal 6 karakter');
      return;
    }

    setState(() {
      saving = true;
      errorText = null;
    });

    FirebaseApp? secondaryApp;

    try {
      // Pakai instance Firebase kedua supaya sesi admin tidak ter-logout
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Simpan data user lewat Firestore utama (login sebagai admin)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'username': username,
        'email': email,
        'role': 'kasir',
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await secondaryAuth.signOut();

      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email sudah terdaftar';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid';
          break;
        case 'weak-password':
          message = 'Password terlalu lemah';
          break;
        default:
          message = e.message ?? 'Gagal membuat akun';
      }
      if (mounted) {
        setState(() {
          saving = false;
          errorText = message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          errorText = 'Terjadi kesalahan: $e';
        });
      }
    } finally {
      await secondaryApp?.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Akun Kasir'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameC,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: emailC,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordC,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: saving ? null : save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5A1F),
            foregroundColor: Colors.white,
          ),
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Buat Akun'),
        ),
      ],
    );
  }
}