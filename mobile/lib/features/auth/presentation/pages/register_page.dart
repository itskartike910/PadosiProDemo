import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/routing/app_router.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/shake_widget.dart';
import '../../../../shared/widgets/swipe_confirm_button.dart';

import '../../../../shared/widgets/server_config_dialog.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey              = GlobalKey<FormState>();
  final _emailCtrl            = TextEditingController();
  final _passwordCtrl         = TextEditingController();
  final _confirmPasswordCtrl  = TextEditingController();
  final _phoneCtrl            = TextEditingController();

  final _emailShakeKey        = GlobalKey<ShakeWidgetState>();
  final _passwordShakeKey     = GlobalKey<ShakeWidgetState>();
  final _confirmPassShakeKey  = GlobalKey<ShakeWidgetState>();

  bool _isPasswordVisible     = false;
  bool _isConfirmPassVisible  = false;
  bool _isFormValid           = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final email = _emailCtrl.text.trim();
    final pw = _passwordCtrl.text;
    final cpw = _confirmPasswordCtrl.text;
    final emailRegex = RegExp(r'^[^\@\s]+\@[^\@\s]+\.[^\@\s]+$');

    setState(() {
      _isFormValid = emailRegex.hasMatch(email) &&
          pw.length >= 8 &&
          pw == cpw;
    });
  }

  void _handleDisabledTap() {
    _emailShakeKey.currentState?.shake();
    _passwordShakeKey.currentState?.shake();
    _confirmPassShakeKey.currentState?.shake();
    _formKey.currentState?.validate();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      _emailShakeKey.currentState?.shake();
      _passwordShakeKey.currentState?.shake();
      _confirmPassShakeKey.currentState?.shake();
      return;
    }

    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;
    final phone = _phoneCtrl.text.trim().isNotEmpty
        ? '+91${_phoneCtrl.text.trim()}'
        : null;

    await ref.read(authProvider.notifier).register(
          email: email,
          password: password,
          confirmPassword: confirmPassword,
          phoneNumber: phone,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next is AuthUnauthenticated && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    const bgGradient = LinearGradient(
      colors: [Color(0xFFF0F9F7), Color(0xFFF5F0E8)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go(AppRoutes.login, extra: {'from': 'register'});
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Container(
          decoration: const BoxDecoration(gradient: bgGradient),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppLogo(),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FAF7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFC8E2D9)),
                              ),
                              child: const Icon(Icons.dns_outlined, color: AppColors.primary, size: 18),
                            ),
                            tooltip: 'Backend Server Settings',
                            onPressed: () => ServerConfigDialog.show(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildForm(isLoading),
                      const SizedBox(height: 14),
                      _buildToggleLogin(),
                      const SizedBox(height: 10),
                      _buildTerms(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF1E5E52), Color(0xFF2D7A6E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Create Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Sign up to get a dedicated Lifestyle Manager. We'll send an OTP to verify your email.",
          style: TextStyle(
            color: Color(0xFF4A6B62),
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Email address'),
          const SizedBox(height: AppSizes.xs),
          ShakeWidget(
            key: _emailShakeKey,
            child: TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => _onFieldChanged(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                final regex = RegExp(r'^[^\@\s]+\@[^\@\s]+\.[^\@\s]+$');
                if (!regex.hasMatch(v.trim())) return 'Enter a valid email';
                return null;
              },
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: _inputDecoration(
                hintText: 'you@example.com',
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: Color(0xFF4A6B62)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _fieldLabel('Password (at least 8 characters)'),
          const SizedBox(height: AppSizes.xs),
          ShakeWidget(
            key: _passwordShakeKey,
            child: TextFormField(
              controller: _passwordCtrl,
              obscureText: !_isPasswordVisible,
              onChanged: (_) => _onFieldChanged(),
              validator: (v) {
                if (v == null || v.length < 8) return 'Password must be at least 8 characters';
                return null;
              },
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: _inputDecoration(
                hintText: 'Create a password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF4A6B62)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: const Color(0xFF4A6B62),
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _fieldLabel('Confirm Password'),
          const SizedBox(height: AppSizes.xs),
          ShakeWidget(
            key: _confirmPassShakeKey,
            child: TextFormField(
              controller: _confirmPasswordCtrl,
              obscureText: !_isConfirmPassVisible,
              onChanged: (_) => _onFieldChanged(),
              validator: (v) {
                if (v != _passwordCtrl.text) return 'Passwords do not match';
                return null;
              },
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: _inputDecoration(
                hintText: 'Re-enter your password',
                prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20, color: Color(0xFF4A6B62)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPassVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: const Color(0xFF4A6B62),
                  ),
                  onPressed: () => setState(() => _isConfirmPassVisible = !_isConfirmPassVisible),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _fieldLabel('Mobile number (optional)'),
          const SizedBox(height: AppSizes.xs),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: _inputDecoration(
              hintText: '98765 43210',
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF4A6B62)),
                    const SizedBox(width: 8),
                    const Text(
                      '+91',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(width: 1, height: 20, color: const Color(0xFFDDD8CC)),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SwipeConfirmButton(
            label: 'Get OTP',
            isLoading: isLoading,
            isDeactivated: !_isFormValid,
            onConfirmed: _register,
            onTapDisabled: _handleDisabledTap,
            onValidate: () => _formKey.currentState!.validate(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleLogin() {
    return Center(
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.login, extra: {'from': 'register'}),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: RichText(
            text: const TextSpan(
              style: TextStyle(color: Color(0xFF4A6B62), fontSize: 14),
              children: [
                TextSpan(text: 'Already have an account? '),
                TextSpan(
                  text: 'Log In',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4A6B62),
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _buildTerms() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 12,
            height: 1.5,
          ),
          children: [
            TextSpan(text: 'By continuing, you agree to our\n'),
            TextSpan(
              text: 'Terms of Service',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required Widget prefixIcon,
    Widget? suffixIcon,
  }) {
    const borderColor = Color(0xFF3D7A6B);
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      counterText: '',
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
      fillColor: Colors.white,
      filled: true,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        borderSide: const BorderSide(color: Color(0xFF3D7A6B), width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        borderSide: const BorderSide(color: borderColor, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
    );
  }
}
