import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'cart_screen.dart';
import 'menu_image.dart';
import 'utils.dart';

const String _defaultShift = 'Shift Reguler (08:00 - 17:00)';

// =========================
// HALAMAN KASIR
// =========================
class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final Map<String, CartItem> cart = {};
  final _searchC = TextEditingController();

  String? businessId;
  bool loadingBusiness = true;
  String? activeShift;

  int get totalItems => cart.values.fold(0, (s, i) => s + i.qty);
  int get totalPrice => cart.values.fold(0, (s, i) => s + i.qty * i.price);

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

      // Wajib pilih shift saat pertama kali masuk
      if (id != null && activeShift == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && activeShift == null) {
            _pickShiftModal(mandatory: true);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingBusiness = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil data usaha: $e')));
    }
  }

  // ------------------------------------------------
  // KERANJANG
  // ------------------------------------------------
  void addToCart(String id, String name, int price, int stock) {
    final current = cart[id]?.qty ?? 0;
    if (current >= stock) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Stok $name tinggal $stock')));
      return;
    }

    setState(() {
      if (cart.containsKey(id)) {
        cart[id]!.qty++;
        cart[id]!.maxQty = stock;
      } else {
        cart[id] = CartItem(id: id, name: name, price: price, maxQty: stock);
      }
    });
  }

  void removeFromCart(String id) {
    final item = cart[id];
    if (item == null) return;
    setState(() {
      item.qty--;
      if (item.qty <= 0) cart.remove(id);
    });
  }

  Future<void> openCart() async {
    final id = businessId;
    if (id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CartScreen(
              cart: cart,
              businessId: id,
              activeShift: activeShift,
            ),
      ),
    );
    if (mounted) setState(() {});
  }

  // ------------------------------------------------
  // PILIH SHIFT
  // ------------------------------------------------
  Widget _shiftTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String label,
    required BuildContext sheetCtx,
  }) {
    final selected = activeShift == label;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? lightPurple.withValues(alpha: 0.15) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? primaryPurple : Colors.grey.shade300,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: CircleAvatar(
          backgroundColor: selected ? primaryPurple : const Color(0xFFF0EDF9),
          foregroundColor: selected ? Colors.white : primaryPurple,
          child: Icon(icon, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected ? primaryPurple : Colors.black87,
          ),
        ),
        subtitle: Text(subtitle),
        trailing:
            selected
                ? const Icon(Icons.check_circle, color: primaryPurple)
                : null,
        onTap: () {
          setState(() => activeShift = label);
          Navigator.pop(sheetCtx);
        },
      ),
    );
  }

  void _pickShiftModal({bool mandatory = false}) {
    if (businessId == null) return;
    showModalBottomSheet<void>(
      context: context,
      isDismissible: !mandatory,
      enableDrag: !mandatory,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return PopScope(
          canPop: !mandatory,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
              maxWidth: 560,
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
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
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      color: primaryPurple,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Pilih Shift Kerja',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tentukan shift kasir yang aktif saat ini.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: shiftsRef(businessId!).snapshots(),
                      builder: (context, snapshot) {
                        final docs =
                            (snapshot.data?.docs ?? [])
                                .where((d) => d.data()['active'] != false)
                                .toList();

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (docs.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: cashierBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: primaryPurple,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Belum ada data shift. Anda dapat memilih Shift Reguler di bawah.',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ...docs.map((doc) {
                              final data = doc.data();
                              final name = data['name']?.toString() ?? 'Shift';
                              final start =
                                  data['startTime']?.toString() ?? '00:00';
                              final end =
                                  data['endTime']?.toString() ?? '00:00';
                              return _shiftTile(
                                title: name,
                                subtitle: '$start - $end WIB',
                                icon: Icons.schedule,
                                label: '$name ($start - $end)',
                                sheetCtx: sheetCtx,
                              );
                            }),
                            _shiftTile(
                              title: 'Shift Reguler',
                              subtitle: '08:00 - 17:00 WIB (Default)',
                              icon: Icons.work_outline,
                              label: _defaultShift,
                              sheetCtx: sheetCtx,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------
  // PESANAN ONLINE
  // ------------------------------------------------
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'diproses':
        return Colors.orange;
      case 'selesai':
        return Colors.green;
      case 'batal':
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _orderCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final customer = data['customer']?.toString() ?? 'Pelanggan';
    final menu = data['menu']?.toString() ?? 'Menu';
    final qty = data['quantity'] ?? 1;
    final note = data['note']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'Terjadwal';
    final s = status.toLowerCase();

    DateTime? date;
    final raw = data['scheduledAt'];
    if (raw is Timestamp) {
      date = raw.toDate();
    } else if (raw is String) {
      date = DateTime.tryParse(raw);
    }

    final color = _statusColor(status);
    final finished = s == 'selesai' || s == 'batal' || s == 'dibatalkan';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cashierBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  customer,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.restaurant_outlined,
                size: 16,
                color: primaryPurple,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$menu x$qty porsi',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (date != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${date.day.toString().padLeft(2, '0')}/'
                  '${date.month.toString().padLeft(2, '0')}/${date.year}'
                  ' • ${date.hour.toString().padLeft(2, '0')}:'
                  '${date.minute.toString().padLeft(2, '0')} WIB',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes, size: 14, color: Colors.amber.shade800),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (s == 'terjadwal')
                FilledButton.icon(
                  onPressed: () => doc.reference.update({'status': 'Diproses'}),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryPurple,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.soup_kitchen, size: 16),
                  label: const Text(
                    'Mulai Proses',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              if (s == 'diproses')
                FilledButton.icon(
                  onPressed: () => doc.reference.update({'status': 'Selesai'}),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text(
                    'Selesaikan',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              if (!finished) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => doc.reference.update({'status': 'Batal'}),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Batal', style: TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showOnlineOrdersSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          height: MediaQuery.of(sheetCtx).size.height * 0.85,
          constraints: const BoxConstraints(maxWidth: 640),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: primaryPurple,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Pesanan Online Masuk',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const Text(
                'Kelola pesanan online / terjadwal dari pelanggan.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream:
                      ordersRef(
                        businessId!,
                      ).orderBy('scheduledAt', descending: false).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: primaryPurple),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Terjadi kesalahan: ${snapshot.error}'),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 54,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada pesanan online',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pesanan yang masuk akan muncul di sini',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _orderCard(docs[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------
  // HEADER
  // ------------------------------------------------
  Widget _headerIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Tooltip(
              message: tooltip,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryPurple, width: 1.5),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _shiftChip() {
    final has = activeShift != null;
    return InkWell(
      onTap: () => _pickShiftModal(),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: has ? 0.16 : 0.26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Icon(
              has ? Icons.access_time_filled_rounded : Icons.warning_amber,
              color: has ? Colors.white : const Color(0xFFFFE08A),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                activeShift ?? 'Belum memilih shift',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              has ? 'Ganti' : 'Pilih',
              style: const TextStyle(
                color: Color(0xFFE9E1FF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFFE9E1FF),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(bool landscape) {
    final top = MediaQuery.paddingOf(context).top;

    final titleBlock = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.point_of_sale_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kasir',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Pilih menu & proses pesanan',
              style: TextStyle(color: Color(0xFFE9E1FF), fontSize: 11.5),
            ),
          ],
        ),
      ],
    );

    final actions = StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ordersRef(businessId!).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final count =
            docs.where((d) {
              final s = (d.data()['status'] ?? '').toString().toLowerCase();
              return s != 'selesai' && s != 'dibatalkan' && s != 'batal';
            }).length;
        return _headerIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Pesanan Online',
          onTap: _showOnlineOrdersSheet,
          badge: count,
        );
      },
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18,
        top + (landscape ? 10 : 14),
        18,
        landscape ? 14 : 18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8068CB), primaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child:
          landscape
              ? Row(
                children: [
                  titleBlock,
                  const SizedBox(width: 20),
                  Expanded(child: _shiftChip()),
                  const SizedBox(width: 12),
                  actions,
                ],
              )
              : Column(
                children: [
                  Row(children: [Expanded(child: titleBlock), actions]),
                  const SizedBox(height: 14),
                  _shiftChip(),
                ],
              ),
    );
  }

  // ------------------------------------------------
  // AREA MENU
  // ------------------------------------------------
  Widget _searchBar() {
    return TextField(
      controller: _searchC,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Cari menu...',
        prefixIcon: const Icon(Icons.search_rounded, color: primaryPurple),
        suffixIcon:
            _searchC.text.isEmpty
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
          borderSide: const BorderSide(color: cashierBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cashierBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryPurple, width: 1.3),
        ),
      ),
    );
  }

  Widget _menuArea({required double bottomPad}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _searchBar(),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  menusRef(
                    businessId!,
                  ).where('isAvailable', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Terjadi kesalahan: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryPurple),
                  );
                }

                final q = _searchC.text.trim().toLowerCase();
                final docs =
                    snapshot.data!.docs.where((doc) {
                        final d = doc.data();
                        final stock = (d['stock'] as num?)?.toInt() ?? 0;
                        if (stock <= 0) return false;
                        if (q.isEmpty) return true;
                        return (d['name'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(q);
                      }).toList()
                      ..sort(
                        (a, b) => (a.data()['name'] ?? '')
                            .toString()
                            .toLowerCase()
                            .compareTo(
                              (b.data()['name'] ?? '').toString().toLowerCase(),
                            ),
                      );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Daftar Menu',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: cashierInk,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE7FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${docs.length} menu',
                            style: const TextStyle(
                              color: primaryPurple,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ketuk menu untuk menambahkan ke keranjang',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child:
                          docs.isEmpty
                              ? _emptyMenu(q.isNotEmpty)
                              : GridView.builder(
                                padding: EdgeInsets.only(bottom: bottomPad),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 200,
                                      mainAxisExtent: 262,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final doc = docs[index];
                                  final data = doc.data();
                                  final name = (data['name'] ?? '').toString();
                                  final price =
                                      (data['price'] as num?)?.toInt() ?? 0;
                                  final stock =
                                      (data['stock'] as num?)?.toInt() ?? 0;

                                  return MenuItemCard(
                                    name: name,
                                    price: price,
                                    imageUrl:
                                        (data['imageUrl'] ?? '').toString(),
                                    imageBase64:
                                        (data['imageBase64'] ?? '').toString(),
                                    stock: stock,
                                    qtyInCart: cart[doc.id]?.qty ?? 0,
                                    onAdd:
                                        () => addToCart(
                                          doc.id,
                                          name,
                                          price,
                                          stock,
                                        ),
                                    onRemove: () => removeFromCart(doc.id),
                                  );
                                },
                              ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMenu(bool searching) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF0EBFF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                searching ? Icons.search_off_rounded : Icons.restaurant_menu,
                color: primaryPurple,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              searching ? 'Menu tidak ditemukan' : 'Belum ada menu tersedia',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              searching
                  ? 'Coba kata kunci lain.'
                  : 'Minta admin untuk menambahkan menu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------
  // TOMBOL KERANJANG (portrait)
  // ------------------------------------------------
  Widget _cartButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: openCart,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8068CB), primaryPurple],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryPurple.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        constraints: const BoxConstraints(minWidth: 17),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '$totalItems',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: primaryPurple,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Lihat Keranjang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                formatRupiah(totalPrice),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------
  // BUILD
  // ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (loadingBusiness) {
      return const Scaffold(
        backgroundColor: cashierBg,
        body: Center(child: CircularProgressIndicator(color: primaryPurple)),
      );
    }
    if (businessId == null) {
      return const Scaffold(
        backgroundColor: cashierBg,
        body: Center(
          child: Text(
            'Data usaha tidak ditemukan.\nSilakan login ulang.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    final cartWidth = (size.width * 0.36).clamp(300.0, 400.0).toDouble();

    return Scaffold(
      backgroundColor: cashierBg,
      body: SafeArea(
        top: false,
        child:
            landscape
                // ===== LANDSCAPE: menu kiri, keranjang kanan =====
                ? Column(
                  children: [
                    _header(true),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _menuArea(bottomPad: 16)),
                          SizedBox(
                            width: cartWidth,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                              child: CartPanel(
                                cart: cart,
                                businessId: businessId!,
                                activeShift: activeShift,
                                onChanged: () => setState(() {}),
                                onCheckedOut: () => setState(() {}),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                // ===== PORTRAIT: tombol keranjang muncul di bawah =====
                : Stack(
                  children: [
                    Column(
                      children: [
                        _header(false),
                        Expanded(
                          child: _menuArea(bottomPad: cart.isEmpty ? 16 : 88),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: IgnorePointer(
                        ignoring: cart.isEmpty,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          offset:
                              cart.isEmpty ? const Offset(0, 1.6) : Offset.zero,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: cart.isEmpty ? 0 : 1,
                            child: _cartButton(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

// =========================
// KARTU MENU
// =========================
class MenuItemCard extends StatelessWidget {
  final String name;
  final int price;
  final String imageUrl;
  final String imageBase64;
  final int stock;
  final int qtyInCart;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const MenuItemCard({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.imageBase64,
    required this.stock,
    required this.qtyInCart,
    required this.onAdd,
    required this.onRemove,
  });

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEDE7FF),
      child: const Icon(
        Icons.fastfood_outlined,
        color: primaryPurple,
        size: 50,
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback? onTap, {bool filled = true}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color:
              filled
                  ? (onTap == null
                      ? lightPurple.withValues(alpha: 0.5)
                      : primaryPurple)
                  : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: filled ? null : Border.all(color: const Color(0xFFE2DDEC)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled ? Colors.white : primaryPurple,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inCart = qtyInCart > 0;
    final maxed = qtyInCart >= stock;
    final low = stock <= 5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: inCart ? primaryPurple : cashierBorder,
          width: inCart ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withValues(alpha: 0.05),
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
          onTap: maxed ? null : onAdd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(19),
                        ),
                        child: MenuImage(
                          imageBase64: imageBase64,
                          imageUrl: imageUrl,
                          placeholder: _placeholder(),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              low
                                  ? Colors.orange.shade700
                                  : Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Sisa $stock',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cashierInk,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatRupiah(price),
                              style: const TextStyle(
                                color: primaryPurple,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (!inCart)
                          _roundBtn(Icons.add_rounded, onAdd)
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _roundBtn(
                                Icons.remove_rounded,
                                onRemove,
                                filled: false,
                              ),
                              SizedBox(
                                width: 26,
                                child: Text(
                                  '$qtyInCart',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              _roundBtn(
                                Icons.add_rounded,
                                maxed ? null : onAdd,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
