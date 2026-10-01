import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/primary_button.dart';

class RequestNotesPage extends ConsumerStatefulWidget {
  final String categoryName;
  final String serviceName;
  final String timing;

  const RequestNotesPage({
    super.key,
    required this.categoryName,
    required this.serviceName,
    required this.timing,
  });

  @override
  ConsumerState<RequestNotesPage> createState() => _RequestNotesPageState();
}

class _RequestNotesPageState extends ConsumerState<RequestNotesPage> {
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post('/users/me/requests', data: {
        'category_name': widget.categoryName,
        'service_name': widget.serviceName,
        'timing': widget.timing,
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          context.go(AppRoutes.home);
        }
      } else {
        _showError('Failed to submit request. Please try again.');
      }
    } catch (e) {
      _showError('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
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
        backgroundColor: const Color(0xFFF8FAF9),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pageHorizontalPadding,
                    vertical: AppSizes.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF1E5E52)),
                              SizedBox(width: 6),
                              Text(
                                'Back',
                                style: TextStyle(
                                  color: Color(0xFF1E5E52),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Category & Service Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF6EC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE8D4B8), width: 1.2),
                        ),
                        child: Text(
                          '${widget.categoryName} • ${widget.serviceName}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9E651E),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),

                      const Text(
                        'Tell us a little more',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF102A24),
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      const Text(
                        "One or two lines is enough. We'll take it from there.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF5A756E),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xl),

                      // Text Area
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD4E2DD), width: 1.4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _notesCtrl,
                          minLines: 5,
                          maxLines: 8,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1A1A1A),
                            height: 1.4,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'e.g. AC in the guest room is leaking onto the floor',
                            hintStyle: TextStyle(
                              color: Color(0xFF9EABA7),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(AppSizes.lg),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Bar with "Leave it with us"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: PrimaryButton(
                  label: 'Leave it with us',
                  isLoading: _isLoading,
                  onPressed: _submitRequest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
