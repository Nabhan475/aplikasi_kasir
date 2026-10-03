import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'sales_data_screen.dart';
import 'transaction_history_screen.dart';
import 'edit_menu_screen.dart';
import 'cashier_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final String role;

  const MainNavigation({
    super.key,
    required this.role,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.role == 'Admin';

    // =========================
    // NAVIGASI ADMIN
    // =========================
    if (isAdmin) {
      final List<Widget> pages = [
        const DashboardScreen(),
        const SalesDataScreen(),
        const TransactionHistoryScreen(),
        const EditMenuScreen(),
        const ProfileScreen(),
      ];

      const List<NavigationDestination> destinations = [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Penjualan',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Riwayat',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu_outlined),
          selectedIcon: Icon(Icons.restaurant_menu),
          label: 'Menu',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];

      return Scaffold(
        body: pages[currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          destinations: destinations,
        ),
      );
    }

    // =========================
    // NAVIGASI KASIR
    // =========================
    final List<Widget> pages = [
      const CashierScreen(),
      const TransactionHistoryScreen(),
      const ProfileScreen(),
    ];

    const List<NavigationDestination> destinations = [
      NavigationDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(Icons.point_of_sale),
        label: 'Kasir',
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Riwayat',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: destinations,
      ),
    );
  }
}