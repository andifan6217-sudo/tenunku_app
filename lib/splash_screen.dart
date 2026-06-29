import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_service.dart';
import 'login_screen.dart';
import 'admin_dashboard.dart';
import 'seller_dashboard.dart';
import 'buyer_main_screen.dart';
import 'widgets/tenun_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    // Memberikan delay singkat agar animasi logo terlihat estetik
    await Future.delayed(const Duration(milliseconds: 2500));
    
    final token = await ApiService.getToken();
    final role = await ApiService.getRole();

    if (!mounted) return;

    if (token != null && token.isNotEmpty && role != null) {
      try {
        await ApiService.getMe();
      } catch (_) {
        await ApiService.logout();
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        return;
      }

      if (!mounted) return;

      if (role == 'ADMIN') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else if (role == 'PENJUAL') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SellerDashboard()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BuyerMainScreen()));
      }
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    const goldPrimary = Color(0xFFD4AF37);
    const goldSoft = Color(0xFFF9E79F);

    return Scaffold(
      body: TenunBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.blur_on_rounded, color: goldPrimary, size: 80)
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2000.ms, color: goldSoft),
              
              const SizedBox(height: 24),
              
              Text(
                'TENUN GEZA',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: goldPrimary,
                  letterSpacing: 8,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.5), offset: const Offset(0, 4), blurRadius: 10),
                  ],
                ),
              ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3),
              
              Container(
                width: 60,
                height: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: goldPrimary,
              ).animate().scaleX(delay: 400.ms),
              
              Text(
                'EXCLUSIVELY HANDCRAFTED',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 6,
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
