import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_style.dart';
import 'main_navigation.dart';

import '../user_service.dart';

/// Isi form login (tanpa header / panel putih).
/// Header & panel dikelola oleh LoginScreen supaya bisa dianimasikan.
class LoginForm extends StatefulWidget {
  /// Dipanggil saat link "Register" ditekan
  final VoidCallback onRegisterTap;

  const LoginForm({super.key, required this.onRegisterTap});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password harus diisi')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ambil role dari Firestore (users/{uid}/role)
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .get();

      final roleDb = (doc.data()?['role'] ?? 'user').toString().toLowerCase();
      final appRole = roleDb == 'admin' ? 'Admin' : 'Kasir';

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainNavigation(role: appRole)),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login gagal';

      if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      } else if (e.code == 'user-not-found') {
        message = 'Akun tidak ditemukan';
      } else if (e.code == 'wrong-password') {
        message = 'Password salah';
      } else if (e.code == 'invalid-credential') {
        message = 'Email atau password salah';
      } else {
        message = e.message ?? 'Login gagal';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
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
      String message = 'Login dengan Google gagal';

      if (e.code == 'account-exists-with-different-credential') {
        message = 'Akun dengan email ini sudah ada dengan metode login lain';
      } else if (e.code == 'invalid-credential') {
        message = 'Kredensial yang diberikan tidak valid';
      } else {
        message = e.message ?? 'Login dengan Google gagal';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login dengan Google gagal: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AuthStyle.primaryColor;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),

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

          const SizedBox(height: 36),

          // LOGIN BUTTON
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isLoading ? null : login,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
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
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),

          const SizedBox(height: 5),

          const Text('or', style: TextStyle(color: Colors.grey, fontSize: 15)),

          const SizedBox(height: 5),

          // GOOGLE BUTTON
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              onPressed: isLoading ? null : _signInWithGoogle,
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
                          Text(
                            'Sign in with Google',
                            style: TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
            ),
          ),

          const SizedBox(height: 10),

          // REGISTER LINK
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Belum punya akun? ',
                style: TextStyle(color: Colors.black87, fontSize: 14),
              ),
              GestureDetector(
                onTap: isLoading ? null : widget.onRegisterTap,
                child: const Text(
                  'Register',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
