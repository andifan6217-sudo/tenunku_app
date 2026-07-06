import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'buyer_profile_screen.dart';
import 'customer_dashboard.dart';
import 'home_screen.dart';
import 'my_reviews_screen.dart';
import 'orders_screen.dart';

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
    const darkBg = Color(0xFF0F0918);
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: darkBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF130B22),
          border: Border(top: BorderSide(color: goldColor.withOpacity(0.1), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF130B22),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: goldColor,
          unselectedItemColor: Colors.white24,
          selectedLabelStyle: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
          unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 8, letterSpacing: 1),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view_rounded), label: 'RINGKASAN'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'KATALOG'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'PESANAN'),
            BottomNavigationBarItem(icon: Icon(Icons.star_border_rounded), activeIcon: Icon(Icons.star), label: 'ULASAN'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'PROFIL'),
          ],
        ),
      ),
    );
  }
}
