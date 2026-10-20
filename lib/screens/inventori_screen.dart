import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

class InventoriScreen extends StatefulWidget {
  const InventoriScreen({super.key});

  @override
  State<InventoriScreen> createState() => _InventoriScreenState();
}

class _InventoriScreenState extends State<InventoriScreen> {
  static const purple = Color(0xFF6952AE);
  static const bg = Color(0xFFF7F6FA);

  final db = FirebaseFirestore.instance;
  final searchC = TextEditingController();

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

  CollectionReference<Map<String, dynamic>> get items =>
      inventoryRef(businessId!);

  @override
  void dispose() {
    searchC.dispose();
    super.dispose();
  }

  Future<void> _form({String? id, Map<String, dynamic>? data}) async {
    final name = TextEditingController(text: data?['name'] ?? '');
    final unit = TextEditingController(text: data?['unit'] ?? 'kg');
    final daily = TextEditingController(text: '${data?['dailyUsage'] ?? 0}');
    final key = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheet) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheet).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: key,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        id == null ? 'Tambah Bahan Baku' : 'Edit Bahan Baku',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kelola bahan dan pemakaian harian.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 20),
                      _field(name, 'Nama bahan', required: true),
                      _field(
                        unit,
                        'Satuan (kg, gram, liter, pcs)',
                        required: true,
                      ),
                      _field(
                        daily,
                        'Pemakaian rata-rata per hari',
                        number: true,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            if (!key.currentState!.validate()) return;

                            final payload = <String, dynamic>{
                              'name': name.text.trim(),
                              'unit': unit.text.trim(),
                              'dailyUsage': double.parse(daily.text),
                              'updatedAt': FieldValue.serverTimestamp(),
                            };

                            try {
                              if (id == null) {
                                payload['stock'] = 0.0;
                                payload['createdAt'] =
                                    FieldValue.serverTimestamp();
                                await items.add(payload);
                              } else {
                                await items.doc(id).update(payload);
                              }

                              if (sheet.mounted) Navigator.pop(sheet);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal menyimpan bahan: $e'),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Simpan Bahan',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
    unit.dispose();
    daily.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool number = false,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType:
            number
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'Wajib diisi';
          }

          if (number) {
            final n = double.tryParse(value ?? '');
            if (n == null || n < 0) {
              return 'Masukkan angka minimal 0';
            }
          }
          return null;
        },
      ),
    );
  }

  Future<void> _delete(String id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Hapus bahan baku?'),
            content: const Text('Data bahan ini akan dihapus.'),
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
      await items.doc(id).delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus bahan: $e')));
    }
  }

  Future<void> _useStock(String id, double current, String unit) async {
    final controller = TextEditingController();
    final key = GlobalKey<FormState>();

    final amount = await showDialog<double>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Catat Pemakaian'),
            content: Form(
              key: key,
              child: TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Jumlah terpakai ($unit)',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final n = double.tryParse(value ?? '');
                  if (n == null || n <= 0) {
                    return 'Masukkan jumlah yang valid';
                  }
                  if (n > current) return 'Stok tidak mencukupi';
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: purple),
                onPressed: () {
                  if (key.currentState!.validate()) {
                    Navigator.pop(ctx, double.parse(controller.text));
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );

    controller.dispose();
    if (amount == null) return;

    try {
      await db.runTransaction((transaction) async {
        final ref = items.doc(id);
        final doc = await transaction.get(ref);
        if (!doc.exists) throw Exception('Bahan tidak ditemukan');

        final stock = (doc.data()?['stock'] as num?)?.toDouble() ?? 0;
        if (amount > stock) throw Exception('Stok tidak mencukupi');

        transaction.update(ref, {
          'stock': stock - amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final usageRef = inventoryUsageRef(businessId!).doc();
        transaction.set(usageRef, {
          'inventoryId': id,
          'amount': amount,
          'unit': unit,
          'date': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mencatat pemakaian: $e')));
    }
  }

  Widget _header(int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
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
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventori',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pantau stok bahan baku usaha',
                      style: TextStyle(color: Color(0xFFE9E1FF), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .18)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.category_outlined,
                  color: Colors.white70,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Jenis Bahan Baku',
                      style: TextStyle(color: Color(0xFFE9E1FF), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _materialCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final stock = (d['stock'] as num?)?.toDouble() ?? 0;
    final daily = (d['dailyUsage'] as num?)?.toDouble() ?? 0;
    final unit = d['unit'] ?? 'kg';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE8F3)),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: .035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBFF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['name'] ?? 'Bahan baku',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pemakaian ${daily.toStringAsFixed(1)} $unit/hari',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _form(id: doc.id, data: d);
                  if (v == 'delete') _delete(doc.id);
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit bahan')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus bahan'),
                      ),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6FC),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STOK TERSEDIA',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 9,
                    letterSpacing: .5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${stock.toStringAsFixed(1)} $unit',
                  style: const TextStyle(
                    color: purple,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.timelapse_rounded,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  daily > 0
                      ? 'Cukup ${(stock / daily).floor()} hari'
                      : 'Pemakaian belum diatur',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
              TextButton.icon(
                onPressed: () => _useStock(doc.id, stock, unit),
                icon: const Icon(Icons.remove_circle_outline, size: 17),
                label: const Text('Catat pakai'),
                style: TextButton.styleFrom(foregroundColor: purple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE8F3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, color: purple, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Belum ada bahan baku',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Tekan tombol tambah untuk memasukkan bahan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingBusiness) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator(color: purple)),
      );
    }
    if (businessId == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          title: const Text('Inventori', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: const Center(
          child: Text('Data usaha tidak ditemukan. Silakan login ulang.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: items.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          final all = snapshot.data?.docs ?? [];
          final filtered =
              all.where((doc) {
                final name =
                    (doc.data()['name'] ?? '').toString().toLowerCase();
                return name.contains(searchC.text.trim().toLowerCase());
              }).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(all.length)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    TextField(
                      controller: searchC,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari bahan baku...',
                        prefixIcon: const Icon(Icons.search, color: purple),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Daftar Bahan Baku',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${filtered.length} bahan',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Pantau stok dan pemakaian bahan harian.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (snapshot.hasError)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Gagal memuat inventori. Periksa koneksi dan aturan Firestore.',
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
                    else if (filtered.isEmpty)
                      _emptyState()
                    else
                      ...filtered.map(_materialCard),
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
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Bahan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
