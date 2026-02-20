import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/app_settings.dart';
import '../../services/database_service.dart';
import '../../services/user_session.dart';
import '../../models/user.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  bool get _isDark => AppSettings.instance.darkMode;
  Color get _bgColor =>
      _isDark ? const Color(0xFF121212) : AppColors.backgroundLight;
  Color get _cardBg => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : AppColors.textDark;
  Color get _textSecondary => _isDark ? Colors.white60 : AppColors.textGrey;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await DatabaseService.instance.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  int get _adminCount => _users.where((u) => u.isAdmin).length;

  // ── CREATE ──────────────────────────────────────────────────────────────────

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isAdmin = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: _cardBg,
          title: Text('Dodaj korisnika', style: TextStyle(color: _textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameCtrl, 'Ime', _textPrimary, _textSecondary),
              const SizedBox(height: 12),
              _dialogField(emailCtrl, 'Email', _textPrimary, _textSecondary,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _dialogField(passCtrl, 'Lozinka', _textPrimary, _textSecondary,
                  obscure: true),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: isAdmin,
                    activeColor: AppColors.primaryOrange,
                    onChanged: (v) => setLocal(() => isAdmin = v ?? false),
                  ),
                  Text('Admin pristup', style: TextStyle(color: _textPrimary)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Otkaži')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameCtrl.text.isEmpty ||
                    emailCtrl.text.isEmpty ||
                    passCtrl.text.isEmpty) {
                  _showSnack('Popunite sva polja');
                  return;
                }
                // Check email uniqueness before closing the dialog
                final exists = await DatabaseService.instance
                    .emailExists(emailCtrl.text.trim());
                if (exists) {
                  _showSnack('Korisnik sa ovim emailom već postoji');
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await DatabaseService.instance.insertUser(User(
                    id: null,
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text,
                    isAdmin: isAdmin,
                  ));
                  _loadUsers();
                } catch (e) {
                  _showSnack('Greška pri dodavanju korisnika');
                }
              },
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );
  }

  // ── UPDATE ──────────────────────────────────────────────────────────────────

  void _showEditUserDialog(User user) {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final passCtrl = TextEditingController(text: user.password);
    bool isAdmin = user.isAdmin;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: _cardBg,
          title: Text('Uredi korisnika', style: TextStyle(color: _textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameCtrl, 'Ime', _textPrimary, _textSecondary),
              const SizedBox(height: 12),
              _dialogField(emailCtrl, 'Email', _textPrimary, _textSecondary,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _dialogField(passCtrl, 'Lozinka', _textPrimary, _textSecondary,
                  obscure: true),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: isAdmin,
                    activeColor: AppColors.primaryOrange,
                    // Prevent un-admining if this is the last admin
                    onChanged: (v) {
                      if (!(v ?? true) && user.isAdmin && _adminCount <= 1) {
                        _showSnack('Mora postojati bar jedan admin');
                        return;
                      }
                      setLocal(() => isAdmin = v ?? false);
                    },
                  ),
                  Text('Admin pristup', style: TextStyle(color: _textPrimary)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Otkaži')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newEmail = emailCtrl.text.trim();
                // Only check uniqueness if the email actually changed
                if (newEmail != user.email) {
                  final exists =
                      await DatabaseService.instance.emailExists(newEmail);
                  if (exists) {
                    _showSnack('Korisnik sa ovim emailom već postoji');
                    return;
                  }
                }
                Navigator.pop(ctx);
                await DatabaseService.instance.updateUser(User(
                  id: user.id,
                  name: nameCtrl.text.trim(),
                  email: newEmail,
                  password: passCtrl.text,
                  isAdmin: isAdmin,
                ));
                // If the edited user is the currently logged-in admin,
                // refresh the session so isAdmin reflects any change.
                if (user.id == UserSession.instance.userId) {
                  final refreshed =
                      await DatabaseService.instance.getUserByEmail(newEmail);
                  if (refreshed != null) {
                    UserSession.instance.setUser(refreshed);
                  }
                }
                _loadUsers();
              },
              child: const Text('Sačuvaj'),
            ),
          ],
        ),
      ),
    );
  }

  // ── DELETE ──────────────────────────────────────────────────────────────────

  void _confirmDelete(User user) {
    // Cannot delete yourself
    if (user.id == UserSession.instance.userId) {
      _showSnack('Ne možete obrisati sopstveni nalog');
      return;
    }
    // Cannot delete the last admin
    if (user.isAdmin && _adminCount <= 1) {
      _showSnack('Ne možete obrisati poslednjeg admina');
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text('Obriši korisnika', style: TextStyle(color: _textPrimary)),
        content: Text(
          'Da li ste sigurni da želite da obrišete ${user.name}?\n'
          'Sve njihove aktivnosti biće obrisane.',
          style: TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Otkaži')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseService.instance.deleteUser(user.id!);
              _loadUsers();
            },
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        title: Text('Admin panel',
            style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Admin count badge
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_adminCount} admin${_adminCount == 1 ? '' : 'a'}',
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: _textPrimary),
            onPressed: _loadUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryOrange,
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Text('Nema korisnika',
                      style: TextStyle(color: _textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (_, i) => _buildUserCard(_users[i]),
                ),
    );
  }

  Widget _buildUserCard(User user) {
    final isSelf = user.id == UserSession.instance.userId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: user.isAdmin
              ? Colors.red.withOpacity(0.15)
              : AppColors.primaryOrange.withOpacity(0.15),
          child: Icon(
            user.isAdmin ? Icons.admin_panel_settings : Icons.person,
            color: user.isAdmin ? Colors.red : AppColors.primaryOrange,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(user.name,
                  style: TextStyle(
                      color: _textPrimary, fontWeight: FontWeight.w600)),
            ),
            if (isSelf) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Vi',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w600)),
              ),
            ],
            if (user.isAdmin) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Admin',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
        subtitle: Text(user.email,
            style: TextStyle(fontSize: 12, color: _textSecondary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: _textSecondary),
              onPressed: () => _showEditUserDialog(user),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: isSelf ? _textSecondary.withOpacity(0.3) : Colors.red,
              ),
              onPressed: isSelf ? null : () => _confirmDelete(user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    Color textColor,
    Color labelColor, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: labelColor.withOpacity(0.4))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryOrange)),
      ),
    );
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
