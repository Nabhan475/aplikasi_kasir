import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'menu_image.dart';
import 'utils.dart';

enum _MenuFilter { all, available, soldOut }

class EditMenuScreen extends StatefulWidget {
  const EditMenuScreen({super.key});

  @override
  State<EditMenuScreen> createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends State<EditMenuScreen> {
  static const Color purple = Color(0xFF6952AE);
  static const Color bg = Color(0xFFF7F6FA);
  static const Color ink = Color(0xFF292532);

  final _searchC = TextEditingController();
  _MenuFilter _filter = _MenuFilter.all;

  // Stok kosong / belum diisi dianggap 0 (menu tidak tersedia)
  static int _stockOf(Map<String, dynamic> d) =>
      (d['stock'] as num?)?.toInt() ?? 0;

  String? businessId;
  bool loadingBusiness = true;

  CollectionReference<Map<String, dynamic>> get _menus => menusRef(businessId!);

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _loadBusiness() async {
    try {
      final id = await getBusinessId();
      if (!mounted) return;
      setState(() {
        businessId = id;
        loadingBusiness = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingBusiness = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data usaha: $e')),
      );
    }
  }

  Future<void> _confirmDelete(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus menu?'),
        content: Text('Menu "${doc.data()['name']}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await doc.reference.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Menu berhasil dihapus')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menghapus menu: $e')));
    }
  }

  // Tambah / kurangi stok. Pakai transaksi supaya aman jika kasir
  // sedang checkout bersamaan. isAvailable ikut dihitung otomatis.
  Future<void> _adjustStock(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    int delta,
  ) async {
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(doc.reference);
        final cur = _stockOf(snap.data() ?? {});
        final next = cur + delta < 0 ? 0 : cur + delta;
        tx.update(doc.reference, {'stock': next, 'isAvailable': next > 0});
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal mengubah stok: $e')));
    }
  }

