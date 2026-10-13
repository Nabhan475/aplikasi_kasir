import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageCashierScreen extends StatefulWidget {
  const ManageCashierScreen({super.key});

  @override
  State<ManageCashierScreen> createState() => _ManageCashierScreenState();
}

class _ManageCashierScreenState extends State<ManageCashierScreen> {
  static const Color primaryColor = Color(0xFF6952AE);
  static const Color lightColor = Color(0xFFAC94F5);

  String? businessId;
  bool loadingBusiness = true;

  @override
  void initState() {
    super.initState();
    loadBusiness();
  }

  // ============================
  // AMBIL BUSINESS ID ADMIN
  // ============================
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

      String? id = doc.data()?['businessId']?.toString();

      // Untuk akun admin lama yang belum mempunyai businessId,
      // otomatis pakai UID admin sebagai businessId.
      if (id == null || id.isEmpty) {
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

  Future<void> _openForm(BuildContext context) async {
    if (businessId == null) return;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CashierFormDialog(businessId: businessId!),
    );

    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun kasir berhasil dibuat')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadingBusiness) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (businessId == null) {
      return const Scaffold(
        body: Center(child: Text('Data usaha tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kelola Akun Kasir',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah Kasir'),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .where('businessId', isEqualTo: businessId)
                .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Hanya tampilkan akun dengan role kasir / user
          final docs =
              snapshot.data!.docs.where((doc) {
                final role = doc.data()['role']?.toString().toLowerCase();

                return role == 'kasir' || role == 'user';
              }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada akun kasir.\n'
                'Tekan "Tambah Kasir" untuk membuat.',
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
                    backgroundColor: lightColor,
                    child: Icon(Icons.person, color: primaryColor),
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

// ===========================================
// DIALOG BUAT AKUN KASIR
// ===========================================
class _CashierFormDialog extends StatefulWidget {
  final String businessId;

  const _CashierFormDialog({required this.businessId});

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
      setState(() {
        errorText = 'Semua data harus diisi';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        errorText = 'Password minimal 6 karakter';
      });
      return;
    }

    setState(() {
      saving = true;
      errorText = null;
    });

    FirebaseApp? secondaryApp;

    try {
      // =================================================
      // FIREBASE SECONDARY
      // =================================================
      // Digunakan supaya ketika admin membuat akun kasir,
      // admin tidak ikut logout.
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Buat akun Authentication untuk kasir
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final adminUser = FirebaseAuth.instance.currentUser;

      // =================================================
      // SIMPAN DATA KASIR
      // =================================================
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            'username': username,
            'email': email,
            'role': 'kasir',

            // PENTING:
            // Kasir mendapatkan businessId milik admin.
            'businessId': widget.businessId,

            // UID admin yang membuat kasir
            'createdBy': adminUser?.uid,

            'createdAt': FieldValue.serverTimestamp(),
          });

      await secondaryAuth.signOut();

      if (!mounted) return;

      Navigator.pop(context, true);
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
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
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
                  onPressed: () {
                    setState(() {
                      obscure = !obscure;
                    });
                  },
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
          onPressed:
              saving
                  ? null
                  : () {
                    Navigator.pop(context, false);
                  },
          child: const Text('Batal'),
        ),

        ElevatedButton(
          onPressed: saving ? null : save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6952AE),
            foregroundColor: Colors.white,
          ),
          child:
              saving
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
