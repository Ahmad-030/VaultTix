// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'services/providers.dart';
import 'theme/app_theme.dart';
import 'utils/app_router.dart';
import 'utils/auto_lock_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.darkBg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    const ProviderScope(
      child: VaultTixApp(),
    ),
  );
}

class VaultTixApp extends ConsumerStatefulWidget {
  const VaultTixApp({super.key});

  @override
  ConsumerState<VaultTixApp> createState() => _VaultTixAppState();
}

class _VaultTixAppState extends ConsumerState<VaultTixApp> {
  late AutoLockManager _autoLockManager;

  @override
  void initState() {
    super.initState();
    _autoLockManager = AutoLockManager(
      onLock: () {
        final isLocked = ref.read(isLockedProvider);
        if (!isLocked) {
          ref.read(isLockedProvider.notifier).state = true;
          appRouter.go('/lock');
        }
      },
    );
  }

  @override
  void dispose() {
    _autoLockManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'VaultTix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // prevent font scaling
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
