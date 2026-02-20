import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/app_settings.dart';
import '../../services/database_service.dart';
import '../../services/user_session.dart';
import '../../models/user.dart';

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
    // Pre-fill with the real session user's data
    _nameController  = TextEditingController(
        text: UserSession.instance.displayName);
    _emailController = TextEditingController(
        text: UserSession.instance.email);
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

    final session = UserSession.instance;
    final newName  = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    // Check duplicate email only if it changed
    if (newEmail != session.email) {
      final exists = await DatabaseService.instance.emailExists(newEmail);
      if (exists) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email je već u upotrebi.'),
              backgroundColor: Colors.red,
            ),
          );
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
    UserSession.instance.setUser(updatedUser); // keep session in sync

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil uspešno ažuriran'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // pass 'true' so profile screen refreshes
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings.instance.darkMode;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final labelColor = isDark ? Colors.white70 : AppColors.textGrey;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: Text(
          'Uredi profil',
          style: TextStyle(
              color: isDark ? Colors.white : AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
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
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text(
                    'Sačuvaj',
                    style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
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

              // Visible labels
              _field(
                controller: _nameController,
                label: 'Ime i prezime',
                icon: Icons.person_outline,
                cardBg: cardBg,
                isDark: isDark,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Unesite ime' : null,
              ),
              const SizedBox(height: 16),
              _field(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                cardBg: cardBg,
                isDark: isDark,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Unesite email';
                  if (!v.contains('@')) return 'Unesite validan email';
                  return null;
                },
              ),

              const SizedBox(height: 32),
              _sectionLabel('Promenite lozinku', labelColor),
              const SizedBox(height: 4),
              Text(
                'Ostavite prazno ako ne želite da menjate lozinku.',
                style: TextStyle(
                    fontSize: 12, color: labelColor.withOpacity(0.8)),
              ),
              const SizedBox(height: 12),

              _field(
                controller: _passwordController,
                label: 'Nova lozinka',
                icon: Icons.lock_outline,
                obscure: !_showPassword,
                cardBg: cardBg,
                isDark: isDark,
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
                cardBg: cardBg,
                isDark: isDark,
                validator: (v) {
                  if (_passwordController.text.isNotEmpty &&
                      v != _passwordController.text) {
                    return 'Lozinke se ne podudaraju';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5),
    );
  }

  //  _field now accepts isDark + cardBg so labels are always visible
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
    final textColor  = isDark ? Colors.white : AppColors.textDark;
    final labelColor = isDark ? Colors.white60 : AppColors.textGrey;
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
        floatingLabelStyle: TextStyle(
            color: AppColors.primaryOrange,
            fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: labelColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: cardBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}