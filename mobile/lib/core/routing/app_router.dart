import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/profile/presentation/pages/profile_setup_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/tasks/presentation/pages/task_selection_page.dart';
import '../../features/tasks/presentation/pages/request_timing_page.dart';
import '../../features/tasks/presentation/pages/request_notes_page.dart';
import '../../features/home/presentation/pages/home_page.dart';

part 'app_router.g.dart';

abstract final class AppRoutes {
  static const String splash        = '/';
  static const String login         = '/login';
  static const String register      = '/register';
  static const String otp           = '/otp';
  static const String profileSetup  = '/profile-setup';
  static const String taskSelect    = '/task-select';
  static const String requestTiming = '/request-timing';
  static const String requestNotes  = '/request-notes';
  static const String profile       = '/profile';
  static const String home          = '/home';
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(
      ref.read(authProvider.notifier).stream,
    ),
    redirect: (context, state) {
      final loc = state.uri.path;
      final authState = ref.read(authProvider);

      if (authState is AuthInitial) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (authState is AuthLoading || authState is AuthSuccessPending) {
        // Active screen displays its own animation/loader; do not redirect to splash
        return null;
      }

      if (authState is AuthOtpSent) {
        if (loc == AppRoutes.otp) return null;
        return AppRoutes.otp;
      }

      if (authState is AuthUnauthenticated) {
        if (loc == AppRoutes.login || loc == AppRoutes.register || loc == AppRoutes.otp) {
          return null;
        }
        return AppRoutes.login;
      }

      if (authState is AuthProfileSetupRequired) {
        if (loc == AppRoutes.profileSetup ||
            loc == AppRoutes.taskSelect ||
            loc == AppRoutes.requestTiming ||
            loc == AppRoutes.requestNotes) {
          return null;
        }
        return AppRoutes.profileSetup;
      }

      if (authState is AuthAuthenticated) {
        if (loc == AppRoutes.splash ||
            loc == AppRoutes.login ||
            loc == AppRoutes.register ||
            loc == AppRoutes.otp ||
            loc == AppRoutes.profileSetup) {
          return AppRoutes.home;
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (ctx, state) => const _SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (ctx, state) {
          final isFromRegister = state.extra is Map && (state.extra as Map)['from'] == 'register';
          return CustomTransitionPage(
            key: state.pageKey,
            child: const LoginPage(),
            transitionDuration: const Duration(milliseconds: 320),
            reverseTransitionDuration: const Duration(milliseconds: 320),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              if (isFromRegister) {
                final slideIn = Tween<Offset>(
                  begin: const Offset(-1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubicEmphasized,
                ));
                return SlideTransition(position: slideIn, child: child);
              }
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (ctx, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const RegisterPage(),
            transitionDuration: const Duration(milliseconds: 320),
            reverseTransitionDuration: const Duration(milliseconds: 320),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final slideIn = Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubicEmphasized,
              ));
              return SlideTransition(position: slideIn, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        builder: (ctx, state) {
          final authState = ref.read(authProvider);
          String email = '';
          String phone = '';
          if (authState is AuthOtpSent) {
            email = authState.email;
            phone = authState.phoneNumber;
          }
          return OtpPage(email: email, phoneNumber: phone);
        },
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        name: 'profileSetup',
        builder: (ctx, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: AppRoutes.taskSelect,
        name: 'taskSelect',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TaskSelectionPage(
            initialCategory: extra?['category_name'] as String?,
            initialService: extra?['service_name'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.requestTiming,
        name: 'requestTiming',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return RequestTimingPage(
            categoryName: extra['category_name'] as String? ?? 'General',
            serviceName: extra['service_name'] as String? ?? 'Service',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.requestNotes,
        name: 'requestNotes',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return RequestNotesPage(
            categoryName: extra['category_name'] as String? ?? 'General',
            serviceName: extra['service_name'] as String? ?? 'Service',
            timing: extra['timing'] as String? ?? 'Standard',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (ctx, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (ctx, state) => const ProfilePage(),
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}

/// Minimal splash while auth state resolves
class _SplashPage extends ConsumerStatefulWidget {
  const _SplashPage();

  @override
  ConsumerState<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<_SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        context.go(AppRoutes.home);
      } else if (authState is AuthProfileSetupRequired) {
        context.go(AppRoutes.profileSetup);
      } else if (authState is AuthOtpSent) {
        context.go(AppRoutes.otp);
      } else {
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F0E8),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PadosiProLogoSplash(),
            SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1E5E52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PadosiProLogoSplash extends StatelessWidget {
  const _PadosiProLogoSplash();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E5E52).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/images/ppro.png',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'PadosiPro',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