  Future<void> _setStockDialog(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    int current,
  ) async {
    final c = TextEditingController(text: '$current');
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Atur stok'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Jumlah stok',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: purple),
            onPressed: () => Navigator.pop(ctx, int.tryParse(c.text) ?? 0),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    c.dispose();
    if (value == null) return;
    await _adjustStock(doc, value - current);
  }

  void _openForm({QueryDocumentSnapshot<Map<String, dynamic>>? doc}) {
    if (businessId == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _MenuFormSheet(menus: _menus, businessId: businessId!, doc: doc),
    );
  }

  // ---------- HEADER ----------
  Widget _header(int total, int available, int soldOut) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top + 18, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8068CB), purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.restaurant_menu_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Kelola menu, harga, dan stok',
                      style: TextStyle(color: Color(0xFFE9E1FF), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .18)),
            ),
            child: Row(
              children: [
                Expanded(child: _stat('Total', '$total')),
                _vline(),
                Expanded(child: _stat('Tersedia', '$available')),
                _vline(),
                Expanded(child: _stat('Habis', '$soldOut')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vline() =>
      Container(height: 36, width: 1, color: Colors.white.withValues(alpha: .25));

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFE9E1FF), fontSize: 11.5),
        ),
      ],
    );
  }

  // ---------- SEARCH + FILTER ----------
  Widget _searchBar() {
    return TextField(
      controller: _searchC,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Cari menu...',
        prefixIcon: const Icon(Icons.search_rounded, color: purple),
        suffixIcon: _searchC.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => setState(_searchC.clear),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFECE8F3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFECE8F3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: purple, width: 1.3),
        ),
      ),
    );
  }

  Widget _chip(String label, _MenuFilter value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? purple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? purple : const Color(0xFFE2DDEC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // ---------- KARTU MENU ----------
  Widget _stepBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2DDEC)),
        ),
        child: Icon(icon,
            size: 18, color: onTap == null ? Colors.grey.shade400 : purple),
      ),
    );
  }

  Widget _menuCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['name'] ?? '').toString();
    final price = (data['price'] as num?)?.toInt() ?? 0;
    final stock = _stockOf(data);
    final soldOut = stock <= 0;
    final low = !soldOut && stock <= 5;

    final Color barBg = soldOut
        ? const Color(0xFFFFEDEE)
        : low
            ? const Color(0xFFFFF3DF)
            : const Color(0xFFE5F7F2);
    final Color barFg = soldOut
        ? const Color(0xFFD64550)
        : low
            ? const Color(0xFFC77D1A)
            : const Color(0xFF1F7F6A);
    final String label = soldOut
        ? 'Stok habis'
        : low
            ? 'Stok menipis'
            : 'Tersedia';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE8F3)),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: .04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openForm(doc: doc),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 74,
                        height: 74,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MenuImage.fromData(data,
                                placeholder: _placeholder()),
                            if (soldOut)
                              Container(
                                color: Colors.black.withValues(alpha: .45),
                                alignment: Alignment.center,
                                child: const Text(
                                  'HABIS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: .8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            formatRupiah(price),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded,
                          color: Colors.grey.shade700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      onSelected: (v) {
                        if (v == 'edit') _openForm(doc: doc);
                        if (v == 'delete') _confirmDelete(doc);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 19),
                            SizedBox(width: 10),
                            Text('Edit menu'),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline,
                                size: 19, color: Colors.redAccent),
                            SizedBox(width: 10),
                            Text('Hapus menu',
                                style: TextStyle(color: Colors.redAccent)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                  decoration: BoxDecoration(
                    color: barBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 17, color: barFg),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: barFg,
                          ),
                        ),
                      ),
                      _stepBtn(Icons.remove_rounded,
                          stock > 0 ? () => _adjustStock(doc, -1) : null),
                      InkWell(
                        onTap: () => _setStockDialog(doc, stock),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 46),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          alignment: Alignment.center,
                          child: Text(
                            '$stock',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: barFg,
                            ),
                          ),
                        ),
                      ),
                      _stepBtn(Icons.add_rounded, () => _adjustStock(doc, 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState({required bool noResult}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
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
            child: Icon(
              noResult ? Icons.search_off_rounded : Icons.restaurant_menu,
              color: purple,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            noResult ? 'Menu tidak ditemukan' : 'Belum ada menu',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            noResult
                ? 'Coba kata kunci atau filter lain.'
                : 'Tekan "Tambah Menu" untuk membuat\nmenu pertama Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: 12.5, height: 1.4),
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
      return const Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Text(
            'Data usaha tidak ditemukan.\nSilakan login ulang.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Tambah Menu',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _menus.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: purple),
            );
          }

          final all = snapshot.data!.docs.toList()
            ..sort(
              (a, b) => (a.data()['name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .compareTo((b.data()['name'] ?? '').toString().toLowerCase()),
            );

          final availableCount =
              all.where((d) => _stockOf(d.data()) > 0).length;
          final soldOutCount = all.length - availableCount;

          final q = _searchC.text.trim().toLowerCase();
          final shown = all.where((d) {
            final data = d.data();
            final ok = _stockOf(data) > 0;
            if (_filter == _MenuFilter.available && !ok) return false;
            if (_filter == _MenuFilter.soldOut && ok) return false;
            if (q.isEmpty) return true;
            return (data['name'] ?? '').toString().toLowerCase().contains(q);
          }).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _header(all.length, availableCount, soldOutCount),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _searchBar(),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _chip('Semua', _MenuFilter.all),
                            const SizedBox(width: 8),
                            _chip('Tersedia', _MenuFilter.available),
                            const SizedBox(width: 8),
                            _chip('Habis', _MenuFilter.soldOut),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              if (shown.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 150),
                  sliver: SliverToBoxAdapter(
                    child: _emptyState(noResult: all.isNotEmpty),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 150),
                  sliver: SliverList.builder(
                    itemCount: shown.length,
                    itemBuilder: (_, i) => _menuCard(shown[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static Widget _placeholder() {
    return Container(
      color: const Color(0xFFEDE7FF),
      child: const Icon(Icons.fastfood_outlined, color: purple, size: 30),
    );
  }
}

// ==========================================
// FORM TAMBAH / EDIT MENU (bottom sheet)
// ==========================================

class _MenuFormSheet extends StatefulWidget {
  final CollectionReference<Map<String, dynamic>> menus;
  final String businessId;
  final QueryDocumentSnapshot<Map<String, dynamic>>? doc;

  const _MenuFormSheet({
    required this.menus,
    required this.businessId,
    this.doc,
  });

  @override
  State<_MenuFormSheet> createState() => _MenuFormSheetState();
}

class _MenuFormSheetState extends State<_MenuFormSheet> {
  static const Color purple = Color(0xFF6952AE);
  static const Color bg = Color(0xFFF7F6FA);
  static const int maxImageBytes = 400 * 1024;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nameC;
  late final TextEditingController priceC;
  late final TextEditingController stockC;
  final _picker = ImagePicker();

  // Gambar yang baru dipilih (belum disimpan)
  Uint8List? _pickedBytes;
  // Gambar yang sudah tersimpan
  String _savedBase64 = '';
  String _savedUrl = '';
  bool _imageRemoved = false;

  bool saving = false;
  bool picking = false;

  bool get isEdit => widget.doc != null;

  bool get _hasImage =>
      !_imageRemoved &&
      (_pickedBytes != null || _savedBase64.isNotEmpty || _savedUrl.isNotEmpty);

  @override
  void initState() {
    super.initState();
    final data = widget.doc?.data();
    nameC = TextEditingController(text: data?['name']?.toString() ?? '');
    priceC = TextEditingController(
      text: data != null ? ((data['price'] as num?)?.toInt() ?? 0).toString() : '',
    );
    stockC = TextEditingController(
      text: data != null ? _EditMenuScreenState._stockOf(data).toString() : '',
    );
    _savedBase64 = (data?['imageBase64'] ?? '').toString();
    _savedUrl = (data?['imageUrl'] ?? '').toString();
  }

  @override
  void dispose() {
    nameC.dispose();
    priceC.dispose();
    stockC.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Ambil dari galeri (HP) / pemilih file (desktop & web).
  // Gambar langsung diperkecil supaya ringan.
  Future<void> _pickImage() async {
    if (picking) return;
    setState(() => picking = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.length > maxImageBytes) {
        _toast('Ukuran gambar terlalu besar, pilih gambar lain.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _pickedBytes = bytes;
        _imageRemoved = false;
      });
    } catch (e) {
      _toast('Gagal memilih gambar: $e');
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  void _removeImage() {
    setState(() {
      _pickedBytes = null;
      _imageRemoved = true;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);

    final stock = int.parse(stockC.text.trim());
    final payload = <String, dynamic>{
      'name': nameC.text.trim(),
      'stock': stock,
      // Otomatis tidak tersedia saat stok 0
      'isAvailable': stock > 0,
      'price': int.parse(priceC.text.trim()),
      'businessId': widget.businessId,
    };

    if (_pickedBytes != null) {
      payload['imageBase64'] = base64Encode(_pickedBytes!);
      payload['imageUrl'] = '';
    } else if (_imageRemoved) {
      payload['imageBase64'] = '';
      payload['imageUrl'] = '';
    }

    try {
      if (isEdit) {
        await widget.doc!.reference.update(payload);
      } else {
        await widget.menus.add({
          ...payload,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      _toast('Gagal menyimpan: $e');
    }
  }

  InputDecoration _decoration(String label, IconData icon, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      prefixIcon: Icon(icon, color: purple),
      filled: true,
      fillColor: bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: purple, width: 1.3),
      ),
    );
  }

  Widget _imagePicker() {
    final placeholder = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFEDE7FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_photo_alternate_outlined,
              color: purple, size: 28),
        ),
        const SizedBox(height: 10),
        const Text(
          'Tambah gambar dari galeri / file',
          style: TextStyle(fontWeight: FontWeight.w600, color: purple),
        ),
        const SizedBox(height: 2),
        Text(
          'Opsional • otomatis dikecilkan',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );

    return Column(
      children: [
        InkWell(
          onTap: saving ? null : _pickImage,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: 170,
            decoration: BoxDecoration(
              color: const Color(0xFFF2EEFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: purple.withValues(alpha: .15)),
            ),
            clipBehavior: Clip.antiAlias,
            child: picking
                ? const Center(child: CircularProgressIndicator(color: purple))
                : !_hasImage
                    ? placeholder
                    : _pickedBytes != null
                        ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
                        : MenuImage(
                            imageBase64: _savedBase64,
                            imageUrl: _savedUrl,
                            placeholder: placeholder,
                          ),
          ),
        ),
        if (_hasImage) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saving ? null : _pickImage,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Ganti'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: purple,
                    side: const BorderSide(color: purple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saving ? null : _removeImage,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 18),
                Text(
                  isEdit ? 'Edit Menu' : 'Tambah Menu',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Isi nama, harga, dan foto menu.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 18),
                _imagePicker(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameC,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration:
                      _decoration('Nama menu', Icons.restaurant_menu_rounded),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nama wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceC,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoration('Harga', Icons.payments_outlined,
                      prefix: 'Rp '),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Harga wajib diisi';
                    }
                    final p = int.tryParse(v.trim());
                    if (p == null || p <= 0) return 'Harga tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: stockC,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoration('Stok', Icons.inventory_2_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Stok wajib diisi';
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 0 || n > 999999) {
                      return 'Stok tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  'Menu otomatis tidak tersedia saat stok 0.',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 22),
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
                    onPressed: saving ? null : _save,
                    child: saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEdit ? 'Simpan Perubahan' : 'Simpan Menu',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}