import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'utils.dart';

class EditMenuScreen extends StatefulWidget {
  const EditMenuScreen({super.key});

  @override
  State<EditMenuScreen> createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends State<EditMenuScreen> {
  static const Color primaryOrange = Color(0xFFFF5A1F);
  static const Color softOrange = Color(0xFFFFEEE8);

  String? businessId;
  bool loadingBusiness = true;

  CollectionReference<Map<String, dynamic>> get _menus =>
      FirebaseFirestore.instance.collection('menus');

  @override
  void initState() {
    super.initState();
    loadBusiness();
  }

  // ====================================
  // AMBIL BUSINESS ID USER YANG LOGIN
  // ====================================
  Future<void> loadBusiness() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            loadingBusiness = false;
          });
        }
        return;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final data = doc.data();

      String? id = data?['businessId']?.toString();

      // Untuk akun admin lama yang belum punya businessId
      if ((id == null || id.isEmpty) &&
          data?['role']?.toString().toLowerCase() == 'admin') {
        id = user.uid;

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'businessId': id,
          'ownerId': user.uid,
        }, SetOptions(merge: true));
      }

      if (!mounted) return;

      setState(() {
        businessId = id;
        loadingBusiness = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingBusiness = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil data usaha: $e')));
    }
  }

  // ====================================
  // KONFIRMASI HAPUS MENU
  // ====================================
  Future<void> _confirmDelete(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Hapus menu?'),
            content: Text('Menu "${doc.data()['name']}" akan dihapus.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (ok == true) {
      try {
        await doc.reference.delete();

        if (!context.mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Menu berhasil dihapus')));
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus menu: $e')));
      }
    }
  }

  // ====================================
  // BUKA FORM TAMBAH / EDIT
  // ====================================
  void _openForm(
    BuildContext context, {
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  }) {
    if (businessId == null) return;

    showDialog(
      context: context,
      builder:
          (_) =>
              _MenuFormDialog(menus: _menus, businessId: businessId!, doc: doc),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingBusiness) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (businessId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Data usaha tidak ditemukan.\nSilakan login ulang.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Menu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Menu'),
      ),

      // ====================================
      // HANYA MENU MILIK BUSINESS INI
      // ====================================
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _menus.where('businessId', isEqualTo: businessId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs =
              snapshot.data!.docs.toList()..sort(
                (a, b) =>
                    (a.data()['name'] ?? '').toString().toLowerCase().compareTo(
                      (b.data()['name'] ?? '').toString().toLowerCase(),
                    ),
              );

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada menu.\n'
                'Tekan "Tambah Menu" untuk menambah.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final name = (data['name'] ?? '').toString();

              final price = (data['price'] as num?)?.toInt() ?? 0;

              final imageUrl = (data['imageUrl'] ?? '').toString();

              final available = data['isAvailable'] != false;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child:
                          imageUrl.isEmpty
                              ? _placeholder()
                              : Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholder(),
                              ),
                    ),
                  ),

                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Text(
                    '${formatRupiah(price)}  •  '
                    '${available ? 'Tersedia' : 'Habis'}',
                    style: TextStyle(
                      color: available ? primaryOrange : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: available,
                        activeColor: primaryOrange,
                        onChanged: (value) async {
                          await doc.reference.update({'isAvailable': value});
                        },
                      ),

                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openForm(context, doc: doc);
                          }

                          if (value == 'delete') {
                            _confirmDelete(context, doc);
                          }
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
    );
  }

  static Widget _placeholder() {
    return Container(
      color: softOrange,
      child: const Icon(Icons.fastfood_outlined, color: primaryOrange),
    );
  }
}

// ==========================================
// DIALOG FORM TAMBAH / EDIT MENU
// ==========================================

class _MenuFormDialog extends StatefulWidget {
  final CollectionReference<Map<String, dynamic>> menus;

  final String businessId;

  final QueryDocumentSnapshot<Map<String, dynamic>>? doc;

  const _MenuFormDialog({
    required this.menus,
    required this.businessId,
    this.doc,
  });

  @override
  State<_MenuFormDialog> createState() => _MenuFormDialogState();
}

class _MenuFormDialogState extends State<_MenuFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameC;
  late final TextEditingController priceC;
  late final TextEditingController imageC;

  bool saving = false;

  bool get isEdit => widget.doc != null;

  @override
  void initState() {
    super.initState();

    final data = widget.doc?.data();

    nameC = TextEditingController(text: data?['name']?.toString() ?? '');

    priceC = TextEditingController(
      text:
          data != null
              ? ((data['price'] as num?)?.toInt() ?? 0).toString()
              : '',
    );

    imageC = TextEditingController(text: data?['imageUrl']?.toString() ?? '');
  }

  @override
  void dispose() {
    nameC.dispose();
    priceC.dispose();
    imageC.dispose();

    super.dispose();
  }

  // ==========================================
  // SIMPAN MENU
  // ==========================================

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      saving = true;
    });

    final payload = <String, dynamic>{
      'name': nameC.text.trim(),
      'price': int.parse(priceC.text.trim()),
      'imageUrl': imageC.text.trim(),

      // PENTING
      // Menu selalu mempunyai businessId.
      'businessId': widget.businessId,
    };

    try {
      if (isEdit) {
        // ==============================
        // UPDATE MENU
        // ==============================

        await widget.doc!.reference.update(payload);
      } else {
        // ==============================
        // TAMBAH MENU BARU
        // ==============================

        await widget.menus.add({
          ...payload,

          'isAvailable': true,

          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? 'Edit Menu' : 'Tambah Menu'),

      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Nama menu'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama wajib diisi';
                  }

                  return null;
                },
              ),

              TextFormField(
                controller: priceC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  prefixText: 'Rp ',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Harga wajib diisi';
                  }

                  final price = int.tryParse(value.trim());

                  if (price == null || price <= 0) {
                    return 'Harga tidak valid';
                  }

                  return null;
                },
              ),

              TextFormField(
                controller: imageC,
                decoration: const InputDecoration(
                  labelText: 'URL gambar (opsional)',
                ),
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),

        ElevatedButton(
          onPressed: saving ? null : save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5A1F),
            foregroundColor: Colors.white,
          ),
          child:
              saving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Simpan'),
        ),
      ],
    );
  }
}
