import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

class DiskonScreen extends StatefulWidget {
  const DiskonScreen({super.key});

  @override
  State<DiskonScreen> createState() => _DiskonScreenState();
}

class _DiskonScreenState extends State<DiskonScreen> {
  static const purple = Color(0xFF6952AE);
  final db = FirebaseFirestore.instance;

  String? businessId;
  bool loadingBusiness = true;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    try {
      final id = await getBusinessId();
      if (!mounted) return;
      setState(() {
        businessId = id;
        loadingBusiness = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingBusiness = false);
    }
  }

  CollectionReference<Map<String, dynamic>> get discounts =>
      discountsRef(businessId!);
  CollectionReference<Map<String, dynamic>> get menus =>
      menusRef(businessId!);

  Future<void> _form({String? id, Map<String, dynamic>? data}) async {
    final name = TextEditingController(text: data?['menuName'] ?? '');
    final normal = TextEditingController(text: '${data?['normalPrice'] ?? ''}');
    final promo = TextEditingController(
      text: '${data?['discountPrice'] ?? ''}',
    );
    DateTime start =
        (data?['startAt'] is Timestamp)
            ? (data!['startAt'] as Timestamp).toDate()
            : DateTime.now();
    DateTime end =
        (data?['endAt'] is Timestamp)
            ? (data!['endAt'] as Timestamp).toDate()
            : DateTime.now().add(const Duration(days: 7));
    final key = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialog) => AlertDialog(
                  title: Text(id == null ? 'Tambah Diskon' : 'Edit Diskon'),
                  content: SingleChildScrollView(
                    child: Form(
                      key: key,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: menus.orderBy('name').snapshots(),
                            builder: (context, snap) {
                              final menuDocs = snap.data?.docs ?? [];
                              return DropdownButtonFormField<String>(
                                initialValue:
                                    name.text.isEmpty ||
                                            !menuDocs.any(
                                              (m) =>
                                                  (m.data()['name'] ?? '')
                                                      .toString() ==
                                                  name.text,
                                            )
                                        ? null
                                        : name.text,
                                decoration: const InputDecoration(
                                  labelText: 'Pilih menu kasir',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    menuDocs.map((m) {
                                      final d = m.data();
                                      return DropdownMenuItem<String>(
                                        value: (d['name'] ?? '').toString(),
                                        child: Text(
                                          (d['name'] ?? 'Menu').toString(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  final selected =
                                      menuDocs
                                          .firstWhere(
                                            (m) =>
                                                (m.data()['name'] ?? '')
                                                    .toString() ==
                                                v,
                                          )
                                          .data();
                                  name.text = v;
                                  final price =
                                      selected['price'] ??
                                      selected['harga'] ??
                                      0;
                                  normal.text = price.toString();
                                  setDialog(() {});
                                },
                                validator:
                                    (v) =>
                                        v == null || v.isEmpty
                                            ? 'Pilih menu'
                                            : null,
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: normal,
                            readOnly: true,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Harga normal (Rp)',
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (v) =>
                                    int.tryParse(v ?? '') == null
                                        ? 'Harga normal tidak ditemukan'
                                        : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: promo,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Harga diskon (Rp)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              final o = int.tryParse(normal.text);
                              if (n == null || n < 0) {
                                return 'Masukkan harga diskon';
                              }
                              if (o == null || n >= o) {
                                return 'Harga diskon harus di bawah harga normal';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.calendar_today,
                              color: purple,
                            ),
                            title: const Text('Mulai diskon'),
                            subtitle: Text(_date(start)),
                            onTap: () async {
                              final d = await showDatePicker(
                                context: ctx,
                                initialDate: start,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) setDialog(() => start = d);
                            },
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.event_available,
                              color: purple,
                            ),
                            title: const Text('Akhir diskon'),
                            subtitle: Text(_date(end)),
                            onTap: () async {
                              final d = await showDatePicker(
                                context: ctx,
                                initialDate: end.isBefore(start) ? start : end,
                                firstDate: start,
                                lastDate: DateTime(2100),
                              );
                              if (d != null) setDialog(() => end = d);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: purple),
                      onPressed: () async {
                        if (!key.currentState!.validate() ||
                            end.isBefore(start)) {
                          return;
                        }
                        final payload = {
                          'menuName': name.text.trim(),
                          'normalPrice': int.parse(normal.text),
                          'discountPrice': int.parse(promo.text),
                          'startAt': Timestamp.fromDate(
                            DateTime(start.year, start.month, start.day),
                          ),
                          'endAt': Timestamp.fromDate(
                            DateTime(end.year, end.month, end.day, 23, 59, 59),
                          ),
                          'updatedAt': FieldValue.serverTimestamp(),
                        };
                        if (id == null) {
                          payload['createdAt'] = FieldValue.serverTimestamp();
                          await discounts.add(payload);
                        } else {
                          await discounts.doc(id).update(payload);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Simpan Diskon'),
                    ),
                  ],
                ),
          ),
    );
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _rupiah(dynamic value) {
    final n = (value as num?)?.toInt() ?? 0;
    final s = n.toString();
    final out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      out.write(s[i]);
      final remain = s.length - i - 1;
      if (remain > 0 && remain % 3 == 0) out.write('.');
    }
    return 'Rp${out.toString()}';
  }

  Future<void> _delete(String id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Hapus diskon?'),
            content: const Text('Promosi ini akan dihapus.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
    if (yes == true) await discounts.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    if (loadingBusiness) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F6FA),
        body: Center(child: CircularProgressIndicator(color: purple)),
      );
    }
    if (businessId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F6FA),
        appBar: AppBar(
          title: const Text(
            'Diskon & Promo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: purple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Data usaha tidak ditemukan. Silakan login ulang.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FA),
      appBar: AppBar(
        title: const Text(
          'Diskon & Promo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: discounts.orderBy('endAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Gagal memuat diskon. Periksa koneksi dan aturan Firestore.',
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: purple),
            );
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada diskon.\nTekan + untuk membuat promo.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();
              final start =
                  d['startAt'] is Timestamp
                      ? (d['startAt'] as Timestamp).toDate()
                      : null;
              final end =
                  d['endAt'] is Timestamp
                      ? (d['endAt'] as Timestamp).toDate()
                      : null;
              final now = DateTime.now();
              final active =
                  start != null &&
                  end != null &&
                  !now.isBefore(start) &&
                  !now.isAfter(end);
              final oldPrice = (d['normalPrice'] as num?)?.toInt() ?? 0;
              final newPrice = (d['discountPrice'] as num?)?.toInt() ?? 0;
              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.sell_outlined,
                          color: purple,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d['menuName'] ?? 'Menu',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _rupiah(oldPrice),
                              style: const TextStyle(
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _rupiah(newPrice),
                              style: const TextStyle(
                                color: purple,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '${start == null ? '-' : _date(start)} - ${end == null ? '-' : _date(end)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              active
                                  ? 'Diskon aktif'
                                  : 'Di luar periode diskon',
                              style: TextStyle(
                                color:
                                    active
                                        ? Colors.green
                                        : Colors.orange.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') await _form(id: doc.id, data: d);
                          if (v == 'delete') await _delete(doc.id);
                        },
                        itemBuilder:
                            (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus'),
                              ),
                            ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        backgroundColor: purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Diskon'),
      ),
    );
  }
}
