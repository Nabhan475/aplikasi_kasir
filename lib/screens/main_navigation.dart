import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'sales_data_screen.dart';
import 'transaction_history_screen.dart';
import 'edit_menu_screen.dart';
import 'cashier_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final String role;

  const MainNavigation({super.key, required this.role});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  static const Color primaryOrange = Color(0xFFFF5A1F);

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.role.toLowerCase() == 'admin';

    // =========================
    // PAGE ADMIN
    // =========================
    final List<Widget> adminPages = [
      const DashboardScreen(),
      const SalesDataScreen(),
      const TransactionHistoryScreen(),
      const EditMenuScreen(),
      const ProfileScreen(),
    ];

    final List<_NavItemData> adminItems = [
      const _NavItemData(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
      ),
      const _NavItemData(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
      ),
      const _NavItemData(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
      ),
      const _NavItemData(
        icon: Icons.restaurant_menu_outlined,
        activeIcon: Icons.restaurant_menu,
      ),
      const _NavItemData(icon: Icons.person_outline, activeIcon: Icons.person),
    ];

    // =========================
    // PAGE KASIR
    // =========================
    final List<Widget> cashierPages = [
      const CashierScreen(),
      const TransactionHistoryScreen(),
      const ProfileScreen(),
    ];

    final List<_NavItemData> cashierItems = [
      const _NavItemData(
        icon: Icons.point_of_sale_outlined,
        activeIcon: Icons.point_of_sale,
      ),
      const _NavItemData(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
      ),
      const _NavItemData(icon: Icons.person_outline, activeIcon: Icons.person),
    ];

    final pages = isAdmin ? adminPages : cashierPages;
    final items = isAdmin ? adminItems : cashierItems;

    if (currentIndex >= pages.length) {
      currentIndex = 0;
    }

    return Scaffold(
      extendBody: true,

      // Supaya page tidak dibuat ulang setiap pindah menu
      body: IndexedStack(index: currentIndex, children: pages),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(left: 24, right: 24, bottom: 10),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: primaryOrange,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final bool isSelected = currentIndex == index;

              return Expanded(
                child: _AnimatedNavItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// =======================================
// DATA ITEM NAVIGATION
// =======================================

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;

  const _NavItemData({required this.icon, required this.activeIcon});
}

// =======================================
// ITEM NAVIGATION ANIMASI
// =======================================

class _AnimatedNavItem extends StatelessWidget {
  final _NavItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),

        splashColor: Colors.white.withOpacity(0.15),

        highlightColor: Colors.transparent,

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,

          margin: const EdgeInsets.symmetric(horizontal: 3),

          decoration: BoxDecoration(
            color:
                isSelected
                    ? Colors.white.withOpacity(0.18)
                    : Colors.transparent,

            borderRadius: BorderRadius.circular(22),
          ),

          child: Center(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,

              offset: isSelected ? const Offset(0, -0.10) : Offset.zero,

              child: AnimatedScale(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,

                scale: isSelected ? 1.12 : 1.0,

                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),

                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },

                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,

                    key: ValueKey<bool>(isSelected),

                    color: Colors.white,

                    size: isSelected ? 25 : 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
