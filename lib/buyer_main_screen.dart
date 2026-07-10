import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'buyer_profile_screen.dart';
import 'customer_dashboard.dart';
import 'home_screen.dart';
import 'my_reviews_screen.dart';
import 'orders_screen.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';

class BuyerMainScreen extends StatefulWidget {
  const BuyerMainScreen({super.key});

  @override
  State<BuyerMainScreen> createState() => _BuyerMainScreenState();
}

class _BuyerMainScreenState extends State<BuyerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CustomerDashboardScreen(showDrawer: false),
    const HomeScreen(showDrawer: false),
    const OrdersScreen(showBackButton: false),
    const MyReviewsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    const lightBg = Color(0xFFF9FAFC);
    const goldColor = Color(0xFFA67C1E); // Deeper gold for light theme contrast

    return Scaffold(
      backgroundColor: lightBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: goldColor,
          unselectedItemColor: Colors.black38,
          selectedLabelStyle: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
          unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 8, letterSpacing: 1),
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.grid_view_outlined), activeIcon: const Icon(Icons.grid_view_rounded), label: lang.translate('home')),
            BottomNavigationBarItem(icon: const Icon(Icons.inventory_2_outlined), activeIcon: const Icon(Icons.inventory_2), label: lang.translate('catalog')),
            BottomNavigationBarItem(icon: const Icon(Icons.shopping_cart_outlined), activeIcon: const Icon(Icons.shopping_cart), label: lang.translate('orders')),
            BottomNavigationBarItem(icon: const Icon(Icons.star_border_rounded), activeIcon: const Icon(Icons.star), label: lang.translate('reviews_buyer')),
            BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: lang.translate('account')),
          ],
        ),
      ),
    );
  }
}
