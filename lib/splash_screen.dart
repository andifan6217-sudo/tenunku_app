import 'package:flutter/material.dart';
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
    const goldSoft = Color(0xFFF9E79F);

    return Scaffold(
      body: TenunBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Premium Luxury Logo
              Image.asset('assets/images/logo.png', height: 120)
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2500.ms, color: goldSoft)
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}
