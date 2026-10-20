import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  static const purple = Color(0xFF6952AE);
  final shifts = FirebaseFirestore.instance.collection('shifts');

  Future<void> _form({String? id, Map<String, dynamic>? data}) async {
    final name = TextEditingController(text: data?['name'] ?? '');
    TimeOfDay? start = _parseTime(data?['startTime']);
    TimeOfDay? end = _parseTime(data?['endTime']);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
        title: Text(id == null ? 'Tambah Shift' : 'Edit Shift'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nama shift', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Nama shift wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.login, color: purple),
              title: const Text('Jam mulai'),
              subtitle: Text(start?.format(ctx) ?? 'Pilih jam mulai'),
              onTap: () async {
                final t = await showTimePicker(context: ctx, initialTime: start ?? const TimeOfDay(hour: 7, minute: 0));
                if (t != null) setDialog(() => start = t);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout, color: purple),
              title: const Text('Jam selesai'),
              subtitle: Text(end?.format(ctx) ?? 'Pilih jam selesai'),
              onTap: () async {
                final t = await showTimePicker(context: ctx, initialTime: end ?? const TimeOfDay(hour: 15, minute: 0));
                if (t != null) setDialog(() => end = t);
              },
            ),
            const Text('Shift yang melewati tengah malam, misalnya 22.00–06.00, juga diperbolehkan.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: purple),
            onPressed: () async {
              if (!formKey.currentState!.validate() || start == null || end == null) return;
              final payload = {
                'name': name.text.trim(),
                'startTime': _timeString(start!),
                'endTime': _timeString(end!),
                'updatedAt': FieldValue.serverTimestamp(),
              };
              if (id == null) {
                payload['createdAt'] = FieldValue.serverTimestamp();
                payload['active'] = true;
                await shifts.add(payload);
              } else {
                await shifts.doc(id).update(payload);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      )),
    );
  }

  TimeOfDay? _parseTime(dynamic value) {
    if (value is! String || !value.contains(':')) return null;
    final p = value.split(':');
    return TimeOfDay(hour: int.tryParse(p[0]) ?? 0, minute: int.tryParse(p[1]) ?? 0);
  }

  String _timeString(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _delete(String id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus shift?'),
        content: const Text('Jadwal shift ini akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (yes == true) await shifts.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FA),
      appBar: AppBar(
        title: const Text('Pengaturan Shift', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: shifts.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Gagal memuat shift. Periksa koneksi dan aturan Firestore.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: purple));
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Belum ada shift.\nTambahkan shift pagi atau malam.', textAlign: TextAlign.center));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();
              final active = d['active'] != false;
              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: const Color(0xFFECE6FF), borderRadius: BorderRadius.circular(15)),
                      child: const Icon(Icons.schedule_rounded, color: purple, size: 27),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['name'] ?? 'Shift', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${d['startTime'] ?? '--:--'} - ${d['endTime'] ?? '--:--'}', style: const TextStyle(color: purple, fontWeight: FontWeight.w600)),
                      Text(active ? 'Aktif untuk dipilih kasir' : 'Nonaktif', style: TextStyle(color: active ? Colors.green : Colors.grey, fontSize: 12)),
                    ])),
                    PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') await _form(id: doc.id, data: d);
                        if (v == 'toggle') await shifts.doc(doc.id).update({'active': !active});
                        if (v == 'delete') await _delete(doc.id);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'toggle', child: Text(active ? 'Nonaktifkan' : 'Aktifkan')),
                        const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
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
        label: const Text('Tambah Shift'),
      ),
    );
  }
}
