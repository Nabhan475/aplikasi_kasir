import 'package:flutter/material.dart';

class CashierScreen extends StatelessWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Menu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: const [
                  MenuItemCard(
                    name: 'Bubur Ayam Original',
                    price: 'Rp15.000',
                  ),
                  MenuItemCard(
                    name: 'Bubur Ayam Spesial',
                    price: 'Rp20.000',
                  ),
                  MenuItemCard(
                    name: 'Sate Usus',
                    price: 'Rp5.000',
                  ),
                  MenuItemCard(
                    name: 'Teh Manis',
                    price: 'Rp5.000',
                  ),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Lihat Keranjang'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuItemCard extends StatelessWidget {
  final String name;
  final String price;

  const MenuItemCard({
    super.key,
    required this.name,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text(price),
        trailing: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.add_shopping_cart),
        ),
      ),
    );
  }
}