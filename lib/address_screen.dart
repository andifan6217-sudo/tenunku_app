import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  List<dynamic> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getAddresses();
      setState(() {
        _addresses = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFA67C1E);
    const lightBg = Color(0xFFF9FAFC);

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05), width: 0.8)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: gold), onPressed: () => Navigator.pop(context)),
        title: Text('ALAMAT SAYA', style: GoogleFonts.montserrat(color: gold, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 4)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : RefreshIndicator(
              onRefresh: _fetchAddresses,
              color: gold,
              child: _addresses.isEmpty
                  ? Center(child: Text('BELUM ADA ALAMAT', style: GoogleFonts.montserrat(color: Colors.black38, fontSize: 10, letterSpacing: 2)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _addresses.length,
                      itemBuilder: (context, index) {
                        final addr = _addresses[index];
                        return _buildAddressCard(addr, gold);
                      },
                    ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressEditScreen()));
            if (result == true) _fetchAddresses();
          },
          icon: const Icon(Icons.add, size: 18),
          label: Text('TAMBAH ALAMAT BARU', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFFEE4D2D), // Shopee-like orange
            side: const BorderSide(color: Color(0xFFEE4D2D), width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(dynamic addr, Color gold) {
    final bool isMain = addr['isMain'] ?? false;
    final String label = addr['label'] ?? 'RUMAH';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddressEditScreen(address: addr)));
        if (result == true) _fetchAddresses();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: isMain ? const Color(0xFFEE4D2D) : Colors.black.withOpacity(0.06)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(addr['name'], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                Text('|', style: TextStyle(color: Colors.black.withOpacity(0.12))),
                const SizedBox(width: 8),
                Text(addr['phone'], style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${addr['streetAddress']}, ${addr['district']}, ${addr['city']}, ${addr['province']}, ${addr['postalCode']}',
              style: const TextStyle(color: Colors.black87, fontSize: 12, height: 1.5),
            ),
            if (addr['detailAddress'] != null && addr['detailAddress'].isNotEmpty)
              Text('(${addr['detailAddress']})', style: const TextStyle(color: Colors.black45, fontSize: 11)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (isMain)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEE4D2D)), borderRadius: BorderRadius.circular(2)),
                    child: const Text('Utama', style: TextStyle(color: Color(0xFFEE4D2D), fontSize: 10)),
                  ),
                if (isMain) const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(2)),
                  child: Text(label == 'RUMAH' ? 'Rumah' : 'Kantor', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn().slideX(begin: 0.1),
    );
  }
}

class AddressEditScreen extends StatefulWidget {
  final dynamic address;
  const AddressEditScreen({super.key, this.address});

  @override
  State<AddressEditScreen> createState() => _AddressEditScreenState();
}

