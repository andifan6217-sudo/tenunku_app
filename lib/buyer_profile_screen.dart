import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'address_screen.dart';
import 'api_service.dart';
import 'financial_report_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  List<dynamic> _addresses = [];
  bool _isLoading = true;
  String? _role;

  // Edit Profile Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();

  // Change Password Controllers
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Payment Settings Controllers
  final _bankNameCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _birthCtrl.dispose();
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await ApiService.getMe();
      final addresses = await ApiService.getAddresses();
      final role = await ApiService.getRole();
      if (mounted) {
        setState(() {
          _user = user;
          _addresses = addresses;
          _role = (user['role']?.toString() ?? '').isNotEmpty ? user['role']?.toString() : role;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat profil: $e')),
        );
      }
    }
  }

  void _editProfile() async {
    if (_user == null) return;
    _nameCtrl.text = _user!['name']?.toString() ?? '';
    _phoneCtrl.text = _user!['phone']?.toString() ?? '';
    _emailCtrl.text = _user!['email']?.toString() ?? '';
    _birthCtrl.text = _user!['birthDate']?.toString() ?? '';

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF130B22),
        title: Text('UBAH PROFIL', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  labelStyle: TextStyle(color: Colors.white38),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  labelStyle: TextStyle(color: Colors.white38),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white38),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _birthCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tanggal Lahir (YYYY-MM-DD)',
                  labelStyle: TextStyle(color: Colors.white38),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
                onTap: () async {
                  FocusScope.of(ctx).requestFocus(FocusNode());
                  DateTime? picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFFD4AF37),
                            onPrimary: Colors.black,
                            surface: Color(0xFF130B22),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    _birthCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL', style: TextStyle(color: Colors.white24))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SIMPAN', style: TextStyle(color: Color(0xFFD4AF37)))),
        ],
      ),
    );

    final newName = _nameCtrl.text;
    final newPhone = _phoneCtrl.text;
    final newEmail = _emailCtrl.text;
    final newBirthDate = _birthCtrl.text;

    if (updated == true && mounted) {
      try {
        await ApiService.updateProfile(newName, newPhone, newEmail, newBirthDate);
        await _loadData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  void _changePassword() async {
    _currentCtrl.clear();
    _newCtrl.clear();
    _confirmCtrl.clear();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF130B22),
          title: Text('UBAH PASSWORD', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentCtrl,
                obscureText: obscureCurrent,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password Sekarang',
                  labelStyle: const TextStyle(color: Colors.white38),
                  suffixIcon: IconButton(
                    icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, color: const Color(0xFFD4AF37), size: 18),
                    onPressed: () => setStateDialog(() => obscureCurrent = !obscureCurrent),
                  ),
                ),
              ),
              TextField(
                controller: _newCtrl,
                obscureText: obscureNew,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  labelStyle: const TextStyle(color: Colors.white38),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: const Color(0xFFD4AF37), size: 18),
                    onPressed: () => setStateDialog(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              TextField(
                controller: _confirmCtrl,
                obscureText: obscureConfirm,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  labelStyle: const TextStyle(color: Colors.white38),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: const Color(0xFFD4AF37), size: 18),
                    onPressed: () => setStateDialog(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
            ],
          ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL', style: TextStyle(color: Colors.white24))),
          TextButton(
            onPressed: () {
              if (_newCtrl.text != _confirmCtrl.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Password baru tidak cocok.')));
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('UBAH', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
      ),
    );

    if (updated == true && mounted) {
      try {
        await ApiService.changePassword(_currentCtrl.text, _newCtrl.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah!')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  void _toggle2FA() async {
    try {
      final res = await ApiService.toggle2fa();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  void _showPaymentSettingsDialog() async {
    const gold = Color(0xFFD4AF37);
    // Muat pengaturan yang sudah ada
    Map<String, dynamic>? currentSettings;
    try {
      currentSettings = await ApiService.getPaymentSettings();
    } catch (_) {}

    if (!mounted) return;

    _bankNameCtrl.text = currentSettings?['bankName']?.toString() ?? '';
    _bankAccountCtrl.text = currentSettings?['bankAccount']?.toString() ?? '';
    _accountNameCtrl.text = currentSettings?['accountName']?.toString() ?? '';
    String? qrisImageUrl = currentSettings?['qrisImageUrl']?.toString();
    bool isUploadingQris = false;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          decoration: const BoxDecoration(
            color: Color(0xFF130B22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Center(
                  child: Text('PENGATURAN REKENING & QRIS',
                      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                const SizedBox(height: 4),
                const Center(child: Text('Info ini akan ditampilkan kepada pembeli saat melakukan transfer manual.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 10))),
                const SizedBox(height: 28),

                // Input fields
                _buildSettingField(_bankNameCtrl, 'Nama Bank', 'Contoh: BCA, Mandiri, BRI, BNI', gold),
                const SizedBox(height: 16),
                _buildSettingField(_bankAccountCtrl, 'Nomor Rekening', 'Contoh: 1234567890', gold, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildSettingField(_accountNameCtrl, 'Nama Pemilik Rekening', 'Contoh: TENUN GEZA OFFICIAL', gold),
                const SizedBox(height: 24),

                // Upload QRIS
                const Text('Gambar QRIS', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: isUploadingQris ? null : () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                    if (pickedFile == null) return;
                    setSheetState(() => isUploadingQris = true);
                    try {
                      final url = await ApiService.uploadImage(pickedFile);
                      setSheetState(() {
                        qrisImageUrl = url;
                        isUploadingQris = false;
                      });
                    } catch (e) {
                      setSheetState(() => isUploadingQris = false);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (qrisImageUrl != null && qrisImageUrl!.isNotEmpty)
                          ? gold.withOpacity(0.05)
                          : Colors.white.withOpacity(0.03),
                      border: Border.all(
                        color: (qrisImageUrl != null && qrisImageUrl!.isNotEmpty)
                            ? gold.withOpacity(0.4)
                            : Colors.white12,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isUploadingQris
                        ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2)))
                        : (qrisImageUrl != null && qrisImageUrl!.isNotEmpty)
                            ? Column(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    ApiService.getFormattedImageUrl(qrisImageUrl),
                                    height: 160, fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white24, size: 40),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Ketuk untuk ganti gambar QRIS', style: TextStyle(color: gold.withOpacity(0.7), fontSize: 10)),
                              ])
                            : Column(children: [
                                const Icon(Icons.qr_code_2, color: Colors.white24, size: 40),
                                const SizedBox(height: 8),
                                const Text('Ketuk untuk upload gambar QRIS dari galeri', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                const SizedBox(height: 4),
                                const Text('JPG / PNG • Maks 5MB', style: TextStyle(color: Colors.white24, fontSize: 10)),
                              ]),
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Simpan
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                     onPressed: isSaving ? null : () async {
                      setSheetState(() => isSaving = true);
                      try {
                        await ApiService.updatePaymentSettings({
                          'bankName': _bankNameCtrl.text.trim(),
                          'bankAccount': _bankAccountCtrl.text.trim(),
                          'accountName': _accountNameCtrl.text.trim(),
                          'qrisImageUrl': qrisImageUrl ?? '',
                        });
                        if (mounted) {
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pengaturan rekening berhasil disimpan!'), backgroundColor: Color(0xFF2ECC71)),
                          );
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
                      } finally {
                        setSheetState(() => isSaving = false);
                      }
                    },
                    icon: isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(isSaving ? 'MENYIMPAN...' : 'SIMPAN PENGATURAN',
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingField(TextEditingController ctrl, String label, String hint, Color gold,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: gold)),
          ),
        ),
      ],
    );
  }

  String _getJoinedDate() {
    if (_user == null || _user!['createdAt'] == null) return '-';
    try {
      final date = DateTime.parse(_user!['createdAt']);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const darkArt = Color(0xFF0F0918);
    const darkCard = Color(0xFF1A1128);

    final isAdminOrSeller = _role == 'ADMIN' || _role == 'PENJUAL';
    
    // Cari alamat utama
    Map<String, dynamic>? mainAddress;
    if (_addresses.isNotEmpty) {
      try {
        mainAddress = _addresses.firstWhere((a) => a['isMain'] == true, orElse: () => _addresses.first);
      } catch (e) {
        mainAddress = _addresses.first;
      }
    }

    return Scaffold(
      backgroundColor: darkArt,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: gold),
        title: Text('Profil Saya', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: gold,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                children: [
                  const Text('Kelola informasi akun Anda', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 24),
                  
                  // Tombol Edit Profil Utama
                  OutlinedButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Card 1: Avatar & Info Singkat
                  _buildCard(
                    darkCard,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_outline, color: Color(0xFF00E5FF), size: 48),
                        ),
                        const SizedBox(height: 16),
                        Text(_user?['name'] ?? 'Guest', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_user?['email'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, color: Colors.blueAccent, size: 14),
                              const SizedBox(width: 6),
                              Text('${_role == 'ADMIN' ? 'Admin' : _role == 'PENJUAL' ? 'Penjual' : 'Pelanggan'} Terverifikasi', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 16),
                        Text('Bergabung sejak', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(_getJoinedDate(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  // Card 2: Informasi Pribadi
                  _buildSectionTitle('Informasi Pribadi'),
                  _buildCard(
                    darkCard,
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person, 'Nama Lengkap', _user?['name'] ?? '-'),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow(Icons.email, 'Email', _user?['email'] ?? '-'),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow(Icons.phone, 'Nomor Telepon', _user?['phone'] ?? 'Belum diatur'),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow(Icons.cake, 'Tanggal Lahir', _user?['birthDate'] ?? 'Belum diatur'),
                      ],
                    ),
                  ),

                  // Card 3: Alamat Pengiriman
                  _buildSectionTitle('Alamat Pengiriman'),
                  _buildCard(
                    darkCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white54, size: 18),
                            const SizedBox(width: 12),
                            const Text('Alamat Lengkap', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())).then((_) => _loadData());
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                alignment: Alignment.centerRight,
                              ),
                              child: Text(mainAddress != null ? 'Ubah' : 'Tambah', style: const TextStyle(color: gold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: mainAddress != null
                              ? Text(
                                  '${mainAddress['streetAddress']}, ${mainAddress['district']}, ${mainAddress['city']}, ${mainAddress['province']} ${mainAddress['postalCode']}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                                )
                              : const Text('Belum ada alamat pengiriman.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                  // Card 4: Keamanan Akun
                  _buildSectionTitle('Keamanan Akun'),
                  _buildCard(
                    darkCard,
                    child: Column(
                      children: [
                        _buildSecurityRow(
                          'Password',
                          'Terakhir diubah beberapa waktu lalu',
                          'Ubah Password',
                          _changePassword,
                        ),
                        const Divider(color: Colors.white10, height: 32),
                        _buildSecurityRow(
                          'Two-Factor Authentication',
                          _user?['isTwoFactorEnabled'] == true ? 'Lapisan keamanan 2FA aktif' : 'Tambahkan lapisan keamanan ekstra',
                          _user?['isTwoFactorEnabled'] == true ? 'Nonaktifkan' : 'Aktifkan',
                          _toggle2FA,
                        ),
                      ],
                    ),
                  ),

                  // Extra Options
                  if (isAdminOrSeller) ...[
                    _buildSectionTitle('Lainnya'),
                    _buildCard(
                      darkCard,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: gold.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.query_stats, color: gold, size: 20),
                            ),
                            title: const Text('Laporan Keuangan', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Lihat ringkasan transaksi & pendapatan', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialReportScreen())),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFF1ABC9C).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.account_balance, color: Color(0xFF1ABC9C), size: 20),
                            ),
                            title: const Text('Pengaturan Rekening & QRIS', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Atur info rekening bank & upload QRIS untuk pembeli', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                            onTap: _showPaymentSettingsDialog,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ApiService.logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                        }
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('LOG KELUAR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.1),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCard(Color bgColor, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityRow(String title, String subtitle, String btnLabel, VoidCallback onTap) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(btnLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
