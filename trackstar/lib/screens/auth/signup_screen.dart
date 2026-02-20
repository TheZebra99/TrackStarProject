import 'package:flutter/material.dart';
import 'package:trackstar/screens/main_navigation.dart';
import 'package:trackstar/services/database_service.dart';
import 'package:trackstar/services/user_session.dart';
import 'package:trackstar/models/user.dart';
import '../../utils/colors.dart';
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
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  bool _isPasswordVisible        = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading   = false;
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

    // Check for duplicate email before inserting
    final exists = await _db.emailExists(email);
    if (exists) {
      setState(() => _isLoading = false);
      _showError('Nalog sa ovom email adresom već postoji.');
      return;
    }

    try {
      final newUser = User(
        id: null,
        name: _nameController.text.trim(),
        email: email,
        password: _passwordController.text,
      );

      // insertUser now returns the new row id
      final insertedId = await _db.insertUser(newUser);

      // Store the registered user in the session, displays the profile name correctly
      UserSession.instance.setUser(User(
        id: insertedId,
        name: newUser.name,
        email: newUser.email,
        password: newUser.password,
      ));

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
        email: account.email,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Google prijava neuspešna: $e');
    }
  }

  Future<void> _handleFacebookSignUp() async {
    try {
      setState(() => _isLoading = true);
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      if (result.status == LoginStatus.success) {
        final data = await FacebookAuth.instance.getUserData();
        await _upsertSocialUser(
          name: data['name'] as String? ?? 'Korisnik',
          email: data['email'] as String? ?? '',
        );
      } else {
        setState(() => _isLoading = false);
        if (result.status != LoginStatus.cancelled) {
          _showError('Facebook prijava neuspešna: ${result.message}');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Facebook prijava neuspešna: $e');
    }
  }

  /// Creates a new user if the email doesn't exist yet, then stores in session
  Future<void> _upsertSocialUser({
    required String name,
    required String email,
  }) async {
    if (email.isEmpty) {
      setState(() => _isLoading = false);
      _showError('Nije moguće dobiti email adresu. Pokušajte ponovo.');
      return;
    }

    User? existing = await _db.getUserByEmail(email);
    final int userId;

    if (existing == null) {
      final u = User(id: null, name: name, email: email, password: '');
      userId = await _db.insertUser(u);
      existing = User(id: userId, name: name, email: email, password: '');
    } else {
      userId = existing.id!;
    }

    UserSession.instance.setUser(existing!);
    if (mounted) _goToMain();
  }

  void _goToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                const Text('Kreirajte nalog',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                const SizedBox(height: 8),
                const Text('Popunite sledeće podatke:',
                    style: TextStyle(fontSize: 16, color: AppColors.textGrey)),
                const SizedBox(height: 32),

                // Name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Puno ime',
                    hintText: 'Ime i Prezime',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Unesite vaše ime';
                    if (v.length < 2)
                      return 'Ime mora imati najmanje 2 karaktera';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'vasa.email@primer.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Unesite email';
                    if (!v.contains('@')) return 'Unesite validan email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Lozinka',
                    hintText: 'Unesite lozinku',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Unesite lozinku';
                    if (v.length < 6)
                      return 'Lozinka mora imati najmanje 6 karaktera';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm password
                TextFormField(
                  controller: _confirmController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Potvrdite lozinku',
                    hintText: 'Unesite lozinku ponovo',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() =>
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Potvrdite lozinku';
                    if (v != _passwordController.text)
                      return 'Lozinke se ne poklapaju';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Terms checkbox
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
                          text: const TextSpan(
                            style: TextStyle(
                                color: AppColors.textGrey, fontSize: 14),
                            children: [
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
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: AppColors.textGrey.withOpacity(0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('ili',
                          style: TextStyle(
                              color: AppColors.textGrey, fontSize: 14)),
                    ),
                    Expanded(
                        child: Divider(
                            color: AppColors.textGrey.withOpacity(0.3))),
                  ],
                ),
                const SizedBox(height: 24),

                // new, functional buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        iconWidget: const _GoogleIcon(),
                        label: 'Google',
                        onPressed: _isLoading ? null : _handleGoogleSignUp,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSocialButton(
                        iconWidget: const Icon(Icons.facebook,
                            color: Color(0xFF1877F2)),
                        label: 'Facebook',
                        onPressed: _isLoading ? null : _handleFacebookSignUp,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Već imate nalog? ',
                        style: TextStyle(color: AppColors.textGrey)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Prijavite se',
                          style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget iconWidget,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: AppColors.textGrey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textDark, fontWeight: FontWeight.w600)),
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
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4285F4)
      )
  );
}