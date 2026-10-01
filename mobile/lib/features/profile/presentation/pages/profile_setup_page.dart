import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _societyCtrl  = TextEditingController();
  final _flatCtrl     = TextEditingController();
  final _gateCtrl     = TextEditingController();
  final _bizNameCtrl  = TextEditingController();

  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    // Prepopulate fields if editing existing profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      final user = authState is AuthAuthenticated
          ? authState.user
          : (authState is AuthProfileSetupRequired ? authState.user : null);
      if (user != null) {
        if (user.name != null && user.name!.isNotEmpty) _nameCtrl.text = user.name!;
        if (user.address != null && user.address!.isNotEmpty) _addressCtrl.text = user.address!;
        if (user.society != null && user.society!.isNotEmpty) _societyCtrl.text = user.society!;
        if (user.flatUnit != null && user.flatUnit!.isNotEmpty) _flatCtrl.text = user.flatUnit!;
        if (user.gateNotes != null && user.gateNotes!.isNotEmpty) _gateCtrl.text = user.gateNotes!;
        if (user.businessName != null && user.businessName!.isNotEmpty) _bizNameCtrl.text = user.businessName!;
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _societyCtrl.dispose();
    _flatCtrl.dispose();
    _gateCtrl.dispose();
    _bizNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authState = ref.read(authProvider);
    final user = authState is AuthAuthenticated
        ? authState.user
        : (authState is AuthProfileSetupRequired ? authState.user : null);
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.put('/users/me/profile', data: {
        'name': _nameCtrl.text.trim(),
        'phone_number': user.phoneNumber,
        'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        'society': _societyCtrl.text.trim().isEmpty ? null : _societyCtrl.text.trim(),
        'flat_unit': _flatCtrl.text.trim().isEmpty ? null : _flatCtrl.text.trim(),
        'gate_notes': _gateCtrl.text.trim().isEmpty ? null : _gateCtrl.text.trim(),
        'business_name': _bizNameCtrl.text.trim().isEmpty ? null : _bizNameCtrl.text.trim(),
      });

      if (response.statusCode == 200) {
        final updatedUser = UserModel.fromJson(response.data['data']);
        ref.read(authProvider.notifier).profileCompleted(updatedUser);
        if (mounted) {
          if (context.canPop()) {
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            context.go(AppRoutes.taskSelect);
          }
        }
      } else {
        _showError('Failed to save profile. Please try again.');
      }
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: context.canPop()
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF1E5E52), size: 18),
                  onPressed: () => context.pop(),
                ),
                title: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: Color(0xFF102A24),
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.4,
                  ),
                ),
                centerTitle: true,
              )
            : null,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.pageHorizontalPadding,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSizes.md),
                          _buildHeader(context),
                          const SizedBox(height: AppSizes.xl),
                          AppTextField(
                            label: 'Full name',
                            controller: _nameCtrl,
                            hint: 'As you would like us to use',
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF4A6B62)),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Full name is required'
                                : null,
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(
                            label: 'Address & area',
                            controller: _addressCtrl,
                            hint: 'Road, area, landmark',
                            maxLines: 2,
                            prefixIcon: const Icon(Icons.home_outlined, size: 20, color: Color(0xFF4A6B62)),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Address is required'
                                : null,
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(
                            label: 'Society / building (optional)',
                            controller: _societyCtrl,
                            hint: 'Name as on the gate',
                            prefixIcon: const Icon(Icons.apartment_outlined, size: 20, color: Color(0xFF4A6B62)),
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(
                            label: 'Flat / unit (optional)',
                            controller: _flatCtrl,
                            hint: 'e.g. Tower B, 1204',
                            prefixIcon: const Icon(Icons.door_front_door_outlined, size: 20, color: Color(0xFF4A6B62)),
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(
                            label: 'Gate or entry notes (optional)',
                            controller: _gateCtrl,
                            hint: 'Anything the team should know at entry',
                            maxLines: 3,
                            prefixIcon: const Icon(Icons.note_outlined, size: 20, color: Color(0xFF4A6B62)),
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(
                            label: 'Business name (optional)',
                            controller: _bizNameCtrl,
                            hint: 'Your business / company name',
                            prefixIcon: const Icon(Icons.business_outlined, size: 20, color: Color(0xFF4A6B62)),
                          ),
                          const SizedBox(height: AppSizes.xl),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomBar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isEditing = context.canPop();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditing ? 'Update Details' : 'A few details',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          isEditing
              ? 'Keep your contact and address info up to date for seamless concierge service.'
              : 'So your Lifestyle Manager can coordinate\nvisits and deliveries smoothly.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final isEditing = context.canPop();
    return Container(
      padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: PrimaryButton(
        label: isEditing ? 'Save Changes' : 'Continue',
        isLoading: _isLoading,
        onPressed: _continue,
      ),
    );
  }
}
