import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PesananOnlineScreen extends StatefulWidget {
  const PesananOnlineScreen({super.key});

  @override
  State<PesananOnlineScreen> createState() => _PesananOnlineScreenState();
}

class _PesananOnlineScreenState extends State<PesananOnlineScreen> {
  static const purple = Color(0xFF6952AE);
  final orders = FirebaseFirestore.instance.collection('scheduled_orders');

  Future<void> _form({String? id, Map<String, dynamic>? data}) async {
    final customer = TextEditingController(text: data?['customer'] ?? '');
    final menu = TextEditingController(text: data?['menu'] ?? '');
    final qty = TextEditingController(text: '${data?['quantity'] ?? 1}');
    final note = TextEditingController(text: data?['note'] ?? '');
    DateTime date = (data?['scheduledAt'] is Timestamp)
        ? (data!['scheduledAt'] as Timestamp).toDate()
        : DateTime.now().add(const Duration(days: 1));
    TimeOfDay time = TimeOfDay(hour: date.hour, minute: date.minute);
    final key = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
        title: Text(id == null ? 'Tambah Pesanan Terjadwal' : 'Edit Pesanan'),
        content: SingleChildScrollView(
          child: Form(
            key: key,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _textField(customer, 'Nama pelanggan', required: true),
              const SizedBox(height: 10),
              _textField(menu, 'Menu pesanan', required: true),
              const SizedBox(height: 10),
              _textField(qty, 'Jumlah porsi', number: true),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month, color: purple),
                title: const Text('Tanggal pesanan'),
                subtitle: Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date.isBefore(DateTime.now()) ? DateTime.now() : date,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) setDialog(() => date = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time, color: purple),
                title: const Text('Jam pesanan'),
                subtitle: Text(time.format(ctx)),
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: time);
                  if (picked != null) {
                    setDialog(() {
                      time = picked;
                      date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    });
                  }
                },
              ),
              _textField(note, 'Catatan (opsional)', maxLines: 2),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: purple),
            onPressed: () async {
              if (!key.currentState!.validate()) return;
              final count = int.tryParse(qty.text) ?? 0;
              if (count < 1) return;
              final scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
              final payload = {
                'customer': customer.text.trim(),
                'menu': menu.text.trim(),
                'quantity': count,
                'scheduledAt': Timestamp.fromDate(scheduled),
                'note': note.text.trim(),
                'status': data?['status'] ?? 'Terjadwal',
                'updatedAt': FieldValue.serverTimestamp(),
              };
              if (id == null) {
                payload['createdAt'] = FieldValue.serverTimestamp();
                await orders.add(payload);
              } else {
                await orders.doc(id).update(payload);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan Pesanan'),
          ),
        ],
      )),
    );
  }

  Widget _textField(TextEditingController c, String label,
      {bool required = false, bool number = false, int maxLines = 1}) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) return 'Wajib diisi';
        if (number && (int.tryParse(v ?? '') == null || int.parse(v!) < 1)) return 'Jumlah minimal 1';
        return null;
      },
    );
  }

  Future<void> _delete(String id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus pesanan?'),
        content: const Text('Pesanan terjadwal ini akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (yes == true) await orders.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FA),
      appBar: AppBar(
        title: const Text('Pesanan Online', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: orders.orderBy('scheduledAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Gagal memuat pesanan. Periksa koneksi dan aturan Firestore.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: purple));
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Belum ada pesanan terjadwal.\nTekan + untuk menambahkan.', textAlign: TextAlign.center));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();
              final dt = d['scheduledAt'] is Timestamp ? (d['scheduledAt'] as Timestamp).toDate() : null;
              final status = (d['status'] ?? 'Terjadwal').toString();
              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 45, height: 45, decoration: BoxDecoration(color: const Color(0xFFECE6FF), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.shopping_bag_outlined, color: purple)),
                      const SizedBox(width: 11),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d['customer'] ?? 'Pelanggan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${d['menu'] ?? 'Menu'} • ${d['quantity'] ?? 1} porsi', style: TextStyle(color: Colors.grey.shade600)),
                      ])),
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') await _form(id: doc.id, data: d);
                          if (v == 'delete') await _delete(doc.id);
                          if (v == 'Terjadwal' || v == 'Diproses' || v == 'Selesai' || v == 'Dibatalkan') {
                            await orders.doc(doc.id).update({'status': v, 'updatedAt': FieldValue.serverTimestamp()});
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'Terjadwal', child: Text('Status: Terjadwal')),
                          PopupMenuItem(value: 'Diproses', child: Text('Status: Diproses')),
                          PopupMenuItem(value: 'Selesai', child: Text('Status: Selesai')),
                          PopupMenuItem(value: 'Dibatalkan', child: Text('Status: Dibatalkan')),
                          PopupMenuItem(value: 'delete', child: Text('Hapus')),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.calendar_month_outlined, size: 17, color: purple),
                      const SizedBox(width: 6),
                      Expanded(child: Text(dt == null ? 'Tanggal belum ditentukan' : '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}')),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFECE6FF), borderRadius: BorderRadius.circular(18)), child: Text(status, style: const TextStyle(color: purple, fontSize: 11, fontWeight: FontWeight.w600))),
                    ]),
                    if ((d['note'] ?? '').toString().isNotEmpty) Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Catatan: ${d['note']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ),
                  ]),
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
        label: const Text('Tambah Pesanan'),
      ),
    );
  }
}
