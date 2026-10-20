import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'utils.dart';

const Color primaryPurple = Color(0xFF6952AE);
const Color lightPurple = Color(0xFFAC94F5);

// =========================
// MODEL KERANJANG
// =========================
class CartItem {
  final String id;
  final String name;
  final int price;
  int qty;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.qty = 1,
  });
}

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

  Future<void> _loadBusiness() async {
    try {
      final id = await getBusinessId();
      if (!mounted) return;
      setState(() {
        businessId = id;
        loadingBusiness = false;
      });

      // Munculkan dialog pilihan shift pertama kali jika kasir belum memilih shift
      if (activeShift == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && activeShift == null) {
            _pickShiftModal(context, mandatory: true);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadingBusiness = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data usaha: $e')),
      );
    }
  }

  void _pickShiftModal(BuildContext context, {bool mandatory = false}) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: !mandatory,
      enableDrag: !mandatory,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return PopScope(
          canPop: !mandatory,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
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
                    Icon(Icons.access_time_filled, color: primaryPurple, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Pilih Shift Kerja',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Silakan tentukan shift kasir yang aktif saat ini.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: shiftsRef(businessId!).snapshots(),
                  builder: (context, snapshot) {
                    final docs = (snapshot.data?.docs ?? [])
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
                              color: const Color(0xFFF7F6FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: primaryPurple, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Belum ada data shift di sistem. Anda dapat memilih Shift Reguler di bawah.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ...docs.map((doc) {
                          final data = doc.data();
                          final name = data['name']?.toString() ?? 'Shift';
                          final start = data['startTime']?.toString() ?? '00:00';
                          final end = data['endTime']?.toString() ?? '00:00';
                          final label = '$name ($start - $end)';
                          final isSelected = activeShift == label;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? lightPurple.withValues(alpha: 0.15) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? primaryPurple : Colors.grey.shade300,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected ? primaryPurple : const Color(0xFFF0EDF9),
                                foregroundColor: isSelected ? Colors.white : primaryPurple,
                                child: const Icon(Icons.schedule, size: 20),
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? primaryPurple : Colors.black87,
                                ),
                              ),
                              subtitle: Text('$start - $end WIB'),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: primaryPurple)
                                  : null,
                              onTap: () {
                                setState(() => activeShift = label);
                                Navigator.pop(sheetCtx);
                              },
                            ),
                          );
                        }),
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: activeShift == 'Shift Reguler (08:00 - 17:00)'
                                ? lightPurple.withValues(alpha: 0.15)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: activeShift == 'Shift Reguler (08:00 - 17:00)'
                                  ? primaryPurple
                                  : Colors.grey.shade300,
                              width: activeShift == 'Shift Reguler (08:00 - 17:00)' ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: activeShift == 'Shift Reguler (08:00 - 17:00)'
                                  ? primaryPurple
                                  : const Color(0xFFF0EDF9),
                              foregroundColor: activeShift == 'Shift Reguler (08:00 - 17:00)'
                                  ? Colors.white
                                  : primaryPurple,
                              child: const Icon(Icons.work_outline, size: 20),
                            ),
                            title: const Text(
                              'Shift Reguler',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text('08:00 - 17:00 WIB (Default)'),
                            trailing: activeShift == 'Shift Reguler (08:00 - 17:00)'
                                ? const Icon(Icons.check_circle, color: primaryPurple)
                                : null,
                            onTap: () {
                              setState(() => activeShift = 'Shift Reguler (08:00 - 17:00)');
                              Navigator.pop(sheetCtx);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOnlineOrdersSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          height: MediaQuery.of(sheetCtx).size.height * 0.85,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, color: primaryPurple, size: 24),
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
                  stream: ordersRef(businessId!)
                      .orderBy('scheduledAt', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: primaryPurple));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada pesanan online',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pesanan yang masuk akan muncul di sini',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final customer = data['customer']?.toString() ?? 'Pelanggan';
                        final menu = data['menu']?.toString() ?? 'Menu';
                        final qty = data['quantity'] ?? 1;
                        final note = data['note']?.toString() ?? '';
                        final status = data['status']?.toString() ?? 'Terjadwal';

                        DateTime? scheduledDate;
                        final scheduledRaw = data['scheduledAt'];
                        if (scheduledRaw is Timestamp) {
                          scheduledDate = scheduledRaw.toDate();
                        } else if (scheduledRaw is String) {
                          scheduledDate = DateTime.tryParse(scheduledRaw);
                        }

                        Color statusColor = Colors.blue;
                        if (status.toLowerCase() == 'diproses') statusColor = Colors.orange;
                        if (status.toLowerCase() == 'selesai') statusColor = Colors.green;
                        if (status.toLowerCase() == 'batal' || status.toLowerCase() == 'dibatalkan') {
                          statusColor = Colors.red;
                        }

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBFBFE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE9E7F2)),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
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
                                  const Icon(Icons.restaurant_outlined, size: 16, color: primaryPurple),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '$menu x$qty porsi',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              if (scheduledDate != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${scheduledDate.day.toString().padLeft(2, '0')}/${scheduledDate.month.toString().padLeft(2, '0')}/${scheduledDate.year} â€¢ ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')} WIB',
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
                                          style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
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
                                  if (status.toLowerCase() == 'terjadwal')
                                    FilledButton.icon(
                                      onPressed: () async {
                                        await doc.reference.update({'status': 'Diproses'});
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: primaryPurple,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      icon: const Icon(Icons.soup_kitchen, size: 16),
                                      label: const Text('Mulai Proses', style: TextStyle(fontSize: 12)),
                                    ),
                                  if (status.toLowerCase() == 'diproses')
                                    FilledButton.icon(
                                      onPressed: () async {
                                        await doc.reference.update({'status': 'Selesai'});
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Selesaikan', style: TextStyle(fontSize: 12)),
                                    ),
                                  if (status.toLowerCase() != 'selesai' &&
                                      status.toLowerCase() != 'batal' &&
                                      status.toLowerCase() != 'dibatalkan') ...[
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () async {
                                        await doc.reference.update({'status': 'Batal'});
                                      },
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
                      },
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

  void addToCart(String id, String name, int price) {
    setState(() {
      if (cart.containsKey(id)) {
        cart[id]!.qty++;
      } else {
        cart[id] = CartItem(id: id, name: name, price: price);
      }
    });
  }

  Future<void> openCart() async {
    final id = businessId;
    if (id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          cart: cart,
          businessId: id,
          activeShift: activeShift,
        ),
      ),
    );
    if (mounted) setState(() {});
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
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kasir',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ordersRef(businessId!).snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              final pending = docs.where((d) {
                final s = (d.data()['status'] ?? '').toString().toLowerCase();
                return s != 'selesai' && s != 'dibatalkan' && s != 'batal';
              }).toList();
              final count = pending.length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Pesanan Online',
                    onPressed: _showOnlineOrdersSheet,
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.access_time_rounded),
            tooltip: 'Pilih Shift',
            onPressed: () => _pickShiftModal(context, mandatory: false),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================
              // BANNER SHIFT AKTIF
              // ============================
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: activeShift != null
                        ? lightPurple.withValues(alpha: 0.5)
                        : Colors.orange.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (activeShift != null ? primaryPurple : Colors.orange)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.access_time_filled_rounded,
                        color: activeShift != null ? primaryPurple : Colors.orange.shade800,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shift Kerja Aktif',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeShift ?? 'Belum memilih shift (Ketuk tombol)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: activeShift != null
                                  ? primaryPurple
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _pickShiftModal(context, mandatory: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryPurple,
                        side: const BorderSide(color: primaryPurple),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        activeShift == null ? 'Pilih' : 'Ganti',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Daftar Menu',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih menu yang ingin ditambahkan',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // ============================
              // GRID MENU (dari Firestore)
              // ============================
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: menusRef(businessId!)
                      .where('isAvailable', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Terjadi kesalahan: ${snapshot.error}'),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs.toList()
                      ..sort((a, b) => (a.data()['name'] ?? '')
                          .toString()
                          .toLowerCase()
                          .compareTo(
                              (b.data()['name'] ?? '').toString().toLowerCase()));

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Belum ada menu tersedia.\nMinta admin untuk menambahkan menu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final name = (data['name'] ?? '').toString();
                        final price = (data['price'] as num?)?.toInt() ?? 0;
                        final imageUrl = (data['imageUrl'] ?? '').toString();

                        return MenuItemCard(
                          name: name,
                          price: price,
                          imageUrl: imageUrl,
                          qtyInCart: cart[doc.id]?.qty ?? 0,
                          onAdd: () => addToCart(doc.id, name, price),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ============================
              // BUTTON KERANJANG
              // ============================
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: cart.isEmpty ? null : openCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: lightPurple.withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: Text(
                    cart.isEmpty
                        ? 'Keranjang kosong'
                        : 'Lihat Keranjang ($totalItems) • ${formatRupiah(totalPrice)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
  final int qtyInCart;
  final VoidCallback onAdd;

  const MenuItemCard({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.qtyInCart,
    required this.onAdd,
  });

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      color: lightPurple.withValues(alpha: 0.25),
      child: const Icon(
        Icons.fastfood_outlined,
        color: primaryPurple,
        size: 55,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    child: imageUrl.isEmpty
                        ? _placeholder()
                        : Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          ),
                  ),
                ),
                if (qtyInCart > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$qtyInCart',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatRupiah(price),
                  style: const TextStyle(
                    color: primaryPurple,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: onAdd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Tambah',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// HALAMAN KERANJANG + CHECKOUT
// =========================
class CartScreen extends StatefulWidget {
  final Map<String, CartItem> cart;
  final String businessId;
  final String? activeShift;

  const CartScreen({
    super.key,
    required this.cart,
    required this.businessId,
    this.activeShift,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool isLoading = false;

  Map<String, CartItem> get cart => widget.cart;

  int get totalItems => cart.values.fold(0, (s, i) => s + i.qty);
  int get totalPrice => cart.values.fold(0, (s, i) => s + i.qty * i.price);

  void changeQty(CartItem item, int delta) {
    setState(() {
      item.qty += delta;
      if (item.qty <= 0) cart.remove(item.id);
    });
    if (cart.isEmpty) Navigator.pop(context);
  }

  Future<void> checkout() async {
    if (cart.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      await transactionsRef(widget.businessId).add({
        'items': cart.values
            .map((i) => {
                  'menuId': i.id,
                  'name': i.name,
                  'price': i.price,
                  'qty': i.qty,
                  'subtotal': i.price * i.qty,
                })
            .toList(),
        'totalItems': totalItems,
        'total': totalPrice,
        'businessId': widget.businessId,
        'cashierId': user?.uid,
        'cashierEmail': user?.email,
        'shift': widget.activeShift ?? 'Reguler',
        'createdAt': FieldValue.serverTimestamp(),
      });

      cart.clear();

      messenger.showSnackBar(
        const SnackBar(content: Text('Checkout berhasil')),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Checkout gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = cart.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Keranjang',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatRupiah(item.price),
                                style: const TextStyle(
                                  color: primaryPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => changeQty(item, -1),
                          icon: const Icon(Icons.remove_circle_outline),
                          color: primaryPurple,
                        ),
                        Text(
                          '${item.qty}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => changeQty(item, 1),
                          icon: const Icon(Icons.add_circle_outline),
                          color: primaryPurple,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total ($totalItems item)',
                        style: const TextStyle(fontSize: 15),
                      ),
                      Text(
                        formatRupiah(totalPrice),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : checkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Checkout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}