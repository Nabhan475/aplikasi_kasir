import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

/// Warna bersama untuk halaman kasir dan keranjang.
const Color primaryPurple = Color(0xFF6952AE);
const Color lightPurple = Color(0xFFAC94F5);
const Color cashierBg = Color(0xFFF7F6FA);
const Color cashierInk = Color(0xFF292532);
const Color cashierBorder = Color(0xFFECE8F3);

// =========================
// MODEL KERANJANG
// =========================
class CartItem {
  final String id;
  final String name;
  final int price;
  int qty;
  int maxQty;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.qty = 1,
    this.maxQty = 999999,
  });
}

// =========================
// PANEL KERANJANG
// Dipakai sebagai panel kanan (landscape)
// dan sebagai isi halaman keranjang (portrait).
// =========================
class CartPanel extends StatefulWidget {
  final Map<String, CartItem> cart;
  final String businessId;
  final String? activeShift;

  /// Dipanggil setiap jumlah item berubah / keranjang dikosongkan.
  final VoidCallback onChanged;

  /// Dipanggil setelah checkout berhasil.
  final VoidCallback onCheckedOut;

  /// true = tampil sebagai halaman penuh (tanpa kartu & judul panel).
  final bool asPage;

  const CartPanel({
    super.key,
    required this.cart,
    required this.businessId,
    required this.onChanged,
    required this.onCheckedOut,
    this.activeShift,
    this.asPage = false,
  });

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  bool isLoading = false;

  Map<String, CartItem> get cart => widget.cart;

  int get totalItems => cart.values.fold(0, (s, i) => s + i.qty);
  int get totalPrice => cart.values.fold(0, (s, i) => s + i.qty * i.price);

  void changeQty(CartItem item, int delta) {
    if (delta > 0 && item.qty + delta > item.maxQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stok ${item.name} tinggal ${item.maxQty}')),
      );
      return;
    }

    setState(() {
      item.qty += delta;
      if (item.qty <= 0) cart.remove(item.id);
    });
    widget.onChanged();
  }

  Future<void> clearCart() async {
    final yes = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Kosongkan keranjang?'),
            content: const Text('Semua item di keranjang akan dihapus.'),
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
                child: const Text('Kosongkan'),
              ),
            ],
          ),
    );
    if (yes != true) return;
    setState(cart.clear);
    widget.onChanged();
  }

  Future<void> checkout() async {
    if (cart.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final items = cart.values.toList();
      final checkoutTotalItems = items.fold<int>(0, (t, i) => t + i.qty);
      final checkoutTotalPrice = items.fold<int>(
        0,
        (t, i) => t + i.price * i.qty,
      );
      final txRef = transactionsRef(widget.businessId).doc();

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final refs = {
          for (final item in items)
            item.id: menusRef(widget.businessId).doc(item.id),
        };
        final stocks = <String, int>{};
        for (final item in items) {
          final snap = await tx.get(refs[item.id]!);
          final stock = (snap.data()?['stock'] as num?)?.toInt() ?? 0;
          if (stock < item.qty) {
            throw Exception('Stok ${item.name} tidak cukup (sisa $stock)');
          }
          stocks[item.id] = stock;
        }

        for (final item in items) {
          final next = stocks[item.id]! - item.qty;
          tx.update(refs[item.id]!, {'stock': next, 'isAvailable': next > 0});
        }

        tx.set(txRef, {
          'items':
              items
                  .map(
                    (item) => {
                      'menuId': item.id,
                      'name': item.name,
                      'price': item.price,
                      'qty': item.qty,
                      'subtotal': item.price * item.qty,
                    },
                  )
                  .toList(),
          'totalItems': checkoutTotalItems,
          'total': checkoutTotalPrice,
          'businessId': widget.businessId,
          'cashierId': user?.uid,
          'cashierEmail': user?.email,
          'shift': widget.activeShift ?? 'Reguler',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      cart.clear();
      messenger.showSnackBar(
        const SnackBar(content: Text('Checkout berhasil')),
      );
      if (mounted) setState(() => isLoading = false);
      widget.onCheckedOut();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      messenger.showSnackBar(SnackBar(content: Text('Checkout gagal: $e')));
    }
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2DDEC)),
        ),
        child: Icon(icon, size: 17, color: primaryPurple),
      ),
    );
  }

  Widget _itemTile(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cashierBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: cashierInk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatRupiah(item.price),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  formatRupiah(item.price * item.qty),
                  style: const TextStyle(
                    color: primaryPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qtyBtn(Icons.remove_rounded, () => changeQty(item, -1)),
              SizedBox(
                width: 30,
                child: Text(
                  '${item.qty}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _qtyBtn(Icons.add_rounded, () => changeQty(item, 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFF0EBFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: primaryPurple,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Keranjang kosong',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih menu di sebelah kiri\nuntuk memulai pesanan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = cart.values.toList();
    final page = widget.asPage;

    final content = Column(
      children: [
        if (!page)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: primaryPurple,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keranjang',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: cashierInk,
                        ),
                      ),
                      Text(
                        '$totalItems item',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (items.isNotEmpty)
                  IconButton(
                    onPressed: isLoading ? null : clearCart,
                    tooltip: 'Kosongkan',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child:
              items.isEmpty
                  ? _empty()
                  : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _itemTile(items[i]),
                  ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: cashierBorder)),
            borderRadius:
                page
                    ? null
                    : const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total ($totalItems item)',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatRupiah(totalPrice),
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: primaryPurple,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: (isLoading || items.isEmpty) ? null : checkout,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryPurple,
                    disabledBackgroundColor: lightPurple.withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon:
                      isLoading
                          ? const SizedBox.shrink()
                          : const Icon(Icons.payments_outlined, size: 20),
                  label:
                      isLoading
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
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
    );

    if (page) return content;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cashierBorder),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: content),
    );
  }
}

// =========================
// HALAMAN KERANJANG (portrait)
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
        child: CartPanel(
          asPage: true,
          cart: widget.cart,
          businessId: widget.businessId,
          activeShift: widget.activeShift,
          onChanged: () {
            // Keranjang kosong -> kembali ke daftar menu
            if (widget.cart.isEmpty) {
              Navigator.pop(context);
            } else {
              setState(() {});
            }
          },
          onCheckedOut: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
