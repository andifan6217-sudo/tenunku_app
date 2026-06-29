import 'forgot_password_screen.dart' as forgot_password;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_service.dart';
import 'admin_dashboard.dart';
import 'seller_dashboard.dart';
import 'register_screen.dart';
import 'buyer_main_screen.dart';
import 'widgets/tenun_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.login(_emailController.text, _passwordController.text);
      if (mounted) {
        if (data['requires2FA'] == true) {
          setState(() => _isLoading = false);
          _show2faDialog(data['email'] ?? _emailController.text);
        } else {
          _proceedLogin(data);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _proceedLogin(Map<String, dynamic> data) {
    final role = data['user']['role'];
    if (role == 'ADMIN') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
    } else if (role == 'PENJUAL') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SellerDashboard()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BuyerMainScreen()));
    }
  }

  void _show2faDialog(String email) {
    final otpCtrl = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF130B22),
          title: Text('2-FACTOR AUTHENTICATION', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Kode OTP telah dikirim ke $email.', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 16),
              TextField(
                controller: otpCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  counterText: "",
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
              ),
              if (isVerifying) const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isVerifying ? null : () => Navigator.pop(ctx), 
              child: const Text('BATAL', style: TextStyle(color: Colors.white24))
            ),
            TextButton(
              onPressed: isVerifying ? null : () async {
                setStateDialog(() => isVerifying = true);
                try {
                  final data = await ApiService.verify2faLogin(email, otpCtrl.text);
                  if (mounted) {
                    Navigator.pop(ctx);
                    _proceedLogin(data);
                  }
                } catch (e) {
                  setStateDialog(() => isVerifying = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('VERIFIKASI', style: TextStyle(color: Color(0xFFD4AF37))),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const goldPrimary = Color(0xFFD4AF37);
    const goldSoft = Color(0xFFF9E79F);

    return Scaffold(
      body: TenunBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minimalist Luxury Logo
                const Icon(Icons.blur_on_rounded, color: goldPrimary, size: 80)
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 2000.ms, color: goldSoft),
                
                const SizedBox(height: 16),
                
                Text(
                  'TENUN GEZA',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 48,
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
                
                const SizedBox(height: 24),

                // Exquisite Glass Form
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 450),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, spreadRadius: -10),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInput(_emailController, 'EMAIL', Icons.account_circle_outlined),
                          const SizedBox(height: 30),
                          _buildInput(_passwordController, 'PASSWORD', Icons.lock_open_outlined, isPassword: true),
                          const SizedBox(height: 15),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const forgot_password.ForgotPasswordScreen()));
                              },
                              child: Text(
                                'LUPA PASSWORD?',
                                style: GoogleFonts.montserrat(
                                  color: const Color(0xFFD4AF37),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          _isLoading 
                            ? const CircularProgressIndicator(color: goldPrimary, strokeWidth: 1.5)
                            : _buildCraftedButton('ENTER BOUTIQUE', _login),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms),
                
                const SizedBox(height: 20),
                
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: Text(
                    'DAFTAR AKUN BARU',
                    style: GoogleFonts.montserrat(
                      color: goldPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, letterSpacing: 1),
      cursorColor: const Color(0xFFD4AF37),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.4), fontSize: 10, letterSpacing: 4),
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37), size: 18),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFFD4AF37), size: 18),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
      ),
    );
  }

  Widget _buildCraftedButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
          foregroundColor: const Color(0xFFD4AF37),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
        onPressed: onPressed,
        child: Text(text, style: GoogleFonts.montserrat(fontWeight: FontWeight.w400, letterSpacing: 4, fontSize: 12)),
      ),
    );
  }
}
