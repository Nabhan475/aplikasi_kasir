import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'utils.dart';

const Color primaryOrange = Color(0xFFFF5A1F);
const Color softOrange = Color(0xFFFFEEE8);

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

  int get totalItems => cart.values.fold(0, (s, i) => s + i.qty);
  int get totalPrice => cart.values.fold(0, (s, i) => s + i.qty * i.price);

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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CartScreen(cart: cart)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kasir',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  stream: FirebaseFirestore.instance
                      .collection('menus')
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
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFFFC9B5),
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
      color: softOrange,
      child: const Icon(
        Icons.fastfood_outlined,
        color: primaryOrange,
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
            color: Colors.black.withOpacity(0.05),
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
                        color: primaryOrange,
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
                    color: primaryOrange,
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
                      backgroundColor: primaryOrange,
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

  const CartScreen({super.key, required this.cart});

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

      await FirebaseFirestore.instance.collection('transactions').add({
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
        'cashierId': user?.uid,
        'cashierEmail': user?.email,
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
        backgroundColor: primaryOrange,
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
                                  color: primaryOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => changeQty(item, -1),
                          icon: const Icon(Icons.remove_circle_outline),
                          color: primaryOrange,
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
                          color: primaryOrange,
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
                          color: primaryOrange,
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
                        backgroundColor: primaryOrange,
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