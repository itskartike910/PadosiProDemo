import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/primary_button.dart';

// ── Models ───────────────────────────────────────────────────────────────────

class TaskCategory {
  final String id;
  final String name;
  final String? subtitle;
  final String icon;
  final bool isComingSoon;
  final List<TaskItem> tasks;

  const TaskCategory({
    required this.id,
    required this.name,
    this.subtitle,
    required this.icon,
    this.isComingSoon = false,
    required this.tasks,
  });

  factory TaskCategory.fromJson(Map<String, dynamic> json) => TaskCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        subtitle: json['subtitle'] as String?,
        icon: json['icon'] as String? ?? 'checklist',
        isComingSoon: json['is_coming_soon'] as bool? ?? false,
        tasks: (json['tasks'] as List<dynamic>?)
                ?.map((t) => TaskItem.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class TaskItem {
  final String id;
  final String name;
  final String? description;
  final String categoryId;

  const TaskItem({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        categoryId: json['category_id'] as String? ?? '',
      );
}

// ── Provider ─────────────────────────────────────────────────────────────────

final taskCatalogueProvider = FutureProvider<List<TaskCategory>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/tasks');
  if (response.statusCode == 200) {
    return (response.data['data'] as List<dynamic>)
        .map((c) => TaskCategory.fromJson(c as Map<String, dynamic>))
        .toList();
  }
  throw Exception('Failed to load tasks');
});

// ── Page ─────────────────────────────────────────────────────────────────────

class TaskSelectionPage extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String? initialService;

  const TaskSelectionPage({
    super.key,
    this.initialCategory,
    this.initialService,
  });

  @override
  ConsumerState<TaskSelectionPage> createState() => _TaskSelectionPageState();
}

class _TaskSelectionPageState extends ConsumerState<TaskSelectionPage> {
  String? _expandedCategoryId;
  String? _selectedServiceName;
  String? _selectedCategoryName;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _didAutoExpand = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryName = widget.initialCategory;
    _selectedServiceName = widget.initialService;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  IconData _getIconData(String icon) {
    switch (icon.toLowerCase()) {
      case 'checklist':
        return Icons.check_box_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'location':
        return Icons.location_on_outlined;
      case 'heart':
        return Icons.favorite_border_rounded;
      case 'senior':
        return Icons.elderly_rounded;
      case 'event':
        return Icons.celebration_outlined;
      case 'workforce':
        return Icons.business_center_outlined;
      case 'tech':
        return Icons.wifi_rounded;
      case 'relocation':
        return Icons.local_shipping_outlined;
      case 'food':
        return Icons.restaurant_rounded;
      case 'fashion':
        return Icons.content_cut_rounded;
      case 'religious':
        return Icons.temple_hindu_outlined;
      case 'business':
        return Icons.domain_rounded;
      case 'education':
        return Icons.school_outlined;
      case 'finance':
        return Icons.account_balance_outlined;
      default:
        return Icons.grid_view_rounded;
    }
  }

  void _onCategoryTapped(TaskCategory cat) {
    setState(() {
      if (_expandedCategoryId == cat.id) {
        _expandedCategoryId = null;
      } else {
        _expandedCategoryId = cat.id;
        _selectedCategoryName = cat.name;
        // If only 1 task or previously selected from another category, reset
        if (_selectedServiceName != null &&
            !cat.tasks.any((t) => t.name == _selectedServiceName)) {
          _selectedServiceName = null;
        }
      }
    });
  }

  void _onServiceSelected(TaskCategory cat, String serviceName) {
    setState(() {
      _selectedCategoryName = cat.name;
      _selectedServiceName = serviceName;
    });
  }