class _AddressEditScreenState extends State<AddressEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  
  LatLng? _selectedLocation;
  bool _isMain = false;
  String _label = 'RUMAH';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _nameCtrl.text = widget.address['name'];
      _phoneCtrl.text = widget.address['phone'];
      _provinceCtrl.text = widget.address['province'];
      _cityCtrl.text = widget.address['city'];
      _districtCtrl.text = widget.address['district'];
      _postalCtrl.text = widget.address['postalCode'];
      _streetCtrl.text = widget.address['streetAddress'];
      _detailCtrl.text = widget.address['detailAddress'] ?? '';
      _isMain = widget.address['isMain'] ?? false;
      _label = widget.address['label'] ?? 'RUMAH';
      if (widget.address['latitude'] != null && widget.address['longitude'] != null) {
        _selectedLocation = LatLng(widget.address['latitude'], widget.address['longitude']);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition();
        setState(() {
          _selectedLocation = LatLng(pos.latitude, pos.longitude);
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final data = {
      'name': _nameCtrl.text,
      'phone': _phoneCtrl.text,
      'province': _provinceCtrl.text,
      'city': _cityCtrl.text,
      'district': _districtCtrl.text,
      'postalCode': _postalCtrl.text,
      'streetAddress': _streetCtrl.text,
      'detailAddress': _detailCtrl.text,
      'latitude': _selectedLocation?.latitude,
      'longitude': _selectedLocation?.longitude,
      'isMain': _isMain,
      'label': _label,
    };

    try {
      if (widget.address == null) {
        await ApiService.addAddress(data);
      } else {
        await ApiService.updateAddress(widget.address['id'], data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Hapus Alamat?', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Tindakan ini tidak dapat dibatalkan.', style: TextStyle(color: Colors.black54, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL', style: TextStyle(color: Colors.black38))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('HAPUS', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ApiService.deleteAddress(widget.address['id']);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFA67C1E);
    const lightBg = Color(0xFFF9FAFC);
    const orangeShopee = Color(0xFFEE4D2D);

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05), width: 0.8)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: gold), onPressed: () => Navigator.pop(context)),
        title: Text(widget.address == null ? 'TAMBAH ALAMAT' : 'UBAH ALAMAT', style: GoogleFonts.montserrat(color: gold, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 4)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ALAMAT', style: GoogleFonts.montserrat(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 4)),
                    const SizedBox(height: 24),
                    _buildTextField(_nameCtrl, 'Nama Lengkap', 'Masukkan nama penerima'),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneCtrl, 'Nomor Telepon', 'Masukkan nomor telepon', keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildTextField(_provinceCtrl, 'Provinsi', 'Riau'),
                    const SizedBox(height: 16),
                    _buildTextField(_cityCtrl, 'Kota/Kabupaten', 'Bengkalis'),
                    const SizedBox(height: 16),
                    _buildTextField(_districtCtrl, 'Kecamatan', 'Bengkalis'),
                    const SizedBox(height: 16),
                    _buildTextField(_postalCtrl, 'Kode Pos', '28711', keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField(_streetCtrl, 'Nama Jalan, Gedung, No. Rumah', 'Contoh: Jl. Utama No. 10', maxLines: 2),
                    const SizedBox(height: 16),
                    _buildTextField(_detailCtrl, 'Detail Lainnya (Cth: Blok / Unit No., Patokan)', 'Contoh: Kedai kayu 2 tingkat', maxLines: 2, isRequired: false),
                    
                    const SizedBox(height: 32),
                    Text('LOKASI PETA', style: GoogleFonts.montserrat(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 4)),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(border: Border.all(color: Colors.black.withOpacity(0.08)), borderRadius: BorderRadius.circular(8)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: _selectedLocation ?? const LatLng(-6.5888, 110.6684),
                            initialZoom: 15,
                            onTap: (tapPos, latLng) => setState(() => _selectedLocation = latLng),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.tenungeza.app',
                            ),
                            if (_selectedLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _selectedLocation!,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on, color: orangeShopee, size: 40),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location, size: 14, color: gold),
                      label: Text('GUNAKAN LOKASI SAAT INI', style: GoogleFonts.montserrat(color: gold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),

                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Atur sebagai Alamat Utama', style: TextStyle(color: Colors.black87, fontSize: 14)),
                        Switch(
                          value: _isMain,
                          onChanged: (v) => setState(() => _isMain = v),
                          activeThumbColor: orangeShopee,
                          inactiveTrackColor: Colors.black.withOpacity(0.06),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Tandai Sebagai:', style: TextStyle(color: Colors.black87, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _labelChip('RUMAH', 'Rumah'),
                        const SizedBox(width: 12),
                        _labelChip('KANTOR', 'Kantor'),
                      ],
                    ),

                    const SizedBox(height: 48),
                    if (widget.address != null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _delete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('HAPUS ALAMAT', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeShopee,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('SIMPAN', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint, {TextInputType keyboardType = TextInputType.text, int maxLines = 1, bool isRequired = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA67C1E))),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          validator: isRequired ? (v) => v == null || v.isEmpty ? 'Wajib diisi' : null : null,
        ),
      ],
    );
  }

  Widget _labelChip(String value, String label) {
    final bool selected = _label == value;
    return GestureDetector(
      onTap: () => setState(() => _label = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEE4D2D).withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: selected ? const Color(0xFFEE4D2D) : Colors.black.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(color: selected ? const Color(0xFFEE4D2D) : Colors.black54, fontSize: 13, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
