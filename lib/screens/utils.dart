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
    await ref.set({
      'businessId': id,
      'ownerId': user.uid,
    }, SetOptions(merge: true));
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

/// users/{businessId}/inventory
CollectionReference<Map<String, dynamic>> inventoryRef(String businessId) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(businessId)
        .collection('inventory');

/// users/{businessId}/inventory_usage
CollectionReference<Map<String, dynamic>> inventoryUsageRef(
  String businessId,
) => FirebaseFirestore.instance
    .collection('users')
    .doc(businessId)
    .collection('inventory_usage');

/// users/{businessId}/shifts
CollectionReference<Map<String, dynamic>> shiftsRef(String businessId) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(businessId)
        .collection('shifts');

/// users/{businessId}/scheduled_orders
CollectionReference<Map<String, dynamic>> ordersRef(String businessId) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(businessId)
        .collection('scheduled_orders');

/// users/{businessId}/discounts
CollectionReference<Map<String, dynamic>> discountsRef(String businessId) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(businessId)
        .collection('discounts');

const List<String> indonesianDays = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const List<String> indonesianMonths = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Format tanggal lengkap: "Selasa, 20 Oktober 2026"
String formatTanggalIndonesia(DateTime date) {
  final dayName = indonesianDays[date.weekday - 1];
  final monthName = indonesianMonths[date.month - 1];
  return '$dayName, ${date.day} $monthName ${date.year}';
}
