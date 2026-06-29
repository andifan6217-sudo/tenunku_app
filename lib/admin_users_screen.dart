import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  final bool showAppBar;
  const AdminUsersScreen({super.key, this.showAppBar = true});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterUsers(_searchController.text);
  }

  void _fetchUsers() async {
    try {
      final users = await ApiService.getUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _users
          .where((user) =>
              user['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
              user['email'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const darkSuite = Color(0xFF0F0B1E);

    return Scaffold(
      backgroundColor: darkSuite,
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: darkSuite,
        elevation: 0,
        title: _buildSearchField(gold),
        centerTitle: true,
        iconTheme: const IconThemeData(color: gold),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => _showUserDialog(null),
          ),
        ],
      ) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : _filteredUsers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    final bool isInactive = user['status'] == 'INACTIVE';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isInactive ? Colors.white.withOpacity(0.01) : Colors.white.withOpacity(0.02),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (isInactive ? Colors.grey : gold).withOpacity(0.1),
                          child: Text(user['name'][0].toUpperCase(), 
                            style: TextStyle(color: isInactive ? Colors.grey : gold)),
                        ),
                        title: Text(
                          user['name'].toUpperCase(), 
                          style: GoogleFonts.montserrat(
                            color: isInactive ? Colors.white24 : Colors.white, 
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            decoration: isInactive ? TextDecoration.lineThrough : null
                          )
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                            Row(
                              children: [
                                Text('Role: ${user['role']}', style: TextStyle(color: gold.withOpacity(0.7), fontSize: 9)),
                                const SizedBox(width: 8),
                                if (isInactive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1)),
                                    child: const Text('INACTIVE', style: TextStyle(color: Colors.red, fontSize: 7, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: _buildPopupMenu(user, gold),
                      ),
                    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
                  },
                ),
    );
  }

  Widget _buildSearchField(Color gold) {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'SEARCH REGISTRY...',
        hintStyle: GoogleFonts.montserrat(color: Colors.white24, fontSize: 11, letterSpacing: 2),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text('NO USERS FOUND', 
        style: GoogleFonts.montserrat(color: Colors.white10, letterSpacing: 4, fontSize: 12))
    );
  }

  Widget _buildPopupMenu(dynamic user, Color gold) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white24, size: 20),
      color: const Color(0xFF1A1A2E),
      onSelected: (value) => _handleMenuAction(value, user),
      itemBuilder: (context) => [
        _menuItem('edit', Icons.edit_outlined, 'EDIT PROFILE', gold),
        _menuItem('reset', Icons.lock_reset_outlined, 'RESET PASSWORD', gold),
        _menuItem('toggle', user['status'] == 'INACTIVE' ? Icons.check_circle_outline : Icons.block_flipped, 
          user['status'] == 'INACTIVE' ? 'ACTIVATE' : 'DEACTIVATE', 
          user['status'] == 'INACTIVE' ? Colors.greenAccent : Colors.orangeAccent),
        _menuItem('delete', Icons.delete_outline, 'DELETE ACCOUNT', Colors.redAccent),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 10, letterSpacing: 1)),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, dynamic user) {
    switch (action) {
      case 'edit':
        _showUserDialog(user);
        break;
      case 'reset':
        _showResetDialog(user);
        break;
      case 'toggle':
        _confirmAction('Toggle Status', 'Change user status?', () => _toggleStatus(user['id']));
        break;
      case 'delete':
        _confirmAction('Delete Account', 'Permanently delete this user?', () => _deleteUser(user['id']));
        break;
    }
  }

  void _showUserDialog(dynamic user) {
    final bool isEdit = user != null;
    final nameCtrl = TextEditingController(text: isEdit ? user['name'] : '');
    final emailCtrl = TextEditingController(text: isEdit ? user['email'] : '');
    final phoneCtrl = TextEditingController(text: isEdit ? user['phone'] : '');
    final passCtrl = TextEditingController();
    String role = isEdit ? user['role'] : 'USER';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0B1E),
        title: Text(isEdit ? 'UPDATE PROFILE' : 'ENROLL NEW USER', 
          style: GoogleFonts.montserrat(color: const Color(0xFFD4AF37), fontSize: 16, letterSpacing: 2)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogInput(nameCtrl, 'FULL NAME'),
                _dialogInput(emailCtrl, 'EMAIL ADDRESS'),
                _dialogInput(phoneCtrl, 'PHONE NUMBER'),
                if (!isEdit) _dialogInput(passCtrl, 'INITIAL PASSWORD', isPass: true),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: role,
                  dropdownColor: const Color(0xFF1A1A2E),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'ASSIGN ROLE', labelStyle: TextStyle(color: Colors.white24, fontSize: 10)),
                  items: ['ADMIN', 'PENJUAL', 'USER'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () async {
              try {
                if (isEdit) {
                  await ApiService.updateUser(user['id'], nameCtrl.text, emailCtrl.text, phoneCtrl.text, role);
                } else {
                  await ApiService.addUser(nameCtrl.text, emailCtrl.text, passCtrl.text, phoneCtrl.text, role);
                }
                if (mounted) {
                  Navigator.pop(ctx);
                  _fetchUsers();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Profil Diperbarui' : 'User Terdaftar')));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(isEdit ? 'SAVE CHANGES' : 'CREATE ACCOUNT'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(dynamic user) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0B1E),
        title: Text('RESET PASSWORD', style: GoogleFonts.montserrat(color: const Color(0xFFD4AF37), fontSize: 16, letterSpacing: 2)),
        content: _dialogInput(passCtrl, 'NEW PASSWORD', isPass: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () async {
              await ApiService.resetPassword(user['id'], passCtrl.text);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password Telah Direset')));
              }
            },
            child: const Text('UPDATE PASSWORD'),
          ),
        ],
      ),
    );
  }

  void _confirmAction(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0B1E),
        title: Text(title.toUpperCase(), style: GoogleFonts.montserrat(color: const Color(0xFFD4AF37), fontSize: 14)),
        content: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('NO', style: TextStyle(color: Colors.white24))),
          TextButton(onPressed: () { Navigator.pop(ctx); onConfirm(); }, child: const Text('YES', style: TextStyle(color: Color(0xFFD4AF37)))),
        ],
      ),
    );
  }

  void _toggleStatus(int id) async {
    try {
      await ApiService.toggleUserStatus(id);
      _fetchUsers();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  void _deleteUser(int id) async {
    try {
      await ApiService.deleteUser(id);
      _fetchUsers();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Widget _dialogInput(TextEditingController ctrl, String label, {bool isPass = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white24, fontSize: 10),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
      ),
    );
  }
}
