import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const KasirBuburAyamApp());
}

class KasirBuburAyamApp extends StatelessWidget {
  const KasirBuburAyamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kasir Bubur Ayam 72',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}