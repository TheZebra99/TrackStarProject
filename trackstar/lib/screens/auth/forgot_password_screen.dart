import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Implementirati reset lozinke kasnije...
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    }
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
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset,
                size: 40,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          const Text(
            'Zaboravili ste lozinku?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Unesite email adresu povezanu sa vašim nalogom i poslaćemo vam link za resetovanje lozinke.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'vasa.email@primer.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Unesite email';
              }
              if (!value.contains('@')) {
                return 'Unesite validan email';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 32),
          
          // Submit button
          CustomButton(
            text: 'Pošaljite link',
            onPressed: _handleResetPassword,
            isLoading: _isLoading,
          ),
          
          const SizedBox(height: 24),
          
          // Back to login
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Vratite se na prijavu',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const SizedBox(height: 40),
        
        // Success icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.successGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 50,
            color: AppColors.successGreen,
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Success message
        const Text(
          'Proverite email!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Poslali smo link za resetovanje lozinke na:\n${_emailController.text}',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textGrey,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.accentBlue.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ako ne vidite email, proverite spam folder.',
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Resend button
        OutlinedButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: AppColors.primaryOrange),
          ),
          child: const Text(
            'Pošaljite ponovo',
            style: TextStyle(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Back to login
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Vratite se na prijavu',
            style: TextStyle(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}