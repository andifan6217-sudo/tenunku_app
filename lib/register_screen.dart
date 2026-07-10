import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_service.dart';
import 'widgets/tenun_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  bool _obscurePassword = true;

  void _requestOtp() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || 
        _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sila lengkapi semua maklumat terlebih dahulu')));
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
      await ApiService.requestOtp(_emailController.text);
      if (mounted) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kode OTP telah dikirim ke email Anda.'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal Minta OTP: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _register() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sila masukkan kode OTP')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _phoneController.text,
        _otpController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pendaftaran Berhasil! Sila masuk ke butik.'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal Daftar: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const goldPrimary = Color(0xFFA67C1E);

    return Scaffold(
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
                  'DAFTAR AKUN',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: goldPrimary,
                    letterSpacing: 6,
                  ),
                ).animate().fadeIn().slideY(begin: -0.2),
                
                const SizedBox(height: 40),

                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 450),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black.withOpacity(0.08), width: 0.8),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 30, spreadRadius: 0),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInput(_nameController, 'NAMA LENGKAP', Icons.person_outline),
                        const SizedBox(height: 20),
                        _buildInput(_phoneController, 'NOMOR TELEPON', Icons.phone_android_outlined, keyboard: TextInputType.phone),
                        const SizedBox(height: 20),
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
                        _buildInput(_passwordController, 'PASSWORD', Icons.lock_outline, isPassword: true),
                        const SizedBox(height: 40),
                        _isLoading && _otpSent
                          ? const CircularProgressIndicator(color: goldPrimary, strokeWidth: 1.5)
                          : _buildCraftedButton('DAFTAR SEKARANG', _register),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
                
                const SizedBox(height: 32),
                
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'SUDAH MEMPUNYAI AKUN? MASUK',
                    style: GoogleFonts.montserrat(
                      color: goldPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {bool isPassword = false, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboard,
      style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 13, letterSpacing: 1),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: Colors.black45, fontSize: 9, letterSpacing: 4),
        prefixIcon: Icon(icon, color: const Color(0xFFA67C1E), size: 16),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFFA67C1E), size: 16),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black.withOpacity(0.12))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA67C1E))),
      ),
    );
  }

  Widget _buildCraftedButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFA67C1E), width: 1.2),
          foregroundColor: const Color(0xFFA67C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Text(text, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, letterSpacing: 3, fontSize: 11)),
      ),
    );
  }
}
