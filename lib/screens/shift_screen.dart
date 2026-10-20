import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'utils.dart';

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  static const purple = Color(0xFF6952AE);
  static const bg = Color(0xFFF7F6FA);

  String? businessId;
  bool loading = true;

  CollectionReference<Map<String, dynamic>> get shifts => FirebaseFirestore
      .instance
      .collection('users')
      .doc(businessId!)
      .collection('shifts');

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
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  TimeOfDay? _parseTime(dynamic value) {
    if (value is! String) return null;
    final p = value.split(':');
    if (p.length != 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null || h > 23 || m > 59 || h < 0 || m < 0)
      return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _timeString(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  Future<void> _form({String? id, Map<String, dynamic>? data}) async {
    final name = TextEditingController(text: data?['name'] ?? '');
    TimeOfDay? start = _parseTime(data?['startTime']);
    TimeOfDay? end = _parseTime(data?['endTime']);
    final key = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => StatefulBuilder(
            builder:
                (ctx, setSheet) => Container(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    24,
                    22,
                    MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: key,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 42,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            id == null
                                ? 'Buat Jadwal Shift'
                                : 'Edit Jadwal Shift',
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Atur nama dan jam kerja karyawan.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Nama shift',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: name,
                            decoration: InputDecoration(
                              hintText: 'Contoh: Shift Pagi',
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                color: purple,
                              ),
                              filled: true,
                              fillColor: bg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator:
                                (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Nama shift wajib diisi'
                                        : null,
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Jam operasional',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _timeBox(
                                  ctx,
                                  'Mulai',
                                  start,
                                  Icons.login_rounded,
                                  () async {
                                    final t = await showTimePicker(
                                      context: ctx,
                                      initialTime:
                                          start ??
                                          const TimeOfDay(hour: 7, minute: 0),
                                    );
                                    if (t != null) setSheet(() => start = t);
                                  },
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: purple,
                                ),
                              ),
                              Expanded(
                                child: _timeBox(
                                  ctx,
                                  'Selesai',
                                  end,
                                  Icons.logout_rounded,
                                  () async {
                                    final t = await showTimePicker(
                                      context: ctx,
                                      initialTime:
                                          end ??
                                          const TimeOfDay(hour: 15, minute: 0),
                                    );
                                    if (t != null) setSheet(() => end = t);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Shift malam boleh melewati tengah malam, '
                            'misalnya pukul 22.00 sampai 06.00.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: purple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: () async {
                                if (!key.currentState!.validate()) return;
                                if (start == null || end == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Pilih jam mulai dan selesai',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final payload = <String, dynamic>{
                                  'name': name.text.trim(),
                                  'startTime': _timeString(start!),
                                  'endTime': _timeString(end!),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                };

                                try {
                                  if (id == null) {
                                    payload['createdAt'] =
                                        FieldValue.serverTimestamp();
                                    payload['active'] = true;
                                    await shifts.add(payload);
                                  } else {
                                    await shifts.doc(id).update(payload);
                                  }
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Gagal menyimpan shift: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                id == null
                                    ? 'Simpan Shift'
                                    : 'Simpan Perubahan',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
    name.dispose();
  }

  Widget _timeBox(
    BuildContext ctx,
    String label,
    TimeOfDay? time,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2EEFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: purple.withValues(alpha: .12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: purple, size: 20),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 3),
            Text(
              time?.format(ctx) ?? '--:--',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(String id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text('Hapus jadwal shift?'),
            content: const Text('Jadwal ini akan dihapus permanen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (yes != true) return;
    try {
      await shifts.doc(id).delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus shift: $e')));
    }
  }

  Widget _header(int total, int active) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8068CB), purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                tooltip: 'Kembali',
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengaturan Shift',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Kelola jadwal kerja karyawan',
                      style: TextStyle(color: Color(0xFFE9E1FF), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _stat(
                    'Total Shift',
                    '$total',
                    Icons.calendar_month_rounded,
                  ),
                ),
                Container(
                  height: 43,
                  width: 1,
                  color: Colors.white.withValues(alpha: .25),
                ),
                Expanded(
                  child: _stat(
                    'Shift Aktif',
                    '$active',
                    Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white70, size: 23),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFE9E1FF), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECE8F3)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFF0EBFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: purple,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada jadwal shift',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 7),
          Text(
            'Buat shift pagi atau malam untuk mulai\n'
            'mengatur jadwal karyawan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _form(),
            icon: const Icon(Icons.add),
            label: const Text('Buat Shift Pertama'),
            style: OutlinedButton.styleFrom(
              foregroundColor: purple,
              side: const BorderSide(color: purple),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shiftCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final active = data['active'] != false;
    final start = data['startTime'] ?? '--:--';
    final end = data['endTime'] ?? '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE8F3)),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: .035),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBFF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.access_time_filled_rounded,
                  color: purple,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name']?.toString() ?? 'Shift',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: active ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          active ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            color: active ? Colors.green.shade700 : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.grey.shade700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                onSelected: (value) async {
                  try {
                    if (value == 'edit') {
                      await _form(id: doc.id, data: data);
                    } else if (value == 'toggle') {
                      await shifts.doc(doc.id).update({'active': !active});
                    } else if (value == 'delete') {
                      await _delete(doc.id);
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal mengubah shift: $e')),
                    );
                  }
                },
                itemBuilder:
                    (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 19),
                            SizedBox(width: 10),
                            Text('Edit jadwal'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              active
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Text(active ? 'Nonaktifkan' : 'Aktifkan'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Hapus jadwal',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6FC),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(child: _scheduleTime('MULAI KERJA', '$start')),
                Container(height: 38, width: 1, color: const Color(0xFFE5DFF0)),
                Expanded(child: _scheduleTime('SELESAI KERJA', '$end')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleTime(String label, String time) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 9,
            letterSpacing: .6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: const TextStyle(
            color: purple,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator(color: purple)),
      );
    }

    if (businessId == null || businessId!.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          title: const Text('Pengaturan Shift'),
        ),
        body: const Center(
          child: Text('Data usaha tidak ditemukan. Silakan login ulang.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: shifts.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final activeCount =
              docs.where((doc) => doc.data()['active'] != false).length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(docs.length, activeCount)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Jadwal Kerja',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF292631),
                            ),
                          ),
                        ),
                        Text(
                          '${docs.length} jadwal',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Atur waktu kerja untuk setiap operator.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (snapshot.hasError)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Gagal memuat jadwal. Periksa koneksi dan '
                          'izin Firestore.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (!snapshot.hasData)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(color: purple),
                        ),
                      )
                    else if (docs.isEmpty)
                      _emptyState()
                    else
                      ...docs.map(_shiftCard),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        backgroundColor: purple,
        foregroundColor: Colors.white,
        elevation: 5,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Shift',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
