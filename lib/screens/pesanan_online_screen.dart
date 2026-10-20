import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PesananOnlineScreen extends StatefulWidget {
  const PesananOnlineScreen({super.key});

  @override
  State<PesananOnlineScreen> createState() => _PesananOnlineScreenState();
}

class _PesananOnlineScreenState extends State<PesananOnlineScreen> {
  static const purple = Color(0xFF6952AE);
  static const bg = Color(0xFFF7F6FA);

  final orders = FirebaseFirestore.instance.collection('scheduled_orders');

  DateTime selected = DateTime.now();
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime? readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String monthLabel(DateTime d) {
    const names = [
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
    return '${names[d.month - 1]} ${d.year}';
  }

  String monthShort(int m) =>
      [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MEI',
        'JUN',
        'JUL',
        'AGU',
        'SEP',
        'OKT',
        'NOV',
        'DES',
      ][m - 1];

  Future<void> form({String? id, Map<String, dynamic>? data}) async {
    final customer = TextEditingController(
      text: data?['customer']?.toString() ?? '',
    );
    final menu = TextEditingController(text: data?['menu']?.toString() ?? '');
    final qty = TextEditingController(text: '${data?['quantity'] ?? 1}');
    final note = TextEditingController(text: data?['note']?.toString() ?? '');

    DateTime date = readDate(data?['scheduledAt']) ?? selected;
    TimeOfDay time = TimeOfDay(hour: date.hour, minute: date.minute);
    final key = GlobalKey<FormState>();

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (sheet) => StatefulBuilder(
              builder:
                  (ctx, setSheet) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(26),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Form(
                          key: key,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                id == null ? 'Tambah Pesanan' : 'Edit Pesanan',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 18),
                              field(customer, 'Nama pelanggan', required: true),
                              field(menu, 'Menu pesanan', required: true),
                              field(qty, 'Jumlah porsi', number: true),
                              ListTile(
                                leading: const Icon(
                                  Icons.calendar_month,
                                  color: purple,
                                ),
                                title: const Text('Tanggal pesanan'),
                                subtitle: Text(dateLabel(date)),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: date,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setSheet(() {
                                      date = DateTime(
                                        picked.year,
                                        picked.month,
                                        picked.day,
                                        time.hour,
                                        time.minute,
                                      );
                                    });
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.access_time,
                                  color: purple,
                                ),
                                title: const Text('Jam pesanan'),
                                subtitle: Text(time.format(ctx)),
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: ctx,
                                    initialTime: time,
                                  );
                                  if (picked != null) {
                                    setSheet(() {
                                      time = picked;
                                      date = DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        time.hour,
                                        time.minute,
                                      );
                                    });
                                  }
                                },
                              ),
                              field(note, 'Catatan (opsional)', maxLines: 2),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: purple,
                                  ),
                                  onPressed: () async {
                                    if (!key.currentState!.validate()) return;

                                    final scheduled = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      time.hour,
                                      time.minute,
                                    );

                                    final payload = <String, dynamic>{
                                      'customer': customer.text.trim(),
                                      'menu': menu.text.trim(),
                                      'quantity': int.parse(qty.text),
                                      'scheduledAt': Timestamp.fromDate(
                                        scheduled,
                                      ),
                                      'note': note.text.trim(),
                                      'status': data?['status'] ?? 'Terjadwal',
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    };

                                    try {
                                      if (id == null) {
                                        payload['createdAt'] =
                                            FieldValue.serverTimestamp();
                                        await orders.add(payload);
                                      } else {
                                        await orders.doc(id).update(payload);
                                      }

                                      if (ctx.mounted) Navigator.pop(ctx);
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Gagal menyimpan: $e'),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Simpan Pesanan'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
      );
    } finally {
      customer.dispose();
      menu.dispose();
      qty.dispose();
      note.dispose();
    }
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) {
            return 'Wajib diisi';
          }
          if (number && (int.tryParse(v ?? '') ?? 0) < 1) {
            return 'Jumlah minimal 1';
          }
          return null;
        },
      ),
    );
  }

  Future<void> deleteOrder(String id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Hapus pesanan?'),
            content: const Text('Data pesanan akan dihapus.'),
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

    if (yes != true) return;

    try {
      await orders.doc(id).delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  Widget header() => Container(
    padding: const EdgeInsets.fromLTRB(12, 12, 18, 22),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF8068CB), purple]),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        const Icon(Icons.calendar_month, color: Colors.white, size: 30),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pesanan Online',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Jadwal pesanan pelanggan',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget calendar(Set<String> booked) {
    final first = DateTime(month.year, month.month, 1).weekday % 7;
    final count = DateTime(month.year, month.month + 1, 0).day;
    final cells = ((first + count + 6) ~/ 7) * 7;
    const weekdays = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECE8F3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthLabel(month),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    () => setState(() {
                      month = DateTime(month.year, month.month - 1);
                    }),
                icon: const Icon(Icons.chevron_left, color: purple),
              ),
              IconButton(
                onPressed:
                    () => setState(() {
                      month = DateTime(month.year, month.month + 1);
                    }),
                icon: const Icon(Icons.chevron_right, color: purple),
              ),
            ],
          ),
          Row(
            children:
                weekdays
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(d, style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              childAspectRatio: .85,
            ),
            itemBuilder: (ctx, i) {
              final day = i - first + 1;
              if (day < 1 || day > count) {
                return const SizedBox.shrink();
              }

              final d = DateTime(month.year, month.month, day);
              final active = sameDay(d, selected);
              final hasOrder = booked.contains('${d.year}-${d.month}-${d.day}');

              return InkWell(
                onTap: () => setState(() => selected = d),
                borderRadius: BorderRadius.circular(10),
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? purple : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: active ? Colors.white : Colors.black87,
                          fontWeight:
                              active ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: hasOrder ? purple : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget orderCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final date = readDate(d['scheduledAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE8F3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EBFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  date == null ? '--' : '${date.day}',
                  style: const TextStyle(
                    color: purple,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  date == null ? '--' : monthShort(date.month),
                  style: const TextStyle(color: purple, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d['customer']?.toString() ?? 'Pelanggan',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${d['menu'] ?? 'Menu'} · '
                  '${d['quantity'] ?? 1} porsi',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(
                  date == null
                      ? 'Jam belum tersedia'
                      : '${date.hour.toString().padLeft(2, '0')}:'
                          '${date.minute.toString().padLeft(2, '0')} · '
                          '${d['status'] ?? 'Terjadwal'}',
                  style: const TextStyle(color: purple, fontSize: 12),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') {
                await form(id: doc.id, data: d);
              } else if (v == 'delete') {
                await deleteOrder(doc.id);
              } else {
                try {
                  await orders.doc(doc.id).update({
                    'status': v,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengubah status: $e')),
                  );
                }
              }
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'Terjadwal',
                    child: Text('Status: Terjadwal'),
                  ),
                  PopupMenuItem(
                    value: 'Diproses',
                    child: Text('Status: Diproses'),
                  ),
                  PopupMenuItem(
                    value: 'Selesai',
                    child: Text('Status: Selesai'),
                  ),
                  PopupMenuItem(
                    value: 'Dibatalkan',
                    child: Text('Status: Dibatalkan'),
                  ),
                  PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: orders.orderBy('scheduledAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat pesanan:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: purple),
            );
          }

          final docs = snapshot.data!.docs;
          final booked = <String>{};

          for (final doc in docs) {
            final d = readDate(doc.data()['scheduledAt']);
            if (d != null) {
              booked.add('${d.year}-${d.month}-${d.day}');
            }
          }

          final selectedOrders =
              docs.where((doc) {
                final d = readDate(doc.data()['scheduledAt']);
                return d != null && sameDay(d, selected);
              }).toList();

          final upcoming =
              docs
                  .where((doc) {
                    final d = readDate(doc.data()['scheduledAt']);
                    return d != null &&
                        !d.isBefore(
                          DateTime(selected.year, selected.month, selected.day),
                        );
                  })
                  .take(5)
                  .toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: header()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    calendar(booked),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Pesanan Mendatang',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              () => setState(() {
                                selected = DateTime.now();
                                month = DateTime(selected.year, selected.month);
                              }),
                          child: const Text('Hari ini'),
                        ),
                      ],
                    ),
                    Text(
                      '${selectedOrders.length} pesanan · '
                      '${dateLabel(selected)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (selectedOrders.isNotEmpty)
                      ...selectedOrders.map(orderCard)
                    else if (upcoming.isNotEmpty) ...[
                      const Text(
                        'Tidak ada pesanan pada tanggal ini. '
                        'Jadwal berikutnya:',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      ...upcoming.map(orderCard),
                    ] else
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('Belum ada pesanan terjadwal.'),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => form(),
        backgroundColor: purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pesanan'),
      ),
    );
  }
}
