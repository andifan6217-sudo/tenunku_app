import 'package:flutter/material.dart';
import 'dart:ui' as ui;
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
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF130B22).withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.grid_view_rounded, 'Ringkasan', goldColor),
                    _buildNavItem(1, Icons.inventory_2_outlined, 'Katalog', goldColor),
                    _buildNavItem(2, Icons.shopping_cart_outlined, 'Pesanan', goldColor),
                    _buildNavItem(3, Icons.star_border_rounded, 'Ulasan', goldColor),
                    _buildNavItem(4, Icons.person_outline, 'Profil', goldColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color accentColor) {
    bool isActive = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(20),
        highlightColor: Colors.transparent,
        splashColor: accentColor.withOpacity(0.1),
        child: AnimatedScale(
          scale: isActive ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? accentColor.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? accentColor : Colors.white38,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: isActive ? accentColor : Colors.white38,
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
