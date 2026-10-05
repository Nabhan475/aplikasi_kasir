import 'package:flutter/material.dart';

class CashierScreen extends StatelessWidget {
  const CashierScreen({super.key});

  static const Color primaryOrange = Color(0xFFFF5A1F);
  static const Color softOrange = Color(0xFFFFEEE8);

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
              // GRID MENU
              // ============================
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                  children: const [
                    MenuItemCard(
                      name: 'Bubur Ayam Original',
                      price: 'Rp15.000',
                      image: 'assets/bubur_original.jpg',
                    ),
                    MenuItemCard(
                      name: 'Bubur Ayam Spesial',
                      price: 'Rp20.000',
                      image: 'assets/bubur_spesial.jpg',
                    ),
                    MenuItemCard(
                      name: 'Sate Usus',
                      price: 'Rp5.000',
                      image: 'assets/sate_usus.jpg',
                    ),
                    MenuItemCard(
                      name: 'Teh Manis',
                      price: 'Rp5.000',
                      image: 'assets/teh_manis.jpg',
                    ),
                  ],
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
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text(
                    'Lihat Keranjang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

class MenuItemCard extends StatelessWidget {
  final String name;
  final String price;
  final String image;

  const MenuItemCard({
    super.key,
    required this.name,
    required this.price,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFFF5A1F);
    const Color softOrange = Color(0xFFFFEEE8);

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
          // ============================
          // GAMBAR MENU
          // ============================
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              child: Image.asset(
                image,
                width: double.infinity,
                fit: BoxFit.cover,

                // Kalau gambar belum ada
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    color: softOrange,
                    child: const Icon(
                      Icons.fastfood_outlined,
                      color: primaryOrange,
                      size: 55,
                    ),
                  );
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NAMA MENU
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

                // HARGA
                Text(
                  price,
                  style: const TextStyle(
                    color: primaryOrange,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // BUTTON TAMBAH
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () {},
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
