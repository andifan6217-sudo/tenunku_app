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
  static const gold = Color(0xFFA67C1E);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05), width: 0.8)),
        title: Text('USER REGISTRY', style: GoogleFonts.montserrat(color: gold, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 4)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: gold),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, color: gold),
            onPressed: () => _showUserDialog(null),
          ),
        ],
      ) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black.withOpacity(0.08), width: 0.8),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(color: Colors.black87, fontSize: 11),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        hintText: 'Cari pengguna...',
                        hintStyle: GoogleFonts.montserrat(color: Colors.black38, fontSize: 10),
                        prefixIcon: const Icon(Icons.search, color: gold, size: 16),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredUsers.isEmpty
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
                        color: Colors.white,
                        border: Border.all(color: isInactive ? Colors.black.withOpacity(0.04) : Colors.black.withOpacity(0.06)),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (isInactive ? Colors.grey : gold).withOpacity(0.1),
                          child: Text(user['name'][0].toUpperCase(), 
                            style: TextStyle(color: isInactive ? Colors.grey : gold, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(
                          user['name'].toUpperCase(), 
                          style: GoogleFonts.montserrat(
                            color: isInactive ? Colors.black38 : Colors.black87, 
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            decoration: isInactive ? TextDecoration.lineThrough : null
                          )
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'], style: const TextStyle(color: Colors.black54, fontSize: 10)),
                            Row(
                              children: [
                                Text('Role: ${user['role']}', style: TextStyle(color: gold, fontSize: 9, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                if (isInactive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
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
                ),
              ],
            ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Text('NO USERS FOUND', 
        style: GoogleFonts.montserrat(color: Colors.black26, letterSpacing: 4, fontSize: 12))
    );
  }

  Widget _buildPopupMenu(dynamic user, Color gold) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black45, size: 20),
      color: Colors.white,
      onSelected: (value) => _handleMenuAction(value, user),
      itemBuilder: (context) => [
        _menuItem('edit', Icons.edit_outlined, 'EDIT PROFILE', gold),
        _menuItem('reset', Icons.lock_reset_outlined, 'RESET PASSWORD', gold),
        _menuItem('toggle', user['status'] == 'INACTIVE' ? Icons.check_circle_outline : Icons.block_flipped, 
          user['status'] == 'INACTIVE' ? 'ACTIVATE' : 'DEACTIVATE', 
          user['status'] == 'INACTIVE' ? Colors.green : Colors.orange),
        _menuItem('delete', Icons.delete_outline, 'DELETE ACCOUNT', Colors.red),
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
          Text(label, style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 10, letterSpacing: 1)),
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
        backgroundColor: Colors.white,
        title: Text(isEdit ? 'UPDATE PROFILE' : 'ENROLL NEW USER', 
          style: GoogleFonts.montserrat(color: gold, fontSize: 16, letterSpacing: 2)),
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
                  initialValue: role,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'ASSIGN ROLE', labelStyle: TextStyle(color: Colors.black45, fontSize: 10)),
                  items: ['ADMIN', 'PENJUAL', 'USER'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.black38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
        backgroundColor: Colors.white,
        title: Text('RESET PASSWORD', style: GoogleFonts.montserrat(color: gold, fontSize: 16, letterSpacing: 2)),
        content: _dialogInput(passCtrl, 'NEW PASSWORD', isPass: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.black38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
        backgroundColor: Colors.white,
        title: Text(title.toUpperCase(), style: GoogleFonts.montserrat(color: gold, fontSize: 14)),
        content: Text(message, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('NO', style: TextStyle(color: Colors.black38))),
          TextButton(onPressed: () { Navigator.pop(ctx); onConfirm(); }, child: Text('YES', style: TextStyle(color: gold))),
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
      style: const TextStyle(color: Colors.black87, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black45, fontSize: 10),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA67C1E))),
      ),
    );
  }
}
