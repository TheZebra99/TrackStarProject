import 'package:flutter/material.dart';
import 'package:trackstar/screens/main_navigation.dart';
import 'package:trackstar/services/database_service.dart';
import 'package:trackstar/services/user_session.dart';
import 'package:trackstar/models/user.dart';
import '../../utils/colors.dart';
import '../../utils/app_settings.dart';
import '../../widgets/custom_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _db = DatabaseService.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (!_agreeToTerms) {
      _showError('Morate prihvatiti uslove korišćenja');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    if (await _db.emailExists(email)) {
      setState(() => _isLoading = false);
      _showError('Nalog sa ovom email adresom već postoji.');
      return;
    }
    try {
      final newUser = User(
          id: null,
          name: _nameController.text.trim(),
          email: email,
          password: _passwordController.text);
      final id = await _db.insertUser(newUser);
      UserSession.instance.setUser(User(
          id: id,
          name: newUser.name,
          email: email,
          password: newUser.password));
      setState(() => _isLoading = false);
      if (mounted) _goToMain();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Registracija neuspešna: $e');
    }
  }

  Future<void> _handleGoogleSignUp() async {
    try {
      setState(() => _isLoading = true);
      final account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() => _isLoading = false);
        return;
      }
      await _upsertSocialUser(
          name: account.displayName ?? account.email.split('@').first,
          email: account.email);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Google prijava neuspešna: $e');
    }
  }

  Future<void> _handleFacebookSignUp() async {
    try {
      setState(() => _isLoading = true);
      final result = await FacebookAuth.instance
          .login(permissions: ['email', 'public_profile']);
      if (result.status == LoginStatus.success) {
        final data = await FacebookAuth.instance.getUserData();
        await _upsertSocialUser(
            name: data['name'] as String? ?? 'Korisnik',
            email: data['email'] as String? ?? '');
      } else {
        setState(() => _isLoading = false);
        if (result.status != LoginStatus.cancelled)
          _showError('Facebook prijava neuspešna: ${result.message}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Facebook prijava neuspešna: $e');
    }
  }

  Future<void> _upsertSocialUser(
      {required String name, required String email}) async {
    if (email.isEmpty) {
      setState(() => _isLoading = false);
      _showError('Nije moguće dobiti email adresu. Pokušajte ponovo.');
      return;
    }
    User? existing = await _db.getUserByEmail(email);
    if (existing == null) {
      final id = await _db
          .insertUser(User(id: null, name: name, email: email, password: ''));
      existing = User(id: id, name: name, email: email, password: '');
    }
    UserSession.instance.setUser(existing!);
    if (mounted) _goToMain();
  }

  void _goToMain() => Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()));

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings.instance.darkMode;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : AppColors.backgroundLight;
    final textPrimary = isDark ? Colors.white : AppColors.textDark;
    final textSecondary = isDark ? Colors.white60 : AppColors.textGrey;
    final borderColor =
        isDark ? Colors.white24 : AppColors.textGrey.withOpacity(0.3);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kreirajte nalog',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textPrimary)),
                const SizedBox(height: 8),
                Text('Popunite sledeće podatke:',
                    style: TextStyle(fontSize: 16, color: textSecondary)),
                const SizedBox(height: 32),

                _f(
                    controller: _nameController,
                    label: 'Puno ime',
                    hint: 'Ime i Prezime',
                    icon: Icons.person_outline,
                    cardBg: cardBg,
                    isDark: isDark,
                    textCap: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Unesite vaše ime';
                      if (v.length < 2)
                        return 'Ime mora imati najmanje 2 karaktera';
                      return null;
                    }),
                const SizedBox(height: 16),
                _f(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'vasa.email@primer.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    cardBg: cardBg,
                    isDark: isDark,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Unesite email';
                      if (!v.contains('@')) return 'Unesite validan email';
                      return null;
                    }),
                const SizedBox(height: 16),
                _f(
                    controller: _passwordController,
                    label: 'Lozinka',
                    hint: 'Unesite lozinku',
                    icon: Icons.lock_outline,
                    obscure: !_isPasswordVisible,
                    cardBg: cardBg,
                    isDark: isDark,
                    suffixIcon: IconButton(
                      icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: textSecondary),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Unesite lozinku';
                      if (v.length < 6)
                        return 'Lozinka mora imati najmanje 6 karaktera';
                      return null;
                    }),
                const SizedBox(height: 16),
                _f(
                    controller: _confirmController,
                    label: 'Potvrdite lozinku',
                    hint: 'Unesite lozinku ponovo',
                    icon: Icons.lock_outline,
                    obscure: !_isConfirmPasswordVisible,
                    cardBg: cardBg,
                    isDark: isDark,
                    suffixIcon: IconButton(
                      icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: textSecondary),
                      onPressed: () => setState(() =>
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Potvrdite lozinku';
                      if (v != _passwordController.text)
                        return 'Lozinke se ne poklapaju';
                      return null;
                    }),
                const SizedBox(height: 16),

                // Terms
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (v) =>
                          setState(() => _agreeToTerms = v ?? false),
                      activeColor: AppColors.primaryOrange,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _agreeToTerms = !_agreeToTerms),
                        child: RichText(
                          text: TextSpan(
                            style:
                                TextStyle(color: textSecondary, fontSize: 14),
                            children: const [
                              TextSpan(text: 'Slažem se sa '),
                              TextSpan(
                                  text: 'Uslovima korišćenja',
                                  style: TextStyle(
                                      color: AppColors.primaryOrange,
                                      fontWeight: FontWeight.w600)),
                              TextSpan(text: ' i '),
                              TextSpan(
                                  text: 'Politikom privatnosti',
                                  style: TextStyle(
                                      color: AppColors.primaryOrange,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                CustomButton(
                    text: 'Registrujte se',
                    onPressed: _handleSignup,
                    isLoading: _isLoading),
                const SizedBox(height: 24),

                Row(children: [
                  Expanded(child: Divider(color: borderColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('ili',
                        style: TextStyle(color: textSecondary, fontSize: 14)),
                  ),
                  Expanded(child: Divider(color: borderColor)),
                ]),
                const SizedBox(height: 24),

                Row(children: [
                  Expanded(
                    child: _socialBtn(
                      iconWidget: const _GoogleIcon(),
                      label: 'Google',
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      onPressed: _isLoading ? null : _handleGoogleSignUp,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _socialBtn(
                      iconWidget:
                          const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                      label: 'Facebook',
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      onPressed: _isLoading ? null : _handleFacebookSignUp,
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Već imate nalog? ',
                      style: TextStyle(color: textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Prijavite se',
                        style: TextStyle(
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _f({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color cardBg,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCap = TextCapitalization.none,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final labelColor = isDark ? Colors.white60 : AppColors.textGrey;
    final border =
        isDark ? Colors.white24 : AppColors.textGrey.withOpacity(0.3);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCap,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: labelColor),
        floatingLabelStyle: const TextStyle(color: AppColors.primaryOrange),
        hintStyle: TextStyle(color: labelColor.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: labelColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: cardBg,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primaryOrange, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2)),
      ),
    );
  }

  Widget _socialBtn({
    required Widget iconWidget,
    required String label,
    required Color borderColor,
    required Color textPrimary,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(width: 8),
          Text(label,
              style:
                  TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) => const Text('G',
      style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4285F4)));
}
