import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Format angka menjadi Rupiah, contoh: 15000 -> Rp15.000
String formatRupiah(num value) {
  final s = value.toInt().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp$buf';
}

/// Ambil businessId user yang sedang login.
Future<String?> getBusinessId() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final data = (await ref.get()).data();

  String? id = data?['businessId']?.toString();

  // Admin lama yang belum punya businessId
  if ((id == null || id.isEmpty) &&
      data?['role']?.toString().toLowerCase() == 'admin') {
    id = user.uid;
    await ref.set({'businessId': id, 'ownerId': user.uid},
        SetOptions(merge: true));
  }
  return (id == null || id.isEmpty) ? null : id;
}

/// users/{businessId}/menus
CollectionReference<Map<String, dynamic>> menusRef(String businessId) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(businessId)
        .collection('menus');

/// users/{businessId}/transactions
CollectionReference<Map<String, dynamic>> transactionsRef(String businessId) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(businessId)
        .collection('transactions');