import 'package:flutter/material.dart';

/// Warna & gaya yang dipakai bersama oleh halaman Login dan Register.
class AuthStyle {
  AuthStyle._();

  static const Color primaryColor = Color(0xFF6952AE);
  static const Color lightColor = Color(0xFFAC94F5);
  static const Color lightField = Color(0xFFF4F4F4);

  static InputDecoration input({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 15),
      filled: true,
      fillColor: lightField,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: primaryColor, width: 1.3),
      ),
    );
  }
}
