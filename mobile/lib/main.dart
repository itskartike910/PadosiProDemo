import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Gracefully suppress offline font network errors so UI renders with fallback fonts
  FlutterError.onError = (details) {
    final msg = details.exception.toString();
    if (msg.contains('fonts.gstatic.com') || msg.contains('Failed to load font')) {
      return;
    }
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final msg = error.toString();
    if (msg.contains('fonts.gstatic.com') || msg.contains('Failed to load font')) {
      return true; // handled
    }
    return false;
  };

  runApp(
    const ProviderScope(
      child: PadosiProApp(),
    ),
  );
}

class PadosiProApp extends ConsumerWidget {
  const PadosiProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PadosiPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
