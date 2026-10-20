import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_style.dart';
import 'main_navigation.dart';
import '../user_service.dart';

/// Isi form register (tanpa header / panel putih).
/// Header & panel dikelola oleh LoginScreen supaya bisa dianimasikan.
class RegisterForm extends StatefulWidget {
  /// Dipanggil saat link "Login" ditekan, dan setelah registrasi berhasil
  final VoidCallback onLoginTap;

  const RegisterForm({super.key, required this.onLoginTap});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua data harus diisi')));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ============================
      // 1. BUAT AKUN FIREBASE AUTH
      // ============================
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final String uid = userCredential.user!.uid;

      // ============================
      // 2. SIMPAN DATA ADMIN
      // ============================
      //
      // Untuk admin:
      // businessId = UID admin sendiri.
      //
      // Jadi setiap admin mempunyai bisnis/data sendiri.
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username,
        'email': email,
        'role': 'admin',

        // ID bisnis milik admin
        'businessId': uid,

        // Pemilik bisnis
        'ownerId': uid,

        'createdAt': FieldValue.serverTimestamp(),
      });

      // Verifikasi bahwa data berhasil ditulis dengan benar
      final verifyDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!verifyDoc.exists) {
        throw Exception('Gagal memverifikasi pembuatan pengguna');
      }

      final verifyData = verifyDoc.data();
      if (verifyData == null ||
          verifyData['role'] != 'admin' ||
          verifyData['email'] != email ||
          verifyData['username'] != username) {
        throw Exception('Data pengguna tidak sesuai dengan yang diharapkan');
      }

      // createUserWithEmailAndPassword otomatis login
      // maka kita logout agar kembali ke halaman login.
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi berhasil, silakan login')),
      );

      // Kembali ke form login (dengan animasi)
      widget.onLoginTap();
    } on FirebaseAuthException catch (e) {
      String message = 'Registrasi gagal';

      if (e.code == 'email-already-in-use') {
        message = 'Email sudah terdaftar';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      } else if (e.code == 'weak-password') {
        message = 'Password terlalu lemah';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Login Email/Password belum diaktifkan di Firebase';
      } else {
        message = e.message ?? 'Registrasi gagal';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _registerWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      // TODO: For web, you need to configure your Google Sign-In client ID
      // Get it from: Firebase Console -> Project Settings -> General -> Your web app
      // Or: Google Cloud Console -> APIs & Services -> Credentials -> OAuth 2.0 Client IDs
      // Format: 1234567890-abcdef.apps.googleusercontent.com
      //
      // For Android/iOS, client ID is configured via google-services.json and GoogleService-Info.plist
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn(
            clientId:
                '478231720986-sq1r9ht5n9f3jqdkjnmemuqa909uo94d.apps.googleusercontent.com',
          ).signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Obtain Google auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      // Buat dokumen users bila belum ada (akun baru = admin), lalu ambil role
      final appRole = await ensureGoogleUser(userCredential.user!);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainNavigation(role: appRole)),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Registrasi dengan Google gagal';

      if (e.code == 'account-exists-with-different-credential') {
        message = 'Akun dengan email ini sudah ada dengan metode login lain';
      } else if (e.code == 'invalid-credential') {
        message = 'Kredensial yang diberikan tidak valid';
      } else {
        message = e.message ?? 'Registrasi dengan Google gagal';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registrasi dengan Google gagal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : register,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthStyle.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child:
            isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                : const Text(
                  'REGISTER',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: isLoading ? null : _registerWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Color(0xFFDDDDDD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child:
            isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black87,
                  ),
                )
                : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'G',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Sign in with Google', style: TextStyle(fontSize: 15)),
                  ],
                ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Sudah punya akun? ',
          style: TextStyle(color: Colors.black87, fontSize: 14),
        ),
        GestureDetector(
          onTap: isLoading ? null : widget.onLoginTap,
          child: const Text(
            'Login',
            style: TextStyle(
              color: AuthStyle.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // USERNAME
          TextField(
            controller: usernameController,
            textInputAction: TextInputAction.next,
            decoration: AuthStyle.input(hint: 'Username'),
          ),

          const SizedBox(height: 12),

          // EMAIL
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: AuthStyle.input(hint: 'Email'),
          ),

          const SizedBox(height: 12),

          // PASSWORD
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: AuthStyle.input(
              hint: 'Password',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // REGISTER BUTTON
          _buildRegisterButton(),

          const SizedBox(height: 12),

          const Text('or', style: TextStyle(color: Colors.grey, fontSize: 15)),

          const SizedBox(height: 12),

          // GOOGLE BUTTON
          _buildGoogleButton(),

          const SizedBox(height: 16),

          // LOGIN LINK
          _buildLoginLink(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
