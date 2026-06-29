import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'api_service.dart';
import 'widgets/tenun_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;
  bool _obscurePassword = true;

  void _requestOtp() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sila masukkan email Anda')));
      return;
    }

    if (!_emailController.text.contains('@') || !_emailController.text.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Format email tidak valid. Pastikan Anda menggunakan titik (.) bukan koma (,).'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.requestPasswordResetOtp(_emailController.text);
      setState(() => _otpSent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kode OTP berhasil dikirim ke email Anda'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetPassword() async {
    if (_otpController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sila masukkan kode OTP dan password baru')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.resetPasswordWithOtp(
        _emailController.text,
        _otpController.text,
        _passwordController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password berhasil direset! Sila login dengan password baru.'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {bool isPassword = false, TextInputType? keyboard}) {
    const goldPrimary = Color(0xFFD4AF37);
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white, letterSpacing: 1),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: Colors.white54, fontSize: 10, letterSpacing: 3),
        prefixIcon: Icon(icon, color: goldPrimary, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: goldPrimary, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: goldPrimary)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildCraftedButton(String text, VoidCallback onPressed) {
    const goldPrimary = Color(0xFFD4AF37);
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: goldPrimary, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          splashColor: goldPrimary.withOpacity(0.2),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                color: goldPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const goldPrimary = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: goldPrimary),
      ),
      body: TenunBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 80.0),
            child: Column(
              children: [
                Text(
                  'LUPA PASSWORD',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: goldPrimary,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn().slideY(begin: -0.2),
                
                const SizedBox(height: 40),

                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 450),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, spreadRadius: -10),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInput(_emailController, 'ALAMAT EMAIL', Icons.email_outlined, keyboard: TextInputType.emailAddress),
                          const SizedBox(height: 10),
                          
                          Align(
                            alignment: Alignment.centerRight,
                            child: _isLoading && !_otpSent
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: goldPrimary, strokeWidth: 1.5))
                              : TextButton(
                                  onPressed: _otpSent ? null : _requestOtp,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    _otpSent ? 'OTP TERKIRIM' : 'KIRIM KODE OTP',
                                    style: GoogleFonts.montserrat(
                                      color: _otpSent ? Colors.green : goldPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                          ),
                          
                          const SizedBox(height: 10),
                          _buildInput(_otpController, 'KODE OTP', Icons.security_outlined, keyboard: TextInputType.number),
                          const SizedBox(height: 20),
                          _buildInput(_passwordController, 'PASSWORD BARU', Icons.lock_outline, isPassword: true),
                          const SizedBox(height: 40),
                          
                          _isLoading && _otpSent
                            ? const CircularProgressIndicator(color: goldPrimary, strokeWidth: 1.5)
                            : _buildCraftedButton('RESET PASSWORD', _resetPassword),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
