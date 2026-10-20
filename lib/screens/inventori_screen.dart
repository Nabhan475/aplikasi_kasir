import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InventoriScreen extends StatefulWidget {
  const InventoriScreen({super.key});

  @override
  State<InventoriScreen> createState() => _InventoriScreenState();
}

class _InventoriScreenState extends State<InventoriScreen> {
  static const purple = Color(0xFF6952AE);
  final db = FirebaseFirestore.instance;
  final searchC = TextEditingController();

  CollectionReference<Map<String, dynamic>> get items =>
      db.collection('inventory');

  @override
  void dispose() {
    searchC.dispose();
    super.dispose();
  }

  Future<void> _form({String? id, Map<String, dynamic>? data}) async {
    final name = TextEditingController(text: data?['name'] ?? '');
    final unit = TextEditingController(text: data?['unit'] ?? 'kg');
    final stock = TextEditingController(text: '${data?['stock'] ?? 0}');
    final daily = TextEditingController(text: '${data?['dailyUsage'] ?? 0}');
    final min = TextEditingController(text: '${data?['minimumStock'] ?? 1}');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(id == null ? 'Tambah Bahan Baku' : 'Edit Bahan Baku'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(name, 'Nama bahan', required: true),
              const SizedBox(height: 10),
              _field(unit, 'Satuan (kg, gram, liter, pcs)', required: true),
              const SizedBox(height: 10),
              _field(stock, 'Stok saat ini', number: true),
              const SizedBox(height: 10),
              _field(daily, 'Pemakaian rata-rata per hari', number: true),
              const SizedBox(height: 10),
              _field(min, 'Batas minimum stok', number: true),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: purple),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final payload = {
                'name': name.text.trim(),
                'unit': unit.text.trim(),
                'stock': double.tryParse(stock.text) ?? 0,
                'dailyUsage': double.tryParse(daily.text) ?? 0,
                'minimumStock': double.tryParse(min.text) ?? 0,
                'updatedAt': FieldValue.serverTimestamp(),
              };
              if (id == null) {
                payload['createdAt'] = FieldValue.serverTimestamp();
                await items.add(payload);
              } else {
                await items.doc(id).update(payload);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool number = false, bool required = false}) {
    return TextFormField(
      controller: c,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) return 'Wajib diisi';
        if (number && (double.tryParse(v ?? '') == null || double.parse(v!) < 0)) {
          return 'Masukkan angka >= 0';
        }
        return null;
      },
    );
  }

  Future<void> _delete(String id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus bahan?'),
        content: const Text('Data bahan baku ini akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (yes == true) await items.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FA),
      appBar: AppBar(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Inventori', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
          child: TextField(
            controller: searchC,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari bahan baku...',
              prefixIcon: const Icon(Icons.search, color: purple),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: items.orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Gagal memuat inventori. Periksa koneksi dan aturan Firestore.'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: purple));
              final docs = snapshot.data!.docs.where((d) =>
                (d.data()['name'] ?? '').toString().toLowerCase().contains(searchC.text.toLowerCase())).toList();
              if (docs.isEmpty) {
                return const Center(child: Text('Belum ada bahan baku.\nTekan + untuk menambahkan.', textAlign: TextAlign.center));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final d = doc.data();
                  final stock = (d['stock'] as num?)?.toDouble() ?? 0;
                  final daily = (d['dailyUsage'] as num?)?.toDouble() ?? 0;
                  final min = (d['minimumStock'] as num?)?.toDouble() ?? 0;
                  final unit = d['unit'] ?? 'unit';
                  final low = stock <= min;
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.grey.shade200)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFECE6FF), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.inventory_2_outlined, color: purple)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(d['name'] ?? 'Bahan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Pemakaian: ${daily.toStringAsFixed(1)} $unit/hari', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ])),
                          IconButton(onPressed: () => _form(id: doc.id, data: d), icon: const Icon(Icons.edit_outlined, color: purple)),
                          IconButton(onPressed: () => _delete(doc.id), icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: Text('Stok: ${stock.toStringAsFixed(1)} $unit', style: const TextStyle(fontWeight: FontWeight.w600))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: low ? const Color(0xFFFFE8E8) : const Color(0xFFE4F7EF), borderRadius: BorderRadius.circular(20)),
                            child: Text(low ? 'Stok menipis' : 'Aman', style: TextStyle(color: low ? Colors.red : Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ]),
                        if (daily > 0) Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text('Perkiraan cukup ${(stock / daily).floor()} hari', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _useStock(doc.id, stock, unit),
                            icon: const Icon(Icons.remove_circle_outline, size: 18),
                            label: const Text('Catat pemakaian'),
                            style: TextButton.styleFrom(foregroundColor: purple),
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        backgroundColor: purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Bahan'),
      ),
    );
  }

  Future<void> _useStock(String id, double current, String unit) async {
    final c = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catat Pemakaian'),
        content: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Jumlah terpakai ($unit)', border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final n = double.tryParse(c.text);
              if (n == null || n <= 0 || n > current) return;
              Navigator.pop(ctx, n);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (amount == null) return;
    await items.doc(id).update({
      'stock': current - amount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await db.collection('inventory_usage').add({
      'inventoryId': id,
      'amount': amount,
      'unit': unit,
      'date': FieldValue.serverTimestamp(),
    });
  }
}
