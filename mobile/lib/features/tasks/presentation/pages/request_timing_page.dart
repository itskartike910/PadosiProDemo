import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/primary_button.dart';

class RequestTimingPage extends StatefulWidget {
  final String categoryName;
  final String serviceName;

  const RequestTimingPage({
    super.key,
    required this.categoryName,
    required this.serviceName,
  });

  @override
  State<RequestTimingPage> createState() => _RequestTimingPageState();
}

class _RequestTimingPageState extends State<RequestTimingPage> {
  String _selectedTiming = 'Standard';

  final List<Map<String, dynamic>> _options = const [
    {
      'title': 'Standard',
      'subtitle': 'Within a few days is fine',
      'icon': Icons.calendar_today_outlined,
    },
    {
      'title': 'Same day',
      'subtitle': 'Today if possible',
      'icon': Icons.wb_sunny_outlined,
    },
    {
      'title': 'Express',
      'subtitle': 'As soon as you can',
      'icon': Icons.bolt_outlined,
    },
    {
      'title': 'Scheduled',
      'subtitle': 'I have a specific time',
      'icon': Icons.access_time_rounded,
    },
  ];

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
                      const Text(
                        'When do you need this?',
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
                        'Pick what feels closest. You can always add detail next.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF5A756E),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xl),
                      // Options list
                      ..._options.map((opt) {
                        final isSelected = _selectedTiming == opt['title'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.md),
                          child: InkWell(
                            onTap: () => setState(() => _selectedTiming = opt['title'] as String),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(AppSizes.lg),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF1E5E52) : const Color(0xFFE2ECE8),
                                  width: isSelected ? 2.0 : 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? const Color(0xFF1E5E52).withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.03),
                                    blurRadius: isSelected ? 12 : 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFE8F5F2)
                                          : const Color(0xFFF2F6F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      opt['icon'] as IconData,
                                      color: isSelected ? const Color(0xFF1E5E52) : const Color(0xFF5A756E),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: AppSizes.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          opt['title'] as String,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? const Color(0xFF102A24)
                                                : const Color(0xFF263330),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          opt['subtitle'] as String,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6C8780),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF1E5E52),
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // Bottom bar
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
                  label: 'Next',
                  onPressed: () {
                    context.push(
                      AppRoutes.requestNotes,
                      extra: {
                        'category_name': widget.categoryName,
                        'service_name': widget.serviceName,
                        'timing': _selectedTiming,
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