  void _handleContinue() {
    if (_selectedCategoryName == null || _selectedServiceName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a service to continue.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.push(
      AppRoutes.requestTiming,
      extra: {
        'category_name': _selectedCategoryName!,
        'service_name': _selectedServiceName!,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogueAsync = ref.watch(taskCatalogueProvider);

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
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.pageHorizontalPadding,
                          vertical: AppSizes.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Back Button
                            GestureDetector(
                              onTap: () {
                                if (Navigator.canPop(context)) {
                                  context.pop();
                                } else {
                                  context.go(AppRoutes.home);
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_back_ios_new_rounded,
                                        size: 16, color: Color(0xFF1E5E52)),
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
                            Text(
                              'What do you need help with?',
                              style: GoogleFonts.sora(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF102A24),
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            Text(
                              'Pick a category, then choose a service. You can add details next.',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                color: const Color(0xFF5A756E),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: AppSizes.md),

                            // Real-time Search Filter Bar
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: const Color(0xFFDCE6E2), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded,
                                      color: Color(0xFF6C8780), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchCtrl,
                                      onChanged: (val) =>
                                          setState(() => _searchQuery = val.trim().toLowerCase()),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Search services, AC, cleaning...',
                                        hintStyle: TextStyle(
                                          color: Color(0xFF8DA39D),
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      child: const Icon(Icons.close_rounded,
                                          size: 18, color: Color(0xFF8DA39D)),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSizes.lg),
                          ],
                        ),
                      ),
                    ),

                    // Categories List
                    catalogueAsync.when(
                      loading: () => const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF1E5E52)),
                        ),
                      ),
                      error: (e, _) => SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_rounded,
                                  size: 48, color: AppColors.error),
                              const SizedBox(height: 12),
                              const Text('Failed to load services catalogue.'),
                              TextButton(
                                onPressed: () =>
                                    ref.refresh(taskCatalogueProvider),
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (categories) {
                        if (!_didAutoExpand && widget.initialCategory != null) {
                          _didAutoExpand = true;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final match = categories.where((c) =>
                                c.name.toLowerCase().contains(widget.initialCategory!.toLowerCase()) ||
                                widget.initialCategory!.toLowerCase().contains(c.name.toLowerCase())).firstOrNull;
                            if (match != null && mounted) {
                              setState(() {
                                _expandedCategoryId = match.id;
                                _selectedCategoryName = match.name;
                                if (widget.initialService != null) {
                                  _selectedServiceName = widget.initialService;
                                }
                              });
                            }
                          });
                        }

                        final filtered = categories.where((cat) {
                          if (_searchQuery.isEmpty) return true;
                          final matchCat = cat.name.toLowerCase().contains(_searchQuery) ||
                              (cat.subtitle?.toLowerCase().contains(_searchQuery) ?? false);
                          final matchTasks = cat.tasks.any(
                              (t) => t.name.toLowerCase().contains(_searchQuery));
                          return matchCat || matchTasks;
                        }).toList();

                        if (filtered.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.xxl),
                              child: Center(
                                child: Text(
                                  'No services matching "$_searchQuery"',
                                  style: const TextStyle(
                                    color: Color(0xFF6C8780),
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.pageHorizontalPadding,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final cat = filtered[index];
                                final isExpanded = _expandedCategoryId == cat.id ||
                                    (_searchQuery.isNotEmpty &&
                                        cat.tasks.any((t) => t.name
                                            .toLowerCase()
                                            .contains(_searchQuery)));
                                return _buildCategoryCard(cat, isExpanded);
                              },
                              childCount: filtered.length,
                            ),
                          ),
                        );
                      },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),

              // Bottom Sticky Continue Bar
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg, vertical: AppSizes.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.15))),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: PrimaryButton(
                  label: 'Continue',
                  onPressed: _selectedServiceName == null ? null : _handleContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(TaskCategory cat, bool isExpanded) {
    final isSelectedCategory = _selectedCategoryName == cat.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isExpanded ? const Color(0xFFEEF8F5) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isExpanded ? const Color(0xFF1E5E52) : const Color(0xFFE2ECE8),
            width: isExpanded ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isExpanded
                  ? const Color(0xFF1E5E52).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isExpanded ? 10 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: isExpanded
                ? const BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Color(0xFFC4A000), // Gold left accent line
                        width: 4.5,
                      ),
                    ),
                  )
                : null,
            child: InkWell(
              onTap: () => _onCategoryTapped(cat),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Icon box
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: isExpanded
                                ? const Color(0xFF1E5E52)
                                : const Color(0xFFE6F4F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIconData(cat.icon),
                            color: isExpanded ? Colors.white : const Color(0xFF1E5E52),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      cat.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF102A24),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  if (cat.isComingSoon)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7EEDD),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Soon',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF9E651E),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (cat.subtitle != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  cat.subtitle!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6C8780),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Expanded Sub-services section
                    if (isExpanded && cat.tasks.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.md),
                      const Divider(height: 1, color: Color(0xFFD4E5DF)),
                      const SizedBox(height: AppSizes.md),
                      const Text(
                        'WHAT KIND OF HELP?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A6B62),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),

                      // Sub-service Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: cat.tasks.map((task) {
                          final isSelected = isSelectedCategory &&
                              _selectedServiceName == task.name;
                          return InkWell(
                            onTap: () => _onServiceSelected(cat, task.name),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1E5E52)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1E5E52)
                                      : const Color(0xFFD2E2DC),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? const Color(0xFF1E5E52)
                                            .withValues(alpha: 0.2)
                                        : Colors.black.withValues(alpha: 0.02),
                                    blurRadius: isSelected ? 6 : 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                task.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF1E2B27),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
