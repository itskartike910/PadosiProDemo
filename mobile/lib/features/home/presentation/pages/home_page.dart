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
import '../../../auth/presentation/providers/auth_provider.dart';

// ── Active Request Provider ──────────────────────────────────────────────────

final activeRequestProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/users/me/requests/active');
  if (response.statusCode == 200 && response.data['data'] != null) {
    return response.data['data'] as Map<String, dynamic>;
  }
  return null;
});

// ── Category & Service Models (From seed.py) ─────────────────────────────────

class _CategoryData {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String filterKey;
  final bool isComingSoon;

  const _CategoryData({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.filterKey,
    this.isComingSoon = false,
  });
}

class _PopularTaskData {
  final String title;
  final String category;
  final String description;
  final String timing;
  final String rating;
  final List<Color> gradient;

  const _PopularTaskData({
    required this.title,
    required this.category,
    required this.description,
    required this.timing,
    required this.rating,
    required this.gradient,
  });
}

// ── Home Page ────────────────────────────────────────────────────────────────

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // Real 15 Categories from backend/src/seed.py
  static const List<_CategoryData> _categories = [
    _CategoryData(
      name: 'Errands & Daily Tasks',
      subtitle: 'Bills, banks, documents, government work',
      icon: Icons.check_box_outlined,
      color: Color(0xFF8B5CF6), // Electric Violet
      filterKey: 'Errands & Daily Tasks',
    ),
    _CategoryData(
      name: 'Home Services',
      subtitle: 'AC, plumbing, electrical, cleaning, repairs',
      icon: Icons.home_outlined,
      color: Color(0xFF00B4CC), // Electric Cyan
      filterKey: 'Home Services',
    ),
    _CategoryData(
      name: 'Travel & Tourism',
      subtitle: 'Flights, hotels, visas, transfers, itineraries',
      icon: Icons.location_on_outlined,
      color: Color(0xFF0EA5E9), // Sky Blue
      filterKey: 'Travel & Tourism',
    ),
    _CategoryData(
      name: 'Health & Medical',
      subtitle: 'Doctor visits, pharmacy, labs, physio',
      icon: Icons.favorite_border_rounded,
      color: Color(0xFFFF6B8A), // Coral Pink
      filterKey: 'Health & Medical',
    ),
    _CategoryData(
      name: 'Senior Care',
      subtitle: 'Check-ins, medicines, vitals, companionship',
      icon: Icons.elderly_rounded,
      color: Color(0xFF1E5E52), // Pine Teal
      filterKey: 'Senior Care',
    ),
    _CategoryData(
      name: 'Events & Management',
      subtitle: 'Weddings, décor, catering, photography',
      icon: Icons.celebration_outlined,
      color: Color(0xFFFFB800), // Electric Gold
      filterKey: 'Events & Management',
    ),
    _CategoryData(
      name: 'Workforce Management',
      subtitle: 'Maids, cooks, drivers, nannies, payroll',
      icon: Icons.business_center_outlined,
      color: Color(0xFFFF8C42), // Vivid Orange
      filterKey: 'Workforce Management',
    ),
    _CategoryData(
      name: 'Digital & Tech Help',
      subtitle: 'WiFi, CCTV, smart locks, devices',
      icon: Icons.wifi_rounded,
      color: Color(0xFF05CC78), // Neon Mint
      filterKey: 'Digital & Tech Help',
    ),
    _CategoryData(
      name: 'Relocation Services',
      subtitle: 'Packers, movers, handover, paperwork',
      icon: Icons.local_shipping_outlined,
      color: Color(0xFFF97316), // Tangerine
      filterKey: 'Relocation Services',
    ),
    _CategoryData(
      name: 'NutriFix',
      subtitle: 'Groceries, food delivery, diet plans, meal prep',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFE11D48), // Rose Red
      filterKey: 'NutriFix',
      isComingSoon: true,
    ),
    _CategoryData(
      name: 'Fashion & Styling',
      subtitle: 'Salon at home, tailoring, styling, gifting',
      icon: Icons.content_cut_rounded,
      color: Color(0xFFA855F7), // Purple
      filterKey: 'Fashion & Styling',
      isComingSoon: true,
    ),
    _CategoryData(
      name: 'Religious & Cultural',
      subtitle: 'Pandit booking, puja, temple visits',
      icon: Icons.temple_hindu_outlined,
      color: Color(0xFFD97706), // Amber
      filterKey: 'Religious & Cultural',
      isComingSoon: true,
    ),
    _CategoryData(
      name: 'Business Support',
      subtitle: 'Registration, GST, bookkeeping, compliance',
      icon: Icons.domain_rounded,
      color: Color(0xFF475569), // Slate
      filterKey: 'Business Support',
      isComingSoon: true,
    ),
    _CategoryData(
      name: 'Education Support',
      subtitle: 'Tutors, admissions, exam prep',
      icon: Icons.school_outlined,
      color: Color(0xFF0284C7), // Blue
      filterKey: 'Education Support',
      isComingSoon: true,
    ),
    _CategoryData(
      name: 'Insurance & Loans',
      subtitle: 'Compare policies, plan loans, paperwork handled',
      icon: Icons.account_balance_outlined,
      color: Color(0xFF14B8A6), // Teal
      filterKey: 'Insurance & Loans',
      isComingSoon: true,
    ),
  ];

  // Real Popular Everyday Tasks from backend/src/seed.py
  static const List<_PopularTaskData> _popularTasks = [
    _PopularTaskData(
      title: 'Pickups & Deliveries',
      category: 'Errands & Daily Tasks',
      description: 'Packages, parcels, keys, laundry and urgent items delivered.',
      timing: 'Same day',
      rating: '4.9 (1.4k)',
      gradient: [Color(0xFFFFB800), Color(0xFFFF8C42)],
    ),
    _PopularTaskData(
      title: 'Cleaning',
      category: 'Home Services',
      description: 'Deep cleaning, kitchen degreasing, bathroom scrubbing & sofas.',
      timing: 'Scheduled',
      rating: '4.8 (2.8k)',
      gradient: [Color(0xFF00E5FF), Color(0xFF00B4CC)],
    ),
    _PopularTaskData(
      title: 'Appointments & Tests',
      category: 'Health & Medical',
      description: 'Specialist consultations, diagnostic scans & lab tests at home.',
      timing: 'Express',
      rating: '4.9 (1.2k)',
      gradient: [Color(0xFFFF6B8A), Color(0xFFCC3050)],
    ),
    _PopularTaskData(
      title: 'Daily Care',
      category: 'Senior Care',
      description: 'Scheduled home visits, vitals monitoring, companion & medicines.',
      timing: 'Routine',
      rating: '5.0 (650)',
      gradient: [Color(0xFF10F99A), Color(0xFF05CC78)],
    ),
    _PopularTaskData(
      title: 'Hire Staff',
      category: 'Workforce Management',
      description: 'Verified domestic help, cooks, drivers & attendance tracking.',
      timing: 'Verified',
      rating: '4.8 (1.1k)',
      gradient: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    ),
    _PopularTaskData(
      title: 'Device Setup',
      category: 'Digital & Tech Help',
      description: 'CCTV security, smart locks, mesh WiFi & gadget setup.',
      timing: 'On-Demand',
      rating: '4.9 (840)',
      gradient: [Color(0xFF38BDF8), Color(0xFF0284C7)],
    ),
    _PopularTaskData(
      title: 'Book Travel',
      category: 'Travel & Tourism',
      description: 'Flight tickets, airport transfers, cabs & boutique stays.',
      timing: 'Scheduled',
      rating: '4.9 (980)',
      gradient: [Color(0xFFF97316), Color(0xFFEA580C)],
    ),
  ];

  // Quick Text-Based Task Shortcuts from seed.py
  static const List<Map<String, String>> _quickTaskChips = [
    {'title': 'Pickups & Deliveries', 'category': 'Errands & Daily Tasks'},
    {'title': 'Payments & Renewals', 'category': 'Errands & Daily Tasks'},
    {'title': 'Cleaning', 'category': 'Home Services'},
    {'title': 'Repairs', 'category': 'Home Services'},
    {'title': 'Appliances & Utilities', 'category': 'Home Services'},
    {'title': 'Appointments & Tests', 'category': 'Health & Medical'},
    {'title': 'Daily Care', 'category': 'Senior Care'},
    {'title': 'Hire Staff', 'category': 'Workforce Management'},
    {'title': 'Device Setup', 'category': 'Digital & Tech Help'},
    {'title': 'Book Travel', 'category': 'Travel & Tourism'},
    {'title': 'Local Transport', 'category': 'Travel & Tourism'},
  ];

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated
        ? authState.user
        : (authState is AuthProfileSetupRequired ? authState.user : null);
    final fullName = user?.name ?? 'there';
    final firstName = fullName.split(' ').first;

    final locationLabel = user?.society?.isNotEmpty == true
        ? user!.society!
        : 'Select Location';
    final locationSubtitle = user?.address?.isNotEmpty == true
        ? user!.address!
        : 'Where do you need the service?';

    final activeRequestAsync = ref.watch(activeRequestProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ── PINNED TOP BAR (Always Visible, Never Cut Off) ─────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pageHorizontalPadding,
                  AppSizes.sm,
                  AppSizes.pageHorizontalPadding,
                  AppSizes.xs,
                ),
                child: _buildTopBar(context, locationLabel, locationSubtitle, firstName),
              ),

              // ── SCROLLABLE DASHBOARD CONTENT ───────────────────────────
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: Colors.white,
                  onRefresh: () async {
                    ref.invalidate(activeRequestProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.pageHorizontalPadding,
                      vertical: AppSizes.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── GREETING & HEADING ────────────────────────────
                        _buildGreeting(firstName),
                        const SizedBox(height: AppSizes.md),

                        // ── SEARCH BAR & FILTER ───────────────────────────
                        _buildSearchBar(context),
                        const SizedBox(height: AppSizes.lg),

                        // ── ACTIVE REQUEST (IF ANY) ───────────────────────
                        activeRequestAsync.when(
                          data: (activeReq) {
                            if (activeReq != null) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSizes.xl),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionHeader(
                                      'Your Active Request',
                                      onActionTap: () => _showRequestDetails(context, activeReq),
                                      actionLabel: 'Details →',
                                    ),
                                    const SizedBox(height: AppSizes.sm),
                                    _buildActiveRequestCard(context, activeReq),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),

                        // ── CATEGORIES (Text-based details from seed.py) ───
                        _buildSectionHeader(
                          'Categories',
                          onActionTap: () => context.push(AppRoutes.taskSelect),
                          actionLabel: 'View All (15) →',
                        ),
                        const SizedBox(height: AppSizes.sm),
                        _buildCategoriesList(context),
                        const SizedBox(height: AppSizes.xl),

                        // ── POPULAR TASKS (From seed.py) ──────────────────
                        _buildSectionHeader(
                          'Popular Everyday Tasks',
                          onActionTap: () => context.push(AppRoutes.taskSelect),
                          actionLabel: 'Browse All →',
                        ),
                        const SizedBox(height: AppSizes.sm),
                        _buildPopularTasksList(context),
                        const SizedBox(height: AppSizes.xl),

                        // ── QUICK TASK CHIPS (Text-based tags) ─────────────
                        _buildSectionHeader(
                          'Explore by Need',
                          onActionTap: () => context.push(AppRoutes.taskSelect),
                          actionLabel: 'All Services →',
                        ),
                        const SizedBox(height: AppSizes.sm),
                        _buildQuickChips(context),
                        const SizedBox(height: AppSizes.xl),

                        // ── WHY CHOOSE PADOSIPRO ──────────────────────────
                        _buildWhyChooseSection(),
                        const SizedBox(height: AppSizes.xl),

                        // ── DEDICATED CONCIERGE CARD ──────────────────────
                        _buildConciergeCard(context),
                        const SizedBox(height: AppSizes.xxxl),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(
    BuildContext context,
    String locationLabel,
    String locationSubtitle,
    String firstName,
  ) {
    return Row(
      children: [
        // Location Selector
        Expanded(
          child: GestureDetector(
            onTap: () => _showLocationSheet(context, locationLabel, locationSubtitle),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              locationLabel,
                              style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textHeading,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                      Text(
                        locationSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: AppSizes.md),

        // Profile Menu Button (drops down Profile & Logout)
        Theme(
          data: Theme.of(context).copyWith(
            cardColor: Colors.white,
          ),
          child: PopupMenuButton<String>(
            tooltip: 'Account Menu',
            offset: const Offset(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.divider, width: 1.2),
            ),
            elevation: 8,
            color: Colors.white,
            onSelected: (val) {
              if (val == 'profile') {
                context.push(AppRoutes.profile);
              } else if (val == 'logout') {
                _confirmLogout(context);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'profile',
                height: 46,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Profile',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem<String>(
                value: 'logout',
                height: 46,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'P',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Greeting ───────────────────────────────────────────────────────────────

  Widget _buildGreeting(String firstName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            children: [
              TextSpan(text: '${_greeting()}, '),
              TextSpan(
                text: '$firstName 👋',
                style: GoogleFonts.sora(
                  color: AppColors.textHeading,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'What are you looking for?',
          style: GoogleFonts.sora(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textHeading,
          ),
        ),
      ],
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push(AppRoutes.taskSelect),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: AppColors.divider, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.textHint,
                    size: 22,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    'Search tasks, cleaning, errands...',
                    style: GoogleFonts.outfit(
                      color: AppColors.textHint,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        GestureDetector(
          onTap: () => _showFilterSheet(context),
          child: Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: AppColors.divider, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
          ),
        ),
      ],
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    String title, {
    required VoidCallback onActionTap,
    required String actionLabel,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textHeading,
          ),
        ),
        GestureDetector(
          onTap: onActionTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusRound),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.outfit(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Categories List (Text-based cards with subtitles from seed.py) ──────────

  Widget _buildCategoriesList(BuildContext context) {
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.md),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          return GestureDetector(
            onTap: () {
              context.push(
                AppRoutes.taskSelect,
                extra: {'category_name': cat.filterKey},
              );
            },
            child: Container(
              width: 195,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: cat.color.withValues(alpha: 0.22),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cat.color.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 20),
                      ),
                      if (cat.isComingSoon)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Soon',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: cat.color.withValues(alpha: 0.6),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.name,
                    style: GoogleFonts.sora(
                      color: AppColors.textHeading,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    cat.subtitle,
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Popular Tasks List (Text-based descriptions from seed.py) ──────────────

  Widget _buildPopularTasksList(BuildContext context) {
    return SizedBox(
      height: 195,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _popularTasks.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.md),
        itemBuilder: (context, i) {
          final t = _popularTasks[i];
          return GestureDetector(
            onTap: () {
              context.push(
                AppRoutes.requestTiming,
                extra: {
                  'category_name': t.category,
                  'service_name': t.title,
                },
              );
            },
            child: Container(
              width: 235,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: t.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: t.gradient.last.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -16,
                    top: -16,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Rating & Timing Badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                                  const SizedBox(width: 3),
                                  Text(
                                    t.rating,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              child: Text(
                                t.timing,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Title, Description & Action
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              style: GoogleFonts.sora(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.description,
                              style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  t.category,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Book',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 11,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Quick Task Chips (Explore by Need) ─────────────────────────────────────

  Widget _buildQuickChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _quickTaskChips.map((c) {
        return GestureDetector(
          onTap: () {
            context.push(
              AppRoutes.requestTiming,
              extra: {
                'category_name': c['category']!,
                'service_name': c['title']!,
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  c['title']!,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Active Request Card ────────────────────────────────────────────────────

  Widget _buildActiveRequestCard(BuildContext context, Map<String, dynamic> req) {
    final categoryName = req['category_name'] as String? ?? 'General Request';
    final serviceName = req['service_name'] as String? ?? '';
    final status = req['status'] as String? ?? 'In Progress';

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName.isNotEmpty ? serviceName : categoryName,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _showRequestDetails(context, req),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    'View',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Why Choose PadosiPro ───────────────────────────────────────────────────

  Widget _buildWhyChooseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why Choose PadosiPro?',
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        const Row(
          children: [
            Expanded(
              child: _FeaturePill(
                icon: Icons.verified_rounded,
                label: 'Verified Pros',
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: AppSizes.sm),
            Expanded(
              child: _FeaturePill(
                icon: Icons.shield_rounded,
                label: '100% Safe',
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        const Row(
          children: [
            Expanded(
              child: _FeaturePill(
                icon: Icons.star_rounded,
                label: 'Top Rated',
                color: AppColors.accent,
              ),
            ),
            SizedBox(width: AppSizes.sm),
            Expanded(
              child: _FeaturePill(
                icon: Icons.support_agent_rounded,
                label: '24/7 Support',
                color: AppColors.accentCoral,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Concierge Card / Custom CTA ────────────────────────────────────────────

  Widget _buildConciergeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_pin_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dedicated Lifestyle Manager',
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your personal household concierge',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Need custom errands, bill management, or special coordination? Tell your Lifestyle Manager what you need.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          PrimaryButton(
            label: 'Request Custom Help',
            onPressed: () => context.push(AppRoutes.taskSelect),
          ),
        ],
      ),
    );
  }

  // ── Filter Sheet ───────────────────────────────────────────────────────────

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSizes.lg),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Browse Services',
              style: GoogleFonts.sora(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Quickly jump into categories or browse the full catalogue',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: _FilterChip(
                    label: '📋 All Categories',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.taskSelect);
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: _FilterChip(
                    label: '⭐ Popular Tasks',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.taskSelect);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  // ── Location Sheet ─────────────────────────────────────────────────────────

  void _showLocationSheet(
    BuildContext context,
    String label,
    String details,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Service Location',
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHeading,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHeading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          details,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            PrimaryButton(
              label: 'Edit Address in Profile',
              onPressed: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.profileSetup);
              },
            ),
            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }

  // ── Request Details Sheet ──────────────────────────────────────────────────

  void _showRequestDetails(BuildContext context, Map<String, dynamic> req) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Request Details',
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHeading,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            _detailRow('Category', req['category_name'] ?? '—'),
            _detailRow('Service', req['service_name'] ?? '—'),
            _detailRow('Timing', req['timing'] ?? 'Standard'),
            if (req['notes'] != null && (req['notes'] as String).isNotEmpty)
              _detailRow('Notes', req['notes']),
            _detailRow('Status', req['status'] ?? 'We are looking at it'),
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout Dialog ──────────────────────────────────────────────────────────

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out',
          style: GoogleFonts.sora(
            fontWeight: FontWeight.w800,
            color: AppColors.textHeading,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of PadosiPro?',
          style: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
              context.go(AppRoutes.login);
            },
            child: Text(
              'Log Out',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature Pill ─────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSizes.sm),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
