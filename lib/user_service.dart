import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Pastikan dokumen users/{uid} ada untuk akun Google.
/// - Akun baru  -> dibuat dengan role 'admin' (businessId = uid)
/// - Akun lama  -> role dibaca dari Firestore
/// Mengembalikan role aplikasi: 'Admin' atau 'Kasir'.
Future<String> ensureGoogleUser(User user) async {
  final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final snap = await ref.get();

  final email = user.email ?? '';
  final displayName = (user.displayName ?? '').trim();
  final username =
      displayName.isNotEmpty
          ? displayName
          : (email.isNotEmpty ? email.split('@').first : 'Admin');

  // Akun Google baru -> langsung admin
  if (!snap.exists) {
    await ref.set({
      'username': username,
      'email': email,
      'role': 'admin',
      'businessId': user.uid,
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return 'Admin';
  }

  final data = snap.data() ?? {};
  final role = (data['role'] ?? '').toString().toLowerCase();

  // Dokumen ada tapi role kosong (akibat bug sebelumnya) -> perbaiki jadi admin
  if (role.isEmpty) {
    await ref.set({
      'username': (data['username'] ?? username).toString(),
      'email': (data['email'] ?? email).toString(),
      'role': 'admin',
      'businessId': user.uid,
      'ownerId': user.uid,
    }, SetOptions(merge: true));
    return 'Admin';
  }

  return role == 'admin' ? 'Admin' : 'Kasir';
}
