import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/colors.dart';
import '../../utils/app_settings.dart';
import '../../services/database_service.dart';
import '../../services/user_session.dart';
import '../../models/user.dart';
import '../auth/login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  bool _isSaving     = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _nameController  = TextEditingController(text: UserSession.instance.displayName);
    _emailController = TextEditingController(text: UserSession.instance.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final session  = UserSession.instance;
    final newName  = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    if (newEmail != session.email) {
      final exists = await DatabaseService.instance.emailExists(newEmail);
      if (exists) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Email je već u upotrebi.'),
                backgroundColor: Colors.red));
        }
        return;
      }
    }

    final newPassword = _passwordController.text.isNotEmpty
        ? _passwordController.text
        : session.currentUser!.password;

    final updatedUser = User(
      id: session.userId,
      name: newName,
      email: newEmail,
      password: newPassword,
    );

    await DatabaseService.instance.updateUser(updatedUser);
    UserSession.instance.setUser(updatedUser);

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profil uspešno ažuriran'),
            backgroundColor: Colors.green));
      Navigator.pop(context, true);
    }
  }

  // Delete account
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Obriši nalog'),
        content: const Text(
            'Ova akcija je trajna. Vaš nalog i sve aktivnosti biće obrisani. Jeste li sigurni?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Otkaži')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Obriši',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final userId = UserSession.instance.userId;

    // Delete persisted profile image for this user
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_image_path_$userId');

    // Delete user + activities from DB
    await DatabaseService.instance.deleteUser(userId);

    UserSession.instance.clearUser();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = AppSettings.instance.darkMode;
    final cardBg     = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final labelColor = isDark ? Colors.white70 : AppColors.textGrey;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: Text('Uredi profil',
            style: TextStyle(
                color: isDark ? Colors.white : AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Sačuvaj',
                    style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Lični podaci', labelColor),
              const SizedBox(height: 12),

              _field(
                controller: _nameController,
                label: 'Ime i prezime',
                icon: Icons.person_outline,
                cardBg: cardBg, isDark: isDark,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Unesite ime' : null,
              ),
              const SizedBox(height: 16),
              _field(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                cardBg: cardBg, isDark: isDark,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Unesite email';
                  if (!v.contains('@')) return 'Unesite validan email';
                  return null;
                },
              ),

              const SizedBox(height: 32),
              _sectionLabel('Promenite lozinku', labelColor),
              const SizedBox(height: 4),
              Text('Ostavite prazno ako ne želite da menjate lozinku.',
                  style: TextStyle(
                      fontSize: 12, color: labelColor.withOpacity(0.8))),
              const SizedBox(height: 12),

              _field(
                controller: _passwordController,
                label: 'Nova lozinka',
                icon: Icons.lock_outline,
                obscure: !_showPassword,
                cardBg: cardBg, isDark: isDark,
                suffixIcon: IconButton(
                  icon: Icon(_showPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 6) {
                    return 'Lozinka mora imati najmanje 6 karaktera';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _field(
                controller: _confirmController,
                label: 'Potvrdite lozinku',
                icon: Icons.lock_outline,
                obscure: !_showPassword,
                cardBg: cardBg, isDark: isDark,
                validator: (v) {
                  if (_passwordController.text.isNotEmpty &&
                      v != _passwordController.text) {
                    return 'Lozinke se ne podudaraju';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // Delete account
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text('Obriši nalog',
                      style: TextStyle(color: Colors.red, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _deleteAccount,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Ova akcija je trajna i ne može se poništiti.',
                    style: TextStyle(
                        fontSize: 12, color: labelColor.withOpacity(0.7))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Text(text,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5));
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color cardBg,
    required bool isDark,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    final textColor   = isDark ? Colors.white : AppColors.textDark;
    final labelColor  = isDark ? Colors.white60 : AppColors.textGrey;
    final borderColor = isDark
        ? Colors.white24
        : AppColors.textGrey.withOpacity(0.4);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor, fontSize: 14),
        floatingLabelStyle: const TextStyle(
            color: AppColors.primaryOrange, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: labelColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: cardBg,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primaryOrange, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Colors.red, width: 2)),
      ),
    );
  }
}